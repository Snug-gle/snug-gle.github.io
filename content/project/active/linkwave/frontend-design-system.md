---
created: 2025-01-17
updated: 2025-01-17
tags:
  - work
  - iotree
  - frontend
  - react
  - design-system
  - tailwind
company: IoTree Inc.
project: LinkWave Frontend
status: active
---

# LinkWave Frontend 디자인 시스템

> "Clarity Through Connection" - 연결을 통한 명확성

## 디자인 철학

LinkWave는 **구글의 Material Design의 접근성**과 **애플의 Human Interface Guidelines의 사용자 중심 철학**을 결합한 독창적인 디자인 철학을 지향합니다.

### 핵심 원칙

#### 1. 명확성 우선 (Clarity First)
- 복잡한 기능도 단순하게 표현
- 중요한 정보는 즉시 인지 가능
- 불필요한 요소 제거
- *애플의 "Simplicity is the ultimate sophistication"에서 영감*

#### 2. 신뢰 구축 (Trust Through Design)
- 일관된 색상과 스타일
- 명확한 피드백 (성공/실패)
- 투명한 정보 제공
- *구글의 "Material is the metaphor"에서 영감*

#### 3. 효율성 극대화 (Efficiency at Scale)
- 대량 작업을 위한 최적화
- 빠른 작업 흐름
- 키보드 단축키 지원
- *B2B SaaS 플랫폼의 실용성*

#### 4. 유기적 연결 (Organic Connection)
- 자연스러운 전환과 흐름
- 사용자 행동에 반응하는 인터페이스
- 부드러운 애니메이션으로 맥락 제공
- *LinkWave의 "연결" 철학 반영*

---

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

### Semantic Colors

#### Success (성공 - Green)
- **Light Mode**: `oklch(0.65 0.15 140)`
- **Dark Mode**: `oklch(0.70 0.17 140)`
- **용도**: 성공 메시지, 발송 완료 상태
- **예시**: "메시지가 성공적으로 발송되었습니다"

#### Warning (경고 - Yellow)
- **Light Mode**: `oklch(0.75 0.12 85)`
- **Dark Mode**: `oklch(0.80 0.14 85)`
- **용도**: 주의 메시지, 예약 발송 대기
- **예시**: "예약 발송은 취소할 수 있습니다"

#### Destructive (위험 - Red)
- **Light Mode**: `oklch(0.62 0.20 25)`
- **Dark Mode**: `oklch(0.67 0.22 25)`
- **용도**: 오류 메시지, 삭제 액션
- **예시**: "메시지 발송에 실패했습니다"

---

## 타이포그래피

### 폰트 스케일

| 용도 | 크기 | 굵기 | 용례 |
|------|------|------|------|
| **Display (Hero)** | 5xl-8xl (48px-96px) | Bold | 랜딩 페이지 헤더 |
| **Heading 1** | 4xl-6xl (36px-60px) | Bold | 페이지 제목 |
| **Heading 2** | 3xl-5xl (30px-48px) | Bold | 섹션 제목 |
| **Heading 3** | 2xl-3xl (24px-30px) | Semibold | 서브 섹션 제목 |
| **Body Large** | xl-2xl (20px-24px) | Regular | 강조 본문 |
| **Body** | base-lg (16px-18px) | Regular | 기본 본문 |
| **Body Small** | sm-base (14px-16px) | Regular | 보조 텍스트 |
| **Caption** | xs-sm (12px-14px) | Regular | 힌트, 캡션 |

### 폰트 특징
- **가독성 우선**: 충분한 line-height (1.5-1.75)
- **계층 구조**: 명확한 크기 차이
- **숫자/통계**: Monospace 폰트 고려 (선택사항)

**예시:**
```css
.heading-1 {
  font-size: 2.25rem; /* 36px */
  font-weight: 700;
  line-height: 1.25;
}

.body {
  font-size: 1rem; /* 16px */
  font-weight: 400;
  line-height: 1.75;
}
```

---

## 간격 시스템

### 4px 기준 그리드

| 크기 | 값 | 용례 |
|------|-----|------|
| **xs** | 4px | 아이콘-텍스트 간격 |
| **sm** | 8px | 버튼 내부 패딩 |
| **md** | 12px | 입력 필드 패딩 |
| **lg** | 16px | 카드 내부 패딩 |
| **xl** | 24px | 카드 간격 |
| **2xl** | 32px | 섹션 간격 (모바일) |
| **3xl** | 48px | 섹션 간격 (데스크톱) |
| **4xl** | 64px | 페이지 여백 |

### 컴포넌트 간격
- **카드 간격**: 16-24px
- **섹션 간격**: 32-48px (모바일), 48-64px (데스크톱)
- **내부 패딩**: 16-24px (모바일), 24-32px (데스크톱)

---

## 컴포넌트 스타일

### 버튼

#### 크기
- **sm**: 32px 높이
- **default**: 40px 높이
- **lg**: 48px 높이
- **xl**: 56px 높이

#### 스타일
- **Border Radius**: `rounded-[980px]` (완전히 둥근 형태)
- **패딩**: 수평 16-24px
- **트랜지션**: `transition-all duration-200`

#### 변형

**Primary Button (주요 액션)**
```tsx
<Button variant="primary" size="default">
  메시지 발송
</Button>
```
- 배경: Primary 색상
- 텍스트: 흰색
- 호버: 어둡게 (10%)
- 예시: "메시지 발송", "저장", "확인"

**Secondary Button (보조 액션)**
```tsx
<Button variant="secondary" size="default">
  미리보기
</Button>
```
- 배경: Secondary 색상
- 텍스트: 흰색
- 호버: 어둡게 (10%)
- 예시: "미리보기", "다운로드"

**Outline Button (부차적 액션)**
```tsx
<Button variant="outline" size="default">
  취소
</Button>
```
- 배경: 투명
- 테두리: Border 색상
- 호버: Muted 배경
- 예시: "취소", "닫기"

**Ghost Button (최소 강조)**
```tsx
<Button variant="ghost" size="default">
  더보기
</Button>
```
- 배경: 투명
- 텍스트: Foreground 색상
- 호버: Muted 배경
- 예시: "더보기", "접기"

**Destructive Button (위험 액션)**
```tsx
<Button variant="destructive" size="default">
  삭제
</Button>
```
- 배경: Destructive 색상
- 텍스트: 흰색
- 호버: 어둡게 (10%)
- 예시: "삭제", "초기화"

---

### 입력 필드 (Input)

#### 스타일
- **Border Radius**: `rounded-lg` (8px)
- **높이**: 40px (default), 48px (lg)
- **테두리**: `border border-input`
- **포커스**: `ring-2 ring-primary`

#### 변형

**Text Input**
```tsx
<Input type="text" placeholder="수신 번호 입력" />
```

**Textarea**
```tsx
<Textarea placeholder="메시지 내용 입력" rows={4} />
```

**Select**
```tsx
<Select>
  <SelectTrigger>
    <SelectValue placeholder="메시지 타입 선택" />
  </SelectTrigger>
  <SelectContent>
    <SelectItem value="SMS">SMS</SelectItem>
    <SelectItem value="LMS">LMS</SelectItem>
    <SelectItem value="MMS">MMS</SelectItem>
  </SelectContent>
</Select>
```

---

### 카드 (Card)

#### 스타일
- **Border Radius**: `rounded-xl` (12px)
- **테두리**: `border border-border`
- **배경**: `bg-card`
- **그림자**: `shadow-sm`
- **패딩**: 24px (default)

#### 구조
```tsx
<Card>
  <CardHeader>
    <CardTitle>발송 통계</CardTitle>
    <CardDescription>최근 30일 발송 현황</CardDescription>
  </CardHeader>
  <CardContent>
    {/* 카드 내용 */}
  </CardContent>
  <CardFooter>
    <Button variant="outline">자세히 보기</Button>
  </CardFooter>
</Card>
```

---

### 테이블 (Table)

#### 스타일
- **Border**: `border-b border-border`
- **헤더**: `bg-muted/50 font-semibold`
- **행**: `hover:bg-muted/50 transition-colors`
- **패딩**: 12px (셀)

#### 구조
```tsx
<Table>
  <TableHeader>
    <TableRow>
      <TableHead>발송 시각</TableHead>
      <TableHead>수신 번호</TableHead>
      <TableHead>메시지 타입</TableHead>
      <TableHead>상태</TableHead>
    </TableRow>
  </TableHeader>
  <TableBody>
    <TableRow>
      <TableCell>2025-01-17 14:30</TableCell>
      <TableCell>010-1234-5678</TableCell>
      <TableCell>SMS</TableCell>
      <TableCell>
        <Badge variant="success">성공</Badge>
      </TableCell>
    </TableRow>
  </TableBody>
</Table>
```

---

### 배지 (Badge)

#### 크기
- **sm**: 20px 높이
- **default**: 24px 높이

#### 변형

**Default**
```tsx
<Badge variant="default">기본</Badge>
```

**Success**
```tsx
<Badge variant="success">성공</Badge>
```

**Warning**
```tsx
<Badge variant="warning">대기</Badge>
```

**Destructive**
```tsx
<Badge variant="destructive">실패</Badge>
```

---

### 알림 (Toast)

#### 위치
- **Bottom Right** (기본)
- **Top Center** (중요 알림)

#### 변형

**Success Toast**
```tsx
toast({
  title: "메시지 발송 완료",
  description: "총 150명에게 메시지가 발송되었습니다.",
  variant: "success",
});
```

**Error Toast**
```tsx
toast({
  title: "메시지 발송 실패",
  description: "잔액이 부족합니다. 충전 후 다시 시도해주세요.",
  variant: "destructive",
});
```

**Warning Toast**
```tsx
toast({
  title: "주의 필요",
  description: "일부 번호는 발송되지 않았습니다.",
  variant: "warning",
});
```

---

## 레이아웃

### 그리드 시스템

#### 12 Column Grid
```tsx
<div className="grid grid-cols-12 gap-6">
  <div className="col-span-12 md:col-span-8">
    {/* 메인 콘텐츠 */}
  </div>
  <div className="col-span-12 md:col-span-4">
    {/* 사이드바 */}
  </div>
</div>
```

#### 반응형 브레이크포인트

| 브레이크포인트 | 크기 | 용례 |
|----------------|------|------|
| **sm** | 640px | 모바일 (가로) |
| **md** | 768px | 태블릿 |
| **lg** | 1024px | 데스크톱 (작음) |
| **xl** | 1280px | 데스크톱 (중간) |
| **2xl** | 1536px | 데스크톱 (큼) |

---

### 페이지 레이아웃

#### Dashboard Layout
```
┌────────────────────────────────────────┐
│          Header (Navigation)           │
├────────┬───────────────────────────────┤
│        │                               │
│ Side   │   Main Content Area           │
│ bar    │                               │
│        │   • 통계 카드                  │
│        │   • 최근 발송 이력              │
│        │   • 차트                       │
│        │                               │
└────────┴───────────────────────────────┘
```

#### Message Form Layout
```
┌────────────────────────────────────────┐
│          Header (Navigation)           │
├────────────────────────────────────────┤
│                                        │
│  ┌──────────────┐  ┌─────────────┐    │
│  │ 발송 설정    │  │ 미리보기    │    │
│  │              │  │             │    │
│  │ • 메시지 타입│  │             │    │
│  │ • 수신 번호  │  │             │    │
│  │ • 내용       │  │             │    │
│  └──────────────┘  └─────────────┘    │
│                                        │
│  [취소] [미리보기] [발송]              │
└────────────────────────────────────────┘
```

---

## 애니메이션

### 트랜지션 시간

| 용도 | 시간 | 예시 |
|------|------|------|
| **빠름** | 150ms | 버튼 호버 |
| **기본** | 200ms | 카드 펼치기 |
| **느림** | 300ms | 모달 열기 |
| **매우 느림** | 500ms | 페이지 전환 |

### Easing Functions

```css
/* 기본 (ease-in-out) */
transition: all 200ms cubic-bezier(0.4, 0, 0.2, 1);

/* 부드러운 시작 (ease-out) */
transition: all 200ms cubic-bezier(0, 0, 0.2, 1);

/* 빠른 시작 (ease-in) */
transition: all 200ms cubic-bezier(0.4, 0, 1, 1);
```

### 호버 효과

**Button Hover**
```tsx
<Button className="hover:scale-105 transition-transform">
  메시지 발송
</Button>
```

**Card Hover**
```tsx
<Card className="hover:shadow-md transition-shadow">
  {/* 카드 내용 */}
</Card>
```

---

## 아이콘 시스템

### Lucide React Icons

**크기:**
- **sm**: 16px
- **default**: 20px
- **lg**: 24px
- **xl**: 32px

**사용 예시:**
```tsx
import { Send, Calendar, User } from 'lucide-react';

<Button>
  <Send className="mr-2 h-4 w-4" />
  메시지 발송
</Button>
```

**주요 아이콘:**
- `Send`: 메시지 발송
- `Calendar`: 예약 발송
- `User`: 사용자
- `Users`: 주소록
- `MessageSquare`: 메시지
- `BarChart`: 통계
- `Settings`: 설정
- `LogOut`: 로그아웃

---

## 다크 모드

### 컬러 변수 (Tailwind CSS)

```css
@layer base {
  :root {
    --background: 0 0% 100%;
    --foreground: 0 0% 14.5%;
    --primary: oklch(0.68 0.12 265);
    /* ... */
  }

  .dark {
    --background: 0 0% 3.9%;
    --foreground: 0 0% 98%;
    --primary: oklch(0.72 0.14 265);
    /* ... */
  }
}
```

### 다크 모드 토글

```tsx
import { Moon, Sun } from 'lucide-react';

function ThemeToggle() {
  const [theme, setTheme] = useState<'light' | 'dark'>('light');

  const toggleTheme = () => {
    const newTheme = theme === 'light' ? 'dark' : 'light';
    setTheme(newTheme);
    document.documentElement.classList.toggle('dark');
  };

  return (
    <Button variant="ghost" size="icon" onClick={toggleTheme}>
      {theme === 'light' ? <Moon /> : <Sun />}
    </Button>
  );
}
```

---

## 접근성 (Accessibility)

### ARIA 속성

**버튼:**
```tsx
<Button aria-label="메시지 발송">
  <Send />
</Button>
```

**입력 필드:**
```tsx
<Input
  id="phone"
  aria-label="수신 번호"
  aria-describedby="phone-description"
/>
<span id="phone-description">010-0000-0000 형식으로 입력</span>
```

### 키보드 네비게이션

- **Tab**: 다음 요소로 이동
- **Shift + Tab**: 이전 요소로 이동
- **Enter/Space**: 버튼 클릭
- **Escape**: 모달 닫기

---

## 기술 스택

### Core
- **React 19** + **TypeScript**
- **Vite 7** (빌드 도구)
- **TanStack Router** (라우팅)

### Styling
- **Tailwind CSS** (유틸리티 CSS)
- **shadcn/ui** (컴포넌트 라이브러리)
- **Radix UI** (헤드리스 UI)

### State Management
- **Zustand** (전역 상태)
- **TanStack Query** (서버 상태)

### Forms
- **React Hook Form** (폼 관리)
- **Zod** (검증)

---

## 배운 점

### 1. 디자인 시스템의 중요성
- 일관된 UI/UX 제공
- 개발 속도 향상 (재사용 가능한 컴포넌트)
- 유지보수성 향상

### 2. shadcn/ui의 철학
- "Copy & Paste" 방식의 컴포넌트
- 커스터마이징 용이
- TypeScript 완벽 지원

### 3. Tailwind CSS의 생산성
- 유틸리티 클래스로 빠른 개발
- 일관된 스타일 유지
- 반응형 디자인 간편

### 4. 접근성의 가치
- ARIA 속성으로 스크린 리더 지원
- 키보드 네비게이션
- 색상 대비 고려

---

## 관련 문서

- [[LinkWave 프로젝트 개요]]
- [[LinkWave Backend 아키텍처]]
- [[React 19 학습]]
- [[Tailwind CSS 패턴]]
- [[shadcn/ui 커스터마이징]]

---

**작성일**: 2025-01-17
**작성자**: 상훈
**프로젝트 경로**: `/Users/sanghoon/Project/iotree-linkwave/linkwave-frontend`
