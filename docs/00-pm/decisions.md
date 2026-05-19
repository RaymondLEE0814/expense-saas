# 의사결정 기록 (Architecture Decision Records)

> 주요 의사결정 시점에 ADR 스타일로 기록.

---

## ADR-001: 멀티 테넌트 아키텍쳐 채택
- **일자**: 2026-05-19
- **결정**: 처음부터 조직(Organization) 단위 멀티 테넌트로 설계
- **대안**:
  1. 단일 조직(자사용)으로 시작 후 점진 확장 — 빠르나 추후 마이그레이션 부담
  2. **(선택)** 멀티 테넌트 처음부터 — 초기 비용 1.5~2배, 확장 매끄러움
- **근거**: 자사 사용 후 스타트업 대상 SaaS로 확장 계획. 권한·격리·초대 등을 처음부터 설계하지 않으면 후행 리스크가 큼.
- **영향**: DB 모든 도메인 테이블에 `organization_id`, RLS 의무.

## ADR-002: 기술 스택 — Next.js + Supabase
- **일자**: 2026-05-19
- **결정**: Next.js 15 (App Router) + TypeScript + Tailwind + shadcn/ui + Supabase (Postgres/Auth/Storage)
- **근거**:
  - Supabase는 RLS·Auth·Storage·Realtime을 한 번에 제공해 SaaS 부트스트랩에 최적
  - Next.js App Router로 RSC 기반 데이터 페칭 단순화
  - shadcn/ui로 디자인 시스템과 컴포넌트 결합 용이
- **영향**: 배포는 Vercel, 환경 변수 분리 필수.

## ADR-003: Apple HIG 기반 디자인 가이드 채택
- **일자**: 2026-05-19
- **결정**: 디자인 원칙은 [design_apple.md](../../.agents/skills/design_apple.md)를 1순위로 따른다 (랜딩·앱 모두).
- **근거**: 사용자의 요청. 명료성·여백·미니멀리즘을 강조해 정산 도구처럼 신뢰감과 가독성이 중요한 도메인과 잘 맞음.
- **영향**: 디자이너는 디자인 시스템 정의 시 design_apple.md의 토큰을 그대로 사용.

## ADR-004: MVP 범위
- **일자**: 2026-05-19
- **결정**: MVP는 [worklist.md §9.1](../../worklist.md) 10개 항목까지. 증빙 첨부·소셜 로그인·결제는 Phase 2+.
- **근거**: 자사 사용에 필수인 기능 우선. SaaS 출시는 이후.
- **영향**: corder는 위 범위만 구현, 임의 확장 금지.

## ADR-005: 도메인 테이블에 감사 컬럼(created_by/updated_by) MVP 포함
- **일자**: 2026-05-19
- **결정**: companies / projects / budget_items / expenses 등 모든 도메인 테이블에 `created_by uuid`, `updated_by uuid` 컬럼을 MVP부터 포함.
- **대안**:
  1. Phase 2부터 추가 — 데이터 누락
  2. **(선택)** MVP부터 포함, 변경 이력 UI는 Phase 2
- **근거**: 변경 이력 UI는 Phase 2로 미루더라도, 데이터가 없으면 추후 추적 불가. 컬럼 추가 비용은 작음.
- **영향**: 아키텍쳐 P0-11 DB 스키마에 반영. ✅ 반영 완료.

## ADR-006: 집계 뷰에 `security_invoker = on` 적용
- **일자**: 2026-05-19
- **결정**: `v_budget_item_execution`, `v_funding_source_execution`, `v_project_execution` 등 집계 뷰에 Postgres 15+의 `security_invoker = on` 옵션을 명시한다.
- **근거**: 뷰 자체는 RLS를 가지지 않으므로, 호출자(invoker)의 권한으로 베이스 테이블 RLS가 적용되도록 강제.
- **영향**: corder 마이그레이션 단계에서 `alter view ... set (security_invoker = on);` 일괄 적용.

## ADR-007: 초대 흐름 단순화 — `pending_company_ids` 컬럼 미사용 (MVP)
- **일자**: 2026-05-19
- **결정**: 멤버 초대 시 company_member 의 회사 매핑은 초대 메시지에 기록하되 DB 컬럼에 사전 저장하지 않는다. 수락 후 관리자가 회사 매핑을 재확인/저장한다.
- **대안**:
  1. `memberships.pending_company_ids uuid[]` 컬럼 추가 — 스키마 복잡도 증가
  2. **(선택)** 컬럼 미사용, 수락 후 별도 매핑
- **근거**: MVP 단순화. Phase 2에 컬럼 추가로 자동 매핑.
- **영향**: 디자이너 멤버 초대 모달에서 회사 선택은 유지하되, 수락 후 별도 매핑 단계가 가능하도록 UX 보완 필요 (Phase 2 정식화).
