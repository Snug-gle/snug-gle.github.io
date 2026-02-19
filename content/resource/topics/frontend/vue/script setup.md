---
tags:
  - resource
  - vue
  - frontend
  - vue3
  - composition-api
category: frontend
topic: script setup
status: complete
created: 2024-01-01
modified: 2025-10-29
---
- <script setup/>은 Vue3에서 새롭게 도입된 Composion API의 SFC(Single File Component) 전용 문법
- Vue2에 없던 정적 컴파일 기반의  setup sugar 문법, 더 간경하고 빠른 코드 작성
## ✅ Vue 2와의 차이점

| 항목             | Vue 2                                 | Vue 3 (`<script setup>`) |
| -------------- | ------------------------------------- | ------------------------ |
| API 스타일        | Options API (`data`, `methods`, etc.) | Composition API          |
| `setup()` 사용   | 불가능 (별도 라이브러리 필요)                     | 기본 지원                    |
| `script setup` | ❌ 없음                                  | ✅ 있음                     |
| 코드 구조          | 명시적으로 나뉘어 있음                          | 함수 기반, 더 자유로움            |
| 반응형 상태         | `data()`에서 관리                         | `ref`, `reactive` 직접 사용  |
## ✅ 왜 사용하는가? 장점은?

|장점|설명|
|---|---|
|✅ 코드 간결|`setup()`, `return`, `export default` 안 써도 됨|
|✅ 자동 import 정리|선언된 변수는 `<template>`에서 바로 사용 가능|
|✅ 빠른 렌더링|컴파일 타임 최적화 가능|
|✅ 높은 가독성|선언형 구조로 명확해짐|
|✅ 타입스크립트 친화|`defineProps`, `defineEmits` 사용 시 타입 추론 우수|
