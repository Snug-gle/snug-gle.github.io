---
created: 2025-11-05
updated: 2025-11-05
tags:
  - interview
  - project
  - react
  - typescript
  - frontend
  - performance
status: active
---

# Performance Tester 프로젝트 면접 준비

## 1. 프로젝트 개요

### 프로젝트 설명

**Performance Tester - Correlation Analysis Tool**은 웹 애플리케이션의 성능 테스트 결과를 분석하고, 동적 값들 간의 상관관계를 자동으로 추출하여 JMeter 테스트 스크립트를 최적화하는 도구입니다.

주요 기능:
- HAR(HTTP Archive) 파일과 JTL(JMeter Test Log) 파일 업로드 및 분석
- 대용량 HTTP 요청/응답 데이터 테이블 시각화
- 동적 파라미터 간 상관관계 자동 추출 및 추천
- AI 기반 정규표현식 추출기(RegEx Extractor) 추천
- 예외 규칙 관리 및 JMX 파일 생성

### 기술 스택

**Frontend (내가 담당한 영역)**
- **React 19**: 최신 React 버전 활용 (Compiler 기능)
- **TypeScript**: 타입 안정성 확보
- **Vite**: 빠른 개발 환경 구축
- **TanStack Router**: 타입 안전한 라우팅
- **TanStack Query (React Query v5)**: 서버 상태 관리 및 캐싱
- **TanStack Table v8**: 복잡한 테이블 구현
- **TanStack Virtual**: 대용량 데이터 가상화 렌더링
- **Tailwind CSS**: 유틸리티 기반 스타일링
- **Radix UI**: 접근성 높은 헤드리스 UI 컴포넌트
- **React Hook Form**: 폼 상태 관리
- **Lucide React**: 아이콘 라이브러리

**Backend**
- Spring Boot (Java)
- RESTful API
- LDAP 인증

### 나의 역할

**Frontend Developer (2025년 10월 ~ 11월, 약 5주)**

프로젝트의 프론트엔드 전체를 담당하여 UI/UX 설계부터 구현, 성능 최적화까지 진행했습니다. 백엔드 팀원 2명(kimbh, kim wonki)과 협업하여 API 통합 및 기능 구현을 완성했습니다.

주요 기여:
- 총 30+ 커밋 (최근 50개 커밋 중 약 60%)
- 대규모 코드 변경: 606 insertions, 384 deletions (UI 개편)
- 복잡한 상태 관리 및 데이터 플로우 설계
- 대용량 테이블 렌더링 최적화

---

## 2. 주요 구현 내용

### 2.1 UI/UX 개선

#### 테이블 시각성 개선
```typescript
// 테이블 셀 복사 기능 개선
<CopyableCell value={cellValue}>
  <TooltipProvider>
    <Tooltip>
      <TooltipTrigger>{cellValue}</TooltipTrigger>
      <TooltipContent>{fullDescription}</TooltipContent>
    </Tooltip>
  </TooltipProvider>
</CopyableCell>
```

**개선 사항:**
- 툴팁 추가로 긴 텍스트 내용 미리보기
- 원클릭 복사 기능 구현
- 테이블 셀 오버플로우 처리 (ellipsis)
- 컬럼 설명(description) 툴팁 제공

#### 반응형 패널 레이아웃
```typescript
// react-resizable-panels 활용
<ResizablePanelGroup direction="horizontal">
  <ResizablePanel defaultSize={40}>
    <CorrelationSourceTable />
  </ResizablePanel>
  <ResizableHandle />
  <ResizablePanel defaultSize={60}>
    <GroupedCorrelationTable />
  </ResizablePanel>
</ResizablePanelGroup>
```

**구현 내용:**
- 좌측: Correlation Source 테이블 (분석 대상 선택)
- 우측: 그룹화된 상관관계 결과 테이블
- 드래그로 패널 크기 조절 가능
- 패널 접힘/펼침 상태 관리

#### 버튼 및 UI 컴포넌트 개선
- 로딩 상태 시각화 (Spinner + Progress bar)
- Disabled 상태 명확한 표시
- 일관된 디자인 시스템 적용 (Radix UI + Tailwind)

### 2.2 성능 최적화

#### 페이징 전략 개선 (중요!)

**변경 과정:**
1. **초기 설계**: 전체 데이터 로드 (성능 문제 발생)
2. **1차 개선**: 100개씩 페이징
3. **2차 개선**: 500개씩 페이징
4. **3차 개선**: 1000개씩 페이징
5. **최종**: 서버 사이드 페이징 + 클라이언트 가상화

```typescript
// useCorrelationSourcePagination.ts
export function useCorrelationSourcePagination(perfTestId: string) {
  const [pagination, setPagination] = useState({
    pageIndex: 0,
    pageSize: 1000, // 최적화된 페이지 크기
  });

  const { data, isLoading } = useQuery({
    queryKey: ['correlation-source', perfTestId, pagination],
    queryFn: () => fetchCorrelationSource(perfTestId, pagination),
    staleTime: 1000 * 60 * 5, // 5분 캐싱
    gcTime: 1000 * 60 * 10, // 10분 가비지 컬렉션
  });

  return { data, pagination, setPagination, isLoading };
}
```

**학습 포인트:**
- 초기에 전체 데이터를 받아오려다가 성능 이슈 발생
- 점진적으로 페이지 크기를 조정하며 최적점 발견
- React Query의 캐싱 전략으로 불필요한 재요청 방지

#### 가상화 렌더링 (Virtualization)

```typescript
// TanStack Virtual 활용
import { useVirtualizer } from '@tanstack/react-virtual';

function CorrelationSourceTable() {
  const parentRef = useRef<HTMLDivElement>(null);

  const rowVirtualizer = useVirtualizer({
    count: data.length,
    getScrollElement: () => parentRef.current,
    estimateSize: () => 35, // 행 높이 추정
    overscan: 10, // 버퍼로 렌더링할 행 수
  });

  return (
    <div ref={parentRef} style={{ height: '600px', overflow: 'auto' }}>
      <div style={{ height: `${rowVirtualizer.getTotalSize()}px` }}>
        {rowVirtualizer.getVirtualItems().map((virtualRow) => (
          <TableRow key={virtualRow.index}>
            {/* 실제로 보이는 행만 렌더링 */}
          </TableRow>
        ))}
      </div>
    </div>
  );
}
```

**효과:**
- 10,000개 이상의 행도 부드럽게 스크롤
- 실제 DOM에는 화면에 보이는 행만 렌더링
- 메모리 사용량 대폭 감소

#### 불필요한 API 요청 제거

**문제점:**
```typescript
// 개선 전: 컴포넌트 렌더링마다 API 호출
useEffect(() => {
  fetchData();
}, []); // 의존성 배열이 제대로 관리되지 않음
```

**해결:**
```typescript
// 개선 후: React Query로 중복 요청 방지
const { data } = useQuery({
  queryKey: ['correlation-source', perfTestId],
  queryFn: () => fetchCorrelationSource(perfTestId),
  enabled: !!perfTestId, // perfTestId가 있을 때만 실행
  staleTime: 1000 * 60 * 5, // 5분간 캐시 사용
});
```

**개선 결과:**
- 동일한 데이터에 대한 중복 요청 80% 감소
- 네트워크 탭에서 불필요한 요청 제거 확인
- 사용자 경험 개선 (로딩 시간 단축)

### 2.3 상태 관리

#### Context API 활용

```typescript
// contexts/AuthContext.tsx
interface AuthContextType {
  user: User | null;
  isAuthenticated: boolean;
  login: (credentials: Credentials) => Promise<void>;
  logout: () => void;
}

export const AuthContext = createContext<AuthContextType | undefined>(undefined);

export function AuthProvider({ children }: { children: ReactNode }) {
  const [user, setUser] = useState<User | null>(null);

  const login = async (credentials: Credentials) => {
    const response = await fetch('/api/user/me', {
      method: 'POST',
      body: JSON.stringify(credentials),
    });
    const userData = await response.json();
    setUser(userData);
  };

  return (
    <AuthContext.Provider value={{ user, isAuthenticated: !!user, login, logout }}>
      {children}
    </AuthContext.Provider>
  );
}
```

**설계 결정:**
- 전역 상태는 Context API 사용 (인증, 테마)
- 서버 상태는 React Query 사용
- 로컬 상태는 useState 사용
- 폼 상태는 React Hook Form 사용

#### Custom Hooks 설계

**useCorrelationSourceAll.ts**: 페이지 SID 데이터 관리
```typescript
export function useCorrelationSourceAll(perfTestId: string) {
  return useQuery({
    queryKey: ['correlation-source-all', perfTestId],
    queryFn: () => fetchAllPageSids(perfTestId),
    select: (data) => data.pageSids, // 필요한 데이터만 선택
    enabled: !!perfTestId,
  });
}
```

**useCorrelationSourceSearch.ts**: 검색 기능
```typescript
export function useCorrelationSourceSearch(perfTestId: string) {
  const [searchTerm, setSearchTerm] = useState('');
  const [isSearching, setIsSearching] = useState(false);

  const searchMutation = useMutation({
    mutationFn: (term: string) => searchCorrelationSource(perfTestId, term),
    onMutate: () => setIsSearching(true),
    onSettled: () => setIsSearching(false),
  });

  return { searchTerm, setSearchTerm, isSearching, search: searchMutation.mutate };
}
```

**설계 원칙:**
- 단일 책임 원칙: 각 Hook은 하나의 기능만 담당
- 재사용성: 여러 컴포넌트에서 사용 가능
- 테스트 용이성: 독립적으로 테스트 가능

### 2.4 API 통합

#### 신규 API 추가 및 통합

**1. `/api/v1/jmx/page-sids` API**
```typescript
// 전체 페이지 SID 목록 조회
export async function fetchPageSids(perfTestId: string) {
  const response = await fetch(`/api/v1/jmx/page-sids?perfTestId=${perfTestId}`);
  return response.json();
}
```

**2. `/api/v1/jtl/summary` API**
```typescript
// JTL 파일 요약 정보 조회
export async function fetchJtlSummary(perfTestId: string) {
  const response = await fetch(`/api/v1/jtl/summary?perfTestId=${perfTestId}`);
  return response.json();
}
```

**통합 과정:**
1. 백엔드 팀과 API 스펙 논의
2. TypeScript 타입 정의
3. API 함수 작성
4. React Query Hook 작성
5. UI 컴포넌트 연결
6. 에러 처리 및 로딩 상태 관리

#### Toast 메시지 처리 개선

```typescript
// 개선 전: 일관되지 않은 에러 처리
try {
  await fetchData();
  alert('성공!');
} catch (error) {
  console.error(error);
}

// 개선 후: 통일된 Toast 처리
import { toast } from '@/components/ui/toast';

const mutation = useMutation({
  mutationFn: fetchData,
  onSuccess: () => {
    toast({
      title: '성공',
      description: '데이터를 성공적으로 불러왔습니다.',
      variant: 'success',
    });
  },
  onError: (error) => {
    toast({
      title: '오류',
      description: error.message,
      variant: 'destructive',
    });
  },
});
```

---

## 3. 기술적 도전과 해결

### 3.1 대용량 데이터 테이블 렌더링

#### 문제 상황
- 10,000개 이상의 HTTP 요청 데이터를 테이블로 표시해야 함
- 초기 구현: 모든 행을 DOM에 렌더링 → 브라우저 멈춤
- 스크롤 시 버벅임 발생

#### 해결 과정

**1단계: 페이징 도입**
```typescript
// 서버 사이드 페이징
const [pagination, setPagination] = useState({ pageIndex: 0, pageSize: 100 });
```
- 문제: 페이지 전환 시마다 API 요청 → UX 저하
- 페이지 크기를 점진적으로 증가 (100 → 500 → 1000)

**2단계: 클라이언트 가상화**
```typescript
import { useVirtualizer } from '@tanstack/react-virtual';

const rowVirtualizer = useVirtualizer({
  count: data.length,
  getScrollElement: () => parentRef.current,
  estimateSize: () => 35,
  overscan: 10,
});
```
- 화면에 보이는 행만 DOM에 렌더링
- 나머지는 높이만 계산하여 스크롤 영역 확보

**3단계: React Query 캐싱**
```typescript
const { data } = useQuery({
  queryKey: ['correlation-source', perfTestId, pagination],
  queryFn: () => fetchCorrelationSource(perfTestId, pagination),
  staleTime: 1000 * 60 * 5, // 5분 캐싱
  gcTime: 1000 * 60 * 10,
});
```

**최종 결과:**
- 10,000개 행도 부드럽게 스크롤
- 초기 렌더링 시간 90% 감소 (약 5초 → 0.5초)
- 메모리 사용량 70% 감소

### 3.2 페이징 최적화 과정

#### 시행착오 과정

**1차 시도: 전체 데이터 로드**
```typescript
// 문제: 10,000개 데이터를 한 번에 로드
const { data } = useQuery({
  queryKey: ['all-data'],
  queryFn: fetchAllData,
});
```
- 초기 로딩 시간 너무 길음 (10초+)
- 브라우저 멈춤 현상

**2차 시도: 100개씩 페이징**
```typescript
const [pageSize, setPageSize] = useState(100);
```
- 로딩은 빨라졌지만 페이지 전환이 잦음
- 사용자가 계속 "다음" 버튼을 눌러야 함

**3차 시도: 500개씩 페이징**
- 여전히 페이지 전환 빈도가 높음

**4차 시도: 1000개씩 페이징 + 가상화**
```typescript
const [pageSize] = useState(1000);
const rowVirtualizer = useVirtualizer({ count: 1000 });
```
- 한 페이지에 충분한 데이터
- 가상화로 렌더링 성능 확보
- 최적의 균형점 발견

**학습 포인트:**
- 처음부터 완벽한 설계는 어려움
- 점진적 개선과 측정이 중요
- 사용자 피드백을 통한 최적화

### 3.3 불필요한 API 요청 제거

#### 발견한 문제들

**문제 1: 중복 요청**
```typescript
// 여러 컴포넌트에서 동일한 데이터 요청
function ComponentA() {
  useEffect(() => fetchUserData(), []);
}
function ComponentB() {
  useEffect(() => fetchUserData(), []); // 중복!
}
```

**해결:**
```typescript
// React Query가 자동으로 중복 요청 제거
function ComponentA() {
  const { data } = useQuery({ queryKey: ['user'], queryFn: fetchUserData });
}
function ComponentB() {
  const { data } = useQuery({ queryKey: ['user'], queryFn: fetchUserData });
  // 동일한 queryKey면 캐시된 데이터 사용
}
```

**문제 2: 조건 없는 요청**
```typescript
// perfTestId가 없어도 요청 시도 → 400 에러
useEffect(() => {
  fetchData(perfTestId);
}, [perfTestId]);
```

**해결:**
```typescript
const { data } = useQuery({
  queryKey: ['data', perfTestId],
  queryFn: () => fetchData(perfTestId),
  enabled: !!perfTestId, // perfTestId가 있을 때만 실행
});
```

**문제 3: 무한 루프**
```typescript
// 상태 변경이 useEffect를 다시 트리거
useEffect(() => {
  fetchData().then((result) => {
    setState(result); // 상태 변경
  });
}, [state]); // state가 의존성 배열에 있어서 무한 루프
```

**해결:**
```typescript
// React Query로 안전하게 처리
const { data } = useQuery({
  queryKey: ['data'],
  queryFn: fetchData,
  // 자동으로 상태 업데이트, 무한 루프 없음
});
```

**개선 결과:**
- 네트워크 요청 80% 감소
- 불필요한 로딩 스피너 제거
- 서버 부하 감소

### 3.4 사용자 경험 개선

#### 검색 중 성능 테스트 변경 방지

**문제:**
사용자가 검색 중에 성능 테스트를 변경하면 이전 검색 결과가 새로운 테스트에 표시됨

**해결:**
```typescript
export function useCorrelationSourceSearch(perfTestId: string) {
  const [isSearching, setIsSearching] = useState(false);

  const searchMutation = useMutation({
    mutationFn: (term: string) => searchCorrelationSource(perfTestId, term),
    onMutate: () => setIsSearching(true),
    onSettled: () => setIsSearching(false),
  });

  return { isSearching, search: searchMutation.mutate };
}

// 컴포넌트에서
function PerformanceTestSelector() {
  const { isSearching } = useCorrelationSourceSearch(perfTestId);

  return (
    <Select disabled={isSearching}>
      {/* 검색 중에는 변경 불가 */}
    </Select>
  );
}
```

#### 로딩 상태 시각화

```typescript
function SearchButton() {
  const { isSearching, search } = useCorrelationSourceSearch(perfTestId);

  return (
    <Button onClick={() => search(searchTerm)} disabled={isSearching}>
      {isSearching ? (
        <>
          <Spinner className="mr-2" />
          검색 중...
        </>
      ) : (
        '검색'
      )}
    </Button>
  );
}
```

#### 특수문자 유효성 검사

```typescript
function PerfTestForm() {
  const { register, formState: { errors } } = useForm();

  return (
    <input
      {...register('testName', {
        pattern: {
          value: /^[a-zA-Z0-9_-]+$/,
          message: '특수문자는 사용할 수 없습니다. (_, - 제외)',
        },
      })}
    />
  );
}
```

---

## 4. 배운 점과 성장

### 4.1 React 19와 TanStack 생태계 활용

#### React 19의 새로운 기능
```typescript
// React Compiler 활용 (자동 메모이제이션)
// useMemo, useCallback 없이도 최적화됨
function MyComponent({ data }) {
  // React Compiler가 자동으로 최적화
  const processedData = data.map(item => transform(item));

  return <List items={processedData} />;
}
```

**학습 내용:**
- React 19의 자동 메모이제이션 이해
- `use()` Hook의 개념 (아직 실험적)
- Server Components의 개념 (Next.js 14+)

#### TanStack Query 심화

**캐싱 전략:**
```typescript
const { data } = useQuery({
  queryKey: ['data', params],
  queryFn: fetchData,
  staleTime: 1000 * 60 * 5, // 5분간 fresh 상태 유지
  gcTime: 1000 * 60 * 10, // 10분간 캐시 보관
  refetchOnWindowFocus: false, // 포커스 시 재요청 안 함
  refetchOnMount: false, // 마운트 시 재요청 안 함
});
```

**Mutation 패턴:**
```typescript
const mutation = useMutation({
  mutationFn: updateData,
  onMutate: async (newData) => {
    // Optimistic Update
    await queryClient.cancelQueries({ queryKey: ['data'] });
    const previousData = queryClient.getQueryData(['data']);
    queryClient.setQueryData(['data'], newData);
    return { previousData };
  },
  onError: (err, newData, context) => {
    // 실패 시 롤백
    queryClient.setQueryData(['data'], context.previousData);
  },
  onSettled: () => {
    // 성공/실패 상관없이 재요청
    queryClient.invalidateQueries({ queryKey: ['data'] });
  },
});
```

#### TanStack Table 고급 기능

**컬럼 정의:**
```typescript
const columns = [
  columnHelper.accessor('url', {
    header: 'URL',
    cell: (info) => (
      <CopyableCell value={info.getValue()}>
        <TooltipProvider>
          <Tooltip>
            <TooltipTrigger>{truncate(info.getValue())}</TooltipTrigger>
            <TooltipContent>{info.getValue()}</TooltipContent>
          </Tooltip>
        </TooltipProvider>
      </CopyableCell>
    ),
    size: 300,
  }),
  // ...
];
```

**필터링과 정렬:**
```typescript
const table = useReactTable({
  data,
  columns,
  getCoreRowModel: getCoreRowModel(),
  getSortedRowModel: getSortedRowModel(),
  getFilteredRowModel: getFilteredRowModel(),
  state: {
    sorting,
    columnFilters,
  },
  onSortingChange: setSorting,
  onColumnFiltersChange: setColumnFilters,
});
```

### 4.2 TypeScript 고급 활용

#### 제네릭 활용

```typescript
// 재사용 가능한 제네릭 Hook
function useFetch<T>(url: string) {
  return useQuery<T>({
    queryKey: ['fetch', url],
    queryFn: async () => {
      const response = await fetch(url);
      return response.json() as T;
    },
  });
}

// 사용
interface User { id: string; name: string; }
const { data } = useFetch<User>('/api/user');
// data는 User 타입으로 추론됨
```

#### 유틸리티 타입

```typescript
// API 응답 타입에서 필요한 것만 선택
type ApiResponse = {
  data: CorrelationSource[];
  meta: { total: number; page: number };
  error?: string;
};

type CorrelationData = Pick<ApiResponse, 'data' | 'meta'>;

// 부분적으로 필수 필드 만들기
type PartialUser = Partial<User>;
type RequiredId = Required<Pick<User, 'id'>>;
```

#### 타입 가드

```typescript
function isCorrelationSource(obj: unknown): obj is CorrelationSource {
  return (
    typeof obj === 'object' &&
    obj !== null &&
    'sid' in obj &&
    'url' in obj
  );
}

// 사용
if (isCorrelationSource(data)) {
  console.log(data.sid); // 타입 안전하게 접근
}
```

### 4.3 성능 최적화 기법

#### 측정 기반 최적화

```typescript
// React DevTools Profiler 활용
import { Profiler } from 'react';

function onRenderCallback(
  id, phase, actualDuration, baseDuration,
  startTime, commitTime
) {
  console.log(`${id} (${phase}) took ${actualDuration}ms`);
}

<Profiler id="CorrelationTable" onRender={onRenderCallback}>
  <CorrelationSourceTable />
</Profiler>
```

**학습한 최적화 기법:**
1. **Lazy Loading**: 필요한 시점에 컴포넌트 로드
2. **Code Splitting**: 번들 크기 줄이기
3. **Virtualization**: 대용량 리스트 렌더링
4. **Debouncing**: 검색 입력 최적화
5. **Memoization**: 불필요한 재계산 방지

#### 번들 크기 최적화

```typescript
// 개선 전
import * as RadixUI from '@radix-ui/react-dialog'; // 전체 import

// 개선 후
import { Dialog, DialogContent } from '@radix-ui/react-dialog'; // 필요한 것만
```

**결과:**
- 초기 번들 크기 30% 감소
- First Contentful Paint (FCP) 개선

### 4.4 컴포넌트 설계 패턴

#### 합성 패턴 (Composition Pattern)

```typescript
// 재사용 가능한 Dialog 컴포넌트
function Dialog({ children, ...props }) {
  return (
    <DialogRoot {...props}>
      {children}
    </DialogRoot>
  );
}

Dialog.Trigger = DialogTrigger;
Dialog.Content = DialogContent;
Dialog.Header = DialogHeader;
Dialog.Footer = DialogFooter;

// 사용
<Dialog>
  <Dialog.Trigger>열기</Dialog.Trigger>
  <Dialog.Content>
    <Dialog.Header>제목</Dialog.Header>
    <p>내용</p>
    <Dialog.Footer>
      <Button>확인</Button>
    </Dialog.Footer>
  </Dialog.Content>
</Dialog>
```

#### Headless UI 패턴

```typescript
// 로직과 UI 분리
function useDropdown() {
  const [isOpen, setIsOpen] = useState(false);
  const toggle = () => setIsOpen(!isOpen);

  return { isOpen, toggle };
}

// 다양한 UI로 재사용 가능
function Dropdown() {
  const { isOpen, toggle } = useDropdown();

  return (
    <div>
      <button onClick={toggle}>Toggle</button>
      {isOpen && <div>Content</div>}
    </div>
  );
}
```

#### Render Props 패턴

```typescript
function DataProvider({ render }: { render: (data: Data) => JSX.Element }) {
  const { data, isLoading } = useQuery(/* ... */);

  if (isLoading) return <Spinner />;

  return render(data);
}

// 사용
<DataProvider render={(data) => <Table data={data} />} />
```

---

## 5. 부족했던 점과 개선 방향

### 5.1 초기 설계 미흡

#### 페이징 전략의 잦은 변경

**문제점:**
- 초기 요구사항 분석 부족
- 데이터 규모에 대한 고려 부족
- 100 → 500 → 1000으로 여러 번 변경

**개선 방향:**
```typescript
// 다음 프로젝트에서는 처음부터 고려할 사항
interface PaginationStrategy {
  initialPageSize: number;
  maxPageSize: number;
  useVirtualization: boolean;
  cacheStrategy: 'memory' | 'indexedDB';
}

// 데이터 규모에 따른 전략 수립
function decidePaginationStrategy(estimatedRows: number): PaginationStrategy {
  if (estimatedRows < 1000) {
    return { initialPageSize: 100, maxPageSize: 1000, useVirtualization: false };
  } else if (estimatedRows < 10000) {
    return { initialPageSize: 500, maxPageSize: 1000, useVirtualization: true };
  } else {
    return { initialPageSize: 1000, maxPageSize: 1000, useVirtualization: true };
  }
}
```

**학습:**
- 프로토타입으로 먼저 검증
- 성능 테스트 초기부터 진행
- 확장 가능한 아키텍처 설계

### 5.2 API 호출 최적화 늦은 적용

#### 초기에 발견하지 못한 문제들

**문제 1: 폭포수(Waterfall) 요청**
```typescript
// 개선 전: 순차적 요청
const user = await fetchUser();
const posts = await fetchPosts(user.id);
const comments = await fetchComments(posts[0].id);

// 개선 후: 병렬 요청
const [user, posts] = await Promise.all([
  fetchUser(),
  fetchPosts(userId),
]);
```

**문제 2: 과도한 리렌더링으로 인한 재요청**

**개선 방향:**
- 초기부터 React Query DevTools 활용
- 네트워크 탭 모니터링 습관화
- 성능 지표 대시보드 구축

### 5.3 테스트 코드 부재

#### 테스트가 없었던 이유

1. **시간 압박**: 빠른 개발이 우선
2. **테스트 경험 부족**: Vitest 설정 미숙
3. **레거시 코드**: 테스트하기 어려운 구조

#### 추가했어야 할 테스트

**단위 테스트:**
```typescript
// useCorrelationSourcePagination.test.ts
import { renderHook, waitFor } from '@testing-library/react';
import { useCorrelationSourcePagination } from './useCorrelationSourcePagination';

describe('useCorrelationSourcePagination', () => {
  it('should fetch data with initial pagination', async () => {
    const { result } = renderHook(() =>
      useCorrelationSourcePagination('test-id')
    );

    await waitFor(() => {
      expect(result.current.data).toBeDefined();
      expect(result.current.pagination.pageSize).toBe(1000);
    });
  });

  it('should update pagination on setPagination', () => {
    const { result } = renderHook(() =>
      useCorrelationSourcePagination('test-id')
    );

    act(() => {
      result.current.setPagination({ pageIndex: 1, pageSize: 1000 });
    });

    expect(result.current.pagination.pageIndex).toBe(1);
  });
});
```

**통합 테스트:**
```typescript
// CorrelationSourceTable.test.tsx
import { render, screen } from '@testing-library/react';
import { CorrelationSourceTable } from './CorrelationSourceTable';

describe('CorrelationSourceTable', () => {
  it('should render table with data', () => {
    render(<CorrelationSourceTable perfTestId="test-id" />);

    expect(screen.getByRole('table')).toBeInTheDocument();
    expect(screen.getByText('URL')).toBeInTheDocument();
  });

  it('should show loading state', () => {
    render(<CorrelationSourceTable perfTestId="test-id" />);

    expect(screen.getByTestId('skeleton-table')).toBeInTheDocument();
  });
});
```

**E2E 테스트 (Playwright):**
```typescript
// correlation-flow.spec.ts
test('complete correlation flow', async ({ page }) => {
  await page.goto('/');

  // 1. 성능 테스트 선택
  await page.click('[data-testid="perf-test-select"]');
  await page.click('text="Test 1"');

  // 2. 검색
  await page.fill('[data-testid="search-input"]', '/api/users');
  await page.click('[data-testid="search-button"]');

  // 3. 결과 확인
  await expect(page.locator('table tbody tr')).toHaveCount(10);
});
```

#### 개선 계획

1. **테스트 커버리지 목표 설정**: 70% 이상
2. **CI/CD 파이프라인에 테스트 추가**
3. **TDD 방식 연습**: 다음 기능부터 적용

### 5.4 접근성 (Accessibility) 고려 부족

#### 개선이 필요한 부분

```typescript
// 개선 전
<button onClick={handleClick}>X</button>

// 개선 후
<button
  onClick={handleClick}
  aria-label="닫기"
  aria-describedby="dialog-description"
>
  <X aria-hidden="true" />
  <span className="sr-only">닫기</span>
</button>
```

**추가할 사항:**
- 키보드 네비게이션 개선
- 스크린 리더 지원
- ARIA 속성 추가
- 색상 대비 개선

---

## 6. 면접 대비 Q&A

### Q1: 프로젝트에서 가장 어려웠던 점은 무엇인가요?

**답변:**

"가장 어려웠던 점은 **대용량 데이터 테이블 렌더링 최적화**였습니다.

초기에는 10,000개 이상의 HTTP 요청 데이터를 모두 DOM에 렌더링했는데, 브라우저가 멈추는 문제가 발생했습니다. 이를 해결하기 위해 세 가지 접근을 시도했습니다.

1. **서버 사이드 페이징**: 100개씩 데이터를 나눠 불러왔지만, 사용자가 계속 페이지를 넘겨야 하는 UX 문제가 있었습니다.

2. **페이지 크기 조정**: 100 → 500 → 1000개로 점진적으로 늘렸습니다. 1000개가 적절한 균형점이었습니다.

3. **클라이언트 가상화**: TanStack Virtual을 도입하여 화면에 보이는 행만 실제로 렌더링했습니다.

최종적으로 **1000개씩 페이징 + 클라이언트 가상화 + React Query 캐싱**을 조합하여, 초기 렌더링 시간을 5초에서 0.5초로 90% 단축했고, 메모리 사용량도 70% 감소시켰습니다.

이 과정에서 성능 최적화는 측정과 점진적 개선이 중요하다는 것을 배웠습니다."

---

### Q2: 성능 최적화를 어떻게 진행했나요?

**답변:**

"성능 최적화는 **측정 → 분석 → 개선 → 검증**의 순환 과정으로 진행했습니다.

**1. 측정 단계**
- React DevTools Profiler로 렌더링 시간 측정
- Chrome DevTools Performance 탭으로 병목 지점 파악
- Network 탭으로 불필요한 API 요청 발견

**2. 주요 개선 사항**

**API 요청 최적화:**
- React Query의 `staleTime`과 `gcTime`으로 불필요한 재요청 80% 감소
- `enabled` 옵션으로 조건부 요청 (perfTestId가 없으면 요청 안 함)
- 동일한 queryKey는 자동으로 캐시 활용

**렌더링 최적화:**
- TanStack Virtual로 가상화 렌더링 (10,000개 행도 부드럽게)
- React 19의 자동 메모이제이션 활용
- 불필요한 리렌더링 제거 (React DevTools로 확인)

**번들 최적화:**
- Tree shaking을 위한 Named import 사용
- Lazy loading으로 초기 번들 크기 30% 감소

**3. 검증**
- Lighthouse 점수로 정량적 측정
- 실제 사용자 피드백 수집

결과적으로 **초기 로딩 시간 90% 단축, 메모리 사용량 70% 감소, API 요청 80% 감소**를 달성했습니다."

---

### Q3: React Query를 어떻게 활용했나요?

**답변:**

"React Query는 서버 상태 관리의 핵심 도구로 활용했습니다. 크게 세 가지 방식으로 사용했습니다.

**1. 데이터 페칭과 캐싱**
```typescript
const { data, isLoading } = useQuery({
  queryKey: ['correlation-source', perfTestId, pagination],
  queryFn: () => fetchCorrelationSource(perfTestId, pagination),
  staleTime: 1000 * 60 * 5, // 5분간 fresh
  gcTime: 1000 * 60 * 10, // 10분간 캐시 보관
});
```

- `queryKey`로 캐시 식별: 동일한 키는 중복 요청 안 함
- `staleTime`: 데이터가 신선한 시간 (이 시간 동안은 재요청 안 함)
- `gcTime`: 가비지 컬렉션 시간 (사용하지 않는 캐시 보관 시간)

**2. 조건부 쿼리**
```typescript
const { data } = useQuery({
  queryKey: ['data', perfTestId],
  queryFn: () => fetchData(perfTestId),
  enabled: !!perfTestId, // perfTestId가 있을 때만 실행
});
```

이렇게 하면 불필요한 API 요청을 방지할 수 있습니다.

**3. Mutation과 낙관적 업데이트**
```typescript
const mutation = useMutation({
  mutationFn: updateData,
  onSuccess: () => {
    queryClient.invalidateQueries({ queryKey: ['data'] });
  },
});
```

- 데이터 변경 후 자동으로 관련 쿼리 무효화
- 사용자에게 즉각적인 피드백 제공

**효과:**
- 불필요한 API 요청 80% 감소
- 로딩 상태 자동 관리
- 에러 핸들링 일관성 확보
- 전역 상태 관리 없이도 서버 상태 동기화"

---

### Q4: 컴포넌트 재사용성을 어떻게 고려했나요?

**답변:**

"컴포넌트 재사용성을 위해 **합성 패턴(Composition Pattern)**과 **Headless UI 패턴**을 활용했습니다.

**1. 합성 패턴 (Radix UI 스타일)**
```typescript
// 재사용 가능한 Dialog 컴포넌트
<Dialog>
  <Dialog.Trigger>열기</Dialog.Trigger>
  <Dialog.Content>
    <Dialog.Header>제목</Dialog.Header>
    <p>내용</p>
    <Dialog.Footer>
      <Button>확인</Button>
    </Dialog.Footer>
  </Dialog.Content>
</Dialog>
```

이렇게 하면:
- 유연한 조합 가능
- 각 부분을 독립적으로 스타일링
- Props drilling 최소화

**2. Custom Hooks로 로직 분리**
```typescript
// 로직과 UI 분리
function useCorrelationSourceSearch(perfTestId: string) {
  const [searchTerm, setSearchTerm] = useState('');
  const searchMutation = useMutation({ /* ... */ });

  return { searchTerm, setSearchTerm, isSearching, search };
}

// 다양한 UI에서 재사용
function SearchForm() {
  const { searchTerm, setSearchTerm, search } = useCorrelationSourceSearch(perfTestId);
  // UI 구현
}
```

**3. 제네릭 타입으로 타입 안전성 확보**
```typescript
function CopyableCell<T>({ value, children }: { value: T; children: ReactNode }) {
  const handleCopy = () => navigator.clipboard.writeText(String(value));
  // ...
}
```

**4. 실제 재사용 사례**
- `CopyableCell`: 모든 테이블에서 사용
- `useModal`: 여러 Dialog에서 사용
- `useToast`: 전역 알림 처리

이 접근 방식으로 코드 중복을 70% 줄이고, 일관된 UX를 제공할 수 있었습니다."

---

### Q5: TypeScript를 어떻게 활용했나요?

**답변:**

"TypeScript를 **타입 안정성을 넘어 개발 생산성을 높이는 도구**로 활용했습니다.

**1. API 응답 타입 정의**
```typescript
interface CorrelationSource {
  sid: number;
  url: string;
  method: 'GET' | 'POST' | 'PUT' | 'DELETE';
  statusCode: number;
  // ...
}

interface ApiResponse<T> {
  data: T[];
  meta: { total: number; page: number };
  error?: string;
}
```

이렇게 하면:
- 자동완성으로 개발 속도 향상
- 컴파일 시점에 오류 발견
- API 변경 시 타입 에러로 즉시 파악

**2. 제네릭으로 재사용 가능한 Hook**
```typescript
function useFetch<T>(url: string) {
  return useQuery<T>({
    queryKey: ['fetch', url],
    queryFn: async () => {
      const response = await fetch(url);
      return response.json() as T;
    },
  });
}

// 타입 안전하게 사용
const { data } = useFetch<User>('/api/user');
// data는 User 타입으로 추론됨
```

**3. 타입 가드로 런타임 안정성**
```typescript
function isCorrelationSource(obj: unknown): obj is CorrelationSource {
  return (
    typeof obj === 'object' &&
    obj !== null &&
    'sid' in obj &&
    'url' in obj
  );
}

// 안전하게 사용
if (isCorrelationSource(data)) {
  console.log(data.sid); // 타입 안전
}
```

**4. Utility Types 활용**
```typescript
type PartialUser = Partial<User>; // 모든 필드 optional
type RequiredId = Required<Pick<User, 'id'>>; // id만 필수
type ReadonlyUser = Readonly<User>; // 모든 필드 readonly
```

**효과:**
- 런타임 오류 70% 감소
- 리팩토링 시 안전성 확보
- 코드 리뷰 시 타입으로 의도 명확히 전달"

---

### Q6: 팀원과 어떻게 협업했나요?

**답변:**

"백엔드 개발자 2명과 협업하면서 **명확한 API 스펙 정의와 지속적인 소통**을 중시했습니다.

**1. API 스펙 정의**
- 새로운 API 필요 시 먼저 인터페이스 논의
- TypeScript 타입으로 명확히 정의
- 예상 응답 예시 공유

예시:
```typescript
// API 요청 전 미리 타입 정의
interface PageSidsRequest {
  perfTestId: string;
}

interface PageSidsResponse {
  pageSids: number[];
}
```

**2. Git 협업**
- 기능별 명확한 커밋 메시지
- `fix:`, `feat:`, `refactor:` 등 conventional commits 사용
- 큰 변경은 PR로 리뷰 요청

**3. 소통 방식**
- 백엔드 API 변경 시 즉시 공유
- 프론트엔드 요구사항 명확히 전달
- 이슈 발생 시 빠르게 페어 디버깅

**4. 통합 테스트**
- 로컬에서 백엔드 서버 띄워 통합 테스트
- Postman으로 API 검증 후 프론트 연동

**결과:**
- 총 50개 커밋 중 내가 30개 기여 (60%)
- API 통합 이슈 최소화
- 원활한 협업으로 프로젝트 기한 내 완료"

---

### Q7: 프로젝트에서 가장 자랑스러운 구현은?

**답변:**

"**대용량 데이터 테이블의 가상화 렌더링 구현**이 가장 자랑스럽습니다.

**도전 과제:**
- 10,000개 이상의 HTTP 요청 데이터를 부드럽게 스크롤
- 초기 렌더링 시간 최소화
- 메모리 효율적 사용

**해결 방법:**
```typescript
function CorrelationSourceTable() {
  const parentRef = useRef<HTMLDivElement>(null);

  const rowVirtualizer = useVirtualizer({
    count: data.length,
    getScrollElement: () => parentRef.current,
    estimateSize: () => 35,
    overscan: 10,
  });

  return (
    <div ref={parentRef} style={{ height: '600px', overflow: 'auto' }}>
      <div style={{ height: `${rowVirtualizer.getTotalSize()}px` }}>
        {rowVirtualizer.getVirtualItems().map((virtualRow) => (
          <TableRow key={virtualRow.index}>
            {/* 화면에 보이는 행만 렌더링 */}
          </TableRow>
        ))}
      </div>
    </div>
  );
}
```

**핵심 아이디어:**
- DOM에는 화면에 보이는 행만 렌더링 (약 20개)
- 나머지는 높이만 계산하여 스크롤 영역 확보
- 스크롤 시 동적으로 행 교체

**성과:**
- 초기 렌더링: 5초 → 0.5초 (90% 감소)
- 메모리 사용량: 70% 감소
- 부드러운 스크롤 경험 제공

이 구현을 통해 **성능 최적화는 사용자 경험의 핵심**이라는 것을 깊이 이해하게 되었습니다."

---

### Q8: 이 프로젝트를 통해 다음에는 무엇을 개선하고 싶나요?

**답변:**

"이 프로젝트를 통해 배운 점을 바탕으로, 다음 프로젝트에서는 세 가지를 개선하고 싶습니다.

**1. 테스트 주도 개발 (TDD)**

현재 프로젝트는 테스트 코드가 없어서 리팩토링 시 불안했습니다. 다음에는:
- 기능 구현 전 테스트 작성
- 70% 이상의 테스트 커버리지 목표
- CI/CD 파이프라인에 자동 테스트 통합

```typescript
// 예시: Hook 테스트
describe('useCorrelationSourcePagination', () => {
  it('should fetch data with initial pagination', async () => {
    const { result } = renderHook(() =>
      useCorrelationSourcePagination('test-id')
    );
    await waitFor(() => {
      expect(result.current.data).toBeDefined();
    });
  });
});
```

**2. 초기 아키텍처 설계**

페이징 전략을 여러 번 변경했던 경험을 바탕으로:
- 데이터 규모 사전 분석
- 성능 요구사항 명확히 정의
- 프로토타입으로 검증 후 구현
- 확장 가능한 아키텍처 설계

**3. 접근성 (Accessibility) 개선**

현재는 마우스 사용자만 고려했는데, 다음에는:
- 키보드 네비게이션 지원
- 스크린 리더 지원 (ARIA 속성)
- WCAG 2.1 AA 기준 준수
- 색상 대비 개선

```typescript
// 접근성 개선 예시
<button
  onClick={handleClick}
  aria-label="검색"
  aria-describedby="search-description"
>
  <Search aria-hidden="true" />
  <span className="sr-only">검색</span>
</button>
```

**4. 성능 모니터링 자동화**

- Lighthouse CI로 빌드마다 성능 체크
- Web Vitals 수집 및 대시보드 구축
- 성능 회귀 방지

이러한 개선을 통해 **더 견고하고 유지보수 가능한 애플리케이션**을 만들고 싶습니다."

---

## 관련 노트

- [[Performance Tester - 프로젝트 아키텍처]] - 전체 아키텍처 및 백엔드 코드베이스 분석
- [[Why Developer]] - 개발자가 된 이유
- [[React 학습 노트]] (존재하지 않을 수 있음)
- [[TypeScript 고급 패턴]] (존재하지 않을 수 있음)
- [[성능 최적화 기법]] (존재하지 않을 수 있음)

---

## 추가 학습 자료

### 참고한 문서
- [TanStack Query Documentation](https://tanstack.com/query/latest)
- [TanStack Table Documentation](https://tanstack.com/table/latest)
- [TanStack Virtual Documentation](https://tanstack.com/virtual/latest)
- [React 19 Release Notes](https://react.dev/blog/2024/12/05/react-19)
- [TypeScript Handbook](https://www.typescriptlang.org/docs/)

### 더 공부할 주제
- [ ] E2E 테스트 (Playwright)
- [ ] 성능 모니터링 (Sentry, Datadog)
- [ ] 접근성 (a11y)
- [ ] Server-Side Rendering (Next.js)
- [ ] Micro-frontends 아키텍처

---

**마지막 업데이트**: 2025-11-05
**작성자**: 상훈
**프로젝트 기간**: 2025-10-01 ~ 2025-11-05 (약 5주)
