---
tags: [typescript, frontend, api, async-await, generics, react, linkwave]
category: resource
created: 2026-03-16
related: [type-system-basics, cursor-pagination-linkwave]
---

# 🔍 TypeScript API 레이어 패턴 — async/await, 제네릭, 타입 어노테이션

## 📌 Situation / Symptom

React + TypeScript 프로젝트에서 백엔드 REST API를 호출하는 함수를 작성할 때 다음과 같은 질문이 생긴다:

- 함수 반환 타입을 어떻게 명시하는가?
- 비동기 함수의 타입은 `Promise<T>`인가, `T`인가?
- cursor 기반 페이지네이션 파라미터를 타입으로 어떻게 표현하는가?
- 인프라 응답 DTO와 UI에서 쓰는 타입을 어떻게 분리하는가?

---

## 🔍 Technical Analysis

### async 함수와 Promise<T>의 관계

`async` 키워드를 붙인 함수는 **반드시 `Promise<T>`를 반환**한다. `await`는 `Promise`가 resolve될 때까지 실행을 일시 중단한다.

```typescript
// async 함수의 반환 타입은 Promise<T>
async function fetchData(): Promise<string> {
    const result = await someAsyncOperation(); // string을 resolve하는 Promise
    return result;
}

// 화살표 함수도 동일
const fetchData = async (): Promise<string> => {
    return await someAsyncOperation();
};
```

| 상황 | 타입 |
|------|------|
| `async` 함수 선언 | 반환 타입: `Promise<T>` |
| `await` 표현식 | 결과 타입: `T` (Promise 벗겨짐) |
| 일반 함수 | 반환 타입: `T` (동기) |

### 제네릭 타입 파라미터 — `CursorPageResponse<T>`

백엔드의 커서 페이지네이션 응답은 항목 타입만 다르고 구조는 동일하다. 제네릭으로 재사용 가능한 타입을 만든다.

```typescript
// 제네릭 응답 타입 — T는 실제 호출 시 결정
interface CursorPageResponse<T> {
    items: T[];
    nextCursor: string | null;
    hasNext: boolean;
}

// MessageHistoryItem으로 타입 채우기
type MessageHistoryPage = CursorPageResponse<MessageHistoryItem>;

// API 함수에서 제네릭 사용
const getSentMessages = async (
    params: MessageHistoryParams
): Promise<CursorPageResponse<MessageHistoryItem>> => {
    const response = await apiClient.get('/message-history/sent', { params });
    return response.data;
};
```

### cursor 기반 파라미터 타입 설계

```typescript
// cursor가 있으면 다음 페이지, 없으면 첫 페이지
interface MessageHistoryParams {
    cursor?: string;       // optional — 첫 페이지는 생략
    status?: string;       // optional — 전체 조회 시 생략
    size?: number;         // optional — 기본값은 서버에서 처리
}
```

`?`(optional 프로퍼티)를 사용하면 첫 페이지 요청과 다음 페이지 요청을 동일한 타입으로 표현할 수 있다.

> [!tip] Best Practice
> API 파라미터 타입에서 `cursor`는 항상 `optional`로 정의한다. 첫 페이지 요청과 다음 페이지 요청을 동일 함수로 처리할 수 있어 UI 컴포넌트 로직이 단순해진다.

---

## 🛠 Solution

### 전체 API 레이어 구조

```typescript
// types/message.ts — 백엔드 응답 필드 기반 인터페이스
interface MessageHistoryItem {
    clientKey: string;
    title: string;
    status: MessageStatus;
    channelType: ChannelType;
    requestedAt: string;    // ISO 8601 string (백엔드 Instant → JSON)
    scheduledAt: string | null;
}

// api/messageApi.ts — cursor 파라미터 타입 + API 함수
interface MessageHistoryParams {
    cursor?: string;
    status?: string;
    size?: number;
}

const getSentMessages = async (
    params: MessageHistoryParams = {}
): Promise<CursorPageResponse<MessageHistoryItem>> => {
    const response = await apiClient.get('/api/v1/message-history/sent', { params });
    return response.data;
};

const getScheduledMessages = async (
    params: MessageHistoryParams = {}
): Promise<CursorPageResponse<MessageHistoryItem>> => {
    const response = await apiClient.get('/api/v1/message-history/scheduled', { params });
    return response.data;
};

const getMessageDetail = async (
    clientKey: string
): Promise<MessageHistoryItem> => {
    const response = await apiClient.get(`/api/v1/message-history/${clientKey}`);
    return response.data;
};
```

> [!warning] 주의 사항
> `requestedAt`, `scheduledAt` 같은 날짜 필드는 백엔드가 `Instant`를 JSON으로 직렬화하면 `string`으로 온다. UI에서 표시할 때 `new Date(item.requestedAt)`으로 변환 필요. `Date` 타입이 아님에 주의.

---

## 🔗 Related Concepts

- [[type-system-basics|TypeScript 타입 시스템 기초 가이드]] — 타입 어노테이션, `as const`, `typeof`, `keyof` 기초
- [[resource/topics/database/cursor-pagination-linkwave|커서 기반 페이징 구현기]] — 백엔드 cursor 구조 이해 (프론트 파라미터 설계 배경)
- [[resource/topics/frontend/react/TanStack|TanStack Query]] — 이 API 함수를 `useQuery`에 연결하는 패턴

---

## 📚 References

- [TypeScript Handbook — Generics](https://www.typescriptlang.org/docs/handbook/2/generics.html)
- [TypeScript Handbook — Functions](https://www.typescriptlang.org/docs/handbook/2/functions.html)
- [MDN — async function](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Statements/async_function)
