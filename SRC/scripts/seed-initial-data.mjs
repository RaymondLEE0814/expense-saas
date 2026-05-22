// =====================================================================
// Initial seed — (주)슈퍼런 조직 + 3개 회사 + 관리자 계정
//                + 데모 사업 (실제 사업비 구성표 양식 기반)
//
// 사용:
//   1) SRC/.env.local 에 SUPABASE_SERVICE_ROLE_KEY 가 설정됐는지 확인
//   2) node scripts/seed-initial-data.mjs <admin_email> <admin_password>
//
// 멱등: 사용자/조직/회사/사업/비목/라인 모두 존재 여부 확인 후 skip.
// =====================================================================

import { createClient } from '@supabase/supabase-js';
import { readFileSync } from 'node:fs';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';

const __dirname = dirname(fileURLToPath(import.meta.url));

function loadEnv() {
  try {
    const content = readFileSync(join(__dirname, '..', '.env.local'), 'utf-8');
    for (const line of content.split('\n')) {
      const trimmed = line.trim();
      if (!trimmed || trimmed.startsWith('#')) continue;
      const idx = trimmed.indexOf('=');
      if (idx < 0) continue;
      const key = trimmed.slice(0, idx).trim();
      const value = trimmed.slice(idx + 1).trim();
      if (!process.env[key]) process.env[key] = value;
    }
  } catch (e) {
    console.warn('⚠ .env.local 을 못 읽었습니다:', e.message);
  }
}
loadEnv();

const URL = process.env.NEXT_PUBLIC_SUPABASE_URL;
const SERVICE_KEY = process.env.SUPABASE_SERVICE_ROLE_KEY;
if (!URL || !SERVICE_KEY) {
  console.error('NEXT_PUBLIC_SUPABASE_URL / SUPABASE_SERVICE_ROLE_KEY 가 .env.local 에 필요합니다.');
  process.exit(1);
}

const [, , emailArg, passwordArg] = process.argv;
const email = emailArg ?? 'raymond@repeach.kr';
const password = passwordArg ?? 'TempPass!234';

const admin = createClient(URL, SERVICE_KEY, {
  auth: { autoRefreshToken: false, persistSession: false },
});

// ---------------------------------------------------------------------
async function ensureUser() {
  console.log(`[1/7] 사용자 보장: ${email}`);
  const { data: list, error: listErr } = await admin.auth.admin.listUsers({ page: 1, perPage: 1000 });
  if (listErr) throw listErr;
  const existing = list.users.find((u) => u.email?.toLowerCase() === email.toLowerCase());
  if (existing) {
    console.log(`  - 이미 존재: id=${existing.id}`);
    return existing.id;
  }
  const { data, error } = await admin.auth.admin.createUser({
    email, password, email_confirm: true,
    user_metadata: { full_name: '이석진' },
  });
  if (error) throw error;
  console.log(`  - 생성됨: id=${data.user.id}`);
  return data.user.id;
}

async function ensureProfileSuperAdmin(userId) {
  console.log('[2/7] 프로필 슈퍼관리자 설정');
  const { error } = await admin.from('profiles')
    .update({ is_super_admin: true, full_name: '이석진' }).eq('id', userId);
  if (error) throw error;
}

async function ensureOrg(userId) {
  console.log('[3/7] 조직 보장: (주)슈퍼런');
  const { data: existing } = await admin.from('organizations')
    .select('id').eq('slug', 'superrun').maybeSingle();
  if (existing) {
    console.log(`  - 이미 존재: ${existing.id}`);
    return existing.id;
  }
  const { data, error } = await admin.from('organizations')
    .insert({ name: '(주)슈퍼런', slug: 'superrun', created_by: userId })
    .select('id').single();
  if (error) throw error;
  console.log(`  - 생성됨: ${data.id}`);
  return data.id;
}

async function ensureMembership(orgId, userId) {
  console.log('[4/7] 조직 관리자 멤버십 보장');
  const { data: existing } = await admin.from('memberships')
    .select('id').eq('organization_id', orgId).eq('user_id', userId).maybeSingle();
  if (existing) {
    console.log(`  - 이미 존재: ${existing.id}`);
    return;
  }
  const { error } = await admin.from('memberships').insert({
    organization_id: orgId, user_id: userId, role: 'org_admin',
    status: 'active', joined_at: new Date().toISOString(),
  });
  if (error) throw error;
}

async function ensureCompanies(orgId, userId) {
  console.log('[5/7] 회사 3개 보장');
  const companies = [
    { name: '리피치', business_number: '1234567890' },
    { name: '슈퍼런', business_number: '2345678901' },
    { name: '팜큐', business_number: '3456789012' },
  ];
  const ids = {};
  for (const c of companies) {
    const { data: existing } = await admin.from('companies')
      .select('id').eq('organization_id', orgId).eq('name', c.name).maybeSingle();
    if (existing) {
      ids[c.name] = existing.id;
      console.log(`  - ${c.name}: 이미 존재`);
      continue;
    }
    const { data, error } = await admin.from('companies').insert({
      organization_id: orgId, name: c.name, business_number: c.business_number,
      representative: '이석진', created_by: userId, updated_by: userId,
    }).select('id').single();
    if (error) throw error;
    ids[c.name] = data.id;
    console.log(`  - ${c.name}: 생성됨`);
  }
  return ids;
}

async function ensureDemoProject(orgId, companyIds, userId) {
  console.log('[6/7] 데모 사업 보장 (리피치 / 글로벌 진출 SaaS)');
  const repeachId = companyIds['리피치'];

  let projectId;
  const { data: existing } = await admin.from('projects')
    .select('id').eq('company_id', repeachId).eq('name', '글로벌 진출 SaaS 개발').maybeSingle();
  if (existing) {
    projectId = existing.id;
    console.log(`  - 사업 이미 존재: ${projectId}`);
  } else {
    const { data: project, error } = await admin.from('projects').insert({
      organization_id: orgId, company_id: repeachId,
      name: '글로벌 진출 SaaS 개발', code: 'REPEACH-2025-GLOBAL',
      host_agency: '중소벤처기업부', managing_agency: 'TIPA',
      start_date: '2025-04-01', end_date: '2026-03-31',
      total_budget: 140000000, selected_amount: 140000000,
      status: 'in_progress', created_by: userId, updated_by: userId,
    }).select('id').single();
    if (error) throw error;
    projectId = project.id;
    console.log(`  - 사업 생성: ${projectId}`);

    // 재원 (사용자 이미지 양식 합계 기준)
    await admin.from('funding_sources').insert([
      { organization_id: orgId, project_id: projectId, source_type: 'gov_grant',    planned_amount: 105000000 },
      { organization_id: orgId, project_id: projectId, source_type: 'self_cash',    planned_amount:  14000000 },
      { organization_id: orgId, project_id: projectId, source_type: 'self_in_kind', planned_amount:  21000000 },
    ]);
    console.log('  - 재원 3종 등록 (정부지원 105M / 현금 14M / 현물 21M)');
  }

  return projectId;
}

async function ensureBudgetItemsAndLines(orgId, projectId, userId) {
  console.log('[7/7] 비목 + 비목 라인 보장 (사용자 이미지 양식 기반)');

  // 비목 카테고리 (단순 이름만)
  const categories = [
    { name: '지급수수료',    code: 'FE', sort_order: 1 },
    { name: '인건비',         code: 'HR', sort_order: 2 },
    { name: '외주용역비',     code: 'OS', sort_order: 3 },
    { name: '기계장치 구입비',code: 'EQ', sort_order: 4 },
    { name: '광고선전비',     code: 'AD', sort_order: 5 },
  ];

  const itemIds = {};
  for (const c of categories) {
    const { data: existing } = await admin.from('budget_items')
      .select('id').eq('project_id', projectId).eq('name', c.name).maybeSingle();
    if (existing) {
      itemIds[c.name] = existing.id;
      console.log(`  - 비목 ${c.name}: 이미 존재`);
      continue;
    }
    const { data, error } = await admin.from('budget_items').insert({
      organization_id: orgId, project_id: projectId,
      name: c.name, code: c.code, planned_amount: 0,  // 라인 합계로 자동
      sort_order: c.sort_order,
      created_by: userId, updated_by: userId,
    }).select('id').single();
    if (error) throw error;
    itemIds[c.name] = data.id;
    console.log(`  - 비목 ${c.name}: 생성됨`);
  }

  // 라인 정의 (사용자 이미지의 사업비 구성표)
  // [비목, 산출 근거, 단가, 수량, 기간(개월), 재원, 합계]
  const lines = [
    ['지급수수료', '사무실 임차료 월 300만원 X 7개월',          3000000, 1, 7, 'self_in_kind', 21000000],
    ['인건비',     '개발자 인건비 340만원 X 2명 X 5개월',       3400000, 2, 5, 'gov_grant',    34000000],
    ['인건비',     '기획자 인건비 1명 280만원 X 5개월',         2800000, 1, 5, 'self_cash',    14000000],
    ['인건비',     'SLLM연구원 인건비 600만원 X 5개월',         6000000, 1, 5, 'gov_grant',    30000000],
    ['외주용역비', '글로벌 진출을 위한 표준 연동 모듈 외주용역 개발', null, null, null, 'gov_grant', 18000000],
    ['기계장치 구입비', '대표자 외 신규 채용 인원 1명 사무용 PC 1대', null, null, null, 'gov_grant',  5000000],
    ['광고선전비', '회사 홍보 영상 제작',                       null, null, null, 'gov_grant', 10000000],
    ['광고선전비', '회사 소개 카달로그 제작 (국문/영문)',       null, null, null, 'gov_grant',  8000000],
  ];

  // 라인 멱등 확인 (description + project_id + budget_item_id 조합으로)
  for (let i = 0; i < lines.length; i++) {
    const [itemName, description, unit_price, quantity, period_months, source_type, planned_amount] = lines[i];
    const budget_item_id = itemIds[itemName];

    const { data: existing } = await admin.from('budget_item_lines')
      .select('id')
      .eq('project_id', projectId)
      .eq('budget_item_id', budget_item_id)
      .eq('description', description)
      .maybeSingle();
    if (existing) {
      console.log(`    · 라인 ${i + 1} 이미 존재`);
      continue;
    }
    const { error } = await admin.from('budget_item_lines').insert({
      organization_id: orgId, project_id: projectId, budget_item_id,
      description, source_type, planned_amount,
      unit_price, quantity, period_months,
      sort_order: i + 1,
      created_by: userId, updated_by: userId,
    });
    if (error) throw error;
    console.log(`    · 라인 ${i + 1}: ${itemName} — ${description.slice(0, 30)}... (₩${planned_amount.toLocaleString()})`);
  }
}

// ---------------------------------------------------------------------
async function main() {
  console.log('🌱 Initial seed 시작\n');
  const userId = await ensureUser();
  await ensureProfileSuperAdmin(userId);
  const orgId = await ensureOrg(userId);
  await ensureMembership(orgId, userId);
  const companyIds = await ensureCompanies(orgId, userId);
  const projectId = await ensureDemoProject(orgId, companyIds, userId);
  await ensureBudgetItemsAndLines(orgId, projectId, userId);
  console.log('\n✅ 완료\n');
  console.log('로그인 정보:');
  console.log(`  이메일: ${email}`);
  console.log(`  비밀번호: ${password}`);
}

main().catch((e) => {
  console.error('\n❌ 실패:', e);
  process.exit(1);
});
