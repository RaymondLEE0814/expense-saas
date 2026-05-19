# 배포 절차

> 작성자: 아키텍쳐설계 | 일자: 2026-05-19
> 대상 환경: Vercel + Supabase

---

## 1. 환경 분리

| 환경 | Supabase 프로젝트 | Vercel 배포 | URL |
|------|------------------|------------|------|
| local | dev 인스턴스 또는 supabase local | `pnpm dev` | http://localhost:3000 |
| staging | `expense-saas-dev` | Vercel Preview | `staging.<domain>` |
| production | `expense-saas-prod` | Vercel Production | `app.<domain>` |

각 환경마다 별도 환경 변수 셋.

---

## 2. 사전 준비

1. **GitHub 저장소**: `SRC/` 또는 모노레포 형태로 푸시
2. **Vercel 프로젝트**: 저장소 연결, Framework=Next.js
3. **Supabase 프로젝트**: 환경별 1개씩

---

## 3. Supabase 마이그레이션

### 3.1 SQL 직접 실행 (MVP)
1. Supabase Dashboard → SQL Editor
2. 순서대로 실행:
   - [db-schema.sql](db-schema.sql)
   - [rls-policies.sql](rls-policies.sql)
   - [seed.sql](seed.sql) (개발/스테이징에서만)
3. 결과 확인: Tables → 각 테이블 RLS enabled 확인

### 3.2 Supabase CLI (권장, Phase 2+)
- `supabase/migrations/` 에 timestamped SQL 파일 보관
- `supabase db push` 로 적용
- 깃에 마이그레이션 이력 보관

### 3.3 타입 생성
```bash
pnpm dlx supabase gen types typescript \
  --project-id <project-id> \
  > SRC/types/database.ts

# CI에서 db-schema 변경 시 자동 실행
```

---

## 4. Vercel 배포

### 4.1 환경 변수 설정
Vercel Dashboard → Project → Settings → Environment Variables:
- `NEXT_PUBLIC_SUPABASE_URL` (Production/Preview/Dev 모두)
- `NEXT_PUBLIC_SUPABASE_ANON_KEY`
- `SUPABASE_SERVICE_ROLE_KEY` (Secret 표시)
- `NEXT_PUBLIC_APP_URL` (환경별 다름)

### 4.2 빌드 설정
- Framework Preset: Next.js
- Build Command: `pnpm build`
- Output: `.next`
- Install Command: `pnpm install --frozen-lockfile`
- Node: 20.x

### 4.3 Preview 배포 = PR 단위
- 각 PR → 고유 URL 생성 → 검토용
- main 브랜치 머지 → Production 자동 배포

---

## 5. 도메인 / SSL

1. Vercel → Domains에 커스텀 도메인 추가
2. DNS A/CNAME 레코드 설정
3. SSL은 Vercel 자동
4. `NEXT_PUBLIC_APP_URL` 갱신
5. Supabase Auth Redirect URL 화이트리스트 갱신

---

## 6. 모니터링 (Phase 2)
- Vercel Analytics (기본)
- Sentry (에러 추적)
- Supabase Dashboard (DB 사용량, slow query)

---

## 7. 배포 체크리스트

### 7.1 최초 운영 배포 전
- [ ] DB 마이그레이션 적용
- [ ] 모든 RLS 정책 활성화 확인 (Tables → RLS 컬럼)
- [ ] 환경 변수 3종 + APP_URL 설정
- [ ] Supabase Auth Redirect URL 등록
- [ ] 도메인 SSL 적용
- [ ] 디코더 P0/P1 0건 확인
- [ ] 시드 데이터는 운영에 적용하지 않음 (수동 가입)

### 7.2 일반 배포
- [ ] PR Green (lint/test/build)
- [ ] Preview URL에서 핵심 흐름 동작 확인
- [ ] DB 마이그레이션이 있다면 사전 적용
- [ ] main 머지 → Production 배포 자동

### 7.3 롤백
- Vercel: 이전 배포로 promote (1클릭)
- DB: 마이그레이션 down 스크립트는 작성하지 않음 — 운영 변경은 Forward only

---

## 8. 백업
- Supabase 일 자동 백업 (유료 플랜)
- 월 1회 수동 export (조직 단위 XLSX 또는 DB dump)
- 환경 변수 / 시크릿은 1Password 등에 별도 보관
