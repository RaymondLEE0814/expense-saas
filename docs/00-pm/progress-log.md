# 진행 로그 (Progress Log)

> PM이 작업 발생 시마다 한 줄 기록. 최신 항목이 위.

---

## 2026-05-19

- [완료] [사용자+PM] 요구사항 정의서 v1 작성 — [worklist.md](../../worklist.md)
- [완료] [PM] 에이전트 정의 6개 + 워크플로우 문서 작성 — [.agents/](../../.agents/)
- [완료] [PM] 폴더 구조 세팅 — `docs/00-pm`, `docs/01-planning`, ..., `docs/05-qa`
- [완료] [PM] 권장 스킬 12개 일괄 설치 (PRD/디자인/Supabase/Next.js/QA)
- [완료] [디자이너 참고] Apple HIG 기반 디자인 가이드 작성 — [.agents/skills/design_apple.md](../../.agents/skills/design_apple.md)
- [완료] [PM] WBS v1 작성 — [WBS.md](WBS.md)
- [완료] [사용자] 기획자 작업(P0-03) 착수 승인 — B-001 해소
- [완료] [기획자] P0-03 PRD 작성 — [PRD.md](../01-planning/PRD.md)
- [완료] [기획자] P0-04 페르소나 4종 작성 — [personas.md](../01-planning/personas.md)
- [완료] [기획자] P0-05 사용자 스토리 27건 + 인수기준 — [user-stories.md](../01-planning/user-stories.md)
- [완료] [기획자] P0-06 기능 명세 23건 — [features.md](../01-planning/features.md)
- [완료] [기획자] P0-07 용어집 7개 카테고리 50+ 용어 — [glossary.md](../01-planning/glossary.md)
- [완료] [PM] P0-08 게이트 리뷰 **통과** — [gate-P0-08.md](gate-P0-08.md)
- [추가] [PM] ADR-005 의사결정 — 감사 컬럼(created_by/updated_by) MVP 포함
- [블록 해소] B-001 closed (기획자 승인 받음)
- [다음 단계] P0-09 ~ P0-17 디자이너·아키텍쳐 병렬 착수 준비 완료
- [완료] [디자이너] P0-09 디자인 시스템 (Tailwind 토큰) — [design-system.md](../02-design/design-system.md)
- [완료] [디자이너] 공통 레이아웃 — [layouts.md](../02-design/layouts.md)
- [완료] [디자이너] P0-10 화면 명세 19개 (auth/org/companies/projects/members/reports/settings)
- [완료] [디자이너] 주요 플로우 5개 + 마이크로카피
- [완료] [아키텍쳐] P0-11 DB 스키마 (11 테이블 + 3 뷰 + 트리거)
- [완료] [아키텍쳐] P0-12 RLS 정책 (헬퍼 6 + 전 테이블 정책)
- [완료] [아키텍쳐] P0-13 시드 데이터 (안티그래비티 + 3사 + 데모 사업)
- [완료] [아키텍쳐] P0-14 API/Server Action 명세
- [완료] [아키텍쳐] P0-15 프론트엔드 아키텍쳐 (폴더/라우팅/미들웨어/패키지)
- [완료] [아키텍쳐] P0-16 인증·초대 흐름 + 보안 체크리스트
- [완료] [아키텍쳐] P0-17 환경 변수 + 배포 절차
- [완료] [PM] P0-18 게이트 리뷰 **통과** — [gate-P0-18.md](gate-P0-18.md)
- [추가] [PM] ADR-006, ADR-007 의사결정 (뷰 security_invoker, 초대 단순화)
- [다음 단계] Phase 1 착수 — corder 부트스트랩 (B-002 Supabase 키 필요)
- [완료] [PM] GitHub Public 리포 생성 — https://github.com/RaymondLEE0814/expense-saas
- [완료] [PM] Git 초기화 + 첫 커밋 (29개 Phase 0 산출물)
- [완료] [PM] pnpm 11.1.3 + supabase CLI 2.100.0 글로벌 설치
- [완료] [PM] Supabase 프로젝트 `expense-saas-dev` 생성 (Seoul ap-northeast-2, Free)
  - Project ref: gwvoiaxdjjmnfofbauwn
- [완료] [PM] API 키 확보 + SRC/.env.local 작성 (gitignored)
- [완료] [PM] supabase init + 마이그레이션 2건 작성 (timestamped)
- [완료] [PM] 원격 link + db push 완료 (스키마 + RLS 정책 적용)
- [완료] [PM] 두 번째 커밋(supabase/) GitHub 푸시
- [블록 해소] B-002 closed (Supabase 프로젝트 생성 + 마이그레이션 완료)
- [다음 단계] **corder 부트스트랩 (P1-01 ~ P1-05)** — Next.js 프로젝트 SRC/ 안에 초기화

---

## 2026-05-20

- [완료] [corder] P1-01~05 부트스트랩 — Next.js 16 + TS + Tailwind v4 + shadcn 초기화, Supabase 클라이언트 3종 + 미들웨어, 디자인 토큰 매핑 (커밋 3f4a779)
- [완료] [corder] 첫 인증 화면 골격 — S-AUTH-001 로그인 페이지 + App Shell 레이아웃
- [완료] [아키텍쳐] **Wave A.5** — 사업비 구성표(`budget_item_lines`) 모델 신설
  - 마이그레이션: [20260520000001_add_budget_item_lines.sql](../../supabase/migrations/20260520000001_add_budget_item_lines.sql)
  - `expenses.budget_item_line_id` 추가, 뷰 `v_budget_item_execution` 재정의 + `v_budget_item_line_execution` 신설
  - 근거 및 영향: [ADR-008](decisions.md)
- [완료] [PM] 조직명 일괄 변경 — "안티그래비티" → "(주)슈퍼런" (worklist/PRD/glossary/personas/design-system/screens/seed.sql 등)

---

## 2026-05-21

- [완료] [PM] 현재 진척 PM 보고 (사용자 요청)
- [완료] [PM] WBS 동기화 — P1-01~05 ✅, P1-06(Wave A.5) 추가
- [진행] [PM] 미커밋 정리 — 의미 단위 2 커밋(Wave A.5 / 조직명 일괄 변경 + 부트스트랩 잔여) + GitHub push + Supabase 원격 마이그레이션 push
