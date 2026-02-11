---
created: 2025-12-26
up: "[[resource/topics/frontend/typescript/_TypeScript MOC]]"
tags: [typescript, type-system, frontend]
---
# TypeScript 타입 시스템 기초 가이드

## 목차
1. [타입이란?](#1-타입이란)
2. [타입 추론 (Type Inference)](#2-타입-추론-type-inference)
3. [리터럴 타입 (Literal Types)](#3-리터럴-타입-literal-types)
4. [const와 타입 추론](#4-const와-타입-추론)
5. [객체와 타입 추론](#5-객체와-타입-추론)
6. [as const의 역할](#6-as-const의-역할)
7. [typeof 연산자](#7-typeof-연산자)
8. [keyof 연산자](#8-keyof-연산자)
9. [인덱스 접근 타입 (Indexed Access Types)](#9-인덱스-접근-타입-indexed-access-types)
10. [복잡한 조합 이해하기](#10-복잡한-조합-이해하기)
11. [실전 예시](#11-실전-예시)

---

## 1. 타입이란?

타입은 값의 종류를 나타냅니다.

```typescript
// JavaScript (타입 없음)
let name = "홍길동"        // 그냥 값
let age = 30               // 그냥 값

// TypeScript (타입 있음)
let name: string = "홍길동"  // name은 string 타입
let age: number = 30         // age는 number 타입
```

---

## 2. 타입 추론 (Type Inference)

TypeScript는 타입을 자동으로 추론합니다.

```typescript
// 타입을 명시하지 않아도 TypeScript가 알아서 추론
let name = "홍길동"  // TypeScript가 자동으로 string 타입으로 추론
let age = 30         // TypeScript가 자동으로 number 타입으로 추론

// 이렇게 사용하면 에러
name = 123  // ❌ 에러! string에 number를 할당할 수 없음
age = "30"  // ❌ 에러! number에 string을 할당할 수 없음
```

---

## 3. 리터럴 타입 (Literal Types)

리터럴 타입은 정확한 값을 타입으로 사용합니다.

```typescript
// 일반적인 타입
let name: string = "홍길동"  // name은 "어떤 문자열이든" 가능
name = "김철수"  // ✅ OK
name = "박영희"  // ✅ OK

// 리터럴 타입 (정확한 값만 허용)
let status: "pending" = "pending"  // status는 오직 "pending"만 가능
status = "approved"  // ❌ 에러! "pending"만 허용

// 유니온 타입 (여러 리터럴 중 하나)
let status2: "pending" | "approved" | "rejected" = "pending"
status2 = "approved"   // ✅ OK
status2 = "rejected"   // ✅ OK
status2 = "cancelled"  // ❌ 에러!
```

---

## 4. const와 타입 추론

`const`로 선언하면 값이 고정되어 리터럴 타입으로 추론됩니다.

```typescript
// let 사용 - 넓은 타입으로 추론
let value = "hello"
// value의 타입: string (어떤 문자열이든 가능)
value = "world"  // ✅ OK

// const 사용 - 리터럴 타입으로 추론
const value2 = "hello"
// value2의 타입: "hello" (정확히 "hello"만 가능)
// value2 = "world"  // ❌ 에러! const는 재할당 불가
```

### 왜 이런 차이가 생기나?

TypeScript의 타입 추론 규칙:

```typescript
// const: 값이 변경 불가능하므로 정확한 리터럴 타입으로 추론
const value = 'hello'  // 타입: 'hello'
// value = 'world'  // ❌ 에러! const는 재할당 불가

// let: 값이 변경 가능하므로 넓은 타입으로 추론
let value2 = 'hello'   // 타입: string
value2 = 'world'       // ✅ OK! string이면 뭐든 가능
```

---

## 5. 객체와 타입 추론

객체는 `const`여도 프로퍼티가 변경 가능하면 넓은 타입으로 추론됩니다.

```typescript
// 객체 - const여도 프로퍼티는 변경 가능
const person = {
  name: "홍길동",
  age: 30
}
// person.name의 타입: string (넓은 타입)
// person.age의 타입: number (넓은 타입)
person.name = "김철수"  // ✅ OK (string이면 뭐든 가능)
person.age = 25         // ✅ OK (number면 뭐든 가능)
```

---

## 6. as const의 역할

`as const`를 사용하면 객체의 모든 값을 리터럴 타입으로 고정합니다.

### 기본 사용법

```typescript
// as const 없이
const ErrorCode = {
  ERROR: "E000",
  SUCCESS: "S000"
}
// ErrorCode.ERROR의 타입: string (넓은 타입)

// as const 사용
const ErrorCode = {
  ERROR: "E000",
  SUCCESS: "S000"
} as const
// ErrorCode.ERROR의 타입: "E000" (리터럴 타입)
// ErrorCode.SUCCESS의 타입: "S000" (리터럴 타입)
```

### 타입 안정성 비교

```typescript
// ❌ as const 없이 - 타입 안정성 부족
const Status = {
  PENDING: 'pending',
  APPROVED: 'approved',
  REJECTED: 'rejected',
}
// Status.PENDING의 타입: string (너무 넓음)

function updateStatus(status: 'pending' | 'approved' | 'rejected') {
  // ...
}

updateStatus(Status.PENDING)  // ❌ 에러! string은 리터럴 유니온에 할당 불가

// ✅ as const 사용 - 타입 안정성 확보
const Status = {
  PENDING: 'pending',
  APPROVED: 'approved',
  REJECTED: 'rejected',
} as const
// Status.PENDING의 타입: 'pending' (정확한 리터럴)

updateStatus(Status.PENDING)  // ✅ OK!
```

### 객체의 경우

```typescript
// 객체의 경우
const obj = {
  name: 'John',
  age: 30
}
type ObjType = typeof obj
// 타입: { name: string, age: number }
// (객체는 const여도 프로퍼티가 변경 가능하므로 넓은 타입)

// as const를 사용하면
const obj2 = {
  name: 'John',
  age: 30
} as const
type ObjType2 = typeof obj2
// 타입: { readonly name: 'John', readonly age: 30 }
// (모든 값이 리터럴 타입으로 고정됨)
```

---

## 7. typeof 연산자

`typeof`는 값의 타입을 추출합니다. (JavaScript의 `typeof`와 다름)

### 기본 사용법

```typescript
const value = "hello"

// JavaScript의 typeof (런타임)
console.log(typeof value)  // 출력: "string"

// TypeScript의 typeof (컴파일 타임, 타입 레벨)
type ValueType = typeof value
// ValueType의 타입: "hello" (리터럴 타입)
```

### 객체에서 사용

```typescript
const person = {
  name: "홍길동",
  age: 30
}

type PersonType = typeof person
// PersonType의 타입: { name: string, age: number }
```

### 출처

- **TypeScript 1.0** (2012년)에서 도입
- JavaScript의 `typeof`와는 다름 (TypeScript는 타입 레벨에서 동작)

---

## 8. keyof 연산자

`keyof`는 객체 타입의 모든 키를 유니온 타입으로 만듭니다.

### 기본 사용법

```typescript
type Person = {
  name: string
  age: number
  city: string
}

type PersonKeys = keyof Person
// PersonKeys의 타입: "name" | "age" | "city"
```

### 실제 객체에서 사용

```typescript
const person = {
  name: "홍길동",
  age: 30
}

type PersonKeys = keyof typeof person
// 1단계: typeof person → { name: string, age: number }
// 2단계: keyof { name: string, age: number } → "name" | "age"
// 결과: "name" | "age"
```

### 출처

- **TypeScript 2.1** (2016년)에서 도입

---

## 9. 인덱스 접근 타입 (Indexed Access Types)

배열처럼 타입에 접근해 특정 프로퍼티의 타입을 추출합니다.

### 기본 사용법

```typescript
type Person = {
  name: string
  age: number
}

type NameType = Person["name"]  // 타입: string
type AgeType = Person["age"]    // 타입: number
```

### 여러 키를 사용

```typescript
type Person = {
  name: string
  age: number
  city: string
}

type NameOrAge = Person["name" | "age"]
// 타입: string | number
```

### 출처

- **TypeScript 2.1** (2016년)에서 도입

---

## 10. 복잡한 조합 이해하기

이제 `typeof ErrorCode[keyof typeof ErrorCode]`를 단계별로 분해합니다.

### 예시 객체

```typescript
export const ErrorCode = {
  INTERNAL_SERVER_ERROR: 'E000',
  INVALID_INPUT: 'E001',
  USER_NOT_FOUND: 'U001',
} as const
```

### 단계 1: `typeof ErrorCode`

```typescript
type Step1 = typeof ErrorCode
// 결과:
// {
//   readonly INTERNAL_SERVER_ERROR: 'E000',
//   readonly INVALID_INPUT: 'E001',
//   readonly USER_NOT_FOUND: 'U001',
// }
```

### 단계 2: `keyof typeof ErrorCode`

```typescript
type Step2 = keyof typeof ErrorCode
// 결과: 'INTERNAL_SERVER_ERROR' | 'INVALID_INPUT' | 'USER_NOT_FOUND'
```

### 단계 3: `typeof ErrorCode[keyof typeof ErrorCode]`

```typescript
type Step3 = typeof ErrorCode[keyof typeof ErrorCode]
// 이것은 다음과 같습니다:
// typeof ErrorCode['INTERNAL_SERVER_ERROR' | 'INVALID_INPUT' | 'USER_NOT_FOUND']
// = typeof ErrorCode['INTERNAL_SERVER_ERROR'] | typeof ErrorCode['INVALID_INPUT'] | typeof ErrorCode['USER_NOT_FOUND']
// = 'E000' | 'E001' | 'U001'
```

### 전체 흐름 정리

```typescript
// 1. 객체를 as const로 리터럴 타입 고정
const ErrorCode = {
  INTERNAL_SERVER_ERROR: 'E000',
  INVALID_INPUT: 'E001',
} as const

// 2. 객체의 타입 추출
type ErrorCodeObject = typeof ErrorCode
// { readonly INTERNAL_SERVER_ERROR: 'E000', readonly INVALID_INPUT: 'E001' }

// 3. 객체의 모든 키 추출
type ErrorCodeKeys = keyof typeof ErrorCode
// 'INTERNAL_SERVER_ERROR' | 'INVALID_INPUT'

// 4. 객체의 모든 값 추출 (최종 목표!)
type ErrorCodeType = typeof ErrorCode[keyof typeof ErrorCode]
// 'E000' | 'E001'
```

---

## 11. 실전 예시

### 예시 1: 에러 코드 관리

```typescript
// 1. 에러 코드 정의
const ErrorCode = {
  NOT_FOUND: 'E404',
  UNAUTHORIZED: 'E401',
} as const

// 2. 모든 에러 코드 값의 타입 자동 생성
type ErrorCodeType = typeof ErrorCode[keyof typeof ErrorCode]
// 타입: 'E404' | 'E401'

// 3. 타입 안전하게 사용
function handleError(code: ErrorCodeType) {
  if (code === ErrorCode.NOT_FOUND) {
    // TypeScript가 code가 'E404'인지 정확히 알고 있음
  }
}

handleError('E404')              // ✅ OK
handleError(ErrorCode.NOT_FOUND) // ✅ OK
handleError('E999')              // ❌ 에러! ErrorCode에 없는 값
```

### 예시 2: API 엔드포인트 관리

```typescript
// ✅ as const로 API 경로 타입 안정성 확보
export const API_ENDPOINTS = {
  USERS: '/api/v1/users',
  LOGIN: '/api/v1/auth/login',
  LOGOUT: '/api/v1/auth/logout',
} as const

// 타입: '/api/v1/users' | '/api/v1/auth/login' | '/api/v1/auth/logout'
type Endpoint = typeof API_ENDPOINTS[keyof typeof API_ENDPOINTS]

function fetchAPI(endpoint: Endpoint) {
  // endpoint는 정확한 경로만 허용
}

fetchAPI(API_ENDPOINTS.USERS)  // ✅ OK
fetchAPI('/api/v1/users')      // ✅ OK (같은 리터럴)
fetchAPI('/wrong/path')        // ❌ 에러!
```

### 예시 3: 상태 관리

```typescript
const Status = {
  IDLE: 'idle',
  LOADING: 'loading',
  SUCCESS: 'success',
  ERROR: 'error',
} as const

type StatusType = typeof Status[keyof typeof Status]
// 타입: 'idle' | 'loading' | 'success' | 'error'
```

### 예시 4: 액션 타입 (Redux 스타일)

```typescript
const ActionTypes = {
  FETCH_START: 'FETCH_START',
  FETCH_SUCCESS: 'FETCH_SUCCESS',
  FETCH_ERROR: 'FETCH_ERROR',
} as const

type ActionType = typeof ActionTypes[keyof typeof ActionTypes]
```

### 예시 5: 테마

```typescript
const Themes = {
  LIGHT: 'light',
  DARK: 'dark',
  AUTO: 'auto',
} as const

type ThemeType = typeof Themes[keyof typeof Themes]
```

---

## 핵심 정리

1. **`const`** = 값 고정 → 리터럴 타입 추론
2. **`as const`** = 객체의 모든 값을 리터럴 타입으로 고정
3. **`typeof`** = 값의 타입 추출
4. **`keyof`** = 객체 타입의 모든 키를 유니온으로
5. **`타입[키]`** = 특정 프로퍼티의 타입 추출
6. **`typeof 객체[keyof typeof 객체]`** = 객체의 모든 값의 유니온 타입

---

## 타입 안정성을 위한 패턴

### 왜 이 패턴이 인기인가?

```typescript
// ❌ 수동으로 타입 작성 (유지보수 어려움)
const ErrorCode = {
  INTERNAL_SERVER_ERROR: 'E000',
  INVALID_INPUT: 'E001',
} as const

type ErrorCodeType = 'E000' | 'E001'  // 수동 작성
// ErrorCode에 값을 추가하면 타입도 수동으로 수정해야 함

// ✅ 자동으로 타입 추출 (DRY 원칙)
type ErrorCodeType = typeof ErrorCode[keyof typeof ErrorCode]
// ErrorCode를 수정하면 타입도 자동 업데이트!
```

### 타입 안정성의 이점

1. **컴파일 타임 에러 발견**: 잘못된 값 사용 시 즉시 에러
2. **자동완성 지원**: IDE에서 정확한 값만 제안
3. **리팩토링 안전성**: 값 변경 시 타입도 자동 업데이트
4. **문서화 효과**: 타입 자체가 문서 역할

---

## 참고 자료

- [TypeScript 공식 문서 - typeof](https://www.typescriptlang.org/docs/handbook/2/typeof-types.html)
- [TypeScript 공식 문서 - keyof](https://www.typescriptlang.org/docs/handbook/2/keyof-types.html)
- [TypeScript 공식 문서 - Indexed Access Types](https://www.typescriptlang.org/docs/handbook/2/indexed-access-types.html)
- [TypeScript 공식 문서 - const assertions](https://www.typescriptlang.org/docs/handbook/release-notes/typescript-3-4.html#const-assertions)

---

## 연습 문제

1. 다음 코드에서 `StatusType`의 타입은 무엇일까요?
```typescript
const Status = {
  PENDING: 'pending',
  APPROVED: 'approved',
} as const

type StatusType = typeof Status[keyof typeof Status]
```

2. `as const`를 제거하면 `StatusType`의 타입은 어떻게 변할까요?

3. 다음 코드를 완성해보세요:
```typescript
const Colors = {
  RED: '#ff0000',
  GREEN: '#00ff00',
  BLUE: '#0000ff',
} as const

// Colors의 모든 값의 타입을 추출하는 타입을 만들어보세요
type ColorType = ???
```

---

*작성일: 2024년*
*마지막 업데이트: 2024년*

