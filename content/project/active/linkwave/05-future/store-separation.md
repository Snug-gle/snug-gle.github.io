---
created: 2026-02-10
tags:
  - linkwave
  - frontend
  - zustand
  - store
---

> 이 문서는 linkwave-docs의 STORE_SEPARATION.md를 요약한 것입니다.

# Zustand Store 분리 마이그레이션 가이드

## 개요

authStore를 3개의 별도 store로 분리하여 백엔드 도메인 구조와 일치시킴.

### 변경 이유
- **백엔드 구조 일치**: User ↔ Organization 테이블 분리와 동일
- **관심사 분리**: 인증, 사용자 정보, 조직 정보를 명확히 구분
- **확장성**: 조직 멤버 관리, 권한 관리 등 향후 기능 추가 용이

---

## 변경 사항

### Before
```typescript
// authStore만 존재 — 모든 정보가 혼재
const { user, token, isAuthenticated, login, logout } = useAuthStore()
```

### After
```typescript
// 1. 인증 정보 (authStore) — JWT 토큰, 인증 상태
const { token, isAuthenticated, userId, userType } = useAuthStore()

// 2. 사용자 정보 (userStore) — 프로필, 설정
const { user, updateUser } = useUserStore()

// 3. 조직 정보 (organizationStore) — 조직, 멤버
const { organization, members } = useOrganizationStore()

// 4. 통합 훅 (권장)
const { servicePriority, isIndividual, displayName } = useCurrentAccount()
```

---

## Store 구조

### authStore (인증)
```typescript
interface AuthState {
  token: string | null
  isAuthenticated: boolean
  userId: string | null
  userType: 'INDIVIDUAL' | 'BUSINESS' | null
  organizationId: string | null
  login: (credentials) => Promise<void>
  logout: () => void
}
```

### userStore (사용자)
```typescript
interface UserState {
  user: UserProfile | null
  fetchUser: () => Promise<void>
  updateUser: (data: Partial<UserProfile>) => Promise<void>
}
```

### organizationStore (조직)
```typescript
interface OrganizationState {
  organization: Organization | null
  members: Member[]
  fetchOrganization: () => Promise<void>
}
```

---

## 마이그레이션 체크리스트

1. authStore에서 user 관련 상태/액션 → userStore로 이동
2. authStore에서 organization 관련 → organizationStore로 이동
3. `useCurrentAccount()` 통합 훅 생성
4. 기존 `useAuthStore().user` 참조 → `useUserStore().user`로 변경
5. 테스트 업데이트

---

## Related Documents

- [[frontend-architecture|Frontend Architecture]]
