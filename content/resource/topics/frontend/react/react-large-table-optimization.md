---
created: 2026-03-11
---
---
created: 2026-03-10
updated: 2026-03-10
tags:
  - frontend
  - react
  - tanstack
  - performance
  - optimization
---

# React 19 대용량 테이블 최적화기 — 렌더링 90% 단축 경험

> SI 프로젝트 구현 경험 기반. 10,000행 테이블에서 5초 블로킹을 0.5초로 줄인 최적화 과정을 정리합니다.
>
> *익명화: 실제 도메인 명칭을 일반화하여 기술합니다.*

---

## 문제 발견

성능 테스트 분석 도구에서 HTTP 요청 데이터를 테이블로 표시하는 기능을 구현했습니다. 개발 환경에서는 문제가 없었지만, 실제 데이터를 넣자 브라우저가 5초간 응답하지 않는 블로킹이 발생했습니다.

**원인 분석 (React DevTools Profiler)**:
- DOM 노드 수: 약 120,000개 (10,000행 × 12열)
- 초기 렌더링 시간: 4.8~5.2초
- 메모리 사용: 340MB (빈 상태 대비 +280MB)

문제는 명확했습니다. **모든 행을 한꺼번에 DOM에 렌더링**하고 있었습니다.

---

## 최적화 전략 수립

세 가지 접근을 순차적으로 적용했습니다:

1. **서버사이드 페이징** — 전체 데이터 한 번에 불러오지 않기
2. **클라이언트 가상화** — 화면에 보이는 행만 DOM에 렌더링
3. **React Query 캐싱** — 불필요한 재요청 제거

---

## Step 1: 서버사이드 페이징

```typescript
// hooks/useDataPagination.ts
export function useDataPagination(perfTestId: string | null) {
  const [currentPage, setCurrentPage] = useState(0);
  const pageSize = 1000;  // 100 → 500 → 1000으로 점진적 조정

  const { data, isLoading, isFetching } = useQuery({
    queryKey: ['data', perfTestId, currentPage],
    queryFn: () => fetchData(perfTestId!, { page: currentPage, size: pageSize }),
    enabled: !!perfTestId,
    staleTime: 1000 * 60 * 5,   // 5분간 캐시 유지
    gcTime: 1000 * 60 * 10,     // 10분간 메모리 보관
    placeholderData: keepPreviousData,  // 페이지 전환 시 깜빡임 방지
  });

  return { data, isLoading, isFetching, currentPage, setCurrentPage, pageSize };
}
```

**페이지 크기 결정 과정**:
- 100개: DOM 노드 수 감소, 하지만 페이지 전환이 너무 잦음 (UX 불편)
- 500개: 적당하지만 여전히 렌더링 체감 지연
- **1,000개**: 서버 응답 속도와 초기 렌더링의 균형점 (최종 선택)

---

## Step 2: TanStack Virtual 가상화

```typescript
import { useVirtualizer } from '@tanstack/react-virtual';

function DataTable({ data }: { data: RowData[] }) {
  const parentRef = useRef<HTMLDivElement>(null);

  const rowVirtualizer = useVirtualizer({
    count: data.length,
    getScrollElement: () => parentRef.current,
    estimateSize: () => 35,    // 행 높이 추정값 (px)
    overscan: 10,              // 화면 밖 미리 렌더링할 행 수
  });

  return (
    <div ref={parentRef} style={{ overflow: 'auto', height: '600px' }}>
      {/* 전체 스크롤 영역 확보 */}
      <div style={{ height: `${rowVirtualizer.getTotalSize()}px`, position: 'relative' }}>
        {rowVirtualizer.getVirtualItems().map((virtualRow) => (
          <div
            key={virtualRow.index}
            style={{
              position: 'absolute',
              top: 0,
              transform: `translateY(${virtualRow.start}px)`,
              height: `${virtualRow.size}px`,
            }}
          >
            <DataRow data={data[virtualRow.index]} />
          </div>
        ))}
      </div>
    </div>
  );
}
```

**가상화의 핵심 원리**:
- `getTotalSize()`: 전체 1,000개 행의 높이 합계 → 스크롤바 정확한 표시
- `getVirtualItems()`: 현재 뷰포트에 보이는 행만 반환 (약 17~20개)
- `overscan: 10`: 뷰포트 위아래로 10개씩 미리 렌더링 → 스크롤 시 빈 화면 방지
- 실제 DOM 노드: 1,000개 → 약 30~40개로 감소

---

## Step 3: React Query 캐싱 전략

```typescript
// 조건부 쿼리 — perfTestId 없으면 실행 안 함
const { data } = useQuery({
  queryKey: ['correlation-data', perfTestId, currentPage],
  queryFn: () => fetchCorrelationData(perfTestId!, currentPage),
  enabled: !!perfTestId,    // null/undefined이면 요청 안 함
  staleTime: 1000 * 60 * 5,
});

// 무한 루프 방지 — useEffect 의존성 배열 설계
React.useEffect(() => {
  setCurrentPage(0);  // ID가 바뀌면 페이지 초기화
  setFilters({});
}, [perfTestId]);    // currentPage는 의도적으로 제외 (포함하면 무한 루프)
//                    ↑ 코드 리뷰에서 "왜 제외했는가?" 질문 대비 주석 추가
```

**발견한 문제들과 해결**:

| 문제 | 원인 | 해결 |
|------|------|------|
| 같은 API 중복 호출 | 여러 컴포넌트에서 독립적 쿼리 | `queryKey` 공유 → 캐시 재사용 |
| perfTestId 없이 요청 | `enabled` 조건 없음 | `enabled: !!perfTestId` |
| 무한 루프 | `useEffect` 내 상태 변경 → 재트리거 | React Query로 전환 |

---

## Step 4: React.memo + CustomEvent 패턴

```tsx
// 불필요한 리렌더링 방지
const DataPanel = React.memo(({
  currentTestId,
  onSearchCompleted,
  data,
  isLoading,
}: DataPanelProps) => {

  // 다른 컴포넌트의 이벤트 수신 — Props drilling 없이
  React.useEffect(() => {
    const handleDataUpdated = (event: CustomEvent) => {
      const { testId, reset } = event.detail;
      if (testId === currentTestId) {
        setCurrentPage(0);
        if (reset) setSearchInput('');
      }
    };

    window.addEventListener('dataUpdated', handleDataUpdated as EventListener);
    return () => window.removeEventListener('dataUpdated', handleDataUpdated as EventListener);
  }, [currentTestId]);

  // ...
});
```

`React.memo`와 `CustomEvent`를 조합한 이유:
- `React.memo`: props가 변경되지 않으면 리렌더링 스킵
- `CustomEvent`: 컴포넌트 계층이 깊어도 중간 컴포넌트를 거치지 않고 직접 통신

---

## 최종 성능 비교

| 지표 | 최적화 전 | 최적화 후 | 개선율 |
|------|---------|---------|-------|
| 초기 렌더링 | 5초 | 0.5초 | **90% 단축** |
| DOM 노드 수 | ~120,000개 | ~360개 | 99.7% 감소 |
| 메모리 사용 | 340MB | 102MB | **70% 감소** |
| API 요청 수 | 기준 100% | 20% | **80% 감소** |

---

## 측정 기반 최적화 원칙

이 작업에서 얻은 가장 중요한 교훈은 **추측이 아닌 측정**입니다.

```
React DevTools Profiler → 렌더링 병목 컴포넌트 식별
Chrome DevTools Elements → DOM 노드 수 확인
Chrome DevTools Network → 중복 API 요청 발견
Chrome DevTools Performance → 메인 스레드 블로킹 측정
```

"느린 것 같다"는 느낌이 아니라, "초기 렌더링 4.8초, DOM 노드 120,000개"라는 숫자가 있어야 어디를 개선해야 할지, 개선 후 얼마나 좋아졌는지 명확하게 알 수 있습니다.

---

## 참고

- [[frontend/react/TanStack|TanStack 생태계 정리]]
- [[frontend/react/react-notes|React 패턴 노트]]
