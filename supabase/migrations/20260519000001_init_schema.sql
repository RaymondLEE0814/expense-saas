-- =====================================================================
-- 사업비 정산 관리 SaaS — 데이터베이스 스키마
-- 작성자: 아키텍쳐설계 | 일자: 2026-05-19 | 버전: v1.0
-- 적용 DB: Supabase (Postgres 15+)
-- 적용 순서: db-schema.sql → rls-policies.sql → seed.sql
-- =====================================================================

-- ---------------------------------------------------------------------
-- 0. EXTENSIONS
-- ---------------------------------------------------------------------
create extension if not exists "pgcrypto";  -- gen_random_uuid()
create extension if not exists "pg_trgm";   -- 한글 부분 검색

-- ---------------------------------------------------------------------
-- 1. ENUMS
-- ---------------------------------------------------------------------
create type public.member_role as enum (
  'super_admin',
  'org_admin',
  'company_member',
  'viewer'
);

create type public.membership_status as enum (
  'invited',
  'active',
  'suspended'
);

create type public.funding_source as enum (
  'gov_grant',
  'self_cash',
  'self_in_kind'
);

create type public.project_status as enum (
  'in_progress',
  'completed',
  'cancelled'
);

create type public.evidence_type as enum (
  'tax_invoice',
  'receipt',
  'card',
  'transfer',
  'etc'
);

-- ---------------------------------------------------------------------
-- 2. profiles  (auth.users 1:1 확장)
-- ---------------------------------------------------------------------
create table public.profiles (
  id              uuid primary key references auth.users(id) on delete cascade,
  email           text not null,
  full_name       text,
  phone           text,
  avatar_url      text,
  is_super_admin  boolean not null default false,
  created_at      timestamptz not null default now(),
  updated_at      timestamptz not null default now()
);

comment on table public.profiles is '사용자 프로필. auth.users 1:1 확장.';

-- ---------------------------------------------------------------------
-- 3. organizations  (테넌트)
-- ---------------------------------------------------------------------
create table public.organizations (
  id               uuid primary key default gen_random_uuid(),
  name             text not null,
  slug             text not null unique,
  business_number  text,
  plan             text not null default 'free',
  created_by       uuid references public.profiles(id),
  created_at       timestamptz not null default now(),
  updated_at       timestamptz not null default now(),
  constraint slug_format check (slug ~ '^[a-z0-9][a-z0-9-]{2,39}$')
);

create index organizations_slug_idx on public.organizations(slug);

comment on table public.organizations is '멀티 테넌트 최상위 단위 (스타트업/그룹사).';

-- ---------------------------------------------------------------------
-- 4. memberships  (조직-사용자 관계 + 역할)
-- ---------------------------------------------------------------------
create table public.memberships (
  id               uuid primary key default gen_random_uuid(),
  organization_id  uuid not null references public.organizations(id) on delete cascade,
  user_id          uuid references public.profiles(id) on delete cascade,
  role             public.member_role not null,
  status           public.membership_status not null default 'active',
  invited_email    text,
  invited_by       uuid references public.profiles(id),
  invite_token     text unique,           -- 가입 전 초대 토큰
  invite_expires_at timestamptz,
  invited_at       timestamptz,
  joined_at        timestamptz,
  created_at       timestamptz not null default now(),
  updated_at       timestamptz not null default now(),
  unique (organization_id, user_id),
  -- super_admin 역할은 멤버십에 들어가지 않음 (profiles.is_super_admin 사용)
  constraint role_not_super check (role <> 'super_admin'),
  -- 초대 상태일 때는 invited_email 필요, 활성 상태일 때는 user_id 필요
  constraint invite_or_user check (
    (status = 'invited' and invited_email is not null) or
    (status in ('active', 'suspended') and user_id is not null)
  )
);

create index memberships_org_idx on public.memberships(organization_id);
create index memberships_user_idx on public.memberships(user_id) where status = 'active';
create index memberships_invite_token_idx on public.memberships(invite_token) where invite_token is not null;

comment on table public.memberships is '조직-사용자 매핑 + 역할. 초대 토큰도 여기에 보관.';

-- ---------------------------------------------------------------------
-- 5. companies
-- ---------------------------------------------------------------------
create table public.companies (
  id               uuid primary key default gen_random_uuid(),
  organization_id  uuid not null references public.organizations(id) on delete cascade,
  name             text not null,
  business_number  text,
  representative   text,
  address          text,
  memo             text,
  is_archived      boolean not null default false,
  created_by       uuid references public.profiles(id),
  updated_by       uuid references public.profiles(id),
  created_at       timestamptz not null default now(),
  updated_at       timestamptz not null default now()
);

create index companies_org_idx on public.companies(organization_id) where is_archived = false;

comment on table public.companies is '조직 내 회사(법인).';

-- ---------------------------------------------------------------------
-- 6. company_members  (회사 담당자 매핑)
-- ---------------------------------------------------------------------
create table public.company_members (
  id           uuid primary key default gen_random_uuid(),
  company_id   uuid not null references public.companies(id) on delete cascade,
  user_id      uuid not null references public.profiles(id) on delete cascade,
  created_at   timestamptz not null default now(),
  unique (company_id, user_id)
);

create index company_members_user_idx on public.company_members(user_id);
create index company_members_company_idx on public.company_members(company_id);

comment on table public.company_members is 'company_member 역할 사용자의 회사 매핑 (N:M).';

-- ---------------------------------------------------------------------
-- 7. projects  (사업)
-- ---------------------------------------------------------------------
create table public.projects (
  id                 uuid primary key default gen_random_uuid(),
  organization_id    uuid not null references public.organizations(id) on delete cascade,
  company_id         uuid not null references public.companies(id) on delete cascade,
  name               text not null,
  code               text,
  host_agency        text,
  managing_agency    text,
  start_date         date not null,
  end_date           date not null,
  total_budget       numeric(15,0) not null,
  selected_amount    numeric(15,0),
  status             public.project_status not null default 'in_progress',
  memo               text,
  created_by         uuid references public.profiles(id),
  updated_by         uuid references public.profiles(id),
  created_at         timestamptz not null default now(),
  updated_at         timestamptz not null default now(),
  constraint dates_order check (end_date >= start_date),
  constraint budget_positive check (total_budget > 0),
  constraint selected_le_total check (selected_amount is null or selected_amount <= total_budget)
);

create index projects_company_idx on public.projects(company_id);
create index projects_org_status_idx on public.projects(organization_id, status);

comment on table public.projects is '정부지원 사업 1건.';

-- ---------------------------------------------------------------------
-- 8. funding_sources  (사업별 재원 구성)
-- ---------------------------------------------------------------------
create table public.funding_sources (
  id               uuid primary key default gen_random_uuid(),
  project_id       uuid not null references public.projects(id) on delete cascade,
  organization_id  uuid not null references public.organizations(id) on delete cascade,
  source_type      public.funding_source not null,
  planned_amount   numeric(15,0) not null default 0,
  memo             text,
  created_at       timestamptz not null default now(),
  updated_at       timestamptz not null default now(),
  unique (project_id, source_type),
  constraint planned_nonneg check (planned_amount >= 0)
);

create index funding_sources_project_idx on public.funding_sources(project_id);

comment on table public.funding_sources is '사업별 재원(정부지원금/현금/현물) 계획 금액.';

-- ---------------------------------------------------------------------
-- 9. budget_items  (비목)
-- ---------------------------------------------------------------------
create table public.budget_items (
  id               uuid primary key default gen_random_uuid(),
  organization_id  uuid not null references public.organizations(id) on delete cascade,
  project_id       uuid not null references public.projects(id) on delete cascade,
  name             text not null,
  code             text,
  planned_amount   numeric(15,0) not null default 0,
  sort_order       int not null default 0,
  memo             text,
  created_by       uuid references public.profiles(id),
  updated_by       uuid references public.profiles(id),
  created_at       timestamptz not null default now(),
  updated_at       timestamptz not null default now(),
  constraint planned_nonneg check (planned_amount >= 0)
);

create index budget_items_project_idx on public.budget_items(project_id, sort_order);

comment on table public.budget_items is '사업의 비목 (인건비/재료비/외주용역비 등).';

-- ---------------------------------------------------------------------
-- 10. expenses  (집행 내역)
-- ---------------------------------------------------------------------
create table public.expenses (
  id               uuid primary key default gen_random_uuid(),
  organization_id  uuid not null references public.organizations(id) on delete cascade,
  project_id       uuid not null references public.projects(id) on delete cascade,
  budget_item_id   uuid not null references public.budget_items(id) on delete restrict,
  expense_date     date not null,
  amount           numeric(15,0) not null,
  source_type      public.funding_source not null,
  vendor           text,
  description      text,
  evidence_type    public.evidence_type,
  memo             text,
  created_by       uuid references public.profiles(id),
  updated_by       uuid references public.profiles(id),
  created_at       timestamptz not null default now(),
  updated_at       timestamptz not null default now(),
  constraint amount_positive check (amount > 0)
);

create index expenses_project_date_idx on public.expenses(project_id, expense_date desc);
create index expenses_budget_item_idx on public.expenses(budget_item_id);
create index expenses_org_date_idx on public.expenses(organization_id, expense_date desc);
create index expenses_vendor_trgm_idx on public.expenses using gin (vendor gin_trgm_ops) where vendor is not null;
create index expenses_description_trgm_idx on public.expenses using gin (description gin_trgm_ops) where description is not null;

comment on table public.expenses is '집행 내역 (개별 지출 1건).';

-- ---------------------------------------------------------------------
-- 11. attachments  (증빙 첨부 — Phase 2)
-- ---------------------------------------------------------------------
create table public.attachments (
  id               uuid primary key default gen_random_uuid(),
  organization_id  uuid not null references public.organizations(id) on delete cascade,
  expense_id       uuid not null references public.expenses(id) on delete cascade,
  file_path        text not null,           -- Supabase Storage path
  file_name        text,
  file_size        int,
  mime_type        text,
  uploaded_by      uuid references public.profiles(id),
  created_at       timestamptz not null default now()
);

create index attachments_expense_idx on public.attachments(expense_id);

comment on table public.attachments is '집행 증빙 파일 (Phase 2 활성).';

-- ---------------------------------------------------------------------
-- 12. updated_at 자동 갱신 트리거
-- ---------------------------------------------------------------------
create or replace function public.set_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at := now();
  return new;
end;
$$;

do $$
declare t text;
begin
  foreach t in array array[
    'profiles', 'organizations', 'memberships',
    'companies', 'projects', 'funding_sources',
    'budget_items', 'expenses'
  ]
  loop
    execute format('
      create trigger %I_set_updated_at
      before update on public.%I
      for each row execute function public.set_updated_at();
    ', t, t);
  end loop;
end $$;

-- ---------------------------------------------------------------------
-- 13. auth.users INSERT → profiles 자동 생성 트리거
-- ---------------------------------------------------------------------
create or replace function public.handle_new_user()
returns trigger language plpgsql security definer as $$
begin
  insert into public.profiles (id, email, full_name)
  values (new.id, new.email, coalesce(new.raw_user_meta_data->>'full_name', ''))
  on conflict (id) do nothing;
  return new;
end;
$$;

create trigger on_auth_user_created
after insert on auth.users
for each row execute function public.handle_new_user();

-- ---------------------------------------------------------------------
-- 14. 집계 뷰 — 비목별 집행 합계 (성능을 위해 materialized 후보)
-- ---------------------------------------------------------------------
create or replace view public.v_budget_item_execution as
select
  bi.id              as budget_item_id,
  bi.project_id,
  bi.organization_id,
  bi.name,
  bi.planned_amount,
  coalesce(sum(e.amount), 0)::numeric(15,0) as executed_amount,
  (bi.planned_amount - coalesce(sum(e.amount), 0))::numeric(15,0) as remaining_amount,
  case when bi.planned_amount > 0
       then round(coalesce(sum(e.amount), 0) / bi.planned_amount * 100, 1)
       else 0 end as execution_rate
from public.budget_items bi
left join public.expenses e on e.budget_item_id = bi.id
group by bi.id;

create or replace view public.v_funding_source_execution as
select
  fs.project_id,
  fs.organization_id,
  fs.source_type,
  fs.planned_amount,
  coalesce(sum(e.amount), 0)::numeric(15,0) as executed_amount,
  (fs.planned_amount - coalesce(sum(e.amount), 0))::numeric(15,0) as remaining_amount,
  case when fs.planned_amount > 0
       then round(coalesce(sum(e.amount), 0) / fs.planned_amount * 100, 1)
       else 0 end as execution_rate
from public.funding_sources fs
left join public.expenses e
  on e.project_id = fs.project_id and e.source_type = fs.source_type
group by fs.project_id, fs.organization_id, fs.source_type, fs.planned_amount;

create or replace view public.v_project_execution as
select
  p.id                                  as project_id,
  p.organization_id,
  p.company_id,
  p.total_budget,
  coalesce(sum(e.amount), 0)::numeric(15,0) as executed_amount,
  (p.total_budget - coalesce(sum(e.amount), 0))::numeric(15,0) as remaining_amount,
  case when p.total_budget > 0
       then round(coalesce(sum(e.amount), 0) / p.total_budget * 100, 1)
       else 0 end as execution_rate
from public.projects p
left join public.expenses e on e.project_id = p.id
group by p.id;

-- =====================================================================
-- END
-- =====================================================================
