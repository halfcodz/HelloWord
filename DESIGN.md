---
name: HelloWord
description: 자매가 함께 쓰는 영어 단어 시험 앱 — 담백한 학습 도구에 둘만 아는 온기를 더한 디자인
colors:
  quiz-blue: "#2563EB"
  quiz-blue-soft: "#DBEAFE"
  quiz-blue-deep: "#1D4ED8"
  study-purple: "#7C3AED"
  study-purple-soft: "#EDE9FE"
  achievement-gold: "#F59E0B"
  achievement-gold-soft: "#FEF3C7"
  ink-navy: "#0F172A"
  ink-navy-soft: "#1E293B"
  surface: "#FFFFFF"
  surface-muted: "#F1F5FD"
  surface-field: "#EFF4FF"
  page-top: "#F7FAFF"
  page-bottom: "#EFF6FF"
  border: "#E4ECFC"
  text-secondary: "#475569"
  text-tertiary: "#64748B"
  text-hint: "#94A3B8"
  correct-green: "#16A34A"
  correct-green-soft: "#DCFCE7"
  wrong-red: "#DC2626"
  wrong-red-soft: "#FEE2E2"
  dark-page: "#0B1220"
  dark-surface: "#151E32"
  dark-border: "#26324F"
  dark-ink: "#E8EDF7"
  dark-primary: "#60A5FA"
  dark-correct: "#4ADE80"
  dark-wrong: "#F87171"
typography:
  display:
    fontFamily: "Fredoka, Noto Sans KR, Apple SD Gothic Neo, sans-serif"
    fontSize: "26sp"
    fontWeight: 600
    lineHeight: 1.2
  headline:
    fontFamily: "Fredoka, Noto Sans KR, Apple SD Gothic Neo, sans-serif"
    fontSize: "20sp"
    fontWeight: 600
  title:
    fontFamily: "Fredoka, Noto Sans KR, Apple SD Gothic Neo, sans-serif"
    fontSize: "17sp"
    fontWeight: 600
  body:
    fontFamily: "Nunito, Noto Sans KR, Apple SD Gothic Neo, sans-serif"
    fontSize: "14sp"
    fontWeight: 400
    lineHeight: 1.5
  label:
    fontFamily: "Nunito, Noto Sans KR, Apple SD Gothic Neo, sans-serif"
    fontSize: "11sp"
    fontWeight: 800
  number:
    fontFamily: "Fredoka, Noto Sans KR, sans-serif"
    fontWeight: 700
    fontFeature: "tabular-nums"
rounded:
  xs: "8"
  sm: "12"
  md: "16"
  lg: "20"
  xl: "28"
  pill: "999"
spacing:
  xxs: "4"
  xs: "8"
  sm: "12"
  md: "16"
  lg: "24"
  xl: "32"
  xxl: "48"
  gutter: "20"
components:
  button-primary:
    backgroundColor: "{colors.quiz-blue}"
    textColor: "{colors.surface}"
    rounded: "{rounded.md}"
    padding: "14 24"
    height: "54"
  button-primary-disabled:
    backgroundColor: "{colors.border}"
    textColor: "{colors.text-hint}"
    rounded: "{rounded.md}"
  button-outlined:
    backgroundColor: "transparent"
    textColor: "{colors.text-secondary}"
    rounded: "{rounded.md}"
    padding: "13 22"
  card:
    backgroundColor: "{colors.surface}"
    textColor: "{colors.ink-navy}"
    rounded: "{rounded.lg}"
    padding: "16"
  card-glass:
    backgroundColor: "rgba(255,255,255,0.72)"
    rounded: "{rounded.lg}"
    padding: "16"
  input:
    backgroundColor: "{colors.surface-field}"
    textColor: "{colors.ink-navy}"
    rounded: "{rounded.md}"
    padding: "16"
  chip-status:
    backgroundColor: "{colors.quiz-blue-soft}"
    textColor: "{colors.quiz-blue}"
    rounded: "{rounded.xs}"
    padding: "4 8"
  nav-item-selected:
    backgroundColor: "{colors.quiz-blue-soft}"
    textColor: "{colors.quiz-blue}"
    rounded: "{rounded.pill}"
---

# HelloWord Design System

> 단위는 Flutter의 논리 픽셀이며, 화면에서는 flutter_screenutil로 `.w / .h / .sp / .r`을 붙여
> 402×874 기준으로 환산해 쓴다. 모든 값의 원본은 `lib/core/theme/app_theme.dart`이다.

## Overview

**Creative North Star — "자매의 공부방."**
단정한 학습 도구지만 둘만 아는 온기가 있는 방. 정보는 또렷하고 담백하게 정리하되,
떠다니는 배경·오늘의 명언·조약돌 효과음처럼 매일 들어와도 반갑도록 만드는 작은 것들을 남긴다.

분위기: 또렷한 · 포근한 · 담백한 · 다정한.
철학은 "**공부에 필요한 것은 크게, 나머지는 조용히**"다. 오늘 할 일과 점수는 한눈에 들어오고,
장식은 배경으로 물러난다. 화면은 언제나 세로 한 손 사용을 전제로 한다.

안티레퍼런스: 게임처럼 요란한 학습 앱(과장된 뱃지·연출·소리), 그리고 반대로
아무 성격 없는 관리자 화면. 둘 다 이 앱이 되려는 모습이 아니다.

이 시스템은 ui-ux-pro-max 스킬이 교육/퀴즈 제품 기준으로 뽑아 준 방향(Flat 디자인,
퀴즈 블루 + 성취 골드, Fredoka + Nunito)을 바탕으로 만들어졌다.

## Colors

| 토큰 | 값 | 쓰임 |
|---|---|---|
| `quiz-blue` | #2563EB | 포인트 색. 주요 버튼, 선택 상태, 강조 아이콘 |
| `quiz-blue-soft` | #DBEAFE | 포인트 색의 옅은 바탕(칩·아바타·선택된 탭) |
| `quiz-blue-deep` | #1D4ED8 | 포인트 색 위 글자, 소프트 바탕 위 텍스트 |
| `study-purple` | #7C3AED | 학습·복습 계열 보조 강조 |
| `achievement-gold` | #F59E0B | 성취·D-DAY·시험 임박 |
| `ink-navy` | #0F172A | 본문 글자, 어두운 표면(통화 패널·스낵바·초대 화면) |
| `correct-green` / `wrong-red` | #16A34A / #DC2626 | 정답/오답. 의미 전용이며 브랜드 색으로 쓰지 않는다 |

**포인트 색은 사용자가 고른다.** 내 정보 > 앱 설정에서 블루·인디고·그린·스카이·오렌지 중
선택하며, 기본값이 퀴즈 블루다. 따라서 새 화면은 `quiz-blue`를 하드코딩하지 말고
`AppColors.pink`(= 현재 포인트 색) 토큰을 참조해야 한다.

**중성색은 파랑기가 살짝 도는 회색**이다(#F1F5FD, #E4ECFC). 순수 회색을 쓰면 배경과 겉돈다.

**다크 모드는 색을 반전하지 않고 바꿔 끼운다.** 표면은 #151E32, 글자는 #E8EDF7,
포인트는 밝은 쪽(#60A5FA)으로, 정답/오답도 밝은 쪽(#4ADE80 / #F87171)으로 교체한다.
어두운 바탕에서 원래 채도로 두면 묻힌다.

대비 기준: 본문 4.5:1, 보조 글자도 4.5:1(#64748B), 힌트만 그 아래를 허용한다.

## Typography

**두 벌을 역할로 나눠 쓴다.**

- **Fredoka** — 제목, 영어 단어, 점수·개수 같은 숫자. 둥글고 친근한 얼굴이라
  이 앱의 주인공인 *영어 단어*를 이 폰트로 그린다.
- **Nunito** — 본문, 라벨, 버튼 글자.
- **Noto Sans KR** — 한글은 항상 이 폰트가 그린다(Fredoka·Nunito에 한글 글리프가 없다).
  `fontFamilyFallback`으로 연결돼 있어 한 문장 안에 영어와 한글이 섞여도 자연스럽다.

크기 계단: 40 / 32 / 28(display) · 24 / 20(headline) · 18 / 16 / 14(title) ·
16 / 14 / 13(body) · 11(label). 본문 줄간격 1.5, 제목 1.2.

**숫자는 고정폭(tabular)으로.** 점수·문항 수처럼 바뀌는 숫자는 `AppTheme.tabularNumber`를
써서 값이 바뀔 때 폭이 흔들리지 않게 한다.

**로딩 화면만 예외.** 구글 폰트를 내려받기 전에 보이는 화면이라 기기 기본 폰트
(`AppTheme.systemFont`)로 그린다. 그러지 않으면 글자가 □로 보인다.

## Layout

- 화면 좌우 기본 여백은 `gutter` 20. 카드 목록은 16을 쓴다.
- 여백은 4/8dp 리듬(4·8·12·16·24·32·48)만 쓰고 임의 값을 섞지 않는다.
- 세로 리듬: 섹션 사이 24, 카드 사이 12, 카드 안 요소 사이 8.
- **스크롤 화면의 아래 여백은 `kBottomInset`(96) 하나로 통일한다.** 하단 탭바에
  콘텐츠가 붙어 보이지 않게 하기 위한 것이며 화면마다 다른 값을 쓰지 않는다.
- 콘텐츠 최대 폭 480. 넓은 화면(데스크톱 브라우저)에서는 이 폭의 폰 컬럼을 가운데 둔다.
- 홈은 위에서부터 **인사 → 프로필 줄 → 오늘의 명언 → 오늘 시험 → 결과** 순서다.
  가장 위가 오늘 할 일이고, 아래로 갈수록 지난 것이다.

**세로 스크롤 안에서 `Row(crossAxisAlignment: stretch)`를 그대로 쓰지 않는다.**
높이가 무한이라 레이아웃이 통째로 실패한다. 카드 높이를 맞추려면 `IntrinsicHeight`로 감싼다.

## Elevation & Depth

**그림자로 띄우지 않고 테두리로 구분한다(Flat).**
카드는 흰 배경 + 1px `border`(#E4ECFC)로 경계를 만든다. `softShadow`는 남아 있지만
아주 옅은 보조 수단이며, 새 화면에서는 테두리를 기본으로 한다.

깊이는 세 겹으로만 표현한다:
1. **배경** — 옅은 파랑 그라디언트 위에 알파벳·방울이 아주 느리게 떠다닌다(투명도 0.1 이하).
2. **표면** — 카드. 불투명 흰색, 또는 배경이 비치는 반투명(0.72) 유리 카드.
3. **잉크** — 시험 중 통화 패널·초대 화면처럼 집중이 필요한 곳만 짙은 네이비로 덮는다.

홈 상단은 색을 채우지 않는다. 배경 애니메이션이 그대로 보여야 하며, 그 위의 숫자·명언
카드만 반투명으로 띄운다.

## Shapes

반경은 여섯 단계만 쓴다: 8(xs) · 12(sm) · 16(md) · 20(lg) · 28(xl) · 999(pill).

- 버튼·입력칸: 16
- 카드: 20 (큰 결과 카드는 28)
- 칩·뱃지: 8 또는 pill
- 아이콘 타일: 12

**중첩된 상자는 동심원 관계를 지킨다.** 바깥 카드가 16이고 안쪽 여백이 12면
안쪽 상자는 8로 내린다. 안팎 반경이 같으면 어긋나 보인다.

아이콘은 Material Rounded 계열로 통일하고 크기는 18 / 24 / 32 세 가지만 쓴다.
**이모지를 기능 아이콘으로 쓰지 않는다.** 마스코트(🐰 🐥)와 장식 용도만 예외다.

## Components

- **주요 버튼** — 단색 포인트 색, 반경 16, 높이 54, 글자 800. 비활성은 투명도를 낮추지 않고
  회색 배경 + 힌트색 글자로 바꿔 못 누른다는 걸 분명히 한다.
- **카드(AppCard)** — 흰 배경 + 테두리, 반경 20, 안쪽 여백 16. 누를 수 있으면 `onTap`을 주고
  누를 때 0.96으로 살짝 작아진다.
- **섹션 제목(SectionHeader)** — Fredoka 18에 왼쪽 포인트 색 아이콘, 오른쪽에 선택적 동작 링크.
- **빈 상태(EmptyState)** — 원형 아이콘 + 두 줄 설명 + (필요할 때만) 버튼. 문장 하나로 끝내지 않는다.
- **상태 칩(StatusChip)** — 반경 8, 소프트 배경 + 진한 글자. D-DAY·개수·완료 표시에 쓴다.
- **하단 탭바** — 아이콘 + 한글 라벨. 선택 상태는 색과 옅은 배경 두 가지로 알린다.
  배경이 비치도록 반투명(0.82) + 뒤 흐리기를 쓰고, 홈 인디케이터 쪽으로
  너무 내려가지 않도록 아래 여백을 줄이는 대신 탭 자체를 키운다.
- **명언 카드(QuoteCard)** — 반투명 카드. 영어 원문(Fredoka) + 한글 뜻 + 출처.
  누르면 미국식 발음으로 읽어 준다. 30분마다 다음 문장으로 바뀐다.
- **단어 타일(WordTile)** — 영어는 Fredoka로 크게, 뜻은 오른쪽 정렬, 예문은 안쪽 회색 상자.
  발음 버튼은 눈에 보이는 원이 작아도 누르는 범위는 44 이상으로 넓힌다.

**모션은 150~300ms, easeOutCubic.** 누를 때 축소는 0.96 고정.
시스템 '동작 줄이기'가 켜져 있으면 배경 애니메이션과 화면 전환 슬라이드를 멈춘다.

**소리.** 버튼을 누르면 조약돌이 부딪히는 짧은 소리만 난다. 설정에서 끌 수 있고,
영상통화 중에는 자동으로 꺼진다. 배경음악은 두지 않는다 — 아이폰에서 재생될 때마다
다이나믹 아일랜드에 음악 표시가 켜졌다 꺼지기를 반복해 오히려 방해가 됐다.

## Do's and Don'ts

**Do**

- 색은 `AppColors`, 여백은 `AppSpace`, 반경은 `AppRadius`, 시간·커브는 `AppMotion` 토큰으로.
- 영어 단어와 숫자는 Fredoka로, 한글 본문은 Nunito+Noto Sans KR로.
- 누를 수 있는 것은 무엇이든 44 이상의 터치 범위를 준다.
- 정답/오답은 색과 아이콘(또는 글자)을 함께 써서 색맹에게도 구분되게 한다.
- 다크 모드는 따로 확인한다. 라이트 값에서 유추하지 않는다.

**Don't**

- 화면에서 hex 색을 직접 쓰지 않는다.
- 그라디언트 버튼·색이 번지는 그림자를 쓰지 않는다(Flat을 깨뜨린다).
- 이모지를 기능 아이콘 자리에 쓰지 않는다.
- 세로 스크롤 안에서 `Row` + `stretch`를 그대로 쓰지 않는다.
- 화면마다 다른 하단 여백을 쓰지 않는다(`kBottomInset` 고정).
- 배경 애니메이션 위에 불투명한 색면을 크게 덮지 않는다.
