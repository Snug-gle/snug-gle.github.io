---
tags:
  - resource
  - react
  - frontend
  - tanstack-query
  - state-management
category: frontend
topic: TanStack
status: complete
created: 2024-01-01
updated: 2025-10-29
---

좋습니다! TanStack Query의 핵심 개념들을 이론과 함께 설명하고, axios와 비교해서 왜 더 좋은지 자세히 설명해드리겠습니다.

## 🧠 **1. QueryClient 기본 설정과 이론**

### **QueryClient란?**
QueryClient는 애플리케이션 전체의 서버 상태를 관리하는 중앙 집중식 저장소입니다.

```typescript
// 현재 구현
const queryClient = new QueryClient();

// 개선된 구현
const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      staleTime: 5 * 60 * 1000,        // 데이터가 "신선"하다고 간주되는 시간
      gcTime: 10 * 60 * 1000,          // 가비지 컬렉션 시간 (구 v4의 cacheTime)
      retry: 1,                         // 실패 시 재시도 횟수
      retryDelay: 1000,                 // 재시도 간격
      refetchOnWindowFocus: false,      // 윈도우 포커스 시 자동 리페치 방지
      refetchOnMount: true,             // 컴포넌트 마운트 시 리페치
    },
    mutations: {
      retry: 1,                         // 뮤테이션 실패 시 재시도
      retryDelay: 1000,
    },
  },
});
```

### **staleTime vs gcTime의 차이점**
```typescript
// staleTime: 데이터가 "신선"하다고 간주되는 시간
// 이 시간 내에는 리페치하지 않음
staleTime: 5 * 60 * 1000, // 5분

// gcTime: 메모리에서 데이터를 유지하는 시간
// 이 시간이 지나면 가비지 컬렉션됨
gcTime: 10 * 60 * 1000,   // 10분
```

## 🛡️ **2. 에러 바운더리와 전역 에러 처리**

### **에러 바운더리란?**
React에서 JavaScript 에러가 발생했을 때 전체 앱이 크래시되는 것을 방지하는 안전장치입니다.

```typescript
// 전역 에러 처리 설정
const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      onError: (error, query) => {
        console.error('Query error:', error);
        console.log('Failed query:', query.queryKey);
        
        // 에러 타입별 처리
        if (error.status === 401) {
          // 인증 에러 처리
          redirectToLogin();
        } else if (error.status === 500) {
          // 서버 에러 처리
          showServerErrorNotification();
        }
      },
    },
    mutations: {
      onError: (error, variables, context) => {
        console.error('Mutation error:', error);
        console.log('Failed variables:', variables);
        
        // 뮤테이션 실패 시 롤백 처리
        if (context?.previousData) {
          queryClient.setQueryData(query.queryKey, context.previousData);
        }
      },
    },
  },
});
```

### **컴포넌트별 에러 처리**
```typescript
// useQuery에서 에러 처리
const { data, error, isError } = useQuery({
  queryKey: ['testPlans'],
  queryFn: () => testPlanService.getAllTestPlans(),
  onError: (error) => {
    // 이 쿼리만의 특별한 에러 처리
    if (error.status === 404) {
      showEmptyStateMessage();
    }
  },
});

// 에러 상태에 따른 UI 렌더링
if (isError) {
  return <ErrorFallback error={error} />;
}
```

## 🛠️ **3. React Query DevTools**

### **DevTools란?**
개발 중에 쿼리와 뮤테이션의 상태를 실시간으로 모니터링할 수 있는 도구입니다.

```typescript
// 개발 환경에서만 DevTools 활성화
import { ReactQueryDevtools } from '@tanstack/react-query-devtools';

const App = () => (
  <QueryClientProvider client={queryClient}>
    {/* ... existing code ... */}
    
    {/* 개발 환경에서만 DevTools 표시 */}
    {process.env.NODE_ENV === 'development' && (
      <ReactQueryDevtools 
        initialIsOpen={false}        // 초기 상태 (닫힘)
        position="bottom-right"      // 위치
        buttonPosition="bottom-right" // 토글 버튼 위치
      />
    )}
  </QueryClientProvider>
);
```

### **DevTools로 확인할 수 있는 정보**
- 🔍 **Active Queries**: 현재 활성화된 쿼리들
- �� **Query Details**: 각 쿼리의 상세 정보
- �� **Cache**: 캐시된 데이터 상태
- ⚡ **Mutations**: 뮤테이션 상태
- �� **Performance**: 쿼리 성능 지표

## 🔄 **4. axios vs TanStack Query 비교**

### **기존 axios 방식의 문제점**

```typescript
// ❌ axios만 사용할 때의 문제점들

// 1. 상태 관리 복잡성
const [data, setData] = useState(null);
const [loading, setLoading] = useState(false);
const [error, setError] = useState(null);

const fetchData = async () => {
  setLoading(true);
  setError(null);
  try {
    const response = await axios.get('/api/test-plans');
    setData(response.data);
  } catch (err) {
    setError(err);
  } finally {
    setLoading(false);
  }
};

// 2. 중복 요청 방지 어려움
useEffect(() => {
  fetchData(); // 컴포넌트가 마운트될 때마다 호출
}, []);

// 3. 캐싱 없음 - 매번 새로 요청
// 4. 에러 처리 일관성 부족
// 5. 로딩 상태 관리 복잡
```

### **TanStack Query 방식의 장점**

```typescript
// ✅ TanStack Query 사용 시 장점들

// 1. 간단한 상태 관리
const { data, isLoading, error } = useQuery({
  queryKey: ['testPlans'],
  queryFn: () => testPlanService.getAllTestPlans(),
});

// 2. 자동 중복 요청 방지
// 같은 queryKey로 여러 컴포넌트에서 사용해도 한 번만 요청

// 3. 자동 캐싱
// staleTime 동안은 캐시된 데이터 사용

// 4. 백그라운드 업데이트
// 사용자가 보는 동안 백그라운드에서 최신 데이터 가져오기

// 5. 낙관적 업데이트
queryClient.setQueryData(['testPlans'], (oldData) => {
  // 즉시 UI 업데이트, 백그라운드에서 서버 동기화
  return oldData.map(test => 
    test.id === updatedTest.id ? updatedTest : test
  );
});
```

## 📊 **구체적인 비교 예시**

### **데이터 조회 비교**

```typescript
// ❌ axios 방식
const TestPlanList = () => {
  const [testPlans, setTestPlans] = useState([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState(null);

  useEffect(() => {
    const fetchTestPlans = async () => {
      setLoading(true);
      try {
        const response = await axios.get('/api/v1/test-plans/findAll');
        setTestPlans(response.data);
      } catch (err) {
        setError(err.message);
      } finally {
        setLoading(false);
      }
    };

    fetchTestPlans();
  }, []);

  if (loading) return <div>로딩 중...</div>;
  if (error) return <div>에러: {error}</div>;

  return (
    <div>
      {testPlans.map(plan => (
        <div key={plan.id}>{plan.name}</div>
      ))}
    </div>
  );
};

// ✅ TanStack Query 방식
const TestPlanList = () => {
  const { data: testPlans = [], isLoading, error } = useQuery({
    queryKey: ['testPlans'],
    queryFn: () => testPlanService.getAllTestPlans(),
  });

  if (isLoading) return <div>로딩 중...</div>;
  if (error) return <div>에러: {error.message}</div>;

  return (
    <div>
      {testPlans.map(plan => (
        <div key={plan.id}>{plan.name}</div>
      ))}
    </div>
  );
};
```

### **데이터 업데이트 비교**

```typescript
// ❌ axios 방식
const updateTestPlan = async (id, data) => {
  try {
    const response = await axios.put(`/api/v1/test-plans/${id}`, data);
    
    // 수동으로 로컬 상태 업데이트
    setTestPlans(prev => 
      prev.map(plan => 
        plan.id === id ? response.data : plan
      )
    );
    
    // 성공 메시지
    showSuccessMessage('업데이트 성공');
  } catch (error) {
    showErrorMessage('업데이트 실패');
  }
};

// ✅ TanStack Query 방식
const updateTestPlanMutation = useMutation({
  mutationFn: ({ id, data }) => testPlanService.updateTestPlan(id, data),
  onSuccess: (updatedTestPlan) => {
    // 자동으로 캐시 업데이트
    queryClient.setQueryData(['testPlans'], (oldData) => {
      if (oldData) {
        return oldData.map(test => 
          test.id === updatedTestPlan.id ? updatedTestPlan : test
        );
      }
      return oldData;
    });
    
    // 쿼리 무효화로 백그라운드 동기화
    queryClient.invalidateQueries({ queryKey: ['testPlans'] });
  },
  onError: (error) => {
    showErrorMessage('업데이트 실패');
  },
});
```

## 🎯 **TanStack Query의 핵심 장점 요약**

| 항목 | axios | TanStack Query | 설명 |
|------|-------|----------------|------|
| **상태 관리** | 수동 (useState 3개) | 자동 (useQuery 1개) | 로딩, 에러, 데이터 상태 자동 관리 |
| **캐싱** | 없음 | 자동 | staleTime 동안 캐시된 데이터 사용 |
| **중복 요청 방지** | 수동 구현 | 자동 | 같은 queryKey로 중복 요청 방지 |
| **백그라운드 업데이트** | 없음 | 자동 | 사용자 경험 향상 |
| **낙관적 업데이트** | 복잡 | 간단 | 즉시 UI 반영 후 서버 동기화 |
| **에러 처리** | 일관성 부족 | 일관성 | 전역 에러 처리 가능 |
| **타입 안전성** | 제한적 | 우수 | TypeScript와 완벽 통합 |
| **성능** | 기본 | 최적화 | 불필요한 리렌더링 방지 |

## 🚀 **결론**

TanStack Query는 **서버 상태 관리의 복잡성을 대폭 줄이고**, **사용자 경험을 크게 향상시키는** 현대적인 솔루션입니다. 

특히 **캐싱, 중복 요청 방지, 낙관적 업데이트** 등의 기능은 axios만으로는 구현하기 어려운 부분들이며, 이는 더 나은 사용자 경험과 개발자 경험을 제공합니다.

현재 프로젝트에서 이미 잘 구현되어 있으므로, 위의 개선사항들을 적용하면 더욱 견고하고 사용자 친화적인 애플리케이션이 될 것입니다! 🎉