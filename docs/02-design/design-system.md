# Design System

> 작성자: 디자이너 | 일자: 2026-05-19 | 버전: v1.0
> 상위 가이드: [`.agents/skills/design_apple.md`](../../.agents/skills/design_apple.md) — Apple HIG 기반, 본 문서가 충돌 시 design_apple.md 우선.
> 대상: corder가 Tailwind 토큰·shadcn/ui 변형으로 그대로 구현 가능한 수준.

---

## 1. 토큰 매핑 — Tailwind config

`SRC/tailwind.config.ts` 에 다음 토큰을 등록한다.

```ts
export default {
  theme: {
    extend: {
      colors: {
        // 기본
        bg: {
          DEFAULT: '#FFFFFF',
          secondary: '#F5F5F7',
          tertiary: '#FAFAFA',
          inverse: '#1D1D1F',
        },
        fg: {
          DEFAULT: '#1D1D1F',
          secondary: '#6E6E73',
          tertiary: '#86868B',
          inverse: '#FFFFFF',
          link: '#0071E3',
        },
        accent: {
          DEFAULT: '#0071E3',  // Apple Blue
          hover: '#0077ED',
          active: '#006EDB',
        },
        divider: '#D2D2D7',
        // 시맨틱
        success: '#34C759',
        warning: '#FF9F0A',
        danger:  '#FF3B30',
        // 도메인 — 재원
        funding: {
          gov:     '#0071E3',   // 정부지원금
          cash:    '#34C759',   // 자기부담현금
          inkind:  '#FF9F0A',   // 자기부담현물
        },
      },
      fontFamily: {
        sans: ['Pretendard', 'SF Pro Text', '-apple-system', 'BlinkMacSystemFont', 'system-ui', 'sans-serif'],
        display: ['SF Pro Display', 'Pretendard', 'sans-serif'],
        mono: ['SF Mono', 'Menlo', 'Consolas', 'monospace'],
      },
      fontSize: {
        // 랜딩
        'hero':     ['80px', { lineHeight: '1.05', letterSpacing: '-0.02em', fontWeight: '600' }],
        'display':  ['56px', { lineHeight: '1.1',  letterSpacing: '-0.02em', fontWeight: '600' }],
        // 앱 헤딩
        'title-1':  ['32px', { lineHeight: '1.15', letterSpacing: '-0.01em', fontWeight: '600' }],
        'title-2':  ['24px', { lineHeight: '1.2',  fontWeight: '600' }],
        'title-3':  ['20px', { lineHeight: '1.25', fontWeight: '600' }],
        // 본문
        'body':     ['14px', { lineHeight: '1.5', fontWeight: '400' }],
        'body-lg':  ['17px', { lineHeight: '1.5', fontWeight: '400' }],
        'caption':  ['12px', { lineHeight: '1.4', fontWeight: '400' }],
      },
      spacing: {
        // 4px 베이스 — 기본 Tailwind 스케일 사용 + 큰 단위만 추가
        '18': '72px',
        '22': '88px',
        '30': '120px',
      },
      borderRadius: {
        sm:    '6px',
        DEFAULT: '12px',
        lg:    '18px',
        xl:    '24px',
        pill:  '980px',
      },
      boxShadow: {
        sm: '0 1px 2px rgba(0,0,0,0.04)',
        DEFAULT: '0 4px 16px rgba(0,0,0,0.06)',
        lg: '0 8px 30px rgba(0,0,0,0.08)',
        xl: '0 20px 60px rgba(0,0,0,0.10)',
      },
      transitionTimingFunction: {
        apple: 'cubic-bezier(0.25, 0.1, 0.25, 1)',
      },
    },
  },
};
```

---

## 2. CSS Variables (globals.css)

shadcn/ui의 cva 변형이 활용 가능하도록 CSS 변수도 노출:

```css
:root {
  --color-bg: #FFFFFF;
  --color-bg-secondary: #F5F5F7;
  --color-fg: #1D1D1F;
  --color-fg-secondary: #6E6E73;
  --color-accent: #0071E3;
  --color-divider: #D2D2D7;
  --radius: 12px;
}
```

> 다크모드는 Phase 2에서 `[data-theme="dark"]` 셀렉터로 추가. MVP는 라이트만.

---

## 3. 컴포넌트 변형 (shadcn/ui 기반)

### 3.1 Button
| variant | 배경 | 텍스트 | 라운드 |
|---------|------|--------|--------|
| `primary` | `accent` | `fg-inverse` | `pill` |
| `secondary` | transparent | `accent` | `pill` |
| `tertiary` | `bg-secondary` | `fg` | `pill` |
| `ghost` | transparent | `fg` | `pill` |
| `danger` | `danger` | `fg-inverse` | `pill` |

| size | height | px | font |
|------|--------|----|------|
| sm | 32px | 16 | 13px |
| md | 40px | 20 | 14px (앱) / 15px (랜딩) |
| lg | 48px | 28 | 17px |

상태: hover에 미세 `translateY(-1px)` + shadow 증가 / active scale(0.98) / disabled opacity 0.4 / focus ring `accent 50%`.

### 3.2 Input
- height: 40px / 48px
- border: 1px solid `divider` → focus: 2px `accent`
- radius: `12px`
- padding: 0 12px
- placeholder: `fg-tertiary`
- error 상태: border `danger`, helper text `danger`

### 3.3 Card
- 배경 `bg`, 보더 없음(또는 `divider` 1px), radius `lg`(18px)
- padding `p-6` (24px) / 큰 카드 `p-8` (32px)
- shadow: 보통 없음 → hover 시 shadow `DEFAULT`

### 3.4 Badge
- 작은 라벨용 — radius `sm`, height 20~22px
- variant: neutral / success / warning / danger / funding-gov / funding-cash / funding-inkind

### 3.5 Table
- border 없는 깔끔 스타일
- 행 구분: 1px `divider` (또는 even row만 `bg-secondary`)
- header: `bg-secondary`, font weight 500, `fg-secondary`
- 행 hover: `bg-secondary`
- 금액 셀: `font-variant-numeric: tabular-nums`, 우측 정렬

### 3.6 Modal / Sheet
- backdrop: `rgba(0,0,0,0.4)` + backdrop-blur(8px)
- 모달: 중앙, 최대 너비 480px(작음)/640px(폼)/800px(상세)
- 시트: 우측에서 슬라이드, 너비 480~600px

### 3.7 Toast
- 우측 하단 (데스크톱) / 상단 (모바일)
- 라운드 `lg`, 그림자 `lg`, 자동 닫힘 4초

---

## 4. 레이아웃

### 4.1 App Shell
```
┌────────┬────────────────────────────────────────────┐
│        │  Header (h-14) — 조직선택 / 알림 / 프로필   │
│ Side-  ├────────────────────────────────────────────┤
│ bar    │                                            │
│ (w-60) │   Content (max-w-7xl, p-6 ~ p-8)           │
│        │                                            │
└────────┴────────────────────────────────────────────┘
```
- 사이드바: `w-60` (240px), 배경 `bg-secondary`, 보더 없음
- 헤더: `h-14`, 흰 배경, 하단 1px `divider`
- 콘텐츠: `max-w-screen-2xl` (1536px), `p-6` ~ `p-8`

### 4.2 Auth Shell
- 중앙 정렬, 카드 너비 `max-w-md` (448px)
- 배경 `bg-secondary`, 카드 흰색

### 4.3 Landing (랜딩 / 마케팅 — Phase 3 본격)
- 컨테이너 `max-w-[980px]`, 좌우 px 22/40/64
- 섹션 간격 `py-30` (120px, 모바일 `py-20`)

---

## 5. 사이드바 메뉴

```
┌──────────────────────────┐
│  [로고]  (주)슈퍼런 ▾    │  ← 조직 선택 (헤더로 이동도 가능)
├──────────────────────────┤
│  ⌂  대시보드             │
│  🏢 회사                 │
│  💸 집행 내역             │
│  📊 리포트               │
│  ─────                   │
│  👥 멤버                 │
│  ⚙  설정                 │
├──────────────────────────┤
│  👤 [이름]               │  ← 프로필 (하단 고정)
└──────────────────────────┘
```

- 활성 항목: 배경 흰색 + 좌측 2px `accent`, 텍스트 `fg`
- 비활성: 텍스트 `fg-secondary`
- 호버: 배경 `bg-tertiary`

---

## 6. 상태(State) 표준

### 6.1 빈 상태 (Empty State)
- 중앙 정렬, 회색 아이콘(48px), 한 줄 안내, 1차 CTA 버튼
- 예: "아직 등록된 회사가 없습니다 / + 회사 추가"

### 6.2 로딩
- 페이지: 스켈레톤 카드/행
- 인라인: 회색 펄스 박스
- 버튼: 좌측 스피너 + 라벨 유지

### 6.3 에러
- 인라인: 필드 아래 `danger` 텍스트 + 아이콘
- 토스트: "저장에 실패했습니다 — 다시 시도" + 재시도 버튼
- 풀페이지: 일러스트(없으면 큰 아이콘) + 메시지 + 메인으로 가기 버튼

### 6.4 권한 없음
- 풀페이지 403: 자물쇠 아이콘 + "이 페이지에 접근할 권한이 없습니다" + 메인으로

---

## 7. 마이크로 인터랙션

- 페이지 진입: opacity 0→1 + translateY 8px→0, 200ms `apple`
- 카드 hover: shadow 0→DEFAULT, 200ms
- 버튼 hover: translateY -1px + shadow, 150ms
- 모달 진입: scale 0.96→1, fade in, 200ms
- 사이드바 메뉴 hover: 배경 fade 100ms

---

## 8. 금지 사항 재확인 ([design_apple §11](../../.agents/skills/design_apple.md))
- ❌ 1px 이상 진한 보더
- ❌ 강한 그림자
- ❌ 컬러 4종 이상 동시 사용
- ❌ 폰트 패밀리 2종 이상
- ❌ 순흑(`#000`)·순백 직접 대비
- ❌ 직각 코너 (어떤 컴포넌트라도 살짝 라운드)
- ❌ 과도한 애니메이션

---

## 9. corder 인계 체크리스트

- [x] Tailwind config 토큰 정의
- [x] 컴포넌트 변형 정의 (Button/Input/Card/Badge/Table/Modal/Toast)
- [x] App Shell / Auth Shell 레이아웃 정의
- [x] 사이드바 메뉴 구조
- [x] 4상태(데이터/빈/로딩/에러) 패턴
- [x] 인터랙션 가이드
