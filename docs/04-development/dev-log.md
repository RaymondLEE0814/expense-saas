# 개발 로그 (Development Log)

> 작성자: corder | 작업 단위마다 한 줄 기록

---

## 2026-05-19 — Phase 1 부트스트랩 (P1-01 ~ P1-05)

### 결정 사항
- **스택 변경 (상향)**: 아키텍쳐에서 정한 Next.js 15 → `create-next-app@latest` 가 Next.js 16.2.6 설치. 그대로 채택.
- **Tailwind 변경**: Tailwind v3 → **v4** (CSS-based config). 디자인 토큰을 `tailwind.config.ts` 대신 `globals.css` 의 `@theme inline` 으로 매핑.
- **패키지 매니저**: pnpm → npm. pnpm이 Windows + 한글 경로(`이석진 업무/안티그래비티/...`)에서 node_modules symlink 생성에 실패해 npm 으로 전환.
- **`middleware.ts` 위치**: Next.js 16에서 `proxy.ts` 로 deprecate 됐으나 동작은 그대로. 일단 `middleware.ts` 유지 (corder 후속 작업에서 rename 고려).

### 완료
- [P1-01] Next.js 16.2.6 + TS + Tailwind 4 + ESLint 9 부트스트랩 (`SRC/`)
- [P1-01] 패키지 설치: @supabase/ssr, @supabase/supabase-js, RHF, Zod, TanStack Query, Recharts, xlsx, date-fns, lucide-react, clsx, tailwind-merge, CVA 등 (424 packages)
- [P1-05] 디자인 토큰을 `app/globals.css` `@theme inline` 으로 적용 (컬러/타이포/간격/라운드/그림자/이징)
- [P1-04] Supabase 클라이언트 4종:
  - `lib/supabase/client.ts` 브라우저용 (createBrowserClient)
  - `lib/supabase/server.ts` 서버 컴포넌트/액션용 (createServerClient with cookies)
  - `lib/supabase/middleware.ts` updateSession 헬퍼
  - `lib/supabase/admin.ts` service_role 전용 (사용 주의)
- [P1-04] `middleware.ts` 라우트 가드 (비로그인 + /app → /login 리다이렉트, 로그인 + /login → /app)
- DB 타입 자동 생성 → `types/database.ts` (Supabase remote 기반)
- 도메인 헬퍼:
  - `lib/utils/cn.ts` clsx + tailwind-merge
  - `lib/domain/money.ts` formatMoney / formatWon / formatMoneyShort (1억, 100만 등) / parseMoney
  - `lib/domain/dates.ts` formatDate / formatDateKo / dDay / dDayLabel / dDayLevel
  - `lib/domain/funding.ts` 재원 ENUM 라벨/색상/순서
  - `lib/domain/business-number.ts` 사업자번호 검증 + 표시 포맷
- 홈 페이지 (`app/page.tsx`) 미니멀 플레이스홀더 (랜딩은 Phase 3)
- 루트 layout 한국어 + 메타 정보 정리

### 빌드 검증
- ✅ `npx tsc --noEmit` 에러 0
- ✅ `npm run build` 성공 (2.9s, route `/` static + middleware 인식)

### 후속 (다음 사이클)
- shadcn/ui 컴포넌트 install (Button, Input, Card, Dialog, Sheet, Toast, Badge, Table, Dropdown, Select, Tabs)
- 인증 화면 (S-AUTH-001 ~ S-AUTH-005)
- 조직 생성 온보딩 (S-ORG-NEW)
- AppShell 레이아웃 + Sidebar/Header
