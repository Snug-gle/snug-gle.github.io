---
created: 2025-12-26
---
# Phase 7: Super Admin 시스템

## 📖 개념 설명

시스템 관리자 전용 기능입니다.

**주요 기능**:
- 전체 사용자 관리
- 조직 승인/거부
- 시스템 전체 통계
- 권한 관리

---

## 🎯 구현 목표

- [ ] `src/api/adminApi.ts` - 관리자 API
- [ ] `src/pages/_super-admin/users.tsx` - 사용자 관리
- [ ] `src/pages/_super-admin/organizations.tsx` - 조직 관리
- [ ] `src/hooks/usePermissions.ts` - 권한 체크 훅

---

## 📝 Step 1: 관리자 API

### 파일: `src/api/adminApi.ts`

```typescript
import client from './client'
import type { ApiResponse, PaginatedResponse } from '@/types/api'
import type { User, UserListFilter } from '@/types/user'
import type { Organization } from '@/types/organization'

/**
 * 사용자 목록 조회
 */
export const getUsers = async (
  filter: UserListFilter
): Promise<ApiResponse<PaginatedResponse<User>>> => {
  return client.get('/admin/users', { params: filter })
}

/**
 * 조직 목록 조회
 */
export const getOrganizations = async (): Promise<
  ApiResponse<Organization[]>
> => {
  return client.get('/admin/organizations')
}

/**
 * 조직 승인
 */
export const approveOrganization = async (
  organizationId: string
): Promise<ApiResponse<void>> => {
  return client.post(`/admin/organizations/${organizationId}/approve`)
}

/**
 * 조직 거부
 */
export const rejectOrganization = async (
  organizationId: string
): Promise<ApiResponse<void>> => {
  return client.post(`/admin/organizations/${organizationId}/reject`)
}
```

---

## 📝 Step 2: 권한 체크 훅

### 파일: `src/hooks/usePermissions.ts`

```typescript
import { useAuthStore } from '@/stores/authStore'
import { useUserStore } from '@/stores/userStore'
import type { UserRole } from '@/types/user'

export const usePermissions = () => {
  const { isAuthenticated } = useAuthStore()
  const { user } = useUserStore()

  const hasRole = (roles: UserRole[]): boolean => {
    if (!isAuthenticated || !user) return false
    return roles.includes(user.role)
  }

  const isSuperAdmin = (): boolean => {
    return hasRole(['SUPER_ADMIN'])
  }

  const isOrganizationAdmin = (): boolean => {
    return hasRole(['ORGANIZATION_ADMIN', 'SUPER_ADMIN'])
  }

  const isUser = (): boolean => {
    return hasRole(['USER', 'ORGANIZATION_ADMIN', 'SUPER_ADMIN'])
  }

  return {
    hasRole,
    isSuperAdmin,
    isOrganizationAdmin,
    isUser,
  }
}
```

**사용 예시**:

```typescript
const MyPage = () => {
  const { isSuperAdmin } = usePermissions()

  if (!isSuperAdmin()) {
    return <div>접근 권한이 없습니다</div>
  }

  return <div>Super Admin 페이지</div>
}
```

---

## 💡 학습 포인트

### Role-based Access Control (RBAC)

```typescript
// TanStack Router에서 권한 체크
export const Route = createFileRoute('/_super-admin')({
  beforeLoad: () => {
    const { user } = useUserStore.getState()
    
    if (user?.role !== 'SUPER_ADMIN') {
      throw redirect({ to: '/' })
    }
  }
})
```

---

## 📚 다음 단계

**다음**: [08-ADVANCED-PATTERNS.md](./08-ADVANCED-PATTERNS.md) →
