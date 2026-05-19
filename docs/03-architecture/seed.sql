-- =====================================================================
-- 시드 데이터 — 안티그래비티 조직 + 3개 회사
-- 작성자: 아키텍쳐설계 | 일자: 2026-05-19
-- 사용: 개발/스테이징에서만. 운영에선 사용자가 직접 가입·생성.
--
-- ※ auth.users 는 Supabase Dashboard 또는 supabase admin API 로 먼저 생성한 뒤
--   해당 uuid 를 아래에 채워서 실행.
--   여기서는 placeholder UUID 를 사용 — 실제 적용 시 치환 필요.
-- =====================================================================

do $$
declare
  v_user_raymond   uuid := '00000000-0000-0000-0000-000000000001'::uuid;  -- TODO: 치환
  v_org            uuid;
  v_repeach        uuid;
  v_superlearn     uuid;
  v_farmq          uuid;
  v_demo_project   uuid;
begin
  -- profiles 는 auth.users insert 트리거로 자동 생성된 상태여야 함
  -- 슈퍼관리자 부여
  update public.profiles set is_super_admin = true, full_name = '이석진'
   where id = v_user_raymond;

  -- 1) 조직
  insert into public.organizations (name, slug, business_number, created_by)
  values ('안티그래비티', 'antigravity', null, v_user_raymond)
  returning id into v_org;

  -- 2) 본인 멤버십 (org_admin)
  insert into public.memberships (organization_id, user_id, role, status, joined_at)
  values (v_org, v_user_raymond, 'org_admin', 'active', now());

  -- 3) 회사 3개
  insert into public.companies (organization_id, name, business_number, representative, created_by, updated_by)
  values (v_org, '리피치',  '1234567890', '이석진', v_user_raymond, v_user_raymond)
  returning id into v_repeach;

  insert into public.companies (organization_id, name, business_number, representative, created_by, updated_by)
  values (v_org, '슈퍼런', '2345678901', '이석진', v_user_raymond, v_user_raymond)
  returning id into v_superlearn;

  insert into public.companies (organization_id, name, business_number, representative, created_by, updated_by)
  values (v_org, '팜큐',   '3456789012', '이석진', v_user_raymond, v_user_raymond)
  returning id into v_farmq;

  -- 4) 데모용 사업 1건 (리피치)
  insert into public.projects (
    organization_id, company_id, name, code,
    host_agency, managing_agency,
    start_date, end_date, total_budget, selected_amount, status,
    created_by, updated_by
  )
  values (
    v_org, v_repeach, 'AI 콘텐츠 R&D', 'REPEACH-2025-AI',
    '중소벤처기업부', 'TIPA',
    '2025-04-01', '2026-03-31', 880000000, 880000000, 'in_progress',
    v_user_raymond, v_user_raymond
  )
  returning id into v_demo_project;

  -- 5) 재원 구성
  insert into public.funding_sources (organization_id, project_id, source_type, planned_amount) values
    (v_org, v_demo_project, 'gov_grant',    600000000),
    (v_org, v_demo_project, 'self_cash',    180000000),
    (v_org, v_demo_project, 'self_in_kind', 100000000);

  -- 6) 비목 템플릿 (정부지원 사업 통상)
  insert into public.budget_items (organization_id, project_id, name, code, planned_amount, sort_order, created_by, updated_by) values
    (v_org, v_demo_project, '인건비',      'HR',  450000000, 1, v_user_raymond, v_user_raymond),
    (v_org, v_demo_project, '재료비',      'MT',  150000000, 2, v_user_raymond, v_user_raymond),
    (v_org, v_demo_project, '외주용역비',  'OS',  200000000, 3, v_user_raymond, v_user_raymond),
    (v_org, v_demo_project, '연구활동비',  'AT',   60000000, 4, v_user_raymond, v_user_raymond),
    (v_org, v_demo_project, '연구장비비',  'EQ',   50000000, 5, v_user_raymond, v_user_raymond),
    (v_org, v_demo_project, '간접비',      'IN',   70000000, 6, v_user_raymond, v_user_raymond);

  raise notice '시드 완료: org=%, repeach=%, superlearn=%, farmq=%, demo_project=%',
    v_org, v_repeach, v_superlearn, v_farmq, v_demo_project;
end $$;
