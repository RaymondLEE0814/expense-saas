# 환경 변수 (Environment Variables)

> 작성자: 아키텍쳐설계 | 일자: 2026-05-19
> 실제 파일: `SRC/.env.local` (gitignore), 템플릿: `SRC/.env.example`

---

## 1. 필수 환경 변수

| 키 | 클라이언트 노출 | 설명 | 예시 |
|----|---------------|------|------|
| `NEXT_PUBLIC_SUPABASE_URL` | ✔ | Supabase 프로젝트 URL | `https://xxxx.supabase.co` |
| `NEXT_PUBLIC_SUPABASE_ANON_KEY` | ✔ | Supabase anon 공개 키 | `eyJ...` |
| `SUPABASE_SERVICE_ROLE_KEY` | ❌ | service_role 키 — 서버 전용 | `eyJ...` |
| `NEXT_PUBLIC_APP_URL` | ✔ | 배포 URL (초대 링크 생성용) | `https://app.example.com` |

## 2. 선택 환경 변수

| 키 | 설명 | 기본값 |
|----|------|--------|
| `INVITATION_EXPIRY_DAYS` | 초대 만료(일) | `7` |
| `RESEND_API_KEY` | (Phase 2) Resend 이메일 API 키 | - |
| `NEXT_PUBLIC_SENTRY_DSN` | (Phase 2) 에러 추적 | - |

## 3. `.env.example` 템플릿 (`SRC/.env.example`)

```bash
# Supabase
NEXT_PUBLIC_SUPABASE_URL=https://your-project.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=your-anon-key
SUPABASE_SERVICE_ROLE_KEY=your-service-role-key  # 서버 전용, 절대 클라이언트로 노출 금지

# App
NEXT_PUBLIC_APP_URL=http://localhost:3000

# Invitations
INVITATION_EXPIRY_DAYS=7

# Phase 2
# RESEND_API_KEY=
# NEXT_PUBLIC_SENTRY_DSN=
```

## 4. 보안 규칙
- `SUPABASE_SERVICE_ROLE_KEY` 는 Vercel/배포 환경 변수에 secret 으로만 저장
- `NEXT_PUBLIC_` 접두사 변수는 빌드 시 클라이언트 번들에 포함됨 — 민감 정보 금지
- `.env.local` 은 절대 커밋 금지 (`.gitignore`에 포함)
- 운영/스테이징/로컬 키 분리

## 5. Supabase 프로젝트 설정 (관리자 작업)

1. **프로젝트 생성**: https://supabase.com/dashboard
   - 이름: `expense-saas-prod` (또는 dev)
   - Region: `ap-northeast-2` (Seoul) 권장
2. **Auth 설정**:
   - Settings → Authentication → Email: enable
   - Email Templates: 한국어 커스터마이즈 (Phase 1.5)
   - Site URL: `NEXT_PUBLIC_APP_URL`
   - Redirect URLs: `<app_url>/auth/callback`, `<app_url>/reset-password`, `<app_url>/invitations/accept`
3. **DB 마이그레이션**:
   - SQL Editor에서 [db-schema.sql](db-schema.sql) → [rls-policies.sql](rls-policies.sql) → [seed.sql](seed.sql) 순으로 실행
4. **Storage**:
   - (Phase 2) Bucket `evidence` 생성, public=false
5. **타입 생성**:
   ```bash
   pnpm dlx supabase gen types typescript --project-id <id> > SRC/types/database.ts
   ```
