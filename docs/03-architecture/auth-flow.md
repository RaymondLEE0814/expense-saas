# 인증 / 권한 / 초대 흐름

> 작성자: 아키텍쳐설계 | 일자: 2026-05-19

---

## 1. 인증 모델

- **인증 제공자**: Supabase Auth (Email + Password)
- **세션 저장**: HTTP-Only Secure Cookie (Supabase SSR)
- **세션 갱신**: Next.js 미들웨어에서 매 요청 시도 (`updateSession`)
- **JWT 클레임**: 기본 `aud`, `exp`, `sub` (auth.uid). 커스텀 클레임 없음 — 권한은 DB에서 조회

---

## 2. 회원가입 흐름

```
[/signup]
   │
   │ supabase.auth.signUp({ email, password, options: { emailRedirectTo: /verify-email/callback }})
   ▼
[auth.users INSERT]
   │
   │ (트리거 on_auth_user_created)
   ▼
[public.profiles INSERT]
   │
   ▼
[Supabase가 인증 메일 발송]
   │
   │ 사용자가 메일 링크 클릭
   ▼
[/verify-email/callback?token=...]
   │
   │ supabase.auth.exchangeCodeForSession()
   ▼
[세션 발급 → /app/onboarding]
```

### 비기능
- 이메일 중복 → Supabase 409 → "이미 가입된 이메일" 안내
- 인증 메일 만료(24시간): 재전송 버튼 (60초 쿨다운)

---

## 3. 로그인 흐름

```
[/login]
  │ supabase.auth.signInWithPassword({email, password})
  ▼
[세션 쿠키 발급]
  │
  │ 미들웨어 → 멤버십 조회
  ▼
[memberships 활성 1개] → /app
[memberships 활성 N개] → /app (last_used_org_id 쿠키 우선)
[memberships 0개]    → /app/onboarding
```

### 에러
- 잘못된 자격 → 401 → "이메일 또는 비밀번호가 올바르지 않습니다"
- 이메일 미인증 → 안내 + 메일 재전송

---

## 4. 비밀번호 재설정

```
[/forgot-password]
   │ supabase.auth.resetPasswordForEmail(email, { redirectTo: /reset-password })
   ▼
[메일 발송 → 사용자 클릭]
   ▼
[/reset-password?token=...]
   │ supabase.auth.updateUser({ password: new })
   ▼
[성공 → /login]
```

---

## 5. 조직 생성 (온보딩)

```
[/app/onboarding]
   │ 이름/슬러그/사업자번호 입력
   │ createOrganization() Server Action
   │
   │  ┌──────────────────────────────────────────┐
   │  │  트랜잭션:                                │
   │  │  1) organizations INSERT (created_by=me) │
   │  │  2) memberships INSERT                   │
   │  │     (role='org_admin', status='active')  │
   │  └──────────────────────────────────────────┘
   ▼
[set cookie: last_used_org_id]
   ▼
[/app]
```

---

## 6. 멤버 초대 흐름

### 6.1 발송
```
[/app/members]  org_admin
   │ inviteMember({ email, role, company_ids? })
   │
   │  ┌──────────────────────────────────────────┐
   │  │  1) 이메일 형식 검증                       │
   │  │  2) 같은 조직 중복 검사                    │
   │  │  3) invite_token = crypto.randomBytes(32)│
   │  │  4) memberships INSERT                   │
   │  │     (status='invited', invited_email=...,│
   │  │      invite_token, expires=now()+7d)     │
   │  │  5) 초대 메일 발송:                       │
   │  │     https://app.../invitations/<token>   │
   │  └──────────────────────────────────────────┘
```

### 6.2 수락 (3가지 시나리오)

#### (A) 미가입자
```
사용자 → [/invitations/<token>]
   │ Server Component에서 토큰 검증
   ▼
[/signup?invitation=<token>] (이메일 prefill)
   │ 가입 완료 (signUp + emailRedirectTo: /invitations/accept?token=<token>)
   ▼
[이메일 인증]
   ▼
[/invitations/accept?token=<token>]
   │ acceptInvitation()
   │   - memberships UPDATE: status='active', user_id=auth.uid(), joined_at=now()
   │   - invite_token=null
   ▼
[/app]  (해당 조직 자동 선택)
```

#### (B) 가입+미로그인
```
사용자 → [/invitations/<token>]
   │
   ▼
[/login?invitation=<token>] (이메일 prefill)
   │ 로그인 성공 후
   ▼
[/invitations/accept?token=<token>]
   │ acceptInvitation()
   ▼
[/app]
```

#### (C) 로그인 상태
```
사용자 → [/invitations/<token>]
   │ "초대 수락" 확인 카드
   │ [수락] 버튼 → acceptInvitation()
   ▼
[/app]
```

### 6.3 검증 / 보안
- 토큰 길이 32바이트 (256비트), `pgcrypto` 또는 Node `crypto.randomBytes`
- 만료(7일): UPDATE 시 `invite_expires_at >= now()` 체크
- 이메일 매칭: `invited_email === auth.user.email` (case-insensitive)
- 토큰 1회 사용 후 무효화 (`invite_token=null`)

---

## 7. 세션 / 권한 컨텍스트

매 요청마다 다음 정보를 계산해 RSC에 주입:

```ts
type AuthContext = {
  user: User;                        // auth.users
  profile: Profile;
  organizations: Array<{ id, name, slug, role }>;  // 멤버십
  currentOrg: { id, name, slug } | null;
  currentRole: 'org_admin' | 'company_member' | 'viewer' | 'super_admin' | null;
  accessibleCompanyIds: string[] | 'all';  // company_member는 매핑 회사만, 그 외 'all'
};
```

### `lib/auth/context.ts` 의 `getCurrentContext()`
1. 미들웨어가 갱신한 세션 쿠키로 `getUser()`
2. profiles 조회
3. memberships 조회 (active)
4. cookie `last_used_org_id` 또는 첫 번째 멤버십을 현재 조직으로
5. 현재 조직의 role
6. company_members 매핑 조회

### `requireUser()` 가드
- RSC/Server Action 진입 시 호출
- 미로그인 → redirect('/login')

### `requireOrgAdmin(orgId)` 가드
- 미들웨어 또는 페이지에서 호출
- 조건 불충족 → redirect('/app') 또는 403

---

## 8. 권한 매트릭스 — 흐름별

| 작업 | 권한 체크 위치 | 정책 |
|------|--------------|------|
| /app 접근 | 미들웨어 | 로그인 + 활성 멤버십 |
| /app/members | 페이지 | currentRole === 'org_admin' |
| /app/projects/[id] | 페이지 | RLS가 차단 → 데이터 0이면 404 |
| 집행 CRUD | Server Action | RLS + 명시적 가드 (UX 친화 에러용) |
| /admin | 미들웨어 | profile.is_super_admin |

---

## 9. RLS와의 통합

- 모든 DB 접근은 anon/authenticated 키로만
- service_role 키는 서버 사이드 어드민 작업(메일 발송 등)에만 사용, 클라이언트 노출 금지
- 정책은 `auth.uid()` 와 `memberships`/`company_members` 매핑을 기준으로 동작

> 자세한 정책은 [rls-policies.sql](rls-policies.sql) 참조.

---

## 10. 보안 체크리스트

- [ ] 모든 도메인 테이블 RLS 활성화
- [ ] anon 키로 service_role 작업 불가 (정책 부재 = 차단)
- [ ] 초대 토큰: 32B 랜덤, 7일 만료, 1회 사용
- [ ] 비밀번호 재설정 토큰: Supabase 기본 (1시간)
- [ ] CSRF: Server Action은 same-origin POST만, 별도 토큰 불필요
- [ ] XSS: React 기본 이스케이프 + dangerouslySetInnerHTML 금지
- [ ] 이메일 매칭 시 case-insensitive
- [ ] super_admin 동작 시 audit log (Phase 3)

---

## 11. 로그아웃

- `supabase.auth.signOut()` → 쿠키 삭제 → `/login`
- "모든 다른 기기에서 로그아웃" (선택): admin API 로 사용자의 모든 세션 무효화

---

## 12. 다중 조직 전환

```
[조직 선택 드롭다운]
   │ setLastOrg(orgId) Server Action
   │   - cookie set 'last_used_org_id'=orgId
   ▼
[router.refresh() → 모든 데이터 재페치]
```
