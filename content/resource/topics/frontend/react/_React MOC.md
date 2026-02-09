---
created: 2025-11-28
tags:
  - moc
  - resource
  - react
  - frontend
category: frontend
---

# ⚛️ React MOC

> React 학습 로드맵 - Hooks부터 실전까지

## 📍 현재 위치
- 학습 단계: **초중급**
- React 버전: React 19+
- 실전 적용: [[project/active/blog|블로그 프로젝트]]

---

## 🌱 기초 개념

### React 핵심
- 컴포넌트와 Props
- JSX 문법
- 상태(State)와 생명주기
- 이벤트 핸들링

### Hooks
- useState - 상태 관리
- useEffect - 사이드 이펙트
- useContext - 전역 상태
- useReducer - 복잡한 상태 로직
- useMemo, useCallback - 성능 최적화

---

## 📊 상태 관리

### Context API
- React Context 패턴
- Provider와 Consumer
- 전역 상태 설계

### 외부 라이브러리
- Redux Toolkit
- Zustand
- Jotai, Recoil

---

## 🔧 Data Fetching

### TanStack Query (React Query)
- [[TanStack]] - 서버 상태 관리
- useQuery - 데이터 조회
- useMutation - 데이터 변경
- 캐싱 전략
- Optimistic Updates

### 기타 도구
- SWR
- Apollo Client (GraphQL)

---

## 🎨 실전 활용

### 프로젝트 구조
- 컴포넌트 설계 패턴
- 폴더 구조 best practices
- 코드 스플리팅

### 성능 최적화
- React.memo
- 렌더링 최적화
- Bundle Size 최적화
- Lazy Loading

---

## 🚀 생태계

### 빌드 도구
- **Vite** - 현대적인 빌드 도구
- Create React App (레거시)
- Next.js (SSR/SSG)

### UI 라이브러리
- Tailwind CSS
- Material-UI
- shadcn/ui
- Radix UI

### 개발 도구
- React DevTools
- ESLint + Prettier
- TypeScript

---

## 🧪 테스팅

### 테스트 도구
- Vitest
- React Testing Library
- Jest

### 테스트 전략
```dataview
LIST
FROM #react AND #testing
```

---

## 🔗 프로젝트 연결

### 블로그 프로젝트
- [[project/active/blog|블로그 프로젝트 개요]]
- React 19 + Vite
- TanStack Query 활용
- Tailwind CSS 스타일링

---

## 📚 학습 자료

### 공식 문서
- [React 공식 문서](https://react.dev/)
- [TanStack Query](https://tanstack.com/query/latest)

### 관련 노트
```dataview
LIST
FROM #react
WHERE !contains(file.name, "MOC")
SORT file.mtime DESC
```

---

## 🔗 관련 MOC
- ← [[resource/topics/frontend/vue/_Vue MOC|Vue MOC]]
- → [[resource/topics/frontend/typescript/_TypeScript MOC|TypeScript MOC]]

## 🎯 다음 학습 목표
- [ ] React 19 새 기능 학습
- [ ] Next.js 14 App Router
- [ ] React Server Components
- [ ] 고급 패턴 (Compound Components, Render Props)
- [ ] 블로그 프로젝트 완성

---
*Last updated: 2025-10-29*
