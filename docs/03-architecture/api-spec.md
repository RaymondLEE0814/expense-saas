# API / Server Action 명세

> 작성자: 아키텍쳐설계 | 일자: 2026-05-19
> 원칙: **Server Component first** — 조회는 RSC에서 Supabase 직접 호출 / **변경은 Server Action**
> 모든 작업은 RLS를 통해 권한 격리됨. 명시적 권한 체크는 추가 안전망.

---

## 0. 공통 규칙

### 0.1 데이터 페칭 패턴
- **목록·상세 조회**: Server Component에서 `createServerClient()` 로 Supabase 직접 호출
- **변경 (CRUD)**: Server Action (`'use server'`) — Zod 검증 → Supabase 호출 → `revalidatePath/Tag`
- **클라이언트 인터랙션** (검색·필터 등): TanStack Query + 라이트 API Route 또는 Server Action

### 0.2 에러 응답
```typescript
type ActionResult<T> =
  | { ok: true; data: T }
  | { ok: false; code: 'VALIDATION' | 'PERMISSION' | 'NOT_FOUND' | 'CONFLICT' | 'INTERNAL'; message: string; fieldErrors?: Record<string, string> };
```

### 0.3 캐시 무효화
- 변경 작업은 관련 path / tag를 `revalidatePath` 또는 `revalidateTag` 로 무효화
- Tag 명명: `org:{orgId}`, `project:{projectId}`, `expenses:{projectId}`, `budget:{projectId}` 등

---

## 1. 인증 / 회원 (Supabase Auth 위임)

| 작업 | 호출 | 비고 |
|------|------|------|
| 회원가입 | `supabase.auth.signUp({email, password, options: { data: { full_name }}})` | 트리거로 profiles 자동 생성 |
| 로그인 | `supabase.auth.signInWithPassword({email, password})` | |
| 로그아웃 | `supabase.auth.signOut()` | |
| 비밀번호 재설정 요청 | `supabase.auth.resetPasswordForEmail(email)` | |
| 비밀번호 업데이트 | `supabase.auth.updateUser({password})` | |
| 세션 새로고침 | `supabase.auth.refreshSession()` (미들웨어) | |

### Server Action — `updateProfile`
- **입력**: `{ full_name?: string; phone?: string }`
- **권한**: 로그인 사용자
- **처리**: `profiles UPDATE WHERE id = auth.uid()` (RLS로 자기 자신만)

---

## 2. 조직 (Organizations)

### 2.1 `createOrganization` (Server Action)
- **입력**: `{ name: string; slug: string; business_number?: string }`
- **권한**: 로그인
- **처리**:
  1. Zod 검증 (slug 정규식)
  2. 슬러그 중복 체크
  3. `organizations` INSERT
  4. 본인을 `org_admin` 으로 `memberships` INSERT
  5. `revalidatePath('/app')`

### 2.2 `checkSlugAvailable` (Server Action / Route)
- **입력**: `{ slug: string }`
- **출력**: `{ available: boolean }`
- 디바운스된 클라이언트 호출

### 2.3 `updateOrganization` (Server Action)
- **입력**: `{ id: string; name?: string; business_number?: string }`
- **권한**: `org_admin` (RLS)
- **처리**: UPDATE → `revalidateTag('org:{id}')`

### 2.4 `deleteOrganization` (Server Action)
- **입력**: `{ id: string; confirmName: string }`
- **권한**: `org_admin`
- **처리**: `confirmName === name` 검증 후 CASCADE DELETE

### 2.5 조회: `getMyOrganizations` (RSC)
```sql
SELECT o.*, m.role
FROM organizations o
JOIN memberships m ON m.organization_id = o.id
WHERE m.user_id = auth.uid() AND m.status = 'active'
ORDER BY o.created_at;
```

---

## 3. 멤버 (Memberships)

### 3.1 `inviteMember` (Server Action)
- **입력**: `{ organization_id: string; email: string; role: 'org_admin'|'company_member'|'viewer'; company_ids?: string[]; message?: string }`
- **권한**: `org_admin`
- **처리**:
  1. Zod 검증, company_member 시 company_ids 필수
  2. 같은 조직 중복 이메일 체크
  3. `invite_token` 생성 (랜덤 32자), expiry = now() + 7일
  4. `memberships` INSERT (status='invited')
  5. company_member 시 pending 매핑 정보를 별도 테이블 또는 memberships 의 JSONB(추가 필요) 에 보관 — MVP에선 `memberships.invited_email`만 사용하고 수락 시점에 매핑 (간단화)
  6. 초대 메일 발송 (Supabase Auth admin API 또는 Resend)
  7. `revalidatePath('/app/members')`

> 구현 메모: company_member 의 회사 사전 지정을 위해 `memberships` 에 `pending_company_ids uuid[]` 컬럼 추가 가능 (스키마 v1.1). MVP는 일단 컬럼 없이 진행 — 수락 시 관리자가 한번 더 매핑하는 흐름도 허용.

### 3.2 `acceptInvitation` (Server Action)
- **입력**: `{ token: string }`
- **권한**: 로그인 (이메일 매칭)
- **처리**:
  1. token 으로 memberships 조회 (status='invited', not expired)
  2. `invited_email === auth.user.email` 검증
  3. UPDATE: `status='active'`, `user_id=auth.uid()`, `joined_at=now()`, `invite_token=null`
  4. `revalidatePath('/app')`

### 3.3 `updateMembership` (Server Action)
- **입력**: `{ id: string; role?: ...; company_ids?: string[] }`
- **권한**: `org_admin`
- **검증**: 본인이 마지막 org_admin이면 역할 변경 차단

### 3.4 `removeMember` (Server Action)
- **입력**: `{ id: string }`
- **권한**: `org_admin` (본인 제외)
- **처리**: `status='suspended'` (soft)

### 3.5 조회
- `listMembers(orgId, status?)` — RSC
- `getMembership(id)` — RSC

---

## 4. 회사 (Companies)

### 4.1 `createCompany`
- **입력**: `{ organization_id: string; name: string; business_number?: string; representative?: string; address?: string; memo?: string }`
- **권한**: `org_admin`
- **처리**: INSERT + `revalidatePath('/app/companies')`

### 4.2 `updateCompany`
- **입력**: `{ id: string; ...partial }`
- **권한**: `org_admin`

### 4.3 `archiveCompany`
- **입력**: `{ id: string }`
- **권한**: `org_admin`
- **검증**: 진행중 사업 0건일 때만
- **처리**: `is_archived=true`

### 4.4 조회
- `listCompanies(orgId, opts)` — 검색·필터
- `getCompany(id)` — 상세 + KPI(사업 수, 집행률) 집계

---

## 5. 사업 (Projects)

### 5.1 `createProject`
- **입력**:
  ```ts
  {
    company_id: string;
    name: string; code?: string;
    host_agency?: string; managing_agency?: string;
    start_date: string; end_date: string;
    total_budget: number; selected_amount?: number;
    funding: { gov_grant: number; self_cash: number; self_in_kind: number };
  }
  ```
- **권한**: `org_admin` 또는 회사 매핑 `company_member`
- **검증**: `gov+cash+inkind === total_budget`, `end_date > start_date`
- **처리**: 트랜잭션
  1. `projects` INSERT
  2. `funding_sources` 3건 INSERT
  3. `revalidateTag('company:{id}')`

### 5.2 `updateProject`
- **입력**: 동일 필드 (부분)
- **권한**: 동일
- **처리**: completed 상태면 재원·총사업비 변경 차단

### 5.3 `setProjectStatus`
- **입력**: `{ id: string; status: 'in_progress'|'completed'|'cancelled' }`

### 5.4 `deleteProject`
- **입력**: `{ id: string }`
- **권한**: `org_admin`
- 집행 내역 CASCADE 삭제 (확인 모달 필수)

### 5.5 조회
- `listProjects(companyId, opts)` — 회사별 사업 목록 (집행률 view 조인)
- `listOrgProjects(orgId, opts)` — 조직 전체 (회사 필터 포함)
- `getProject(id)` — 상세 + funding_sources + 집행률
- `getProjectDashboard(id)` — Overview 탭 데이터 (KPI/재원/비목/월별)

---

## 6. 비목 (Budget Items)

### 6.1 `createBudgetItem`
- **입력**: `{ project_id; name; code?; planned_amount; memo? }`
- **권한**: writer (org_admin or company_member 매핑)
- **처리**: sort_order 자동 = max+1

### 6.2 `updateBudgetItem`
- **입력**: `{ id; ...partial }`

### 6.3 `reorderBudgetItems`
- **입력**: `{ project_id; orderedIds: string[] }`
- **처리**: 트랜잭션으로 sort_order 일괄 UPDATE

### 6.4 `deleteBudgetItem`
- **입력**: `{ id }`
- **검증**: 해당 비목에 expenses count = 0 일 때만

### 6.5 조회
- `listBudgetItems(projectId)` — v_budget_item_execution 조인

---

## 7. 집행 내역 (Expenses)

### 7.1 `createExpense`
- **입력**:
  ```ts
  {
    project_id: string;
    budget_item_id: string;
    expense_date: string;       // ISO date
    amount: number;             // > 0
    source_type: 'gov_grant'|'self_cash'|'self_in_kind';
    vendor?: string;
    description?: string;
    evidence_type?: 'tax_invoice'|'receipt'|'card'|'transfer'|'etc';
    force?: boolean;            // 비목 초과/기간 외 강제 허용
  }
  ```
- **권한**: writer
- **검증**:
  1. project.status === 'in_progress'
  2. budget_item.project_id === project_id
  3. 비목 잔여 < amount && !force → CONFLICT(BUDGET_EXCEEDED)
  4. expense_date < project.start_date or > end_date && !force → CONFLICT(DATE_OUTSIDE)
- **처리**: INSERT + revalidate

### 7.2 `updateExpense`
- 동일 검증, force 옵션 동일

### 7.3 `deleteExpense`
- **입력**: `{ id }`
- **권한**: writer (작성자 본인 또는 org_admin)

### 7.4 조회
- `listExpenses(projectId, filters, pagination)`
  - 필터: `dateRange`, `budgetItemIds`, `sourceTypes`, `query`
  - 출력: `{ items: Expense[], total: number, sum: number }`
- `getExpense(id)` — 편집용 상세

---

## 8. 대시보드 / 집계

### 8.1 `getOrgDashboard(orgId)` (RSC)
- 출력:
  ```ts
  {
    kpi: { activeProjects, totalBudget, executed, remaining, executionRate },
    companies: Array<{ id, name, projectCount, totalBudget, executed, executionRate }>,
    upcoming: Array<{ projectId, name, company, dDay, executionRate }>,  // D-30 이내
    recentActivity: Array<{ expenseId, date, budgetItemName, amount, vendor, companyName, createdBy }>
  }
  ```

### 8.2 `getProjectDashboard(projectId)` (RSC)
- 출력:
  ```ts
  {
    project: ProjectDetail,
    kpi: { total, executed, remaining, executionRate },
    fundingExecution: Array<{ sourceType, planned, executed, rate }>,
    budgetExecution: Array<{ budgetItem, planned, executed, rate, status }>,
    monthlyTrend: Array<{ ym, executed, cumulative }>,
    recentExpenses: Expense[]  // 5건
  }
  ```

### 8.3 `getCompanyDashboard(companyId)` (RSC)
- KPI + 사업 목록 + 집행률

---

## 9. 리포트 / 엑셀

### 9.1 `previewReport` (Server Action)
- **입력**: `{ orgId; companyIds?; projectIds?; from; to }`
- **출력**: `{ projectCount, budgetItemCount, expenseCount, totalAmount }`

### 9.2 `exportXlsx` (Route Handler)
- **경로**: `POST /api/reports/export`
- **입력**: 동일 + `sheets: ('summary'|'budget'|'expenses')[]`
- **출력**: `application/vnd.openxmlformats-officedocument.spreadsheetml.sheet`
- **구현**: 서버에서 `xlsx` 라이브러리로 워크북 생성

---

## 10. 메타 / 헬퍼

### 10.1 `getCurrentContext` (RSC helper)
- 출력: `{ user, profile, currentOrg, role, accessibleCompanyIds }`
- 미들웨어에서 호출 후 React context로 주입

### 10.2 `setLastOrg` (Server Action)
- 쿠키 `lastUsedOrgId` 갱신

---

## 11. 권한 표 (Server-side enforcement)

| 작업 | super_admin | org_admin | company_member | viewer |
|------|:-:|:-:|:-:|:-:|
| 조직 생성 | ✔ | ✔ (자동 self admin) | ✔ (자기 조직) | ✔ |
| 조직 수정/삭제 | ✔ | ✔ | × | × |
| 멤버 초대/변경 | ✔ | ✔ | × | × |
| 회사 CRUD | ✔ | ✔ | × | × |
| 사업 CRUD | ✔ | ✔ | △(매핑 회사) | × |
| 비목 CRUD | ✔ | ✔ | △ | × |
| 집행 CRUD | ✔ | ✔ | △ | × |
| 모든 조회 | ✔ | ✔ | △(매핑 회사) | ✔(전체) |
| 엑셀 export | ✔ | ✔ | △ | ✔ |

> RLS가 강제. 위 정책은 단지 UI/Server Action 단의 명시적 가드 (사용자 친화적 에러용).

---

## 12. Server Action 표준 패턴 (참고)

```ts
'use server';
import { z } from 'zod';
import { createServerClient } from '@/lib/supabase/server';
import { revalidateTag } from 'next/cache';

const InputSchema = z.object({
  project_id: z.string().uuid(),
  budget_item_id: z.string().uuid(),
  expense_date: z.coerce.date(),
  amount: z.number().int().positive(),
  source_type: z.enum(['gov_grant','self_cash','self_in_kind']),
  vendor: z.string().max(100).optional(),
  description: z.string().max(500).optional(),
  evidence_type: z.enum(['tax_invoice','receipt','card','transfer','etc']).optional(),
  force: z.boolean().optional(),
});

export async function createExpense(input: z.infer<typeof InputSchema>) {
  const parsed = InputSchema.safeParse(input);
  if (!parsed.success) return { ok: false, code: 'VALIDATION', fieldErrors: ... };

  const supabase = createServerClient();
  // 비즈니스 검증
  // ...
  const { data, error } = await supabase.from('expenses').insert({...}).select().single();
  if (error) return { ok: false, code: 'INTERNAL', message: error.message };

  revalidateTag(`expenses:${input.project_id}`);
  revalidateTag(`project:${input.project_id}`);
  return { ok: true, data };
}
```
