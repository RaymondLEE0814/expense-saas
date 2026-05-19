# Gate Review — P0-08 기획 검수

> 검수자: PM | 일자: 2026-05-19 | 결과: **✅ 통과 (Pass with notes)**

---

## 1. 검수 대상

| 산출물 | 경로 | 상태 |
|--------|------|------|
| PRD | [PRD.md](../01-planning/PRD.md) | ✅ |
| 페르소나 | [personas.md](../01-planning/personas.md) | ✅ |
| 사용자 스토리 + 인수 기준 | [user-stories.md](../01-planning/user-stories.md) | ✅ |
| 기능 명세 | [features.md](../01-planning/features.md) | ✅ |
| 용어집 | [glossary.md](../01-planning/glossary.md) | ✅ |

---

## 2. 게이트 체크리스트 ([WORKFLOW.md §4.1](../../.agents/WORKFLOW.md))

- [x] PRD에 범위(In/Out) 명시 → [PRD §5](../01-planning/PRD.md#5-제품-범위-scope)
- [x] 모든 기능에 인수 기준 존재 → user-stories.md의 27개 스토리 모두 Given/When/Then 포함
- [x] 모든 역할의 권한 명시 → user-stories.md §매트릭스, features.md F-021
- [x] 비기능 요구사항(보안/성능/접근성) 포함 → PRD §8 (NFR)
- [x] 도메인 용어 glossary.md 등록 → 7개 카테고리, 50+ 용어

## 3. 정합성 점검

| 점검 항목 | 결과 |
|----------|------|
| PRD MoSCoW vs 기능 명세 ID 매핑 | ✅ M-01~13 ↔ F-001~023 매핑 일관 |
| 사용자 스토리 ↔ 기능 매핑 | ✅ features.md "관련 스토리" 컬럼으로 추적 |
| 용어 일관성 (사업/비목/재원) | ✅ 모든 문서가 glossary 표준어 사용 |
| 권한 매트릭스 일관성 | ✅ PRD / user-stories / features 동일 4단계 |

## 4. 발견 사항 (Notes)

> 통과를 막을 결함은 없으나 다음 단계에서 보완 권장:

1. **다국적 결제·VAT 처리**: MVP 범위 외이나 Phase 3 사양에 명시 필요 (지금은 'won't have')
2. **변경 이력**: 사업/비목 변경 이력 UI는 Phase 2로 정의되어 있음 → DB 스키마에서 audit 컬럼은 MVP에 포함하는 게 좋음 (아키텍쳐에 전달)
3. **이메일 발송 인프라**: 초대·비번재설정 메일은 Supabase 기본 SMTP 사용으로 일단 진행. 대량 발송은 Phase 2 (Resend 등)

## 5. 다음 단계 지시

P0-08 통과에 따라 **P0-09 ~ P0-17** 병렬 착수:

### 5.1 디자이너 트랙
- P0-09 디자인 시스템 정의 → `docs/02-design/design-system.md`
- P0-10 화면 명세서 전 화면 → `docs/02-design/screens/`
- 입력: PRD, user-stories, features, [design_apple.md](../../.agents/skills/design_apple.md) **(1순위 준수)**

### 5.2 아키텍쳐 트랙
- P0-11 ~ P0-17 (DB 스키마, RLS, 시드, API, FE 아키텍쳐, 인증 흐름, 환경)
- 입력: PRD, user-stories, features, glossary, [worklist.md §10](../../worklist.md)
- 보완 사항(§4-2): 모든 도메인 테이블에 `created_by`, `updated_by` 컬럼 포함 권장

## 6. 의사결정 (ADR 추가)

- **ADR-005**: MVP에서도 도메인 테이블에 `created_by`/`updated_by` 감사 컬럼 포함 (변경 이력 UI는 Phase 2지만 데이터는 확보)
