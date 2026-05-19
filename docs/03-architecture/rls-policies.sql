-- =====================================================================
-- RLS Policies — 사업비 정산 SaaS
-- 작성자: 아키텍쳐설계 | 일자: 2026-05-19 | 버전: v1.0
-- 적용 순서: db-schema.sql → rls-policies.sql → seed.sql
--
-- 원칙
--  1. 모든 도메인 테이블에 RLS 활성화 (default deny)
--  2. organization_id 비정규화 컬럼으로 단순한 정책 작성
--  3. 헬퍼 함수로 권한 체크 캡슐화
--  4. super_admin (profiles.is_super_admin = true) 은 모든 정책에서 우회
-- =====================================================================

-- ---------------------------------------------------------------------
-- 1. 헬퍼 함수
-- ---------------------------------------------------------------------

-- 현재 사용자가 슈퍼관리자인가
create or replace function public.is_super_admin()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select coalesce(
    (select is_super_admin from public.profiles where id = auth.uid()),
    false
  );
$$;

-- 현재 사용자의 해당 조직 활성 역할 (없으면 null)
create or replace function public.current_role_in_org(p_org uuid)
returns text
language sql
stable
security definer
set search_path = public
as $$
  select role::text
  from public.memberships
  where organization_id = p_org
    and user_id = auth.uid()
    and status = 'active'
  limit 1;
$$;

-- 현재 사용자가 해당 조직의 활성 멤버인가
create or replace function public.is_org_member(p_org uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select is_super_admin() or public.current_role_in_org(p_org) is not null;
$$;

-- 현재 사용자가 해당 조직의 관리자인가
create or replace function public.is_org_admin(p_org uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select is_super_admin() or public.current_role_in_org(p_org) = 'org_admin';
$$;

-- 현재 사용자가 해당 회사에 접근 권한이 있는가
-- - super_admin / org_admin: 무조건 true
-- - viewer: 조직 멤버이면 읽기는 허용 (호출 측에서 SELECT 한정)
-- - company_member: company_members 매핑이 있어야 true
create or replace function public.can_access_company(p_company uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  with comp as (select organization_id from public.companies where id = p_company)
  select
    public.is_super_admin()
    or exists (
      select 1 from comp c
      where public.is_org_admin(c.organization_id)
         or public.current_role_in_org(c.organization_id) = 'viewer'
    )
    or exists (
      select 1 from public.company_members cm
      where cm.company_id = p_company and cm.user_id = auth.uid()
    );
$$;

-- 현재 사용자가 해당 회사를 수정할 권한이 있는가 (org_admin 또는 매핑된 company_member)
create or replace function public.can_write_company(p_company uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  with comp as (select organization_id from public.companies where id = p_company)
  select
    public.is_super_admin()
    or exists (select 1 from comp c where public.is_org_admin(c.organization_id))
    or exists (
      select 1 from public.company_members cm
      where cm.company_id = p_company and cm.user_id = auth.uid()
    );
$$;

-- ---------------------------------------------------------------------
-- 2. profiles
-- ---------------------------------------------------------------------
alter table public.profiles enable row level security;

create policy profiles_select_self_or_admin on public.profiles
  for select
  using (
    is_super_admin()
    or id = auth.uid()
    -- 조직 멤버끼리는 서로의 프로필 노출 (멤버 목록용)
    or exists (
      select 1
      from public.memberships m1
      join public.memberships m2
        on m1.organization_id = m2.organization_id
      where m1.user_id = auth.uid()
        and m1.status = 'active'
        and m2.user_id = public.profiles.id
        and m2.status = 'active'
    )
  );

create policy profiles_update_self on public.profiles
  for update
  using (id = auth.uid() or is_super_admin())
  with check (id = auth.uid() or is_super_admin());

-- INSERT는 트리거(handle_new_user)로만 발생하므로 정책 불필요

-- ---------------------------------------------------------------------
-- 3. organizations
-- ---------------------------------------------------------------------
alter table public.organizations enable row level security;

create policy organizations_select_member on public.organizations
  for select
  using (is_org_member(id));

create policy organizations_insert_authenticated on public.organizations
  for insert
  with check (auth.uid() is not null);

create policy organizations_update_admin on public.organizations
  for update
  using (is_org_admin(id))
  with check (is_org_admin(id));

create policy organizations_delete_admin on public.organizations
  for delete
  using (is_org_admin(id));

-- ---------------------------------------------------------------------
-- 4. memberships
-- ---------------------------------------------------------------------
alter table public.memberships enable row level security;

-- 조직 멤버는 본인 조직의 멤버십 목록을 볼 수 있다
create policy memberships_select_org_member on public.memberships
  for select
  using (is_org_member(organization_id));

-- INSERT: org_admin 만 (초대 발송)
create policy memberships_insert_admin on public.memberships
  for insert
  with check (is_org_admin(organization_id));

-- UPDATE: org_admin 만, 또는 본인 초대 수락(invited → active) 의 경우
create policy memberships_update_admin on public.memberships
  for update
  using (
    is_org_admin(organization_id)
    or (status = 'invited' and invited_email is not null)
  )
  with check (
    is_org_admin(organization_id)
    or (status in ('active', 'invited') and user_id = auth.uid())
  );

create policy memberships_delete_admin on public.memberships
  for delete
  using (is_org_admin(organization_id));

-- ---------------------------------------------------------------------
-- 5. companies
-- ---------------------------------------------------------------------
alter table public.companies enable row level security;

create policy companies_select_access on public.companies
  for select
  using (
    is_super_admin()
    or is_org_admin(organization_id)
    or current_role_in_org(organization_id) = 'viewer'
    or exists (
      select 1 from public.company_members cm
      where cm.company_id = companies.id and cm.user_id = auth.uid()
    )
  );

create policy companies_insert_admin on public.companies
  for insert
  with check (is_org_admin(organization_id));

create policy companies_update_admin on public.companies
  for update
  using (is_org_admin(organization_id))
  with check (is_org_admin(organization_id));

create policy companies_delete_admin on public.companies
  for delete
  using (is_org_admin(organization_id));

-- ---------------------------------------------------------------------
-- 6. company_members
-- ---------------------------------------------------------------------
alter table public.company_members enable row level security;

create policy company_members_select_org on public.company_members
  for select
  using (
    is_super_admin()
    or exists (
      select 1 from public.companies c
      where c.id = company_members.company_id and is_org_member(c.organization_id)
    )
  );

create policy company_members_modify_admin on public.company_members
  for all
  using (
    exists (
      select 1 from public.companies c
      where c.id = company_members.company_id and is_org_admin(c.organization_id)
    )
  )
  with check (
    exists (
      select 1 from public.companies c
      where c.id = company_members.company_id and is_org_admin(c.organization_id)
    )
  );

-- ---------------------------------------------------------------------
-- 7. projects
-- ---------------------------------------------------------------------
alter table public.projects enable row level security;

create policy projects_select_access on public.projects
  for select
  using (can_access_company(company_id));

create policy projects_insert_writer on public.projects
  for insert
  with check (
    is_org_admin(organization_id)
    or exists (
      select 1 from public.company_members cm
      where cm.company_id = projects.company_id and cm.user_id = auth.uid()
    )
  );

create policy projects_update_writer on public.projects
  for update
  using (can_write_company(company_id))
  with check (can_write_company(company_id));

create policy projects_delete_admin on public.projects
  for delete
  using (is_org_admin(organization_id));

-- ---------------------------------------------------------------------
-- 8. funding_sources
-- ---------------------------------------------------------------------
alter table public.funding_sources enable row level security;

create policy funding_sources_select on public.funding_sources
  for select
  using (
    exists (
      select 1 from public.projects p
      where p.id = funding_sources.project_id and can_access_company(p.company_id)
    )
  );

create policy funding_sources_modify_writer on public.funding_sources
  for all
  using (
    exists (
      select 1 from public.projects p
      where p.id = funding_sources.project_id and can_write_company(p.company_id)
    )
  )
  with check (
    exists (
      select 1 from public.projects p
      where p.id = funding_sources.project_id and can_write_company(p.company_id)
    )
  );

-- ---------------------------------------------------------------------
-- 9. budget_items
-- ---------------------------------------------------------------------
alter table public.budget_items enable row level security;

create policy budget_items_select on public.budget_items
  for select
  using (
    exists (
      select 1 from public.projects p
      where p.id = budget_items.project_id and can_access_company(p.company_id)
    )
  );

create policy budget_items_modify_writer on public.budget_items
  for all
  using (
    exists (
      select 1 from public.projects p
      where p.id = budget_items.project_id and can_write_company(p.company_id)
    )
  )
  with check (
    exists (
      select 1 from public.projects p
      where p.id = budget_items.project_id and can_write_company(p.company_id)
    )
  );

-- ---------------------------------------------------------------------
-- 10. expenses
-- ---------------------------------------------------------------------
alter table public.expenses enable row level security;

create policy expenses_select on public.expenses
  for select
  using (
    exists (
      select 1 from public.projects p
      where p.id = expenses.project_id and can_access_company(p.company_id)
    )
  );

create policy expenses_modify_writer on public.expenses
  for all
  using (
    exists (
      select 1 from public.projects p
      where p.id = expenses.project_id and can_write_company(p.company_id)
    )
  )
  with check (
    exists (
      select 1 from public.projects p
      where p.id = expenses.project_id and can_write_company(p.company_id)
    )
  );

-- ---------------------------------------------------------------------
-- 11. attachments  (Phase 2)
-- ---------------------------------------------------------------------
alter table public.attachments enable row level security;

create policy attachments_select on public.attachments
  for select
  using (
    exists (
      select 1
      from public.expenses e
      join public.projects p on p.id = e.project_id
      where e.id = attachments.expense_id and can_access_company(p.company_id)
    )
  );

create policy attachments_modify_writer on public.attachments
  for all
  using (
    exists (
      select 1
      from public.expenses e
      join public.projects p on p.id = e.project_id
      where e.id = attachments.expense_id and can_write_company(p.company_id)
    )
  )
  with check (
    exists (
      select 1
      from public.expenses e
      join public.projects p on p.id = e.project_id
      where e.id = attachments.expense_id and can_write_company(p.company_id)
    )
  );

-- =====================================================================
-- Storage 정책 (Phase 2 활성 시)
-- =====================================================================
-- 버킷 'evidence' 생성 후 적용:
-- 경로 규칙: org_{organization_id}/expense_{expense_id}/{filename}
--
-- insert into storage.buckets (id, name, public) values ('evidence', 'evidence', false);
--
-- create policy storage_evidence_select on storage.objects
--   for select using (
--     bucket_id = 'evidence'
--     and (storage.foldername(name))[1] like 'org_%'
--     and public.is_org_member(
--       replace((storage.foldername(name))[1], 'org_', '')::uuid
--     )
--   );

-- =====================================================================
-- END
-- =====================================================================
