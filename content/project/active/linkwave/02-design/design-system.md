---
created: 2026-02-10
tags:
  - linkwave
  - frontend
  - design-system
---

> 이 문서는 linkwave-docs의 frontend/DESIGN_SYSTEM.md 원본입니다.

# LinkWave 디자인 시스템

## 디자인 철학

### "Clarity Through Connection" (연결을 통한 명확성)

**구글의 Material Design의 접근성**과 **애플의 Human Interface Guidelines의 사용자 중심 철학**을 결합한 독창적인 디자인 철학.

#### 핵심 원칙

1. **명확성 우선 (Clarity First)** — 복잡한 기능도 단순하게 표현, 중요한 정보는 즉시 인지 가능
2. **신뢰 구축 (Trust Through Design)** — 일관된 색상과 스타일, 명확한 피드백
3. **효율성 극대화 (Efficiency at Scale)** — 대량 작업을 위한 최적화, 키보드 단축키
4. **유기적 연결 (Organic Connection)** — 자연스러운 전환과 흐름, 부드러운 애니메이션

## 브랜드 컬러

### Primary (신뢰 - Indigo)
- **Light Mode**: `oklch(0.68 0.12 265)`
- **Dark Mode**: `oklch(0.72 0.14 265)`
- **용도**: 주요 액션 버튼, 강조 요소, 브랜드 아이덴티티

### Secondary (혁신 - Violet)
- **Light Mode**: `oklch(0.55 0.12 288)`
- **Dark Mode**: `oklch(0.60 0.14 288)`
- **용도**: 보조 액션, 그라데이션 배경

### Accent (젊음 - Cyan)
- **Light Mode**: `oklch(0.69 0.12 232)`
- **Dark Mode**: `oklch(0.75 0.14 232)`
- **용도**: 알림, 강조, 에너지 표현

### Neutral Colors
- Background: `oklch(1 0 0)` / Foreground: `oklch(0.145 0 0)`
- Muted: `oklch(0.97 0 0)` / Border: `oklch(0.922 0 0)`

## 타이포그래피

| 용도 | 크기 | 웨이트 |
|------|------|--------|
| Display (Hero) | 48-96px | Bold |
| Heading 1 | 36-60px | Bold |
| Heading 2 | 30-48px | Bold |
| Heading 3 | 24-30px | Semibold |
| Body Large | 20-24px | Regular |
| Body | 16-18px | Regular |
| Caption | 12-14px | Regular |

- 가독성 우선: line-height 1.5-1.75
- 숫자/통계: Monospace 폰트 고려

## 간격 시스템

4px 기준 그리드: xs(4) / sm(8) / md(12) / lg(16) / xl(24) / 2xl(32) / 3xl(48) / 4xl(64)

## 컴포넌트 스타일

### 버튼
- Border Radius: `rounded-[980px]` (완전히 둥근 형태)
- 높이: sm(32) / default(40) / lg(48) / xl(56)
- 전환: 200ms ease-out

### 카드
- Border Radius: `rounded-xl` (12px) 또는 `rounded-2xl` (16px)
- Shadow: `shadow-md` (기본), `shadow-xl` (호버)

### 입력 필드
- Border Radius: `rounded-lg` (8px)
- Focus: Primary 색상 border + ring
- 높이: 40-48px

## 애니메이션

- 빠른 전환: 150ms (호버, 클릭)
- 표준 전환: 200-300ms (상태 변경)
- 느린 전환: 500-800ms (페이지 전환)
- Easing: `ease-out` 또는 `[0.16, 1, 0.3, 1]` (애플 스타일)

## 레이아웃 원칙

- 사용자 페이지 최대 너비: 1920px / 관리자: 1400px
- 반응형: Mobile(<640) / Tablet(640-1024) / Desktop(>1024)

## 접근성

- WCAG AA 기준 준수 (4.5:1 이상)
- 모든 대화형 요소 키보드 접근 가능
- 색상만으로 정보 전달하지 않음

## 다크모드

- 밝기 증가: Light mode 대비 10-15%
- 채도 증가: 가독성 위해 약간 높게

## 영감 소스

Linear, Vercel, Stripe, Apple / Material Design 3, HIG, Ant Design
