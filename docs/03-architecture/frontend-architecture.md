# 프론트엔드 아키텍쳐

> 작성자: 아키텍쳐설계 | 일자: 2026-05-19
> 스택: Next.js 15 (App Router) + TS + Tailwind + shadcn/ui + Supabase JS

---

## 1. 폴더 구조 (`SRC/`)

```
SRC/
├── app/
│   ├── (public)/                       # 비로그인 영역
│   │   ├── login/page.tsx              # S-AUTH-001
│   │   ├── signup/page.tsx             # S-AUTH-002
│   │   ├── forgot-password/page.tsx    # S-AUTH-003
│   │   ├── reset-password/page.tsx     # S-AUTH-004
│   │   ├── verify-email/page.tsx       # S-AUTH-005
│   │   ├── invitations/[token]/page.tsx # S-AUTH-INVITE
│   │   ├── layout.tsx                  # Auth Shell
│   │   └── (auth)/_actions.ts          # 인증 server actions
│   │
│   ├── (app)/                          # 로그인 영역 (조직 컨텍스트)
│   │   ├── layout.tsx                  # App Shell (사이드바+헤더)
│   │   ├── onboarding/page.tsx         # S-ORG-NEW
│   │   ├── page.tsx                    # S-ORG-001 조직 대시보드
│   │   ├── companies/
│   │   │   ├── page.tsx                # S-COM-001
│   │   │   ├── _actions.ts
│   │   │   └── [companyId]/
│   │   │       ├── page.tsx            # S-COM-002
│   │   │       └── _components/
│   │   ├── projects/[projectId]/
│   │   │   ├── layout.tsx              # 사업 헤더 + 탭
│   │   │   ├── page.tsx                # S-PRJ-001 Overview
│   │   │   ├── budget/page.tsx         # S-PRJ-003
│   │   │   ├── expenses/page.tsx       # S-PRJ-002
│   │   │   ├── settings/page.tsx       # S-PRJ-004
│   │   │   └── _actions.ts
│   │   ├── expenses/page.tsx           # 조직 전체 집행 (보조)
│   │   ├── reports/page.tsx            # S-RPT-001
│   │   ├── members/
│   │   │   ├── page.tsx                # S-MEM-001
│   │   │   └── _actions.ts
│   │   ├── settings/page.tsx           # S-SET-001
│   │   ├── account/page.tsx            # S-ACC-001
│   │   └── _layout/                    # AppShell 내부 컴포넌트
│   │       ├── Sidebar.tsx
│   │       ├── Header.tsx
│   │       └── OrgSwitcher.tsx
│   │
│   ├── (admin)/                        # Phase 3 — super admin
│   │   ├── layout.tsx
│   │   └── admin/...
│   │
│   ├── api/
│   │   └── reports/export/route.ts     # XLSX export
│   │
│   ├── layout.tsx                      # Root layout (font, providers)
│   ├── globals.css
│   ├── error.tsx                       # 글로벌 에러 바운더리
│   └── not-found.tsx
│
├── components/
│   ├── ui/                             # shadcn/ui primitives
│   │   ├── button.tsx
│   │   ├── input.tsx
│   │   ├── card.tsx
│   │   ├── dialog.tsx
│   │   ├── sheet.tsx
│   │   ├── toast.tsx
│   │   ├── badge.tsx
│   │   ├── table.tsx
│   │   ├── dropdown-menu.tsx
│   │   ├── date-picker.tsx
│   │   ├── select.tsx
│   │   └── ...
│   ├── app/                            # 도메인 컴포넌트
│   │   ├── KpiCard.tsx
│   │   ├── ExecutionBar.tsx            # 집행률 게이지
│   │   ├── FundingBadge.tsx
│   │   ├── ProjectStatusBadge.tsx
│   │   ├── DDayBadge.tsx
│   │   ├── MoneyInput.tsx              # 천단위 콤마 input
│   │   ├── MoneyDisplay.tsx
│   │   ├── BusinessNumberInput.tsx
│   │   ├── EmptyState.tsx
│   │   ├── DataTable.tsx
│   │   └── ...
│   ├── charts/
│   │   ├── BudgetBarChart.tsx
│   │   ├── MonthlyTrendChart.tsx
│   │   └── FundingGauge.tsx
│   └── forms/                          # 재사용 폼
│       ├── CompanyForm.tsx
│       ├── ProjectForm.tsx
│       ├── BudgetItemForm.tsx
│       └── ExpenseForm.tsx
│
├── lib/
│   ├── supabase/
│   │   ├── client.ts                   # 브라우저용 (createBrowserClient)
│   │   ├── server.ts                   # RSC/Server Action용
│   │   ├── middleware.ts               # 세션 갱신 헬퍼
│   │   └── admin.ts                    # service_role (서버 어드민 작업 전용)
│   ├── auth/
│   │   ├── session.ts                  # getSession, requireUser
│   │   └── context.ts                  # getCurrentContext
│   ├── permissions/
│   │   ├── roles.ts
│   │   ├── checks.ts                   # canEdit(...), canDelete(...)
│   │   └── guards.ts                   # requireRole, requireOrgAdmin
│   ├── domain/
│   │   ├── money.ts                    # formatMoney, parseMoney
│   │   ├── dates.ts                    # formatDate, dDay
│   │   ├── business-number.ts          # validate, format
│   │   └── funding.ts                  # source type 매핑
│   ├── validation/
│   │   ├── company.ts                  # Zod schemas
│   │   ├── project.ts
│   │   ├── budget.ts
│   │   ├── expense.ts
│   │   └── member.ts
│   ├── reports/
│   │   └── xlsx.ts                     # 엑셀 생성
│   └── utils/
│       ├── cn.ts                       # className helper
│       └── debounce.ts
│
├── hooks/
│   ├── useToast.ts
│   ├── useDebouncedValue.ts
│   ├── useFilterParams.ts              # URL 쿼리 ↔ 상태 동기화
│   └── useOrgContext.ts
│
├── types/
│   ├── database.ts                     # Supabase generated types
│   ├── domain.ts                       # 도메인 모델 (DB 타입 위 매핑)
│   └── api.ts                          # ActionResult 등
│
├── styles/
│   └── tokens.css                      # CSS 변수
│
├── middleware.ts                       # Next.js 미들웨어 (세션 갱신 + 라우트 가드)
├── tailwind.config.ts
├── next.config.mjs
├── tsconfig.json
├── package.json
├── pnpm-lock.yaml
├── .env.local                          # gitignore
├── .env.example
└── README.md
```

---

## 2. 라우팅 그룹

| 그룹 | 보호 | 레이아웃 | 용도 |
|------|------|---------|------|
| `(public)` | 비로그인 (또는 누구나) | Auth Shell | 인증·온보딩 |
| `(app)` | 로그인 + 조직 컨텍스트 | App Shell | 모든 비즈니스 화면 |
| `(admin)` | super_admin 만 | Admin Shell | 운영 콘솔 (Phase 3) |

> 미들웨어에서 그룹 별로 가드. `(app)` 진입 시 활성 조직 없으면 `/app/onboarding` 으로 리다이렉트.

---

## 3. 미들웨어 (`middleware.ts`)

```ts
import { type NextRequest, NextResponse } from 'next/server';
import { updateSession } from '@/lib/supabase/middleware';

export async function middleware(request: NextRequest) {
  // 1) Supabase 세션 갱신 (쿠키 회전)
  const { response, user } = await updateSession(request);

  const path = request.nextUrl.pathname;
  const isPublic = path.startsWith('/login') ||
                   path.startsWith('/signup') ||
                   path.startsWith('/forgot-password') ||
                   path.startsWith('/reset-password') ||
                   path.startsWith('/verify-email') ||
                   path.startsWith('/invitations');

  // 2) 비로그인 + 보호 라우트 → /login
  if (!user && !isPublic && path.startsWith('/app')) {
    const url = request.nextUrl.clone();
    url.pathname = '/login';
    url.searchParams.set('redirect', path);
    return NextResponse.redirect(url);
  }

  // 3) 로그인 + 공개 라우트 → /app
  if (user && (path === '/login' || path === '/signup')) {
    const url = request.nextUrl.clone();
    url.pathname = '/app';
    return NextResponse.redirect(url);
  }

  return response;
}

export const config = {
  matcher: ['/((?!_next/static|_next/image|favicon.ico|.*\\.(?:svg|png|jpg|jpeg|gif|webp)$).*)'],
};
```

---

## 4. Supabase 클라이언트 3종

### 4.1 `lib/supabase/client.ts` (브라우저)
```ts
import { createBrowserClient } from '@supabase/ssr';
import type { Database } from '@/types/database';

export function createClient() {
  return createBrowserClient<Database>(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!
  );
}
```

### 4.2 `lib/supabase/server.ts` (서버)
```ts
import { createServerClient } from '@supabase/ssr';
import { cookies } from 'next/headers';
import type { Database } from '@/types/database';

export function createClient() {
  const cookieStore = cookies();
  return createServerClient<Database>(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
    {
      cookies: {
        getAll: () => cookieStore.getAll(),
        setAll: (list) => list.forEach(({ name, value, options }) =>
          cookieStore.set(name, value, options)),
      },
    }
  );
}
```

### 4.3 `lib/supabase/middleware.ts` (세션 갱신)
세션 쿠키를 회전시키며 user 객체 반환.

### 4.4 `lib/supabase/admin.ts` (service_role)
- **절대 클라이언트로 노출 금지**
- 서버 사이드 전용 (초대 메일 발송 시 admin API 등)

---

## 5. 데이터 페칭 패턴

### 5.1 RSC에서 조회 (기본)
```tsx
// app/(app)/projects/[projectId]/page.tsx
export default async function ProjectOverviewPage({ params }) {
  const dashboard = await getProjectDashboard(params.projectId);
  return <OverviewView data={dashboard} />;
}
```

### 5.2 Server Action으로 변경
```tsx
'use client';
import { createExpense } from './_actions';
async function onSubmit(values) {
  const result = await createExpense(values);
  if (!result.ok) toast.error(result.message);
  else toast.success('집행이 등록되었어요');
}
```

### 5.3 TanStack Query (클라이언트 인터랙션 한정)
- 필터 변경에 따른 즉시 목록 갱신
- 무한 스크롤 (Phase 2)

---

## 6. 컴포넌트 계층

```
페이지 (Server Component)
   ↓ props
도메인 뷰 (Server/Client 혼합)
   ↓ props
도메인 컴포넌트 (components/app/*)
   ↓ props
UI 프리미티브 (components/ui/* — shadcn)
```

**규칙**
- 비즈니스 로직은 페이지·`lib/`에 — 컴포넌트는 표시만
- 폼 컴포넌트는 RHF + Zod 일관
- Server Action 호출은 `_actions.ts` 에서

---

## 7. 상태 관리

| 영역 | 도구 |
|------|------|
| 서버 상태 (목록·상세) | RSC 또는 TanStack Query |
| 폼 상태 | React Hook Form |
| UI 상태 (모달 열림/사이드바 토글) | useState / Zustand (필요시) |
| URL 상태 (필터·페이지) | URLSearchParams + useFilterParams 훅 |
| 토스트 | shadcn Toaster + useToast |

---

## 8. 타입 안전성

### 8.1 Supabase 타입 생성
```bash
supabase gen types typescript --project-id <PROJECT> > types/database.ts
```

### 8.2 도메인 매핑
```ts
// types/domain.ts
import type { Database } from './database';
export type Project = Database['public']['Tables']['projects']['Row'];
export type ProjectInsert = Database['public']['Tables']['projects']['Insert'];
// ... 등
```

### 8.3 Zod 스키마 = 검증 + 타입 추론
```ts
import { z } from 'zod';
export const ExpenseInput = z.object({...});
export type ExpenseInputT = z.infer<typeof ExpenseInput>;
```

---

## 9. 캐시 전략

- **RSC fetch**: Next.js fetch cache (기본 force-cache, 변경 후 revalidateTag)
- **Supabase 호출**: `unstable_cache` 로 래핑 + 태그 부여
- **변경 후**: `revalidateTag('expenses:{projectId}')` + `revalidateTag('project:{projectId}')`
- **Realtime (Phase 2)**: Supabase Realtime 구독으로 대시보드 자동 갱신

---

## 10. 폼 / 검증 표준

```tsx
const form = useForm<ExpenseInputT>({
  resolver: zodResolver(ExpenseInput),
  defaultValues: { ... },
});

async function onSubmit(values: ExpenseInputT) {
  const r = await createExpense(values);
  if (!r.ok) {
    if (r.fieldErrors) Object.entries(r.fieldErrors).forEach(([k,v]) => form.setError(k as any, { message: v }));
    else toast.error(r.message);
    return;
  }
  toast.success('저장되었어요');
  router.refresh();
}
```

---

## 11. 디자인 시스템 통합

- `tailwind.config.ts` 에 [design-system.md §1](../02-design/design-system.md#1-토큰-매핑--tailwind-config) 토큰 등록
- shadcn 컴포넌트 install 후 variant CVA 매핑
- `globals.css` 에 CSS 변수 노출

---

## 12. 테스트

- **유닛**: `lib/` 비즈니스 로직만 Vitest (e.g. `formatMoney`, `validateBusinessNumber`)
- **컴포넌트**: 핵심 폼 / 차트는 React Testing Library
- **e2e**: Playwright — 핵심 흐름 (가입 → 조직 → 사업 → 집행 → 엑셀)
- **DB**: RLS 정책 검증 — `pgTAP` 또는 Vitest로 직접 SQL 실행 비교

---

## 13. 코드 컨벤션
- 파일: kebab-case (`expense-form.tsx`)
- 컴포넌트: PascalCase
- 훅: `useXxx`
- 서버 액션: 동사로 시작 (`createExpense`)
- 상수: SCREAMING_SNAKE_CASE
- 매직넘버 금지

---

## 14. 패키지 (초기 설치)
```bash
pnpm dlx create-next-app@latest SRC --typescript --tailwind --eslint --app --src-dir=false --import-alias="@/*"

pnpm add @supabase/supabase-js @supabase/ssr
pnpm add react-hook-form zod @hookform/resolvers
pnpm add @tanstack/react-query
pnpm add recharts
pnpm add xlsx file-saver
pnpm add date-fns
pnpm add lucide-react
pnpm add class-variance-authority clsx tailwind-merge

# shadcn
pnpm dlx shadcn@latest init
pnpm dlx shadcn@latest add button input card dialog sheet toast table badge dropdown-menu select tabs progress

# dev
pnpm add -D vitest @testing-library/react @testing-library/jest-dom
pnpm add -D @playwright/test
pnpm add -D supabase
```
