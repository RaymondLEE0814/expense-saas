# 사업비 정산 관리 SaaS

> 정부지원 사업을 운영하는 스타트업·법인을 위한 멀티 테넌트 사업비 정산 SaaS.
> 회사·사업·재원·비목·집행을 한 곳에서 관리하고, 실시간 집행률과 잔여 예산을 추적합니다.

---

## ✨ 무엇을 할 수 있나요

- 🏢 **멀티 회사 관리**: 한 조직에서 여러 법인의 정부지원 사업을 통합 관리
- 💰 **재원 분리 추적**: 정부지원금 / 자기부담현금 / 자기부담현물 각각의 집행률
- 📊 **사업 대시보드**: 비목별 집행률, D-day, 월별 추이를 한눈에
- 👥 **권한 격리**: 조직 관리자 / 회사 담당자 / 조회자 — RLS 기반
- 📥 **엑셀 내보내기**: 정산 보고용 표준 XLSX

---

## 🛠 기술 스택

| 영역 | 선택 |
|------|------|
| Frontend | Next.js 15 (App Router) + TypeScript |
| UI | Tailwind CSS + shadcn/ui |
| Backend / DB | Supabase (Postgres + Auth + Storage + RLS) |
| 차트 | Recharts |
| 폼 | React Hook Form + Zod |
| 배포 | Vercel + Supabase Cloud |

---

## 📁 프로젝트 구조

```
.
├── .agents/              # AI 에이전트 정의 (PM/기획자/디자이너/아키텍쳐/corder/디코더)
│   └── skills/           # 디자인 가이드 등
├── docs/                 # 모든 산출물 (워크플로우 결과물)
│   ├── 00-pm/            # PM: WBS, 진행 로그, 게이트 리뷰
│   ├── 01-planning/      # 기획자: PRD, 사용자 스토리, 기능 명세, 용어집
│   ├── 02-design/        # 디자이너: 디자인 시스템, 화면 명세, 플로우
│   ├── 03-architecture/  # 아키텍쳐: DB 스키마, RLS, API, FE 구조, 인증
│   ├── 04-development/   # corder: 개발 로그
│   └── 05-qa/            # 디코더: 테스트 계획, 버그 리포트
├── SRC/                  # 소스 코드 (Next.js 앱)
└── worklist.md           # 요구사항 정의서
```

---

## 🚀 개발 시작하기

> 자세한 부트스트랩 절차는 [`docs/03-architecture/deployment.md`](docs/03-architecture/deployment.md) 참조.

```bash
# 1) 의존성 설치
cd SRC
pnpm install

# 2) 환경 변수 설정
cp .env.example .env.local
# .env.local에 Supabase 키 입력

# 3) DB 마이그레이션 (Supabase Dashboard SQL Editor에서 순서대로 실행)
#   docs/03-architecture/db-schema.sql
#   docs/03-architecture/rls-policies.sql
#   docs/03-architecture/seed.sql  (개발/스테이징만)

# 4) 개발 서버
pnpm dev
```

---

## 📑 주요 문서

- [요구사항 정의서](worklist.md)
- [PRD](docs/01-planning/PRD.md)
- [사용자 스토리](docs/01-planning/user-stories.md)
- [디자인 시스템](docs/02-design/design-system.md)
- [DB 스키마](docs/03-architecture/db-schema.sql)
- [API 명세](docs/03-architecture/api-spec.md)
- [프론트엔드 아키텍쳐](docs/03-architecture/frontend-architecture.md)
- [에이전트 워크플로우](.agents/WORKFLOW.md)

---

## 🗓 단계별 로드맵

| 단계 | 내용 | 상태 |
|------|------|------|
| Phase 0 | 기획·설계 | ✅ 완료 |
| Phase 1 (M1) | MVP α — 자사((주)슈퍼런) 사용 가능 | 🟡 진행 중 |
| Phase 2 (M2) | 클로즈드 베타 — 외부 스타트업 가입 | ⬜ 대기 |
| Phase 3 (M3) | 퍼블릭 SaaS — 결제 / 운영 콘솔 | ⬜ 대기 |

---

## 📜 라이센스

TBD (Phase 3 출시 전 결정)
