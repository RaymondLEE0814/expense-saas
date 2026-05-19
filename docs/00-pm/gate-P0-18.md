# Gate Review — P0-18 디자인·아키텍쳐 정합성 검수

> 검수자: PM | 일자: 2026-05-19 | 결과: **✅ 통과 (Pass with notes)**

---

## 1. 검수 대상

### 1.1 디자이너 트랙 (P0-09, P0-10)
| 산출물 | 경로 | 상태 |
|--------|------|------|
| 디자인 시스템 | [design-system.md](../02-design/design-system.md) | ✅ |
| 공통 레이아웃 | [layouts.md](../02-design/layouts.md) | ✅ |
| 화면 명세 인덱스 | [screens/INDEX.md](../02-design/screens/INDEX.md) | ✅ (19개 화면) |
| 인증 화면 | [screens/auth.md](../02-design/screens/auth.md) | ✅ |
| 조직 화면 | [screens/org.md](../02-design/screens/org.md) | ✅ |
| 회사 화면 | [screens/companies.md](../02-design/screens/companies.md) | ✅ |
| 사업 화면 | [screens/projects.md](../02-design/screens/projects.md) | ✅ |
| 멤버 화면 | [screens/members.md](../02-design/screens/members.md) | ✅ |
| 리포트 화면 | [screens/reports.md](../02-design/screens/reports.md) | ✅ |
| 설정 화면 | [screens/settings.md](../02-design/screens/settings.md) | ✅ |
| 주요 플로우 | [flows.md](../02-design/flows.md) | ✅ (5개) |
| 마이크로 카피 | [microcopy.md](../02-design/microcopy.md) | ✅ |

### 1.2 아키텍쳐 트랙 (P0-11 ~ P0-17)
| 산출물 | 경로 | 상태 |
|--------|------|------|
| DB 스키마 | [db-schema.sql](../03-architecture/db-schema.sql) | ✅ (11 테이블 + 3 뷰 + 트리거) |
| RLS 정책 | [rls-policies.sql](../03-architecture/rls-policies.sql) | ✅ (헬퍼 6 + 전 테이블 정책) |
| 시드 | [seed.sql](../03-architecture/seed.sql) | ✅ (안티그래비티 + 3사 + 데모 사업) |
| API 명세 | [api-spec.md](../03-architecture/api-spec.md) | ✅ (12 섹션) |
| 프론트엔드 아키텍쳐 | [frontend-architecture.md](../03-architecture/frontend-architecture.md) | ✅ (14 섹션) |
| 인증 흐름 | [auth-flow.md](../03-architecture/auth-flow.md) | ✅ (12 섹션) |
| 환경 변수 | [env.example.md](../03-architecture/env.example.md) | ✅ |
| 배포 절차 | [deployment.md](../03-architecture/deployment.md) | ✅ |

---

## 2. 게이트 체크리스트 ([WORKFLOW.md §4.2 / §4.3](../../.agents/WORKFLOW.md))

### 디자이너 → corder
- [x] 사이트맵의 모든 화면에 화면 ID 부여 (19개 — S-AUTH/ORG/COM/PRJ/MEM/RPT/SET/ACC)
- [x] 각 화면에 4상태(데이터/빈/로딩/에러) 명시
- [x] 디자인 시스템 토큰 정의 완료 (Tailwind config 직매핑)
- [x] 마이크로 카피 작성 (버튼/빈상태/검증/확인/토스트/에러)

### 아키텍쳐 → corder
- [x] DDL이 SQL 파일로 실행 가능
- [x] 모든 도메인 테이블에 RLS 정책 존재
- [x] 화면에서 필요한 모든 데이터 페칭이 API 명세에 매핑
- [x] 환경 변수 목록 (`env.example.md`)
- [x] 시드 데이터(`seed.sql`) — 안티그래비티 + 3개 회사 + 데모 사업

---

## 3. 정합성 점검

| 점검 항목 | 결과 | 비고 |
|----------|------|------|
| 화면 ID ↔ 라우트 매핑 | ✅ | INDEX.md ↔ frontend-architecture §1 |
| 화면 ↔ API 매핑 | ✅ | 각 화면의 필요 데이터가 api-spec에 존재 |
| API ↔ DB 매핑 | ✅ | 모든 server action이 실존 테이블 사용 |
| RLS ↔ 권한 매트릭스 | ✅ | user-stories §매트릭스와 일치 |
| 도메인 용어 일관성 | ✅ | glossary 기준어 적용 |
| ADR-005 반영 | ✅ | created_by/updated_by 모든 도메인 테이블 포함 |
| Apple HIG 적용 | ✅ | design-system §1 토큰이 design_apple §2-7과 일치 |
| 재원 색상 일관성 | ✅ | gov 파랑 / cash 초록 / inkind 주황 (디자인 + DB ENUM) |

---

## 4. 발견 사항 (Notes)

> 통과를 막을 결함은 없으나 corder 단계에서 보완:

1. **`pending_company_ids` 컬럼**: 초대 시점에 company_member의 회사 매핑을 사전 저장하려면 `memberships` 테이블에 `pending_company_ids uuid[]` 컬럼 추가 필요. MVP에서는 일단 컬럼 없이 진행하고, 수락 시 관리자가 매핑을 재확인하는 흐름으로 단순화 (또는 corder가 컬럼 추가 마이그레이션 작성 — 권장).

2. **Realtime 미사용 (MVP)**: TanStack Query refetch + revalidateTag로 충분. Phase 2에서 도입.

3. **Storage 정책 비활성**: 증빙 첨부 Phase 2에서 활성. rls-policies.sql에 주석으로만 보관.

4. **`v_budget_item_execution` 등 뷰의 RLS**: 뷰 자체는 RLS 직접 적용 불가, 하지만 정의에서 RLS가 적용된 테이블을 참조하므로 자동 격리됨. 단, security_invoker 옵션 명시 권장 (Postgres 15+):
   ```sql
   alter view public.v_budget_item_execution set (security_invoker = on);
   ```
   → corder가 마이그레이션 단계에서 추가.

5. **데모 사업 비목 계획 합계**: seed.sql 의 비목 합계(₩980,000,000) > 총사업비(₩880,000,000). 디자인의 "비목 계획 > 총사업비 경고" 시나리오를 테스트할 수 있는 의도된 데이터.

---

## 5. ADR 추가

- **ADR-006**: 뷰 `v_*_execution` 에 `security_invoker = on` 적용 (corder가 마이그레이션에 포함)
- **ADR-007**: 초대 흐름 단순화 — `pending_company_ids` 컬럼 없이, 회사 매핑은 수락 후 관리자 재확인 (MVP 한정, Phase 2에 컬럼 추가)

---

## 6. 다음 단계 지시 — Phase 1 착수

corder가 다음 순서로 부트스트랩 + 구현 시작:

1. **P1-01 ~ P1-05** (부트스트랩, 1 슬롯)
   - Next.js 15 + TS + Tailwind + shadcn 초기화 → `SRC/`
   - Supabase 프로젝트 세팅 (B-002 해결 시점)
   - 마이그레이션 적용 (스키마 → RLS → 시드)
   - 디자인 토큰 매핑
   - Supabase 클라이언트 3종 + 미들웨어
2. **P1-10 ~ P1-12** (인증 / 조직)
3. **P1-20 ~ P1-23** (회사·사업·비목·집행)
4. **P1-30 ~ P1-32** (대시보드·리포트)

**블록 사항**: B-002 (Supabase 프로젝트 키) — corder 부트스트랩 시점 이전에 필요.
