# WBS — 사업비 정산 관리 SaaS (멀티 테넌트)

> 작성: PM | 최초: 2026-05-19 | 갱신: 2026-05-19
> 출처: [worklist.md](../../worklist.md) / [.agents/WORKFLOW.md](../../.agents/WORKFLOW.md)

---

## 0. 마일스톤

| 단계 | 마일스톤 | 핵심 산출물 | 완료 기준 |
|------|----------|-------------|-----------|
| **M0** | 기획·설계 완료 | PRD / 디자인 / 아키텍쳐 산출물 | 게이트 리뷰 통과 |
| **M1** | MVP α — 자사 사용 가능 | Next.js + Supabase 가동, 핵심 흐름 동작 | 디코더 P0/P1 0건 |
| **M2** | 클로즈드 베타 | 멀티 조직 / 초대 / 결제 제외 | 외부 1팀 가입 가능 |
| **M3** | 퍼블릭 SaaS | 결제, 슈퍼관리자, 알림 | 일반 가입 오픈 |

> 본 WBS는 **M0 → M1** 까지를 다룬다. M2/M3은 별도 WBS.

---

## 1. WBS — Phase 0 (기획·설계)

| ID | 작업 | 담당 | 의존 | 상태 | 산출물 |
|----|------|------|------|------|--------|
| P0-01 | 요구사항 확정 (worklist.md) | 사용자+PM | - | ✅ 완료 | `worklist.md` |
| P0-02 | WBS 작성 | PM | P0-01 | ✅ 완료 | `docs/00-pm/WBS.md` |
| P0-03 | PRD 작성 | 기획자 | P0-02 | ✅ 완료 | `docs/01-planning/PRD.md` |
| P0-04 | 페르소나 정의 | 기획자 | P0-02 | ✅ 완료 | `docs/01-planning/personas.md` |
| P0-05 | 사용자 스토리 + 인수 기준 | 기획자 | P0-03 | ✅ 완료 | `docs/01-planning/user-stories.md` |
| P0-06 | 기능 명세 | 기획자 | P0-03 | ✅ 완료 | `docs/01-planning/features.md` |
| P0-07 | 용어집 | 기획자 | P0-03 | ✅ 완료 | `docs/01-planning/glossary.md` |
| P0-08 | **[게이트] 기획 검수** | PM | P0-03~07 | ✅ 통과 | `docs/00-pm/gate-P0-08.md` |
| P0-09 | 디자인 시스템 정의 | 디자이너 | P0-08 | ✅ 완료 | `docs/02-design/design-system.md` |
| P0-10 | 화면 명세서 (전 화면) | 디자이너 | P0-09 | ✅ 완료 | `docs/02-design/screens/*` (19화면) |
| P0-11 | DB 스키마 SQL | 아키텍쳐 | P0-08 | ✅ 완료 | `docs/03-architecture/db-schema.sql` |
| P0-12 | RLS 정책 SQL | 아키텍쳐 | P0-11 | ✅ 완료 | `docs/03-architecture/rls-policies.sql` |
| P0-13 | 시드 데이터 SQL | 아키텍쳐 | P0-11 | ✅ 완료 | `docs/03-architecture/seed.sql` |
| P0-14 | API / 서버액션 명세 | 아키텍쳐 | P0-10, P0-11 | ✅ 완료 | `docs/03-architecture/api-spec.md` |
| P0-15 | 프론트엔드 아키텍쳐 | 아키텍쳐 | P0-09 | ✅ 완료 | `docs/03-architecture/frontend-architecture.md` |
| P0-16 | 인증 / 권한 흐름 | 아키텍쳐 | P0-12 | ✅ 완료 | `docs/03-architecture/auth-flow.md` |
| P0-17 | 환경 변수 / 배포 명세 | 아키텍쳐 | P0-15 | ✅ 완료 | `docs/03-architecture/env.example.md`, `deployment.md` |
| P0-18 | **[게이트] 디자인·아키텍쳐 정합성 검수** | PM | P0-09~17 | ✅ 통과 | `docs/00-pm/gate-P0-18.md` |

---

## 2. WBS — Phase 1 (MVP 구현, M1)

### 2.1 부트스트랩
| ID | 작업 | 담당 | 의존 | 상태 |
|----|------|------|------|------|
| P1-01 | Next.js 16 + TS + Tailwind v4 + shadcn 초기화 | corder | P0-18 | ✅ 완료 |
| P1-02 | Supabase 프로젝트 생성·환경변수 설정 | corder + 사용자 | P1-01 | ✅ 완료 |
| P1-03 | DB 마이그레이션 적용 (스키마/RLS/시드) | corder | P1-02 | ✅ 완료 |
| P1-04 | Supabase 클라이언트 3종 + 미들웨어 | corder | P1-02 | ✅ 완료 |
| P1-05 | 디자인 토큰 → Tailwind 설정 매핑 | corder | P0-09 | ✅ 완료 |
| P1-06 | **Wave A.5** — 사업비 구성표(`budget_item_lines`) 모델 추가 | 아키텍쳐 | P1-03 | ✅ 완료 — [ADR-008](decisions.md) |

### 2.2 인증 / 조직
| ID | 작업 | 화면 ID | 담당 | 상태 |
|----|------|---------|------|------|
| P1-10 | 회원가입 / 로그인 / 비번 재설정 | S-AUTH-001~003 | corder | ⬜ |
| P1-11 | 조직 생성 온보딩 | S-ORG-NEW | corder | ⬜ |
| P1-12 | 멤버 초대 / 초대 수락 | S-MEM-INVITE | corder | ⬜ |

### 2.3 회사 / 사업 / 비목 / 집행
| ID | 작업 | 화면 ID | 담당 | 상태 |
|----|------|---------|------|------|
| P1-20 | 회사 CRUD | S-COM-001/002 | corder | ⬜ |
| P1-21 | 사업 CRUD | S-PRJ-NEW | corder | ⬜ |
| P1-22 | 비목 CRUD | S-PRJ-003 | corder | ⬜ |
| P1-23 | 집행 내역 CRUD | S-PRJ-002 | corder | ⬜ |

### 2.4 대시보드 / 리포트
| ID | 작업 | 화면 ID | 담당 | 상태 |
|----|------|---------|------|------|
| P1-30 | 조직 대시보드 | S-ORG-001 | corder | ⬜ |
| P1-31 | 사업 대시보드 (집행률/재원/D-day) | S-PRJ-001 | corder | ⬜ |
| P1-32 | 엑셀 내보내기 | S-RPT-001 | corder | ⬜ |

### 2.5 QA / 디버깅
| ID | 작업 | 담당 | 상태 |
|----|------|------|------|
| P1-90 | 테스트 계획 + 매트릭스 | 디코더 | ⬜ |
| P1-91 | 권한 매트릭스 검증 | 디코더 | ⬜ |
| P1-92 | 보안 체크리스트 | 디코더 | ⬜ |
| P1-93 | 핵심 흐름 e2e 1세트 | 디코더 | ⬜ |
| P1-94 | **[게이트] 사용자 데모 준비** | PM | ⬜ |

---

## 3. 상태 범례
- ✅ 완료
- 🟡 진행 중
- ⬜ 대기 (미착수)
- 🔴 블록 (blockers.md 참조)
- 🔄 재작업 필요

---

## 4. 추적 메모
- 이 WBS는 **살아있는 문서(Living Doc)**. 작업 상태 변경 시 즉시 갱신.
- 작업 추가/삭제 시 `progress-log.md`에 사유 기록.
- 게이트 리뷰 결과는 `decisions.md`에 기록.
