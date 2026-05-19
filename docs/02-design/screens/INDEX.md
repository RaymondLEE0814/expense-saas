# 화면 명세서 인덱스

> 작성자: 디자이너 | 일자: 2026-05-19
> 화면 ID는 절대 키 — 디자인·구현·QA가 이 ID로 연결됨.

---

## 1. 화면 목록

| ID | 화면명 | 경로 | 파일 | US |
|----|--------|------|------|------|
| S-AUTH-001 | 로그인 | `/login` | [auth.md](auth.md) | US-AU-02 |
| S-AUTH-002 | 회원가입 | `/signup` | [auth.md](auth.md) | US-AU-01 |
| S-AUTH-003 | 비밀번호 재설정 | `/forgot-password` | [auth.md](auth.md) | US-AU-03 |
| S-AUTH-004 | 새 비밀번호 입력 | `/reset-password` | [auth.md](auth.md) | US-AU-03 |
| S-AUTH-005 | 이메일 인증 안내 | `/verify-email` | [auth.md](auth.md) | US-AU-01 |
| S-AUTH-INVITE | 초대 수락 | `/invitations/[token]` | [auth.md](auth.md) | US-ME-02 |
| S-ORG-NEW | 조직 생성 온보딩 | `/app/onboarding` | [org.md](org.md) | US-OR-01 |
| S-ORG-001 | 조직 대시보드 | `/app` | [org.md](org.md) | US-DA-01 |
| S-COM-001 | 회사 목록 | `/app/companies` | [companies.md](companies.md) | US-CO-01 |
| S-COM-002 | 회사 상세 + 사업 목록 | `/app/companies/[id]` | [companies.md](companies.md) | US-CO-02, US-PR-01 |
| S-PRJ-NEW | 사업 등록 모달 | `(modal)` | [projects.md](projects.md) | US-PR-01 |
| S-PRJ-001 | 사업 대시보드 (Overview 탭) | `/app/projects/[id]` | [projects.md](projects.md) | US-DA-02 |
| S-PRJ-002 | 집행 내역 탭 | `/app/projects/[id]/expenses` | [projects.md](projects.md) | US-EX-01~04 |
| S-PRJ-003 | 비목 관리 탭 | `/app/projects/[id]/budget` | [projects.md](projects.md) | US-BU-01~03 |
| S-PRJ-004 | 사업 설정 탭 | `/app/projects/[id]/settings` | [projects.md](projects.md) | US-PR-02, US-PR-03 |
| S-MEM-001 | 멤버 관리 | `/app/members` | [members.md](members.md) | US-ME-01~04 |
| S-RPT-001 | 리포트 / 엑셀 | `/app/reports` | [reports.md](reports.md) | US-RP-01 |
| S-SET-001 | 조직 설정 | `/app/settings` | [settings.md](settings.md) | US-SE-02 |
| S-ACC-001 | 내 계정 | `/app/account` | [settings.md](settings.md) | US-SE-01 |

## 2. 화면 ID 명명 규칙

`S-{도메인}-{번호}`:
- AUTH: 인증/온보딩
- ORG: 조직
- COM: 회사
- PRJ: 사업
- MEM: 멤버
- RPT: 리포트
- SET: 설정
- ACC: 계정

## 3. 공통 사항 (모든 화면)
- 4상태 모두 정의: 데이터 있음 / 빈 / 로딩(스켈레톤) / 에러
- 권한 없음 시 403 풀페이지
- 모바일 반응형 — 테이블은 카드 또는 가로 스크롤
- 디자인 토큰 외 색상·간격 사용 금지 ([design-system.md](../design-system.md))
- 인터랙션 가이드 ([design_apple.md §7](../../.agents/skills/design_apple.md))
