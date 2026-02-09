---
created: 2025-11-28
tags:
  - moc
  - resource
  - typescript
  - frontend
category: frontend
---

# 📘 TypeScript MOC

> TypeScript 학습 로드맵 - 타입 안정성부터 고급 기법까지

## 📍 현재 위치
- 학습 단계: **준비 중**
- 목표: 프론트엔드 프로젝트에 TypeScript 적용

---

## 🌱 기초 개념

### TypeScript 시작하기
- TypeScript란?
- JavaScript vs TypeScript
- 개발 환경 설정
- tsconfig.json 설정

### 기본 타입
- Primitive Types (string, number, boolean)
- Array, Tuple
- Enum
- Any, Unknown, Never
- Type Assertions

---

## 🔧 고급 타입

### Type System
- Union Types
- Intersection Types
- Type Aliases
- Interfaces
- Generic Types

### 유틸리티 타입
- Partial, Required
- Pick, Omit
- Record, Exclude
- ReturnType, Parameters

---

## ⚛️ React와 TypeScript

### 컴포넌트 타이핑
- Function Component 타입
- Props 타입 정의
- Event Handler 타입
- Hooks 타이핑 (useState, useEffect, etc.)

### 실전 패턴
- Custom Hooks 타이핑
- Context API 타이핑
- Higher-Order Components (HOC)

---

## 🔍 고급 기법

### Advanced Types
- Conditional Types
- Mapped Types
- Template Literal Types
- Discriminated Unions

### Type Guards
- typeof
- instanceof
- Custom Type Guards
- Assertion Functions

---

## 🚀 실전 프로젝트

### 적용 예정 프로젝트
- [[project/active/blog|블로그 프로젝트]]
- React + TypeScript
- TanStack Query + TypeScript

### Best Practices
```dataview
LIST
FROM #typescript AND #best-practice
```

---

## 🛠️ 도구와 생태계

### 개발 도구
- TSC (TypeScript Compiler)
- ts-node
- ESLint + TypeScript
- Prettier

### 타입 라이브러리
- @types/* (DefinitelyTyped)
- type-fest
- utility-types

---

## 📚 학습 자료

### 공식 문서
- [TypeScript 공식 문서](https://www.typescriptlang.org/docs/)
- [TypeScript Handbook](https://www.typescriptlang.org/docs/handbook/intro.html)

### 관련 노트
```dataview
LIST
FROM #typescript
WHERE !contains(file.name, "MOC")
SORT file.mtime DESC
```

---

## 🔗 관련 MOC
- → [[resource/topics/frontend/react/_React MOC|React MOC]]
- → [[resource/topics/frontend/vue/_Vue MOC|Vue MOC]]
- ← [[resource/topics/java/_Java MOC|Java MOC]] (타입 시스템 비교)

## 🎯 학습 목표
- [ ] TypeScript 기초 완료
- [ ] React + TypeScript 프로젝트 경험
- [ ] 고급 타입 패턴 마스터
- [ ] Generic 타입 자유자재로 활용
- [ ] 타입 에러 디버깅 능력 향상

---
*Last updated: 2025-10-29*
