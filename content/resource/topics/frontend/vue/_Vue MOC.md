---
created: 2025-11-28
tags:
  - moc
  - resource
  - vue
  - frontend
category: frontend
---

# 🟢 Vue.js MOC

> Vue 3 학습 로드맵 - Composition API를 중심으로

## 📍 현재 위치
- 학습 단계: **중급**
- Vue 버전: Vue 3 (Composition API)

---

## 🌱 기초 개념

### Vue 핵심
- [[vue]] - Vue.js 개요 및 기본 개념
- 반응형 시스템
- 컴포넌트 기초
- 템플릿 문법

---

## 🔧 컴포넌트 통신

### Props & Events
- [[props]] - 부모→자식 데이터 전달
- [[custom event]] - 자식→부모 이벤트 발생

### 양방향 바인딩
- [[input-v-model]] - v-model 디렉티브

---

## 📊 상태 관리

### Reactivity
- [[watcher로 데이터 감시하는 법]] - Watch와 WatchEffect
- Computed Properties
- Reactive vs Ref

### Vuex
- [[Vuex]] - 중앙 집중식 상태 관리
- Store 패턴
- Actions, Mutations, Getters

---

## ⚡ Composition API

### Script Setup
- [[script setup]] - 간결한 컴포넌트 작성
- Composables 패턴
- TypeScript 통합

### 고급 패턴
```dataview
LIST
FROM #vue AND #composition-api
```

---

## 🎨 실전 활용

### 프로젝트 구조
- 컴포넌트 설계 패턴
- 폴더 구조 best practices
- 코드 스플리팅

### 성능 최적화
- Lazy Loading
- Keep-Alive
- Virtual Scrolling

---

## 🚀 생태계

### 주요 라이브러리
- **Vue Router** - 라우팅
- **Pinia** - 차세대 상태 관리
- **VueUse** - Composition 유틸리티

### 개발 도구
- Vite
- Vue DevTools
- ESLint + Prettier

---

## 📚 학습 자료

### 공식 문서
- [Vue 3 공식 문서](https://vuejs.org/)
- [Composition API RFC](https://github.com/vuejs/rfcs/blob/master/active-rfcs/0013-composition-api.md)

### 관련 노트
```dataview
LIST
FROM #vue
WHERE !contains(file.name, "MOC")
SORT file.mtime DESC
```

---

## 🔗 관련 MOC
- → [[resource/topics/frontend/react/_React MOC|React MOC]]
- → [[resource/topics/frontend/typescript/_TypeScript MOC|TypeScript MOC]]

## 🎯 다음 학습 목표
- [ ] Pinia 실전 적용
- [ ] Vue 3 + TypeScript 프로젝트
- [ ] SSR with Nuxt 3
- [ ] Testing (Vitest + Vue Test Utils)
- [ ] 성능 최적화 실습

---
*Last updated: 2025-10-29*
