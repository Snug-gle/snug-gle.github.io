---
tags: [frontend, react, tanstack-query, infinite-scroll, intersection-observer, cursor-pagination, linkwave]
category: resource
created: 2026-03-18
related: [TanStack, typescript-api-layer-patterns]
---

# 🔍 useInfiniteQuery + IntersectionObserver 무한스크롤 패턴

## 📌 Situation / Symptom

메시지 히스토리 목록 페이지에서 실제 API를 연결할 때, 수백~수천 건의 데이터를 한 번에 가져오는 것은 비효율적이다. 사용자가 스크롤을 내릴 때마다 다음 페이지를 불러오는 무한스크롤이 필요하다.

백엔드는 cursor 기반 페이지네이션(`nextCursor` 포함)을 제공하므로, 프론트엔드도 커서 기반으로 맞춰야 한다.

---

## 🔍 Technical Analysis

### useInfiniteQuery 동작 원리

`useQuery`가 단일 페이지 데이터를 관리한다면, `useInfiniteQuery`는 여러 페이지 데이터를 누적 관리한다.

**핵심 개념**:

1. `queryFn`의 `pageParam` — 현재 페이지의 cursor 값 (첫 요청 시 `initialPageParam`)
2. `getNextPageParam(lastPage)` — 마지막 페이지의 응답에서 다음 cursor 추출. `undefined` 반환 시 더 이상 페이지 없음
3. `data.pages` — 누적된 모든 페이지 배열. `flatMap`으로 단일 배열로 펼쳐서 사용
4. `fetchNextPage()` — 다음 페이지 수동 요청
5. `hasNextPage` — `getNextPageParam`이 `undefined`가 아닌 값을 반환할 때 `true`

```typescript
const {
  data,
  fetchNextPage,
  hasNextPage,
  isFetchingNextPage,
  isLoading,
} = useInfiniteQuery({
  queryKey: ['sentMessages', filter],   // filter 포함 → 필터 변경 시 자동 재요청
  queryFn: ({ pageParam }) =>
    getSentMessages({ ...filter, cursor: pageParam }),
  getNextPageParam: (lastPage) => lastPage.nextCursor ?? undefined,
  initialPageParam: undefined,
});

// 누적 데이터 펼치기
const items = data?.pages.flatMap((page) => page.items) ?? [];
```

### IntersectionObserver 무한스크롤 연결

스크롤 이벤트(`scroll`) 방식은 호출 빈도가 높아 성능 부담이 있다. `IntersectionObserver`는 특정 DOM 요소가 뷰포트에 진입/이탈할 때만 콜백을 호출하므로 훨씬 효율적이다.

**구현 흐름**:
1. `loadMoreRef` — 목록 하단에 위치한 빈 div를 가리키는 ref
2. `IntersectionObserver` 인스턴스 생성 — 대상 요소가 뷰포트에 진입하면 `fetchNextPage()` 호출
3. `useEffect`에서 observer 등록/해제 관리

```typescript
const loadMoreRef = useRef<HTMLDivElement>(null);

useEffect(() => {
  const observer = new IntersectionObserver(
    (entries) => {
      if (entries[0].isIntersecting && hasNextPage && !isFetchingNextPage) {
        fetchNextPage();
      }
    },
    { threshold: 0.1 }
  );

  if (loadMoreRef.current) observer.observe(loadMoreRef.current);
  return () => observer.disconnect();
}, [hasNextPage, isFetchingNextPage, fetchNextPage]);
```

컴포넌트에서 ref 연결:
```tsx
<div ref={loadMoreRef} />  {/* 목록 하단 트리거 */}
```

### queryKey에 filter를 포함하는 이유

TanStack Query의 `queryKey`는 캐시의 식별자다. filter 값이 다르면 다른 요청이므로 다른 캐시 엔트리가 필요하다.

| queryKey | 상황 | 캐시 |
|----------|------|------|
| `['sentMessages', { status: 'SENT' }]` | 발송 완료 필터 | 캐시 A |
| `['sentMessages', { status: 'FAILED' }]` | 실패 필터 | 캐시 B |
| `['sentMessages', {}]` | 전체 | 캐시 C |

filter가 변경되면 자동으로 새 queryKey로 재요청이 발생하고, 이전 캐시는 staleTime 동안 유지된다.

> [!tip] Best Practice
> `useInfiniteQuery`의 `queryKey` 배열 두 번째 요소에 filter 객체를 통째로 넣는 것이 일반적이다. 이렇게 하면 filter의 어떤 필드가 바뀌어도 자동으로 재요청된다.

---

## 🛠 Solution

### useSentMessages 훅 전체 패턴

```typescript
export const useSentMessages = (filter: MessageHistoryParams) => {
  const loadMoreRef = useRef<HTMLDivElement>(null);

  const query = useInfiniteQuery({
    queryKey: ['sentMessages', filter],
    queryFn: ({ pageParam }) =>
      getSentMessages({ ...filter, cursor: pageParam }),
    getNextPageParam: (lastPage) => lastPage.nextCursor ?? undefined,
    initialPageParam: undefined,
  });

  useEffect(() => {
    const observer = new IntersectionObserver(
      ([entry]) => {
        if (entry.isIntersecting && query.hasNextPage && !query.isFetchingNextPage) {
          query.fetchNextPage();
        }
      },
      { threshold: 0.1 }
    );
    if (loadMoreRef.current) observer.observe(loadMoreRef.current);
    return () => observer.disconnect();
  }, [query.hasNextPage, query.isFetchingNextPage, query.fetchNextPage]);

  const items = query.data?.pages.flatMap((p) => p.items) ?? [];

  return { ...query, items, loadMoreRef };
};
```

### useCancelScheduled 패턴

```typescript
export const useCancelScheduled = () => {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (clientKey: string) => cancelScheduledMessage(clientKey),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['scheduledMessages'] });
      toast.success('예약이 취소되었습니다.');
    },
  });
};
```

> [!warning] isFetchingNextPage 체크 누락 주의
> IntersectionObserver 콜백에서 `isFetchingNextPage` 체크를 빠뜨리면, 이전 요청이 완료되기 전에 동일한 페이지를 중복 요청할 수 있다. 반드시 `hasNextPage && !isFetchingNextPage` 조합으로 가드해야 한다.

---

## 🔗 Related Concepts

- [[resource/topics/frontend/react/TanStack|TanStack Query — useQuery, useMutation, 캐싱 전략]]
- [[resource/topics/frontend/typescript/typescript-api-layer-patterns|TypeScript API 레이어 패턴]]
- [[resource/topics/database/cursor-pagination-linkwave|커서 기반 페이징 구현기]]
- [[resource/topics/frontend/react/react-large-table-optimization|React 19 대용량 테이블 최적화]]

---

## 📚 References

- [TanStack Query — useInfiniteQuery](https://tanstack.com/query/latest/docs/framework/react/reference/useInfiniteQuery)
- [MDN — Intersection Observer API](https://developer.mozilla.org/en-US/docs/Web/API/Intersection_Observer_API)
