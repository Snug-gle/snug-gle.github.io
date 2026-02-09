---
created: 2025-12-26
---
# LinkWave 디자인 시스템

## 디자인 철학

### "Clarity Through Connection" (연결을 통한 명확성)

LinkWave는 **구글의 Material Design의 접근성**과 **애플의 Human Interface Guidelines의 사용자 중심 철학**을 결합한 독창적인 디자인 철학을 지향합니다.

#### 핵심 원칙

1. **명확성 우선 (Clarity First)**
   - 복잡한 기능도 단순하게 표현
   - 중요한 정보는 즉시 인지 가능
   - 불필요한 요소 제거
   - *애플의 "Simplicity is the ultimate sophistication"에서 영감*

2. **신뢰 구축 (Trust Through Design)**
   - 일관된 색상과 스타일
   - 명확한 피드백 (성공/실패)
   - 투명한 정보 제공
   - *구글의 "Material is the metaphor"에서 영감*

3. **효율성 극대화 (Efficiency at Scale)**
   - 대량 작업을 위한 최적화
   - 빠른 작업 흐름
   - 키보드 단축키 지원
   - *B2B SaaS 플랫폼의 실용성*

4. **유기적 연결 (Organic Connection)**
   - 자연스러운 전환과 흐름
   - 사용자 행동에 반응하는 인터페이스
   - 부드러운 애니메이션으로 맥락 제공
   - *LinkWave의 "연결" 철학 반영*

## 브랜드 컬러

### Primary (신뢰 - Indigo)
- **Light Mode**: `oklch(0.68 0.12 265)` - 채도 낮춤
- **Dark Mode**: `oklch(0.72 0.14 265)`
- **용도**: 주요 액션 버튼, 강조 요소, 브랜드 아이덴티티
- **의미**: 신뢰, 안정성, 전문성

### Secondary (혁신 - Violet)
- **Light Mode**: `oklch(0.55 0.12 288)` - 채도 낮춤
- **Dark Mode**: `oklch(0.60 0.14 288)`
- **용도**: 보조 액션, 그라데이션 배경
- **의미**: 혁신, 창의성, 연결

### Accent (젊음 - Cyan)
- **Light Mode**: `oklch(0.69 0.12 232)` - 채도 낮춤
- **Dark Mode**: `oklch(0.75 0.14 232)`
- **용도**: 알림, 강조, 에너지 표현
- **의미**: 젊음, 활력, 소통

### Neutral Colors
- **Background**: `oklch(1 0 0)` (흰색)
- **Foreground**: `oklch(0.145 0 0)` (거의 검정)
- **Muted**: `oklch(0.97 0 0)` (연한 회색)
- **Border**: `oklch(0.922 0 0)` (경계선)

## 타이포그래피

### 폰트 스케일
- **Display (Hero)**: 5xl-8xl (48px-96px) - Bold
- **Heading 1**: 4xl-6xl (36px-60px) - Bold
- **Heading 2**: 3xl-5xl (30px-48px) - Bold
- **Heading 3**: 2xl-3xl (24px-30px) - Semibold
- **Body Large**: xl-2xl (20px-24px) - Regular
- **Body**: base-lg (16px-18px) - Regular
- **Body Small**: sm-base (14px-16px) - Regular
- **Caption**: xs-sm (12px-14px) - Regular

### 폰트 특징
- **가독성 우선**: 충분한 line-height (1.5-1.75)
- **계층 구조**: 명확한 크기 차이
- **숫자/통계**: Monospace 폰트 고려 (선택사항)

## 간격 시스템

### 4px 기준 그리드
- **xs**: 4px
- **sm**: 8px
- **md**: 12px
- **lg**: 16px
- **xl**: 24px
- **2xl**: 32px
- **3xl**: 48px
- **4xl**: 64px

### 컴포넌트 간격
- **카드 간격**: 16-24px
- **섹션 간격**: 32-48px (모바일), 48-64px (데스크톱)
- **내부 패딩**: 16-24px (모바일), 24-32px (데스크톱)

## 컴포넌트 스타일

### 버튼
- **Border Radius**: `rounded-[980px]` (완전히 둥근 형태)
- **높이**: sm(32px), default(40px), lg(48px), xl(56px)
- **패딩**: 수평 16-24px
- **전환**: 200ms ease-out

### 카드
- **Border Radius**: `rounded-xl` (12px) 또는 `rounded-2xl` (16px)
- **Shadow**: `shadow-md` (기본), `shadow-xl` (호버)
- **Border**: 얇은 경계선 (`border-border`)
- **배경**: 반투명 가능 (`bg-card/80`)

### 입력 필드
- **Border Radius**: `rounded-lg` (8px)
- **Focus**: Primary 색상 border + ring
- **높이**: 40-48px

## 애니메이션

### 전환 시간
- **빠른 전환**: 150ms (호버, 클릭)
- **표준 전환**: 200-300ms (일반 상태 변경)
- **느린 전환**: 500-800ms (페이지 전환, 섹션 등장)

### Easing 함수
- **기본**: `ease-out` 또는 `[0.16, 1, 0.3, 1]` (애플 스타일)
- **부드러운 등장**: `ease-in-out`
- **탄성 효과**: 필요시 `ease-out-back`

### 애니메이션 패턴
- **Fade In**: opacity 0 → 1
- **Slide Up**: y: 20-50px → 0
- **Scale**: scale: 0.95 → 1 (버튼 클릭)
- **Parallax**: 스크롤 기반 이동

## 레이아웃 원칙

### 그리드 시스템
- **컨테이너 최대 너비**: 
  - 사용자 페이지: 1920px
  - 관리자 페이지: 1400px
- **반응형 브레이크포인트**:
  - Mobile: < 640px
  - Tablet: 640px - 1024px
  - Desktop: > 1024px

### 여백 원칙
- **외부 여백**: 섹션 간 충분한 공간 (48-64px)
- **내부 여백**: 콘텐츠 주변 여유 공간 (16-24px)
- **그룹 간격**: 관련 요소 간 일관된 간격 (8-16px)

## 접근성

### 색상 대비
- **텍스트/배경**: WCAG AA 기준 준수 (4.5:1 이상)
- **대화형 요소**: 명확한 포커스 표시
- **색상 의존성**: 색상만으로 정보 전달하지 않음

### 키보드 네비게이션
- 모든 대화형 요소 키보드 접근 가능
- 포커스 순서 논리적
- 포커스 링 명확하게 표시

## 다크모드

### 색상 조정
- **밝기 증가**: Light mode 대비 10-15% 밝게
- **채도 증가**: Light mode 대비 약간 높게 (가독성)
- **대비 유지**: 텍스트 가독성 보장

## 사용 예시

### Hero 섹션
- 브랜드 컬러 그라데이션 배경
- 큰 타이포그래피
- 부드러운 스크롤 애니메이션

### 카드 레이아웃
- 그리드 시스템 활용
- 호버 시 상승 효과
- 일관된 간격과 패딩

### 버튼 그룹
- 균일한 크기와 간격
- 명확한 계층 구조
- 일관된 스타일

## 참고 자료

### 영감 소스
- **Linear**: 깔끔한 인터페이스, 부드러운 애니메이션
- **Vercel**: 미니멀리즘, 타이포그래피 중심
- **Stripe**: 신뢰감 있는 디자인, 명확한 정보 구조
- **Apple**: 사용자 중심, 자연스러운 인터랙션

### 디자인 원칙 참고
- Material Design 3 (Google)
- Human Interface Guidelines (Apple)
- Ant Design (엔터프라이즈 패턴)

