---
created: 2026-02-23
---
# Zustand vs TanStack Query — 상태 출처에 따라 도구를 나눈다

> 2026-02-23 | Linkwave Phase 4 아키텍처 리팩토링

---

## 왜 이 글을 쓰는가

오늘 오전에 주소록 Zustand 스토어를 설계하면서 `entities(Record<string, Contact>)`, `ids(Array)`, `groups`, `loading`을 넣었다. 오후에 가이드 문서를 검토하다가 이것이 아키텍처 원칙 위반임을 발견했다.

수정하면서 "왜 이 결정이 맞는가?"를 정리하기 위해 쓴다.

---

## 문제: 서버 상태를 Zustand에 넣으면 생기는 일

Redux 시대부터 내려온 패턴이 있다. API 응답을 받으면 전역 스토어에 저장하고, 컴포넌트는 스토어에서 읽는다.

```typescript
// 이렇게 짜면 안 되는 이유를 이제 안다
const useContactStore = create((set) => ({
  entities: {} as Record<string, Contact>, // 서버 데이터
  ids: [] as string[],                     // 서버 데이터
  loading: false,

  fetchContacts: async () => {
    set({ loading: true })
    const data = await api.getContacts()
    set({
      entities: Object.fromEntries(data.map(c => [c.id, c])),
      ids: data.map(c => c.id),
      loading: false,
    })
  }
}))
```

이 코드의 문제를 하나씩 나열하면:

1. **캐시 만료를 직접 판단해야 한다.** 데이터가 1분 전에 받아온 건데 여전히 유효한가? 직접 판단 로직을 써야 한다.
2. **중복 요청을 직접 막아야 한다.** 두 컴포넌트가 동시에 `fetchContacts`를 호출하면?
3. **에러 상태도 직접 관리한다.** `loading` 옆에 `error`도 따로 저장해야 한다.
4. **재조회 타이밍을 직접 결정한다.** 연락처를 삭제한 뒤 목록을 언제 다시 fetch할지 직접 구현한다.

결국 스토어 코드의 절반이 "서버와 동기화 유지"를 위한 코드가 된다.

---

## 해결: 상태의 출처에 따라 다른 도구

```
서버에서 온 데이터       → TanStack Query  (캐싱, 재조회, 만료, 에러 자동 처리)
클라이언트에만 있는 상태  → Zustand        (UI 제어, 폼 상태, 선택값)
```

**수정 전 (Zustand에 서버 상태)**:
```typescript
entities, ids, groups, loading, setLoading, fetchContacts
```

**수정 후 (UI 상태만)**:
```typescript
const useAddressBookStore = create<AddressBookUIState>((set) => ({
  selectedContactId: null,  // 어떤 행이 선택됐는가
  selectedGroupId: null,    // 어떤 그룹 탭인가
  filter: { search: '' },   // 검색창 텍스트

  setSelectedContactId: (id) => set({ selectedContactId: id }),
  setFilter: (filter) => set({ filter }),
  resetFilter: () => set({ filter: { search: '' } }),
}))
```

서버 데이터는 TanStack Query가 담당한다:

```typescript
// O(1) 접근이 필요하다면 Query 캐시가 그 역할을 한다
const { data: contacts, isLoading } = useQuery({
  queryKey: ['contacts', filter],
  queryFn: () => addressBookApi.getContacts(filter),
  staleTime: 30_000, // 30초 후 자동 만료 → 재요청
})
```

> 냉장고(Query 캐시)에 있는 음식을 책상 위에도 꺼내놓으면, 어느 쪽이 더 신선한지 매번 확인해야 한다.

---

## 동시에 적용한 것: useMutation 표준화

같은 원칙이 "쓰기 작업"에도 적용된다.

**수정 전 패턴**:
```typescript
const [loading, setLoading] = useState(false)

const handleLogin = async () => {
  setLoading(true)
  try {
    await api.login(...)
    navigate('/dashboard')
  } catch (e) {
    showError(e.message)
  } finally {
    setLoading(false) // navigate() 이후 언마운트 → 메모리 경고
  }
}
```

**수정 후 패턴**:
```typescript
const { mutate: loginMutate, isPending } = useMutation({
  mutationFn: () => authApi.login({ username, password }),
  onSuccess: (response) => {
    login(response.data.token, response.data.user)
    navigate('/dashboard')
  },
  onError: () => showError('로그인 실패'),
})
```

`isPending`, `isSuccess`, `isError`는 라이브러리가 자동으로 전환한다. 언마운트 이후 상태 변경도 안전하게 처리된다.

오늘 마이그레이션한 파일:
- `LoginPage.tsx` — 단일 useMutation
- `SignupVerifyPage.tsx` — `sendCodeMutation` + `verifyMutation` (각각 독립적인 로딩 상태)
- `SignupCompletePage.tsx` — `useMutation` + `useEffect(() => mutate(), [])` (마운트 즉시 실행)

---

## 오늘의 한 줄 원칙

> **직접 관리하는 것을 최소화하고, 전문 도구에 위임한다.**

| 상황 | 위임 대상 |
|------|----------|
| 서버 데이터 캐싱·만료 | TanStack Query |
| 쓰기 작업 로딩/에러 전환 | useMutation |
| 문서와 파일명 일관성 | 명시적 네이밍 규칙 (구현 시 즉시 반영) |

---

## 다음 단계

- `src/hooks/useAddressBook.ts` — `useInfiniteQuery` + 커서 기반 페이징 구현
- `AddressBookPage.tsx` — mock 데이터를 실제 훅으로 교체
- Phase 7 `usePermissions` — `useUserStore` 참조를 `useQuery(프로필 조회)`로 교체
