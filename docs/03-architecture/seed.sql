-- =====================================================================
-- 시드 데이터 — (주)슈퍼런 조직 + 3개 회사 (리피치 / 슈퍼런 / 팜큐)
-- 작성자: 아키텍쳐설계 | 수정: 2026-05-20 (조직명 갱신)
-- 사용: 개발/스테이징에서만. 운영에선 사용자가 직접 가입·생성.
--
-- ※ 이 SQL 은 auth.users 가 이미 존재해야 함.
--   admin API 로 사용자 생성 후 그 uuid 를 v_user_admin 에 넣고 실행.
--   실제 적용은 SRC/scripts/seed-initial-data.ts 가 자동화.
-- =====================================================================

do $$
declare
  v_user_admin     uuid := '00000000-0000-0000-0000-000000000001'::uuid;  -- TODO: 치환
  v_org            uuid;
  v_repeach        uuid;
  v_superrun       uuid;
  v_farmq          uuid;
  v_demo_project   uuid;
begin
  -- 프로필 보강 (트리거로 자동 생성된 상태)
  update public.profiles
     set is_super_admin = true,
         full_name      = '이석진'
   where id = v_user_admin;

  -- 1) 조직 — (주)슈퍼런 (서비스 공급사이자 첫 파일럿 조직)
  insert into public.organizations (name, slug, business_number, created_by)
  values ('(주)슈퍼런', 'superrun', null, v_user_admin)
  returning id into v_org;

  -- 2) 본인 멤버십 (org_admin)
  insert into public.memberships (organization_id, user_id, role, status, joined_at)
  values (v_org, v_user_admin, 'org_admin', 'active', now());

  -- 3) 회사 3개 — 리피치 / 슈퍼런 / 팜큐
  insert into public.companies (organization_id, name, business_number, representative, created_by, updated_by)
  values (v_org, '리피치',  '1234567890', '이석진', v_user_admin, v_user_admin)
  returning id into v_repeach;

  insert into public.companies (organization_id, name, business_number, representative, created_by, updated_by)
  values (v_org, '슈퍼런', '2345678901', '이석진', v_user_admin, v_user_admin)
  returning id into v_superrun;

  insert into public.companies (organization_id, name, business_number, representative, created_by, updated_by)
  values (v_org, '팜큐',   '3456789012', '이석진', v_user_admin, v_user_admin)
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
    v_user_admin, v_user_admin
  )
  returning id into v_demo_project;

  -- 5) 재원 구성
  insert into public.funding_sources (organization_id, project_id, source_type, planned_amount) values
    (v_org, v_demo_project, 'gov_grant',    600000000),
    (v_org, v_demo_project, 'self_cash',    180000000),
    (v_org, v_demo_project, 'self_in_kind', 100000000);

  -- 6) 비목 템플릿 (정부지원 사업 통상)
  insert into public.budget_items (organization_id, project_id, name, code, planned_amount, sort_order, created_by, updated_by) values
    (v_org, v_demo_project, '인건비',      'HR',  450000000, 1, v_user_admin, v_user_admin),
    (v_org, v_demo_project, '재료비',      'MT',  150000000, 2, v_user_admin, v_user_admin),
    (v_org, v_demo_project, '외주용역비',  'OS',  200000000, 3, v_user_admin, v_user_admin),
    (v_org, v_demo_project, '연구활동비',  'AT',   60000000, 4, v_user_admin, v_user_admin),
    (v_org, v_demo_project, '연구장비비',  'EQ',   50000000, 5, v_user_admin, v_user_admin),
    (v_org, v_demo_project, '간접비',      'IN',   70000000, 6, v_user_admin, v_user_admin);

  raise notice '시드 완료: org=%, repeach=%, superrun=%, farmq=%, demo_project=%',
    v_org, v_repeach, v_superrun, v_farmq, v_demo_project;
end $$;
