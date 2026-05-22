-- =====================================================================
-- Wave A.5 — 사업비 구성표 모델 (비목 라인 + 산출 근거)
-- 작성자: 아키텍쳐설계 | 일자: 2026-05-20
--
-- 변경 사항
--  1) budget_items.description 추가 (카테고리 보충 설명, 선택)
--  2) budget_item_lines 테이블 신규 (사업비 구성표의 한 행 = 1 레코드)
--     - 산출 근거(description), 단가/수량/기간, 재원, 라인 합계
--  3) expenses.budget_item_line_id 추가 (어느 라인에서 집행했는지 추적)
--  4) View: v_budget_item_line_execution (라인별 집행 합계)
--  5) RLS 정책 + 트리거
-- =====================================================================

-- ---------------------------------------------------------------------
-- 1) budget_items 보강
-- ---------------------------------------------------------------------
alter table public.budget_items
  add column if not exists description text;

comment on column public.budget_items.description is '비목 카테고리 보충 설명 (선택). 실제 산출 근거는 budget_item_lines.description.';

-- ---------------------------------------------------------------------
-- 2) budget_item_lines 신규
-- ---------------------------------------------------------------------
create table public.budget_item_lines (
  id                uuid primary key default gen_random_uuid(),
  organization_id   uuid not null references public.organizations(id) on delete cascade,
  project_id        uuid not null references public.projects(id) on delete cascade,
  budget_item_id    uuid not null references public.budget_items(id) on delete cascade,

  description       text not null,                       -- 산출 근거: "개발자 인건비 340만원 X 2명 X 5개월"
  source_type       public.funding_source not null,      -- 라인 단위 재원
  planned_amount    numeric(15,0) not null default 0,    -- 라인 합계

  unit_price        numeric(15,0),                       -- 단가 (선택, 자동 계산 보조)
  quantity          numeric(10,2),                       -- 수량/인원 (선택)
  period_months     int,                                 -- 기간(개월, 선택)

  sort_order        int not null default 0,
  memo              text,

  created_by        uuid references public.profiles(id),
  updated_by        uuid references public.profiles(id),
  created_at        timestamptz not null default now(),
  updated_at        timestamptz not null default now(),

  constraint budget_item_lines_planned_nonneg check (planned_amount >= 0)
);

comment on table public.budget_item_lines is '사업비 구성표의 한 행. 예: 인건비 > "개발자 340만원 X 2명 X 5개월" = 34M / gov_grant.';

create index budget_item_lines_item_idx on public.budget_item_lines(budget_item_id, sort_order);
create index budget_item_lines_project_idx on public.budget_item_lines(project_id);
create index budget_item_lines_project_source_idx on public.budget_item_lines(project_id, source_type);

-- ---------------------------------------------------------------------
-- 3) expenses.budget_item_line_id (라인 단위 집행 추적)
-- ---------------------------------------------------------------------
alter table public.expenses
  add column if not exists budget_item_line_id uuid references public.budget_item_lines(id) on delete set null;

create index if not exists expenses_line_idx on public.expenses(budget_item_line_id) where budget_item_line_id is not null;

comment on column public.expenses.budget_item_line_id is '집행 건이 속한 비목 라인 (선택). 라인이 있는 사업은 권장, 없는 사업은 NULL 허용.';

-- ---------------------------------------------------------------------
-- 4) View — 라인별 집행 합계
-- ---------------------------------------------------------------------
create or replace view public.v_budget_item_line_execution as
select
  bil.id              as line_id,
  bil.budget_item_id,
  bil.project_id,
  bil.organization_id,
  bil.description,
  bil.source_type,
  bil.planned_amount,
  coalesce(sum(e.amount), 0)::numeric(15,0)                              as executed_amount,
  (bil.planned_amount - coalesce(sum(e.amount), 0))::numeric(15,0)       as remaining_amount,
  case when bil.planned_amount > 0
       then round(coalesce(sum(e.amount), 0) / bil.planned_amount * 100, 1)
       else 0 end                                                         as execution_rate
from public.budget_item_lines bil
left join public.expenses e on e.budget_item_line_id = bil.id
group by bil.id;

alter view public.v_budget_item_line_execution set (security_invoker = on);

-- ---------------------------------------------------------------------
-- 5) View — 비목별 집행 (라인 합계 우선, 없으면 직접 planned_amount)
--    기존 view 컬럼 구조 변경 → drop 후 재생성
-- ---------------------------------------------------------------------
drop view if exists public.v_budget_item_execution;

create view public.v_budget_item_execution as
select
  bi.id                                                                   as budget_item_id,
  bi.project_id,
  bi.organization_id,
  bi.name,
  bi.description,
  bi.planned_amount                                                       as planned_direct,
  coalesce(line_sum.planned, 0)                                           as planned_from_lines,
  case when coalesce(line_sum.planned, 0) > 0
       then line_sum.planned
       else bi.planned_amount end                                         as planned_amount,
  coalesce(sum(e.amount), 0)::numeric(15,0)                               as executed_amount,
  (case when coalesce(line_sum.planned, 0) > 0
       then line_sum.planned
       else bi.planned_amount end - coalesce(sum(e.amount), 0))::numeric(15,0) as remaining_amount,
  case when (case when coalesce(line_sum.planned, 0) > 0 then line_sum.planned else bi.planned_amount end) > 0
       then round(coalesce(sum(e.amount), 0) /
                  (case when coalesce(line_sum.planned, 0) > 0 then line_sum.planned else bi.planned_amount end)
                  * 100, 1)
       else 0 end                                                         as execution_rate
from public.budget_items bi
left join lateral (
  select sum(planned_amount) as planned
  from public.budget_item_lines
  where budget_item_id = bi.id
) line_sum on true
left join public.expenses e on e.budget_item_id = bi.id
group by bi.id, line_sum.planned;

alter view public.v_budget_item_execution set (security_invoker = on);

-- 기존 다른 view 들도 invoker 모드 일괄 적용 (ADR-006)
alter view public.v_funding_source_execution set (security_invoker = on);
alter view public.v_project_execution set (security_invoker = on);

-- ---------------------------------------------------------------------
-- 6) updated_at 트리거
-- ---------------------------------------------------------------------
create trigger budget_item_lines_set_updated_at
  before update on public.budget_item_lines
  for each row execute function public.set_updated_at();

-- ---------------------------------------------------------------------
-- 7) RLS
-- ---------------------------------------------------------------------
alter table public.budget_item_lines enable row level security;

create policy budget_item_lines_select on public.budget_item_lines
  for select
  using (
    exists (
      select 1 from public.projects p
      where p.id = budget_item_lines.project_id and public.can_access_company(p.company_id)
    )
  );

create policy budget_item_lines_modify_writer on public.budget_item_lines
  for all
  using (
    exists (
      select 1 from public.projects p
      where p.id = budget_item_lines.project_id and public.can_write_company(p.company_id)
    )
  )
  with check (
    exists (
      select 1 from public.projects p
      where p.id = budget_item_lines.project_id and public.can_write_company(p.company_id)
    )
  );

-- =====================================================================
-- END
-- =====================================================================
