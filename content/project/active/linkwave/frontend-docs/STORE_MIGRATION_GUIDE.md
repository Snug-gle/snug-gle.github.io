---
created: 2025-12-26
---
# Store 분리 마이그레이션 가이드

## 📋 개요

authStore를 3개의 별도 store로 분리하여 백엔드 도메인 구조와 일치시켰습니다.

### 변경 이유

- **백엔드 구조 일치**: User ↔ Organization 테이블 분리와 동일하게 프론트엔드도 분리
- **관심사 분리**: 인증, 사용자 정보, 조직 정보를 명확히 구분
- **확장성**: 조직 멤버 관리, 권한 관리 등 향후 기능 추가 용이

---

## 🔄 변경 사항

### Before (기존)

```typescript
// authStore만 존재
const { user, token, isAuthenticated, login, logout, updateUser } =
  useAuthStore();

// user에 모든 정보가 혼재
console.log(user.userId);
console.log(user.userType); // INDIVIDUAL | BUSINESS
console.log(user.servicePriority); // ???
```

### After (변경 후)

```typescript
// 1. 인증 정보 (authStore)
const { token, isAuthenticated, userId, userType, organizationId } =
  useAuthStore();

// 2. 사용자 정보 (userStore)
const { user, updateUser } = useUserStore();

// 3. 조직 정보 (organizationStore)
const { organization, members } = useOrganizationStore();

// 4. 통합 훅 (권장)
const { servicePriority, isIndividual, displayName } = useCurrentAccount();
```

---

## 📦 Store 구조

### 1. authStore - 인증만 담당

```typescript
interface AuthState {
  token: string | null;
  isAuthenticated: boolean;
  userId: string | null;
  userType: UserType | null; // INDIVIDUAL | BUSINESS
  organizationId: string | null;

  login: (
    token: string,
    userId: string,
    userType: UserType,
    organizationId?: string
  ) => void;
  logout: () => void;
  updateToken: (token: string) => void;
}
```

### 2. userStore - 사용자 프로필

```typescript
interface UserState {
  user: User | null;
  isLoading: boolean;
  error: string | null;

  setUser: (user: User) => void;
  updateUser: (userData: Partial<User>) => void;
  fetchUser: (userId: string) => Promise<void>;
}
```

### 3. organizationStore - 조직 정보

```typescript
interface OrganizationState {
  organization: Organization | null;
  members: User[];
  isLoading: boolean;
  error: string | null;

  setOrganization: (organization: Organization) => void;
  fetchOrganization: (organizationId: string) => Promise<void>;
  fetchMembers: (organizationId: string) => Promise<void>;
}
```

---

## 🔧 마이그레이션 방법

### Case 1: 기존 authStore 사용 코드

#### Before

```typescript
import { useAuthStore } from "@/stores/authStore";

function MyComponent() {
  const { user, isAuthenticated } = useAuthStore();

  if (!isAuthenticated || !user) return <div>Not logged in</div>;

  return <div>Hello, {user.name}</div>;
}
```

#### After (Option A: 개별 store 사용)

```typescript
import { useAuthStore } from "@/stores/authStore";
import { useUserStore } from "@/stores/userStore";

function MyComponent() {
  const { isAuthenticated } = useAuthStore();
  const { user } = useUserStore();

  if (!isAuthenticated || !user) return <div>Not logged in</div>;

  return <div>Hello, {user.name}</div>;
}
```

#### After (Option B: 통합 훅 사용 - 권장)

```typescript
import { useCurrentAccount } from "@/hooks/useCurrentAccount";

function MyComponent() {
  const { isAuthenticated, user, displayName } = useCurrentAccount();

  if (!isAuthenticated || !user) return <div>Not logged in</div>;

  return <div>Hello, {displayName}</div>;
}
```

---

### Case 2: 로그인 처리

#### Before

```typescript
const { login } = useAuthStore();

// 로그인 API 호출 후
const response = await loginApi(username, password);
login(response.user, response.token);
```

#### After

```typescript
import { useAuthStore } from "@/stores/authStore";
import { useUserStore } from "@/stores/userStore";
import { useOrganizationStore } from "@/stores/organizationStore";

const { login } = useAuthStore();
const { setUser } = useUserStore();
const { setOrganization } = useOrganizationStore();

// 로그인 API 호출 후
const response = await loginApi(username, password);

// 1. 인증 정보 저장
login(
  response.token,
  response.user.userId,
  response.user.userType,
  response.user.organizationId // BUSINESS 타입인 경우
);

// 2. 사용자 정보 저장
setUser(response.user);

// 3. 법인 사용자라면 조직 정보도 저장
if (response.user.userType === "BUSINESS" && response.organization) {
  setOrganization(response.organization);
}
```

---

### Case 3: 로그아웃 처리

#### Before

```typescript
const { logout } = useAuthStore();
logout();
```

#### After

```typescript
import { useAuthStore } from "@/stores/authStore";
import { useUserStore } from "@/stores/userStore";
import { useOrganizationStore } from "@/stores/organizationStore";

const { logout } = useAuthStore();
const { clearUser } = useUserStore();
const { clearOrganization } = useOrganizationStore();

// 모든 store 초기화
logout();
clearUser();
clearOrganization();
```

---

### Case 4: 사용자 정보 업데이트

#### Before

```typescript
const { updateUser } = useAuthStore();
updateUser({ name: "새이름" });
```

#### After

```typescript
const { updateUser } = useUserStore();
updateUser({ name: "새이름" });
```

---

### Case 5: 서비스 우선순위 사용

#### Before

```typescript
const { user } = useAuthStore();
const servicePriority = user?.servicePriority || []; // ???
```

#### After (개인 사용자)

```typescript
const { user } = useUserStore();
const { userType } = useAuthStore();

const servicePriority =
  userType === "INDIVIDUAL" ? user?.servicePriority || [] : [];
```

#### After (법인 사용자)

```typescript
const { organization } = useOrganizationStore();
const { userType } = useAuthStore();

const servicePriority =
  userType === "BUSINESS" ? organization?.servicePriority || [] : [];
```

#### After (통합 - 권장) ⭐

```typescript
const { servicePriority } = useCurrentAccount();
// 개인/법인 구분 없이 바로 사용 가능!
```

---

## 🎯 권장 사용 패턴

### 1. **대부분의 컴포넌트**: `useCurrentAccount` 사용

```typescript
import { useCurrentAccount } from "@/hooks/useCurrentAccount";

function Header() {
  const { displayName, isAuthenticated, servicePriority } =
    useCurrentAccount();

  return (
    <header>
      {isAuthenticated && <div>Welcome, {displayName}</div>}
      <div>Available services: {servicePriority.join(", ")}</div>
    </header>
  );
}
```

### 2. **인증 체크만 필요**: `useAuthStore`

```typescript
import { useAuthStore } from "@/stores/authStore";

function PrivateRoute({ children }) {
  const { isAuthenticated } = useAuthStore();

  if (!isAuthenticated) {
    return <Navigate to="/login" />;
  }

  return children;
}
```

### 3. **개인 사용자 전용 기능**: `useUserStore`

```typescript
import { useUserStore } from "@/stores/userStore";

function UserProfileEdit() {
  const { user, updateUser } = useUserStore();

  const handleSubmit = (data) => {
    updateUser(data);
  };

  return <form>...</form>;
}
```

### 4. **법인/조직 관리 기능**: `useOrganizationStore`

```typescript
import { useOrganizationStore } from "@/stores/organizationStore";

function OrganizationSettings() {
  const { organization, members, updateOrganization } =
    useOrganizationStore();

  return (
    <div>
      <h1>{organization?.organizationName}</h1>
      <div>Members: {members.length}</div>
    </div>
  );
}
```

---

## 🚨 주의사항

### 1. LocalStorage 키 변경

기존 `auth-storage`의 구조가 변경되었으므로, **사용자 재로그인 필요**

```typescript
// 기존
{
  user: { userId, name, ... },
  isAuthenticated: true
}

// 변경 후
{
  userId: "...",
  userType: "INDIVIDUAL",
  organizationId: null,
  isAuthenticated: true
}
```

### 2. 조직 정보 로딩

법인 사용자 로그인 시 조직 정보도 함께 로드해야 함:

```typescript
// 로그인 성공 후
if (user.userType === "BUSINESS" && user.organizationId) {
  await fetchOrganization(user.organizationId);
}
```

### 3. servicePriority 접근

개인/법인에 따라 다른 위치에 있으므로 **`useCurrentAccount` 훅 사용 권장**

---

## ✅ 체크리스트

마이그레이션 시 확인할 사항:

- [ ] 로그인 로직 수정 (3개 store 모두 업데이트)
- [ ] 로그아웃 로직 수정 (3개 store 모두 초기화)
- [ ] `useAuthStore`의 `user` 사용 → `useUserStore`로 변경
- [ ] servicePriority 접근 → `useCurrentAccount` 사용
- [ ] 법인 사용자 조직 정보 로딩 추가
- [ ] 기존 localStorage 클리어 안내 (재로그인 필요)

---

## 📚 참고

- [authStore.ts](../src/stores/authStore.ts)
- [userStore.ts](../src/stores/userStore.ts)
- [organizationStore.ts](../src/stores/organizationStore.ts)
- [useCurrentAccount.ts](../src/hooks/useCurrentAccount.ts)
- [User 타입](../src/types/user.ts)
- [Organization 타입](../src/types/organization.ts)
