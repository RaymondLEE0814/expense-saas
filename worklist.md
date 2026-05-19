# 사업비 정산 관리 프로그램 요구사항 정의서

## 1. 프로젝트 개요

### 1.1 목적
정부지원 사업비를 집행하는 다수의 법인(리피치, 슈퍼런, 팜큐 등)을 통합적으로 관리하여, 회사별·사업별 예산 집행 현황과 잔여 예산을 실시간으로 파악하고, 효율적인 예산 운영 및 정산 업무를 지원하는 **클라우드 기반 SaaS 서비스**를 개발한다.

### 1.2 배경
- 회사 그룹 내 3개 법인(리피치 / 슈퍼런 / 팜큐)이 각각 별도의 정부지원 사업을 수행 중
- 각 사업별로 현금·현물·정부지원금이 혼합되어 집행됨
- 사업 기한과 비목별 집행 계획 대비 실제 사용 현황을 한눈에 파악하기 어려움
- 수기·엑셀 관리 방식의 한계로 인한 관리 부담 및 정산 오류 가능성 존재
- **자체 사용 후, 동일한 문제를 겪는 스타트업들에게 서비스로 확장 배포 계획**

### 1.3 기대 효과
- 회사별·사업별 예산 집행 현황 통합 가시화
- 비목별 잔여 예산 및 잔여 기한 실시간 모니터링
- 예산 초과 집행 사전 방지
- 정산 업무 효율화
- **SaaS 서비스화를 통한 수익 모델 확보**

### 1.4 서비스화 단계
| 단계 | 내용 | 사용자 |
|------|------|--------|
| Phase 1 | 자사(안티그래비티 그룹) 내부 사용 | 관리자 + 3개사 담당자 |
| Phase 2 | 클로즈드 베타 (지인 스타트업) | 베타 조직 |
| Phase 3 | 퍼블릭 SaaS 출시 | 일반 스타트업 |

> **개발 방침**: 처음부터 **멀티 테넌트 아키텍처**로 설계한다. Phase 1에서는 안티그래비티 조직 1개만 운영하되, 데이터 모델·인증·권한 체계는 Phase 2/3 확장을 전제로 구축한다.

---

## 2. 시스템 구조 (멀티 테넌트)

### 2.1 계층 구조
```
조직 (Organization, 스타트업 그룹 / 테넌트)
 └─ 회사 (Company, 법인)
     └─ 사업 (Project, 정부지원 사업 건)
         ├─ 재원 구성 (정부지원금 / 자기부담금-현금 / 자기부담금-현물)
         └─ 비목 (Budget Item, 인건비/재료비/외주용역비 등)
             └─ 집행 내역 (Expense, 개별 지출 건)
```

### 2.2 자사 적용 예시
- **조직**: 안티그래비티
  - **회사**: 리피치, 슈퍼런, 팜큐
    - **사업**: 각 회사별 정부지원 사업들

---

## 3. 사용자 및 권한 모델

### 3.1 사용자 역할(Role)
| 역할 | 범위 | 주요 권한 |
|------|------|-----------|
| **슈퍼관리자 (Super Admin)** | 전체 서비스 | 모든 조직 관리, 서비스 운영자 (서비스 제공자) |
| **조직 관리자 (Org Admin)** | 소속 조직 | 조직 내 회사·사업·비목·집행 전체 CRUD, 멤버 초대/권한 부여 |
| **회사 담당자 (Company Member)** | 소속 회사 | 본인 소속 회사의 사업·집행 내역 등록/조회, 비목 조회 |
| **조회자 (Viewer, 선택)** | 지정 범위 | 읽기 전용 (감사·외부 회계사 등) |

### 3.2 접근 제어 원칙
- 조직 간 데이터는 **완전 격리** (Supabase RLS 기반)
- 동일 조직 내에서도 회사 담당자는 본인 소속 회사 데이터만 접근
- 조직 관리자는 조직 내 전 회사·전 사업 접근 가능

### 3.3 회원가입 / 가입 흐름
- 이메일 기반 회원가입 (Supabase Auth)
- 조직 생성: 가입자가 신규 조직 생성 시 자동으로 해당 조직 관리자가 됨
- 멤버 초대: 조직 관리자가 이메일로 초대 → 초대 수락 시 지정 회사·역할로 합류
- 소셜 로그인(Google 등) 추후 확장

---

## 4. 핵심 데이터 모델

### 4.1 주요 엔티티
- **organizations**: 조직(테넌트)
- **users / profiles**: 사용자 프로필 (Supabase auth.users 연동)
- **memberships**: 사용자-조직-회사-역할 매핑
- **companies**: 회사(법인)
- **projects**: 사업
- **funding_sources**: 사업별 재원(정부지원금/현금/현물) 금액
- **budget_items**: 비목
- **expenses**: 집행 내역
- **attachments**: 증빙 파일 (Supabase Storage)

### 4.2 주요 필드
- **회사**: 회사명, 사업자번호, 대표자, 담당자
- **사업**: 사업명, 주관/전담기관, 사업 시작일/종료일, 총 사업비, 선정 금액, 상태
- **재원**: 정부지원금 / 자기부담금(현금) / 자기부담금(현물) 각 계획 금액
- **비목**: 비목명, 비목 코드, 계획 금액, 비고
- **집행 건**: 집행일자, 비목, 거래처, 금액, 재원 유형, 증빙 첨부, 비고

---

## 5. 주요 기능 요구사항

### 5.1 인증 / 조직 관리
- 회원가입 / 로그인 / 비밀번호 재설정
- 조직 생성 및 기본 정보 설정
- 멤버 초대 / 역할 변경 / 제거
- 조직 전환 (1인이 여러 조직 소속 가능)

### 5.2 회사 관리
- 조직 내 회사 등록 / 수정 / 조회
- 회사별 대시보드 진입
- 회사 담당자 지정

### 5.3 사업 관리
- 회사별 사업 등록 / 수정 / 종료 처리
- 사업 기간, 총 사업비, 재원별 금액 설정
- 사업별 진행 상태 표시 (진행중 / 종료 / D-day)

### 5.4 비목 관리
- 사업별 비목 자유롭게 추가 / 수정 / 삭제
- 비목별 계획 금액 설정
- 비목 템플릿 (자주 쓰는 비목 세트, 추후)

### 5.5 집행 내역 관리
- 집행 건 등록 (날짜, 금액, 비목, 재원 유형, 거래처, 증빙 등)
- 집행 건 목록 / 검색 / 필터링
- 증빙 파일 첨부 (Supabase Storage)

### 5.6 대시보드 / 현황 조회
- **조직 대시보드**: 전 회사 통합 요약
- **회사 대시보드**: 사업별 집행 요약
- **사업 대시보드**:
  - 비목별 계획 대비 집행률, 잔여 예산
  - 재원별(정부지원금 / 현금 / 현물) 집행 현황
  - 사업 종료일까지 잔여 기한 (D-day)
  - 월별 / 기간별 집행 추이 차트

### 5.7 리포트 / 내보내기
- 회사별·사업별 정산 보고서 출력
- 엑셀(XLSX) 내보내기
- 비목별 집행 명세서

### 5.8 운영자(슈퍼관리자) 기능
- 조직 목록 / 사용량 조회
- 요금제·구독 관리 (Phase 3)
- 공지사항 / 알림 발송

---

## 6. 비기능 요구사항

### 6.1 사용성
- 엑셀 작업에 익숙한 사용자가 빠르게 적응 가능한 입력 흐름
- 모바일 반응형 (조회 위주, 입력은 데스크톱 우선)
- 한국어 기본, 다국어는 추후

### 6.2 보안
- Supabase Auth + Row Level Security(RLS) 기반 조직 격리
- 증빙 파일은 Supabase Storage + 서명 URL 접근
- 민감정보(사업자번호 등) 접근 로그

### 6.3 성능 / 확장성
- 조직당 회사 ~수십개, 사업 ~수백개 규모까지 무리없이 대응
- 페이지네이션 / 인덱스 최적화

### 6.4 데이터
- 일별 자동 백업 (Supabase 기본 + 별도 export)
- 조직 단위 데이터 export(JSON/엑셀)

---

## 7. 기술 스택 (제안)

| 영역 | 후보 | 비고 |
|------|------|------|
| 인증 / DB / Storage | **Supabase** | Auth, Postgres, RLS, Storage, Realtime |
| 프론트엔드 | Next.js (React) + TypeScript | App Router 기반 |
| UI | Tailwind CSS + shadcn/ui | 또는 Mantine |
| 상태 관리 | TanStack Query | 서버 상태 |
| 차트 | Recharts / ECharts | 대시보드 |
| 배포 | Vercel | 또는 Cloudflare Pages |
| 결제 (Phase 3) | Stripe / 토스페이먼츠 | 구독 모델 |

---

## 8. 향후 확장 고려사항
- 통장 거래내역 import 및 자동 매칭
- 정산 제출용 양식 자동 생성 (주관기관 양식 매핑)
- 회계 시스템(더존, 세무사 등) 연동
- 카카오톡/이메일 알림 (예산 초과 임박, 사업 종료 임박 등)
- 다국어 (영어) 지원
- 모바일 앱

---

## 9. 1차 개발 (MVP) 범위

> 멀티 테넌트 아키텍처를 기반으로, **자사(안티그래비티) 사용에 필요한 핵심 기능**을 우선 구현한다.

### 9.1 MVP 포함
- [x] 멀티 테넌트 데이터 모델 + Supabase RLS
- [x] 회원가입 / 로그인 (이메일)
- [x] 조직 생성 / 멤버 초대 / 역할 부여 (조직 관리자, 회사 담당자)
- [x] 회사 CRUD
- [x] 사업 CRUD (사업 기간, 총 사업비, 재원별 금액)
- [x] 비목 CRUD (계획 금액)
- [x] 집행 내역 CRUD
- [x] 사업 대시보드 (비목별 집행률, 재원별 사용 현황, D-day)
- [x] 회사 / 조직 대시보드 (요약)
- [x] 엑셀 내보내기

### 9.2 MVP 이후 (Phase 2~)
- 증빙 파일 첨부 (Supabase Storage)
- 소셜 로그인
- 정산 양식 자동 생성
- 알림 (이메일 / 카카오톡)
- 결제 / 구독 (Phase 3)
- 슈퍼관리자 대시보드 (Phase 3)

---

## 10. 데이터 모델 상세 설계

### 10.1 ERD 개요
```
auth.users (Supabase)
   │ 1:1
   ▼
profiles ──────────────┐
   │ N:M               │ N:1
   ▼                   ▼
memberships ──► organizations
   │                   │ 1:N
   │                   ▼
   │              companies
   │                   │ 1:N
   │                   ▼
company_members    projects
                       │ 1:N
        ┌──────────────┼──────────────┐
        ▼              ▼              ▼
 funding_sources   budget_items    expenses
                       │ 1:N          │
                       └──────────────┘
                                      │ 1:N
                                      ▼
                              attachments (Phase 2)
```

### 10.2 테이블 스키마

#### 10.2.1 `profiles`
사용자 프로필 (auth.users 1:1 확장)

| 컬럼 | 타입 | 제약 | 설명 |
|------|------|------|------|
| id | uuid | PK, FK→auth.users.id | |
| email | text | not null | |
| full_name | text | | |
| phone | text | | |
| avatar_url | text | | |
| is_super_admin | boolean | default false | 서비스 운영자 플래그 |
| created_at | timestamptz | default now() | |
| updated_at | timestamptz | default now() | |

#### 10.2.2 `organizations`
조직(테넌트)

| 컬럼 | 타입 | 제약 | 설명 |
|------|------|------|------|
| id | uuid | PK | |
| name | text | not null | 조직명 |
| slug | text | unique | URL용 식별자 |
| business_number | text | | 대표 사업자번호(선택) |
| plan | text | default 'free' | free / pro / enterprise (Phase 3) |
| created_by | uuid | FK→profiles.id | |
| created_at | timestamptz | default now() | |
| updated_at | timestamptz | default now() | |

#### 10.2.3 `memberships`
사용자-조직 소속 및 역할

| 컬럼 | 타입 | 제약 | 설명 |
|------|------|------|------|
| id | uuid | PK | |
| organization_id | uuid | FK→organizations.id, not null | |
| user_id | uuid | FK→profiles.id, not null | |
| role | text | not null | 'org_admin' / 'company_member' / 'viewer' |
| status | text | default 'active' | active / invited / suspended |
| invited_email | text | | 초대 시 |
| invited_by | uuid | FK→profiles.id | |
| invited_at | timestamptz | | |
| joined_at | timestamptz | | |
| | | unique(organization_id, user_id) | |

#### 10.2.4 `companies`
회사(법인)

| 컬럼 | 타입 | 제약 | 설명 |
|------|------|------|------|
| id | uuid | PK | |
| organization_id | uuid | FK→organizations.id, not null | |
| name | text | not null | 회사명 (리피치/슈퍼런/팜큐) |
| business_number | text | | 사업자번호 |
| representative | text | | 대표자명 |
| address | text | | |
| memo | text | | |
| created_at | timestamptz | default now() | |
| updated_at | timestamptz | default now() | |

#### 10.2.5 `company_members`
회사 담당자 매핑 (company_member 역할 사용자에게 부여)

| 컬럼 | 타입 | 제약 | 설명 |
|------|------|------|------|
| id | uuid | PK | |
| company_id | uuid | FK→companies.id, not null | |
| user_id | uuid | FK→profiles.id, not null | |
| created_at | timestamptz | default now() | |
| | | unique(company_id, user_id) | |

#### 10.2.6 `projects`
사업

| 컬럼 | 타입 | 제약 | 설명 |
|------|------|------|------|
| id | uuid | PK | |
| company_id | uuid | FK→companies.id, not null | |
| organization_id | uuid | FK→organizations.id, not null | RLS 편의용 |
| name | text | not null | 사업명 |
| code | text | | 사업 코드 |
| host_agency | text | | 주관기관 |
| managing_agency | text | | 전담기관 |
| start_date | date | not null | |
| end_date | date | not null | |
| total_budget | numeric(15,0) | not null | 총 사업비 |
| selected_amount | numeric(15,0) | | 선정 금액 |
| status | text | default 'in_progress' | in_progress / completed / cancelled |
| memo | text | | |
| created_at | timestamptz | default now() | |
| updated_at | timestamptz | default now() | |

#### 10.2.7 `funding_sources`
사업별 재원 구성

| 컬럼 | 타입 | 제약 | 설명 |
|------|------|------|------|
| id | uuid | PK | |
| project_id | uuid | FK→projects.id, not null | |
| source_type | text | not null | 'gov_grant' / 'self_cash' / 'self_in_kind' |
| planned_amount | numeric(15,0) | not null | 계획 금액 |
| memo | text | | |
| | | unique(project_id, source_type) | |

#### 10.2.8 `budget_items`
비목

| 컬럼 | 타입 | 제약 | 설명 |
|------|------|------|------|
| id | uuid | PK | |
| project_id | uuid | FK→projects.id, not null | |
| organization_id | uuid | FK→organizations.id, not null | RLS 편의용 |
| name | text | not null | 비목명 (인건비/재료비/외주용역비 등) |
| code | text | | 비목 코드 |
| planned_amount | numeric(15,0) | not null | 계획 금액 |
| sort_order | int | default 0 | 표시 순서 |
| memo | text | | |
| created_at | timestamptz | default now() | |
| updated_at | timestamptz | default now() | |

#### 10.2.9 `expenses`
집행 내역

| 컬럼 | 타입 | 제약 | 설명 |
|------|------|------|------|
| id | uuid | PK | |
| project_id | uuid | FK→projects.id, not null | |
| budget_item_id | uuid | FK→budget_items.id, not null | |
| organization_id | uuid | FK→organizations.id, not null | RLS 편의용 |
| expense_date | date | not null | 집행일자 |
| amount | numeric(15,0) | not null | 금액 |
| source_type | text | not null | 'gov_grant' / 'self_cash' / 'self_in_kind' |
| vendor | text | | 거래처 |
| description | text | | 적요 |
| evidence_type | text | | 'tax_invoice' / 'receipt' / 'card' / 'transfer' / 'etc' |
| memo | text | | |
| created_by | uuid | FK→profiles.id | |
| created_at | timestamptz | default now() | |
| updated_at | timestamptz | default now() | |

#### 10.2.10 `attachments` (Phase 2)
증빙 첨부 파일

| 컬럼 | 타입 | 제약 | 설명 |
|------|------|------|------|
| id | uuid | PK | |
| expense_id | uuid | FK→expenses.id, not null | |
| file_path | text | not null | Supabase Storage 경로 |
| file_name | text | | |
| file_size | int | | |
| mime_type | text | | |
| uploaded_by | uuid | FK→profiles.id | |
| created_at | timestamptz | default now() | |

### 10.3 주요 인덱스
- `companies(organization_id)`
- `projects(company_id)`, `projects(organization_id, status)`
- `budget_items(project_id)`
- `expenses(project_id, expense_date desc)`
- `expenses(budget_item_id)`
- `expenses(organization_id, expense_date desc)`
- `memberships(user_id, organization_id)`
- `company_members(user_id)`

### 10.4 RLS 정책 (Supabase)

**전체 원칙**
- 모든 도메인 테이블에 `organization_id`를 두어 단순/빠른 정책 작성
- 헬퍼 함수로 권한 체크 캡슐화

**헬퍼 함수**
```sql
-- 현재 사용자가 슈퍼관리자인지
create function is_super_admin() returns boolean ...

-- 현재 사용자가 해당 조직의 멤버인지 + 역할 반환
create function current_role_in_org(org_id uuid) returns text ...

-- 현재 사용자가 해당 회사에 접근 권한이 있는지
-- (org_admin 이면 무조건 true, company_member 이면 company_members에 매핑이 있어야 true)
create function can_access_company(company_id uuid) returns boolean ...
```

**정책 패턴 (대표 예시)**

| 테이블 | SELECT | INSERT/UPDATE/DELETE |
|--------|--------|----------------------|
| organizations | 멤버이거나 super_admin | org_admin 또는 super_admin |
| memberships | 같은 조직 멤버 | org_admin (자기 자신 제외 또는 본인 nameOnly) |
| companies | 같은 조직 멤버 중 can_access_company | org_admin |
| projects | can_access_company(company_id) | org_admin |
| budget_items | projects 접근권한 상속 | org_admin |
| expenses | projects 접근권한 상속 | 본인이 작성 권한 있는 회사 멤버 + org_admin |
| attachments | expenses 접근권한 상속 | 작성자 또는 org_admin |

**비기능: storage 정책**
- 버킷 경로 규칙: `org_{organization_id}/project_{project_id}/expense_{expense_id}/{filename}`
- Storage 정책도 위 헬퍼 함수로 조직 격리

### 10.5 시드 데이터 (자사 초기 세팅)
- organization: 안티그래비티
- companies: 리피치, 슈퍼런, 팜큐
- 비목 템플릿: 인건비, 재료비/외주용역비, 연구활동비, 연구장비비, 간접비 등 (정부지원 사업 통상 비목)

---

## 11. 화면 흐름 / 정보 구조(IA)

### 11.1 전체 사이트맵
```
[Public]
 ├─ /                     랜딩 (제품 소개, Phase 3에 본격)
 ├─ /login                로그인
 ├─ /signup               회원가입
 ├─ /forgot-password      비밀번호 재설정
 └─ /invitations/[token]  초대 수락

[App — 인증 필요, 조직 컨텍스트]
 /app
  ├─ /                                대시보드 (조직 전체 요약)
  ├─ /companies                       회사 목록
  ├─ /companies/[companyId]           회사 상세 + 사업 목록
  ├─ /projects/[projectId]
  │   ├─ (Overview)                   사업 대시보드 (탭)
  │   ├─ /budget                      비목 관리 (탭)
  │   ├─ /expenses                    집행 내역 (탭)
  │   └─ /settings                    사업 설정 (탭)
  ├─ /expenses                        전 사업 집행 내역 (필터 검색)
  ├─ /reports                         리포트/엑셀 내보내기
  ├─ /members                         멤버 관리 (초대/역할)
  ├─ /settings                        조직 설정
  └─ /account                         내 계정/프로필

[Super Admin — Phase 3]
 /admin
  ├─ /organizations
  ├─ /users
  └─ /metrics
```

### 11.2 핵심 사용자 흐름

**① 신규 가입 → 조직 생성 (조직 관리자 본인 가입)**
```
회원가입 → 이메일 인증 → 로그인
  → "조직이 없습니다" 안내
  → 조직 생성 (이름/슬러그 입력)
  → 회사 등록 (리피치/슈퍼런/팜큐)
  → 첫 사업 등록
  → 비목 설정
  → 집행 내역 입력 시작
```

**② 멤버 초대 → 가입 (회사 담당자)**
```
[관리자] 멤버 페이지 → 이메일·역할(company_member)·소속 회사 지정 → 초대 발송
[초대받은 사람] 메일의 초대 링크 → 회원가입 or 로그인 → 초대 수락
  → 본인 소속 회사만 보이는 상태로 앱 진입
```

**③ 집행 등록 (회사 담당자 일상 업무)**
```
대시보드 → 사업 선택 → "집행 내역" 탭
  → [+ 집행 추가] 버튼
  → 모달: 일자/비목/금액/재원유형/거래처/적요/(증빙) 입력
  → 저장 → 사업 대시보드의 집행률 즉시 갱신
```

**④ 정산 보고 (월말/사업 종료)**
```
리포트 페이지 → 회사/사업/기간 선택
  → 미리보기 (비목별 집행 명세서)
  → 엑셀 다운로드
```

### 11.3 주요 화면 와이어프레임 (텍스트 스케치)

**조직 대시보드 (/app)**
```
┌─────────────────────────────────────────────────────┐
│ [조직 선택▼: 안티그래비티]   알림  내 계정          │
├─────────────────────────────────────────────────────┤
│ ▣ 진행중 사업  N건   ▣ 총 사업비 ₩00억             │
│ ▣ 집행 완료   ₩00억  ▣ 남은 예산 ₩00억 (00%)       │
├─────────────────────────────────────────────────────┤
│ [회사별 집행 현황]                                  │
│  ┌──────────┬──────────┬──────────┐                │
│  │ 리피치   │ 슈퍼런   │ 팜큐     │                │
│  │ 사업 N건 │ 사업 N건 │ 사업 N건 │                │
│  │ ████░ 70%│ ███░░ 55%│ ██░░░ 40%│                │
│  └──────────┴──────────┴──────────┘                │
├─────────────────────────────────────────────────────┤
│ [임박 사업 (D-30 이내)]                             │
│ • [팜큐] 스마트팜 실증사업    D-12   집행률 68%     │
│ • [리피치] AI 콘텐츠 R&D      D-25   집행률 82%     │
└─────────────────────────────────────────────────────┘
```

**사업 대시보드 (/app/projects/[id])**
```
┌─────────────────────────────────────────────────────┐
│ [팜큐 > 스마트팜 실증사업]            상태: 진행중  │
│ 2025-03-01 ~ 2026-02-28   D-285                     │
├──[Overview]──[비목]──[집행]──[설정]─────────────────┤
│                                                     │
│ ▣ 총 사업비 5억   ▣ 집행 2.4억  ▣ 잔여 2.6억 (52%) │
│                                                     │
│ [재원별]                                            │
│  정부지원금  ████████░░  3.5억 / 5억  70%           │
│  자기부담현금 ████░░░░░░  0.6억 / 1.0억 60%         │
│  자기부담현물 ██░░░░░░░░  0.3억 / 1.0억 30%         │
│                                                     │
│ [비목별 집행률]                                     │
│  인건비       ████████░░  80%                      │
│  재료비       █████░░░░░  50%                      │
│  외주용역비   ███░░░░░░░  30%                      │
│  ...                                                │
│                                                     │
│ [월별 집행 추이]   (라인 차트)                     │
└─────────────────────────────────────────────────────┘
```

**집행 내역 (/app/projects/[id]/expenses)**
```
┌─────────────────────────────────────────────────────┐
│ 필터: [기간] [비목▼] [재원▼] [검색...]  [+ 추가]   │
├─────────────────────────────────────────────────────┤
│ 일자       비목       거래처   재원   금액    증빙 │
│ 2025-05-12 인건비     -        지원금 ₩1,500,000 ✔ │
│ 2025-05-10 재료비     OO상사   현금   ₩  320,000 ✔ │
│ ...                                                 │
├─────────────────────────────────────────────────────┤
│ 합계: ₩00,000,000   페이지 1/N   [엑셀 내보내기]   │
└─────────────────────────────────────────────────────┘
```

**멤버 관리 (/app/members)**
```
┌─────────────────────────────────────────────────────┐
│ 멤버 (5)                              [+ 멤버 초대] │
├─────────────────────────────────────────────────────┤
│ 이름        이메일           역할         회사      │
│ 이석진      raymond@...      조직 관리자   전체     │
│ 홍길동      hong@...         회사 담당자   리피치   │
│ 김철수      kim@...          회사 담당자   슈퍼런   │
│ (초대중)    invite@...       회사 담당자   팜큐     │
└─────────────────────────────────────────────────────┘
```

### 11.4 네비게이션 / 레이아웃

- **좌측 사이드바**: 대시보드 / 회사 / 집행 내역 / 리포트 / 멤버 / 설정
- **상단 헤더**: 조직 선택 드롭다운(다중 조직 소속 시) / 검색(차후) / 알림 / 프로필
- **반응형**: 모바일에서 사이드바는 햄버거, 표는 가로 스크롤 또는 카드 변환

### 11.5 권한별 화면 노출 차이

| 화면 | super_admin | org_admin | company_member | viewer |
|------|:-:|:-:|:-:|:-:|
| 조직 대시보드 | ◯ | ◯ | △ (본인 회사만 집계) | ◯(읽기) |
| 회사 목록 | ◯ | ◯ | △ (본인 회사만) | ◯(읽기) |
| 사업/비목/집행 CRUD | ◯ | ◯ | △ (본인 회사만, CRUD) | × |
| 멤버 관리 | ◯ | ◯ | × | × |
| 조직 설정 | ◯ | ◯ | × | × |
| 슈퍼관리자 패널 | ◯ | × | × | × |

---

## 12. 협의 필요 사항 (TBD)
- [ ] 디자인 시안 / 디자인 시스템 (shadcn 기본 vs 커스텀)
- [ ] 증빙 파일 첨부 MVP 포함 여부 재검토
- [ ] 정부지원 사업 주관기관별 정산 양식 표준화 범위
- [ ] 도메인 / 서비스명
- [ ] 요금제 정책 (Phase 3, 조직당/사용자당/사업 수 기준 등)
- [ ] 회사 담당자가 여러 회사 담당 가능한가 (현재 설계는 N:M 지원)
- [ ] 비목 템플릿 사전 정의 범위 (정부지원 사업 표준 비목)
