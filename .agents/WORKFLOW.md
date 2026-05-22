# 업무 플로우 (Agent Workflow)

> 사업비 정산 관리 프로그램(멀티 테넌트 SaaS) 개발의 에이전트 간 협업 체계.
> 사용자의 요구사항 → 기획 → 디자인/아키텍쳐 → 구현 → 검증 → 보고까지 한 사이클을 정의한다.

---

## 0. 에이전트 명단

| 에이전트 | 핵심 역할 | 파일 |
|----------|-----------|------|
| **PM** | 전체 총괄, 작업 분배, 진행 추적, 사용자 보고 | [.agents/PM.md](PM.md) |
| **기획자** | PRD / 기능 명세 / 사용자 스토리 | [.agents/기획자.md](기획자.md) |
| **디자이너** | UI/UX, 디자인 시스템, 화면 명세 | [.agents/디자이너.md](디자이너.md) |
| **아키텍쳐설계** | DB / RLS / API / FE 구조 / 인증 | [.agents/아키텍쳐설계.md](아키텍쳐설계.md) |
| **corder** | 실제 코드 구현 (`SRC/`) | [.agents/corder.md](corder.md) |
| **디코더** | 검증 / QA / 디버깅 | [.agents/디코더.md](디코더.md) |

---

## 1. 전체 파이프라인

```
                            ┌─────────────────────────────┐
                            │   사용자 (이석진 / Raymond)  │
                            └──────────────┬──────────────┘
                                           │ 요구사항
                                           ▼
                            ┌──────────────────────────────┐
                            │           PM                 │ ◀─── 사용자 보고
                            │  (총괄 / WBS / 진행 추적)     │ ───▶ docs/00-pm/
                            └──────────────┬───────────────┘
                                           │ 작업 배분
                                           ▼
                            ┌──────────────────────────────┐
                            │          기획자              │
                            │  (PRD / 기능 / 스토리)        │ ───▶ docs/01-planning/
                            └───────┬──────────────┬───────┘
                                    │              │
                          ┌─────────▼──┐      ┌────▼──────────────┐
                          │  디자이너   │      │  아키텍쳐설계자    │
                          │ (UI/UX)    │      │  (DB/API/FE 구조)  │
                          └─────┬──────┘      └────────┬──────────┘
                       docs/02-design/         docs/03-architecture/
                                │                      │
                                └──────────┬───────────┘
                                           ▼
                            ┌──────────────────────────────┐
                            │          corder              │
                            │      (실제 구현, SRC/)        │ ───▶ SRC/
                            └──────────────┬───────────────┘                                                 │ ───▶ docs/04-development/
                                           ▼
                            ┌──────────────────────────────┐
                            │          디코더              │
                            │  (검증 / 디버깅 / QA)         │ ───▶ docs/05-qa/
                            └──────────────┬───────────────┘
                                           │ 결과 종합
                                           ▼
                            ┌──────────────────────────────┐
                            │           PM                 │
                            │   사용자 보고서 제출          │
                            └──────────────────────────────┘
```

---

## 2. 폴더 구조 (확정)

```
00.사업비정산프로그램/
├── worklist.md                       # 요구사항 정의서 (Living Doc)
├── .agents/                          # 에이전트 정의
│   ├── WORKFLOW.md                   # ★ 이 문서
│   ├── PM.md
│   ├── 기획자.md
│   ├── 디자이너.md
│   ├── 아키텍쳐설계.md
│   ├── corder.md
│   ├── 디코더.md
│   └── skills/                       # find-skills 등
├── SRC/                              # ★ 소스 코드 (corder 담당)
│   ├── app/
│   ├── components/
│   ├── lib/
│   ├── hooks/
│   ├── types/
│   ├── README.md
│   └── ...
└── docs/                             # ★ 모든 산출물 / 보고서
    ├── 00-pm/                        # PM
    │   ├── WBS.md
    │   ├── progress-log.md
    │   ├── weekly-report-*.md
    │   ├── decisions.md
    │   └── blockers.md
    ├── 01-planning/                  # 기획자
    │   ├── PRD.md
    │   ├── features.md
    │   ├── user-stories.md
    │   ├── personas.md
    │   └── glossary.md
    ├── 02-design/                    # 디자이너
    │   ├── design-system.md
    │   ├── layouts.md
    │   ├── flows.md
    │   ├── microcopy.md
    │   └── screens/
    │       ├── S-AUTH-001.md
    │       ├── S-PRJ-002.md
    │       └── ...
    ├── 03-architecture/              # 아키텍쳐설계
    │   ├── db-schema.sql
    │   ├── rls-policies.sql
    │   ├── seed.sql
    │   ├── api-spec.md
    │   ├── frontend-architecture.md
    │   ├── auth-flow.md
    │   ├── env.example.md
    │   └── deployment.md
    ├── 04-development/               # corder
    │   └── dev-log.md
    └── 05-qa/                        # 디코더
        ├── test-plan.md
        ├── test-matrix.md
        ├── verification-log.md
        ├── security-checklist.md
        ├── performance-notes.md
        └── bugs/
            └── BUG-001.md
```

---

## 3. 사이클별 흐름

### 3.1 Phase 0 — 킥오프 (1회)
**진입 조건**: `worklist.md` 작성 완료

| Step | 담당 | 산출물 |
|------|------|--------|
| 1 | PM | WBS 초안, 마일스톤 정의 → `docs/00-pm/WBS.md` |
| 2 | 기획자 | PRD/기능/스토리 작성 → `docs/01-planning/` |
| 3 | PM | 게이트 리뷰 (PRD 검수) |
| 4 | 디자이너 + 아키텍쳐 | 병렬 진행 → `docs/02-design/`, `docs/03-architecture/` |
| 5 | PM | 게이트 리뷰 (디자인·아키텍쳐 정합성) |
| 6 | corder | 프로젝트 부트스트랩 → `SRC/` |
| 7 | corder | DB 마이그레이션 적용 |
| 8 | PM | 사용자 보고서 (Phase 0 종료) → `docs/00-pm/weekly-report-*.md` |

### 3.2 Phase 1 — 기능 사이클 (반복)
**한 사이클 = 1~3개 화면 / 기능 단위**

| Step | 담당 | 산출물 / 액션 |
|------|------|---------------|
| 1 | PM | 이번 사이클 범위 지정 (화면 ID 리스트) |
| 2 | 기획자 | (필요 시) 명세 보완 |
| 3 | 디자이너 | 화면 명세 추가 → `docs/02-design/screens/` |
| 4 | 아키텍쳐 | (필요 시) 스키마·API 보완 |
| 5 | corder | 구현 → `SRC/` + `dev-log.md` |
| 6 | corder | 빌드/타입체크 통과 → 인계 |
| 7 | 디코더 | 검증·테스트·버그 리포트 → `docs/05-qa/` |
| 8 | corder | 버그 수정 |
| 9 | 디코더 | 재검증 → 통과 시 종료 |
| 10 | PM | 사이클 완료 보고 → `docs/00-pm/` |

### 3.3 Phase 2 — 베타·확장 (MVP 이후)
- 증빙 첨부, 알림, 정산 양식 자동화 등
- 동일 사이클을 반복하되 사용자 피드백을 1순위 입력으로

---

## 4. 산출물 인계 규칙 (Handoff)

산출물이 다음 단계로 넘어가려면 **모든 인계 체크리스트**가 충족되어야 한다.
체크리스트 미충족 시 PM이 반려한다.

### 4.1 기획자 → 디자이너 / 아키텍쳐
- [ ] PRD에 범위(In/Out) 명시
- [ ] 모든 기능에 인수 기준 존재
- [ ] 모든 역할(super_admin / org_admin / company_member / viewer)의 권한 명시
- [ ] 비기능 요구사항(보안/성능/접근성) 포함
- [ ] 도메인 용어 `glossary.md` 등록

### 4.2 디자이너 → corder
- [ ] 사이트맵의 모든 화면에 화면 ID 부여
- [ ] 각 화면에 4상태(데이터/빈/로딩/에러) 명시
- [ ] 디자인 시스템 토큰 정의 완료
- [ ] 마이크로 카피 작성

### 4.3 아키텍쳐 → corder
- [ ] DDL이 SQL 파일로 실행 가능
- [ ] 모든 도메인 테이블에 RLS 정책 존재
- [ ] 화면에서 필요한 모든 데이터 페칭이 API 명세에 매핑
- [ ] 환경 변수 목록 (`env.example.md`)
- [ ] 시드 데이터(`seed.sql`) — (주)슈퍼런 + 3개 회사

### 4.4 corder → 디코더
- [ ] 빌드/타입체크/린트 통과
- [ ] 모든 화면 라우팅 동작
- [ ] 권한 격리 수동 1회 확인
- [ ] `SRC/README.md` 최신화
- [ ] `dev-log.md` 갱신

### 4.5 디코더 → 사용자 데모
- [ ] P0/P1 버그 0건
- [ ] 인수 기준 100% 통과
- [ ] 권한 매트릭스 100% 통과
- [ ] `verification-log.md` 최신화

---

## 5. 의사소통 규칙

### 5.1 모든 변경은 문서를 통해
- 구두/채팅 합의는 PM이 `decisions.md`에 즉시 기록
- 코드만 바뀌고 문서가 안 바뀐 변경은 무효 (PM이 반려)

### 5.2 블로커는 즉시 보고
- 다른 에이전트나 사용자 입력이 필요한 상황 = 블로커
- `blockers.md`에 등록 + PM이 사용자에게 즉시 보고

### 5.3 산출물 링크는 상대 경로
- `docs/01-planning/PRD.md` 처럼 워크스페이스 루트 기준

### 5.4 화면 ID는 절대 키
- 화면 ID로 디자인·구현·테스트가 연결된다
- 변경 시 PM이 매핑 테이블 업데이트 (`docs/00-pm/screen-id-map.md`)

---

## 6. 권장 스킬 (Skills) — 일괄 설치 제안

각 에이전트별 권장 스킬을 정리. 사용자 승인 후 일괄 설치 가능:

```bash
# 기획자
npx skills add mattpocock/skills@to-prd -g -y
npx skills add mattpocock/skills@prd-to-plan -g -y

# 디자이너
npx skills add anthropics/skills@frontend-design -g -y
npx skills add vercel-labs/agent-skills@web-design-guidelines -g -y

# 아키텍쳐설계
npx skills add supabase/agent-skills@supabase-postgres-best-practices -g -y
npx skills add supabase/agent-skills@supabase -g -y
npx skills add wshobson/agents@nextjs-app-router-patterns -g -y

# corder
npx skills add sickn33/antigravity-awesome-skills@nextjs-supabase-auth -g -y
npx skills add sickn33/antigravity-awesome-skills@nextjs-best-practices -g -y

# 디코더
npx skills add anthropics/skills@webapp-testing -g -y
npx skills add obra/superpowers@requesting-code-review -g -y
npx skills add wshobson/agents@e2e-testing-patterns -g -y
```

> **주의**: 설치는 사용자 승인 후 실행. 각 에이전트 .md 파일의 "권장 스킬" 섹션에 install 수와 출처가 명시되어 있다.

---

## 7. 시작 절차 (Quick Start)

1. **사용자 → PM**: "Phase 0 시작" 지시
2. **PM**: `docs/00-pm/WBS.md` 작성, 기획자에 작업 지시
3. **기획자**: `docs/01-planning/` 산출물 작성
4. **PM 게이트 리뷰**: 통과 시 디자이너·아키텍쳐 병렬 착수 지시
5. **디자이너 + 아키텍쳐**: 산출물 작성
6. **PM 게이트 리뷰**: 통과 시 corder 부트스트랩 지시
7. **corder**: `SRC/` 부트스트랩 + 첫 화면 구현
8. **디코더**: 첫 검증
9. **PM**: 사용자에게 첫 데모 + 보고서 제출
