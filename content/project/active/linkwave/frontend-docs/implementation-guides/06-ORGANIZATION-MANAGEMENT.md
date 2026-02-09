---
created: 2025-12-26
---
# Phase 6: 조직 관리 (Organization Admin)

## 📖 개념 설명

법인 사용자를 위한 조직 관리 기능입니다.

**주요 기능**:
- 조직 정보 관리
- 멤버 초대 및 관리
- 발신번호 등록 및 관리
- 조직 설정

---

## 🎯 구현 목표

- [ ] `src/api/memberApi.ts` - 멤버 관리 API
- [ ] `src/api/senderNumberApi.ts` - 발신번호 API
- [ ] `src/pages/_organization-admin/members.tsx` - 멤버 관리
- [ ] `src/pages/_organization-admin/sender-numbers.tsx` - 발신번호 관리

---

## 📝 Step 1: 멤버 API

### 파일: `src/api/memberApi.ts`

```typescript
import client from './client'
import type { ApiResponse } from '@/types/api'
import type { OrganizationMember, InviteMemberRequest } from '@/types/organization'

/**
 * 멤버 목록 조회
 */
export const getOrganizationMembers = async (): Promise<
  ApiResponse<OrganizationMember[]>
> => {
  return client.get('/organization/members')
}

/**
 * 멤버 초대
 */
export const inviteMember = async (
  request: InviteMemberRequest
): Promise<ApiResponse<void>> => {
  return client.post('/organization/members/invite', request)
}

/**
 * 멤버 삭제
 */
export const removeMember = async (
  memberId: string
): Promise<ApiResponse<void>> => {
  return client.delete(`/organization/members/${memberId}`)
}
```

---

## 📝 Step 2: 발신번호 API

### 파일: `src/api/senderNumberApi.ts`

```typescript
import client from './client'
import type { ApiResponse } from '@/types/api'

export interface SenderNumber {
  senderNumberId: string
  phoneNumber: string
  approvalStatus: 'PENDING' | 'APPROVED' | 'REJECTED'
  createdAt: string
}

export interface RegisterSenderNumberRequest {
  phoneNumber: string
  documentFile: File
}

/**
 * 발신번호 목록 조회
 */
export const getSenderNumbers = async (): Promise<
  ApiResponse<SenderNumber[]>
> => {
  return client.get('/sender-numbers')
}

/**
 * 발신번호 등록
 */
export const registerSenderNumber = async (
  request: RegisterSenderNumberRequest
): Promise<ApiResponse<SenderNumber>> => {
  const formData = new FormData()
  formData.append('phoneNumber', request.phoneNumber)
  formData.append('documentFile', request.documentFile)

  return client.post('/sender-numbers', formData, {
    headers: {
      'Content-Type': 'multipart/form-data'
    }
  })
}
```

---

## 💡 학습 포인트

### 멀티테넌시 패턴

```typescript
// authStore에서 organizationId 관리
const { organizationId } = useAuthStore()

// API 호출 시 자동으로 organizationId가 포함됨
// (백엔드가 JWT에서 추출)
const members = await getOrganizationMembers()
```

---

## 📚 다음 단계

**다음**: [07-SUPER-ADMIN.md](./07-SUPER-ADMIN.md) →
