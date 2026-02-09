---
created: 2025-12-26
---
# Phase 1: 타입 시스템 및 API 클라이언트

## 📖 개념 설명

### 왜 이 Phase가 중요한가?

프론트엔드 개발에서 **타입 안전성**과 **API 통신 레이어**는 전체 애플리케이션의 기반이 됩니다. 이 Phase에서는:

1. **TypeScript 타입 시스템**: 백엔드 API와 1:1 매핑되는 타입 정의
2. **Axios 클라이언트**: JWT 인증, 에러 처리를 자동화하는 HTTP 클라이언트
3. **API 함수**: 재사용 가능하고 타입 안전한 API 호출 함수

이 세 가지를 구축하여 **컴파일 타임에 에러를 잡고**, **런타임 에러를 최소화**합니다.

### TypeScript Generic의 핵심 개념

```typescript
// Generic이 없으면
interface LoginResponse {
  success: boolean
  data: { userId: string } | null
  error: { code: string } | null
}

interface MessageResponse {
  success: boolean
  data: { groupId: string } | null
  error: { code: string } | null
}

// Generic을 사용하면
interface ApiResponse<T> {
  success: boolean
  data: T | null
  error: ApiError | null
}

// 사용
type LoginResponse = ApiResponse<{ userId: string }>
type MessageResponse = ApiResponse<{ groupId: string }>
```

**인사이트**: Generic을 사용하면 **반복을 제거**하고 **타입 안전성을 유지**할 수 있습니다.

### 백엔드 API 응답 구조와 Axios 매핑 이해하기

이 부분이 **가장 중요**합니다! 백엔드와 프론트엔드가 어떻게 데이터를 주고받는지 정확히 이해해야 합니다.

#### 1단계: 백엔드에서 보내는 실제 응답

```json
// POST /api/v1/auth/login 성공 시
{
  "success": true,
  "data": {
    "accessToken": "eyJhbGciOiJIUzI1NiJ9...",
    "tokenType": "Bearer",
    "userId": "abc-123",
    "username": "testuser",
    "role": "USER"
  },
  "error": null,
  "timestamp": "2025-12-26T10:30:00"
}

// POST /api/v1/auth/login 실패 시
{
  "success": false,
  "data": null,
  "error": {
    "code": "U004",
    "message": "아이디 또는 비밀번호가 일치하지 않습니다"
  },
  "timestamp": "2025-12-26T10:30:00"
}
```

#### 2단계: Axios의 응답 구조

```typescript
// Axios가 HTTP 응답을 받으면
const axiosResponse = {
  data: {  // ← 백엔드가 보낸 JSON 전체가 여기에!
    success: true,
    data: { accessToken: "...", ... },
    error: null,
    timestamp: "..."
  },
  status: 200,
  statusText: 'OK',
  headers: {...},
  config: {...}
}
```

**핵심**:
- `axiosResponse.data` = 백엔드의 `ApiResponse` 전체
- `axiosResponse.data.data` = 실제 비즈니스 데이터

#### 3단계: Response Interceptor의 역할

```typescript
// client.ts의 Response Interceptor
client.interceptors.response.use(
  (response: AxiosResponse<ApiResponse>) => {
    // response.data = { success, data, error, timestamp }
    return response.data  // ← ApiResponse 전체를 반환
  }
)
```

**반환값**:
```typescript
{
  success: true,
  data: { accessToken: "...", userId: "..." },
  error: null,
  timestamp: "..."
}
```

#### 4단계: API 함수에서 사용

```typescript
// authApi.ts
export const login = async (
  request: LoginRequest
): Promise<ApiResponse<LoginResponseData>> => {
  // client.post()의 반환값은 Interceptor를 거쳐서
  // ApiResponse<LoginResponseData> 형태
  return client.post('/auth/login', request)
}

// 사용 예시 (LoginPage.tsx)
const response = await login({ username, password })

// response 구조:
// {
//   success: true,
//   data: { accessToken, userId, ... },  ← LoginResponseData
//   error: null,
//   timestamp: "..."
// }

if (response.success && response.data) {
  const token = response.data.accessToken  // ✅ 올바른 접근
}
```

#### ⚠️ 자주하는 착각

```typescript
// ❌ 잘못된 생각
const response = await login(...)
const token = response.accessToken  // undefined!

// ❌ 이것도 잘못됨
const token = response.data.data.accessToken  // data.data는 없음!

// ✅ 올바른 접근
const token = response.data.accessToken
```

#### 💡 왜 이렇게 설계했나?

1. **일관성**: 모든 API가 동일한 형태로 응답
2. **에러 처리 통일**: `success`, `error` 필드로 성공/실패 구분
3. **타입 안전성**: TypeScript Generic으로 각 API의 데이터 타입 보장

### 아키텍처 다이어그램

```
┌─────────────────────────────────────────────────────────────┐
│                         Frontend                             │
├─────────────────────────────────────────────────────────────┤
│  Component (LoginPage.tsx)                                   │
│    └─> API Function (authApi.ts)                            │
│         └─> Axios Client (client.ts)                        │
│              ├─ Request Interceptor (JWT 토큰 추가)         │
│              ├─ HTTP Request                                 │
│              ├─ Response Interceptor (에러 처리)            │
│              └─> TypeScript Type (ApiResponse<LoginData>)   │
└─────────────────────────────────────────────────────────────┘
                          │
                          │ HTTP (JSON)
                          ▼
┌─────────────────────────────────────────────────────────────┐
│                      Backend API                             │
│  /api/v1/auth/login → ApiResponse<LoginResponseData>        │
└─────────────────────────────────────────────────────────────┘
```

---

## 🎯 구현 목표

이 Phase에서 구현할 파일 목록:

- [ ] `src/types/api.ts` - 공통 API 응답 타입
- [ ] `src/types/auth.ts` - 인증 관련 타입 (로그인, 회원가입, 토큰)
- [ ] `src/types/user.ts` - 사용자 타입 (✅ 이미 존재)
- [ ] `src/types/organization.ts` - 조직 타입
- [ ] `src/types/message.ts` - 메시지 타입
- [ ] `src/api/client.ts` - Axios 클라이언트 + 인터셉터 (✅ 이미 존재)
- [ ] `src/api/authApi.ts` - 인증 API 함수

---

## 📝 Step 1: 공통 API 응답 타입 정의

### 파일: `src/types/api.ts`

백엔드 API는 모든 엔드포인트에서 통일된 응답 형식을 사용합니다.

```typescript
/**
 * 공통 API 응답 형식
 * 백엔드의 모든 API는 이 형식을 따릅니다
 */
export interface ApiResponse<T = unknown> {
  /** 요청 성공 여부 */
  success: boolean

  /** 응답 데이터 (성공 시) */
  data: T | null

  /** 에러 정보 (실패 시) */
  error: ApiError | null

  /** 응답 생성 시각 (ISO 8601) */
  timestamp: string
}

/**
 * API 에러 응답 형식
 */
export interface ApiError {
  /** 에러 코드 (백엔드 ErrorCode enum과 매핑) */
  code: string

  /** 사용자에게 표시할 에러 메시지 */
  message: string

  /** 추가 에러 상세 정보 (선택적) */
  details?: Record<string, unknown>
}

/**
 * 페이지네이션 응답 형식
 */
export interface PaginatedResponse<T> {
  content: T[]
  pageNumber: number
  pageSize: number
  totalElements: number
  totalPages: number
  last: boolean
  first: boolean
}

/**
 * 백엔드 ErrorCode enum 매핑
 */
export const ErrorCode = {
  // 공통 에러
  INTERNAL_SERVER_ERROR: 'E000',
  INVALID_INPUT: 'E001',
  RESOURCE_NOT_FOUND: 'E002',

  // 사용자 관련 에러
  USER_NOT_FOUND: 'U001',
  DUPLICATE_USERNAME: 'U002',
  DUPLICATE_EMAIL: 'U003',
  INVALID_CREDENTIALS: 'U004',
  DUPLICATE_PHONE: 'U005',

  // 인증 관련 에러
  INVALID_TOKEN: 'A001',
  EXPIRED_TOKEN: 'A002',
  UNAUTHORIZED: 'A003',

  // 메시지 관련 에러
  MESSAGE_SEND_FAILED: 'M001',
  INVALID_PHONE_NUMBER: 'M002',
  INSUFFICIENT_BALANCE: 'M003',
} as const

export type ErrorCodeType = typeof ErrorCode[keyof typeof ErrorCode]
```

**인사이트**: 
- `as const`를 사용하여 TypeScript가 문자열 리터럴 타입으로 추론하도록 함
- `ApiResponse<T>` Generic을 사용하여 모든 API 응답을 표현

---

## 📝 Step 2: 인증 관련 타입 정의

### 파일: `src/types/auth.ts`

백엔드 API 스펙에 맞춘 인증 타입을 정의합니다.

```typescript
import type { UserRole, UserType } from './user'

/**
 * 로그인 요청
 * POST /api/v1/auth/login
 */
export interface LoginRequest {
  username: string
  password: string
}

/**
 * 로그인 응답 데이터
 */
export interface LoginResponseData {
  accessToken: string
  tokenType: 'Bearer'
  userId: string
  username: string
  role: UserRole
  userType?: UserType
  organizationId?: string
}

/**
 * 휴대폰 인증번호 요청
 * POST /api/v1/auth/phone/request-verification
 */
export interface PhoneVerificationRequest {
  phone: string
}

/**
 * 휴대폰 인증번호 확인 요청
 * POST /api/v1/auth/phone/verify
 */
export interface PhoneVerifyRequest {
  phone: string
  verificationCode: string
}

/**
 * 휴대폰 인증번호 확인 응답
 */
export interface PhoneVerifyResponseData {
  phoneVerificationToken: string
}

/**
 * 회원가입 요청
 * POST /api/v1/auth/signup
 */
export interface SignupRequest {
  username: string
  password: string
  name: string
  phone: string
  email?: string
  displayName?: string
  userType: UserType
  organizationId?: string
}

/**
 * 회원가입 응답 (로그인과 동일)
 */
export type SignupResponseData = LoginResponseData

/**
 * 아이디 중복 확인 요청
 * GET /api/v1/auth/check-username
 */
export interface CheckUsernameRequest {
  username: string
}

/**
 * 아이디 중복 확인 응답
 */
export interface CheckUsernameResponseData {
  available: boolean
}
```

---

## 📝 Step 3: 메시지 타입 정의

### 파일: `src/types/message.ts`

```typescript
/**
 * 메시지 타입
 */
export type MessageType = 'SMS' | 'LMS' | 'MMS'

/**
 * 메시지 상태
 */
export type MessageStatus =
  | 'PENDING'
  | 'PROCESSING'
  | 'SENT'
  | 'FAILED'
  | 'SCHEDULED'

/**
 * 메시지 발송 요청
 * POST /api/v1/messages
 */
export interface MessageSendRequest {
  type: MessageType
  from: string
  to: string[]
  subject?: string
  content: string
  scheduledAt?: string
}

/**
 * 메시지 발송 응답
 */
export interface MessageSendResponseData {
  groupId: string
  totalCount: number
  successCount: number
  failedCount: number
  scheduled: boolean
  scheduledAt?: string
}

/**
 * 메시지 이력 조회 필터
 */
export interface MessageHistoryFilter {
  type?: MessageType
  status?: MessageStatus
  startDate?: string
  endDate?: string
  page?: number
  size?: number
}

/**
 * 메시지 이력 항목
 */
export interface MessageHistory {
  messageId: string
  groupId: string
  type: MessageType
  from: string
  to: string
  content: string
  status: MessageStatus
  sentAt?: string
  createdAt: string
}
```

---

## 📝 Step 4: 조직 타입 정의

### 파일: `src/types/organization.ts`

```typescript
/**
 * 조직 정보
 */
export interface Organization {
  organizationId: string
  name: string
  businessNumber: string
  ownerId: string
  approvalStatus: OrganizationApprovalStatus
  createdAt: string
  updatedAt?: string
}

/**
 * 조직 승인 상태
 */
export type OrganizationApprovalStatus = 'PENDING' | 'APPROVED' | 'REJECTED'

/**
 * 조직 생성 요청
 */
export interface CreateOrganizationRequest {
  name: string
  businessNumber: string
}

/**
 * 조직 멤버
 */
export interface OrganizationMember {
  memberId: string
  userId: string
  username: string
  email: string
  role: 'OWNER' | 'ADMIN' | 'MEMBER'
  joinedAt: string
}
```

---

## 📝 Step 5: Axios 클라이언트 개선

### 파일: `src/api/client.ts`

기존 클라이언트를 타입 안전하게 개선합니다.

```typescript
import axios, {
  type AxiosInstance,
  type InternalAxiosRequestConfig,
  type AxiosResponse,
  type AxiosError
} from 'axios'

/**
 * 백엔드 API 공통 응답 형식
 * 이 타입을 client.ts에도 정의하여 Interceptor에서 사용
 */
interface ApiResponse<T = unknown> {
  success: boolean
  data: T | null
  error: {
    code: string
    message: string
    details?: Record<string, unknown>
  } | null
  timestamp: string
}

const client: AxiosInstance = axios.create({
  baseURL: import.meta.env.VITE_API_BASE_URL || '/api/v1',
  timeout: 30000,
  headers: {
    'Content-Type': 'application/json',
  },
})

// Request Interceptor: JWT 토큰 자동 추가
client.interceptors.request.use(
  (config: InternalAxiosRequestConfig) => {
    const token = localStorage.getItem('auth-token')

    if (token && config.headers) {
      config.headers.Authorization = `Bearer ${token}`
    }

    return config
  },
  (error: AxiosError) => Promise.reject(error)
)

// Response Interceptor: 응답 처리 및 에러 핸들링
client.interceptors.response.use(
  // 성공 응답: ApiResponse<T> 형태를 그대로 반환
  (response: AxiosResponse<ApiResponse>) => {
    // response.data는 백엔드의 { success, data, error, timestamp }
    return response.data
  },
  // 에러 응답: HTTP 상태 코드별 처리
  (error: AxiosError<ApiResponse>) => {
    // 401 Unauthorized: 토큰 만료 또는 인증 실패
    if (error.response?.status === 401) {
      localStorage.removeItem('auth-token')
      localStorage.removeItem('auth-storage')
      window.location.href = '/login'
    }

    // 에러 응답도 ApiResponse 형태일 수 있음
    // 예: { success: false, data: null, error: { code: 'U004', message: '...' } }
    return Promise.reject(error)
  }
)

export default client
```

**중요 포인트**:

1. **타입 명시**: `AxiosResponse<ApiResponse>`로 응답 타입 지정
2. **Interceptor 반환값**: `response.data`는 `ApiResponse` 전체
3. **에러 타입**: `AxiosError<ApiResponse>`로 에러 응답도 타입 지정

**데이터 흐름**:
```
백엔드 응답 (JSON)
  → Axios가 받음 (AxiosResponse)
    → response.data = ApiResponse 전체
      → Interceptor가 반환 (ApiResponse)
        → API 함수가 받음 (Promise<ApiResponse<T>>)
```

**인사이트**:
- `ApiResponse` 타입을 client.ts에도 정의 (src/types/api.ts와 동일)
- Interceptor에서 타입을 명시하여 TypeScript가 정확히 체크
- 401 에러 시 자동 로그아웃 처리

---

## 📝 Step 6: 인증 API 함수 구현

### 파일: `src/api/authApi.ts`

```typescript
import client from './client'
import type { ApiResponse } from '@/types/api'
import type {
  LoginRequest,
  LoginResponseData,
  PhoneVerificationRequest,
  PhoneVerifyRequest,
  PhoneVerifyResponseData,
  SignupRequest,
  SignupResponseData,
  CheckUsernameRequest,
  CheckUsernameResponseData,
} from '@/types/auth'

/**
 * 로그인
 */
export const login = async (
  request: LoginRequest
): Promise<ApiResponse<LoginResponseData>> => {
  return client.post('/auth/login', request)
}

/**
 * 회원가입
 */
export const signup = async (
  request: SignupRequest
): Promise<ApiResponse<SignupResponseData>> => {
  return client.post('/auth/signup', request)
}

/**
 * 아이디 중복 확인
 */
export const checkUsername = async (
  request: CheckUsernameRequest
): Promise<ApiResponse<CheckUsernameResponseData>> => {
  return client.get('/auth/check-username', {
    params: request,
  })
}

/**
 * 휴대폰 인증번호 요청
 */
export const requestPhoneVerification = async (
  request: PhoneVerificationRequest
): Promise<ApiResponse<void>> => {
  return client.post('/auth/phone/request-verification', request)
}

/**
 * 휴대폰 인증번호 확인
 */
export const verifyPhone = async (
  request: PhoneVerifyRequest
): Promise<ApiResponse<PhoneVerifyResponseData>> => {
  return client.post('/auth/phone/verify', request)
}
```

---

## 📝 Step 7: 메시지 API 함수 구현

### 파일: `src/api/messageApi.ts`

```typescript
import client from './client'
import type { ApiResponse } from '@/types/api'
import type {
  MessageSendRequest,
  MessageSendResponseData,
} from '@/types/message'

/**
 * 메시지 발송
 * POST /api/v1/messages
 */
export const sendMessage = async (
  request: MessageSendRequest
): Promise<ApiResponse<MessageSendResponseData>> => {
  return client.post('/messages', request)
}

/**
 * 예약 메시지 취소
 * DELETE /api/v1/messages/scheduled/{groupId}
 */
export const cancelScheduledMessage = async (
  groupId: string
): Promise<ApiResponse<void>> => {
  return client.delete(`/messages/scheduled/${groupId}`)
}

/**
 * 메시지 그룹 상태 조회
 * GET /api/v1/messages/group/{groupId}
 */
export const getMessageGroupStatus = async (
  groupId: string
): Promise<ApiResponse<MessageSendResponseData>> => {
  return client.get(`/messages/group/${groupId}`)
}
```

---

## ✅ 완료 체크리스트

- [ ] `src/types/api.ts` 작성
- [ ] `src/types/auth.ts` 작성
- [ ] `src/types/message.ts` 작성
- [ ] `src/types/organization.ts` 작성
- [ ] `src/api/client.ts` 확인 및 개선
- [ ] `src/api/authApi.ts` 작성
- [ ] `src/api/messageApi.ts` 작성
- [ ] TypeScript 컴파일 에러 없음 (`npx tsc --noEmit`)

---

## 🧪 테스트 방법

### 1. TypeScript 타입 체크

```bash
npx tsc --noEmit
```

### 2. API 호출 테스트

```typescript
// LoginPage에서 테스트
import { login } from '@/api/authApi'

const handleLogin = async () => {
  try {
    const response = await login({ username, password })
    
    if (response.success && response.data) {
      console.log('토큰:', response.data.accessToken)
      localStorage.setItem('auth-token', response.data.accessToken)
    }
  } catch (error) {
    console.error('로그인 실패:', error)
  }
}
```

---

## ⚠️ 두 가지 에러의 차이점 이해하기

### ApiResponse.error vs AxiosError

프론트엔드에서 처리해야 할 **두 가지 에러**가 있습니다:

#### 1. `ApiResponse.error` - 비즈니스 로직 에러

```typescript
interface ApiResponse<T> {
  success: boolean
  data: T | null
  error: ApiError | null  // ← 백엔드 비즈니스 에러
  timestamp: string
}
```

**언제 발생?**
- HTTP 요청은 성공 (200 OK 또는 4xx)
- 백엔드가 응답은 보냈지만, 비즈니스 로직상 실패
- 예: 아이디 중복, 비밀번호 틀림, 권한 없음

**예시**:
```json
// HTTP 200 OK
{
  "success": false,
  "data": null,
  "error": {
    "code": "U004",
    "message": "아이디 또는 비밀번호가 일치하지 않습니다"
  }
}
```

#### 2. `AxiosError` - HTTP 통신 에러

**언제 발생?**
- HTTP 요청 자체가 실패
- 네트워크 오류
- 서버 다운 (5xx)
- 타임아웃
- CORS 에러

**예시**:
```typescript
AxiosError: Network Error
AxiosError: timeout of 30000ms exceeded
AxiosError: Request failed with status code 500
```

### 실전 에러 처리 패턴

```typescript
// LoginPage.tsx
const handleLogin = async () => {
  setLoading(true)

  try {
    const response = await login({ username, password })

    // 1️⃣ 비즈니스 로직 에러 체크 (ApiResponse.error)
    if (!response.success || !response.data) {
      const errorMsg = response.error?.message || '로그인에 실패했습니다'
      toast.error(errorMsg)
      return
    }

    // 2️⃣ 성공 처리
    const { accessToken, userId, userType } = response.data
    login(accessToken, userId, userType)
    toast.success('로그인 성공!')
    navigate({ to: '/dashboard' })

  } catch (error: any) {
    // 3️⃣ HTTP 통신 에러 (AxiosError)
    if (error.code === 'ECONNABORTED') {
      toast.error('요청 시간이 초과되었습니다')
    } else if (error.message === 'Network Error') {
      toast.error('서버와 연결할 수 없습니다')
    } else if (error.response?.status === 500) {
      toast.error('서버 오류가 발생했습니다')
    } else {
      // 백엔드가 에러 응답을 보낸 경우
      const backendError = error.response?.data?.error
      const errorMsg = backendError?.message || '알 수 없는 오류가 발생했습니다'
      toast.error(errorMsg)
    }
  } finally {
    setLoading(false)
  }
}
```

### 요약 테이블

| 에러 종류 | 발생 시점 | HTTP 상태 | 응답 존재 | 처리 위치 |
|----------|---------|----------|----------|---------|
| **ApiResponse.error** | 비즈니스 로직 실패 | 200, 400, 409 등 | ✅ 있음 | `if (!response.success)` |
| **AxiosError** | HTTP 통신 실패 | 500, 없음 | ❌ 없거나 5xx | `catch (error)` |

### 핵심 정리

```typescript
try {
  const response = await login(...)

  // HTTP는 성공 → ApiResponse.error 체크
  if (!response.success) {
    console.log('비즈니스 에러:', response.error.message)
  }

} catch (error) {
  // HTTP 실패 → AxiosError 처리
  console.log('통신 에러:', error.message)
}
```

---

## 🔍 자주하는 실수

### ❌ 실수 1: Generic 타입 누락

```typescript
// ❌ 잘못된 예
const login = async (request: LoginRequest): Promise<ApiResponse> => {
  return client.post('/auth/login', request)
}

// ✅ 올바른 예
const login = async (
  request: LoginRequest
): Promise<ApiResponse<LoginResponseData>> => {
  return client.post('/auth/login', request)
}
```

### ❌ 실수 2: Response Unwrap 이중 접근

```typescript
// ❌ 잘못된 예
const response = await login({ username, password })
const token = response.data.data.accessToken // data.data는 잘못됨

// ✅ 올바른 예
const response = await login({ username, password })
const token = response.data.accessToken // Interceptor가 이미 unwrap함
```

### ❌ 실수 3: as const 누락

```typescript
// ❌ ErrorCodeType이 string으로 추론됨
export const ErrorCode = {
  USER_NOT_FOUND: 'U001',
}

// ✅ ErrorCodeType이 'U001'로 정확히 추론됨
export const ErrorCode = {
  USER_NOT_FOUND: 'U001',
} as const
```

---

## 💡 학습 포인트

### 1. TypeScript Generic의 힘

```typescript
// Generic 없이: 중복 코드
interface LoginResponse {
  success: boolean
  data: LoginData | null
}

interface MessageResponse {
  success: boolean
  data: MessageData | null
}

// Generic 사용: 재사용 가능
interface ApiResponse<T> {
  success: boolean
  data: T | null
}

type LoginResponse = ApiResponse<LoginData>
type MessageResponse = ApiResponse<MessageData>
```

### 2. Axios Interceptor 패턴

**왜 사용하는가?**
- 모든 요청에 JWT 토큰 자동 추가
- 401 에러 시 자동 로그아웃
- 에러 처리 중앙화

### 3. Type-safe API 함수

```typescript
// TypeScript가 자동으로 타입 체크
const response = await login({ 
  username: 'test',
  password: '1234' 
})

// response.data는 LoginResponseData 타입
if (response.data) {
  const token = response.data.accessToken // ✅ 타입 안전
}
```

---

## 📚 다음 단계

Phase 1 완료! 타입 안전한 API 레이어가 구축되었습니다.

**다음**: [02-AUTHENTICATION-SYSTEM.md](./02-AUTHENTICATION-SYSTEM.md) - 실제 로그인/회원가입 구현 →

---

## 🎨 전체 흐름 시각화

### 로그인 API 호출 예시

```
┌─────────────────────────────────────────────────────────────┐
│ LoginPage.tsx                                                │
├─────────────────────────────────────────────────────────────┤
│  const response = await login({                             │
│    username: 'testuser',                                     │
│    password: 'password123'                                   │
│  })                                                          │
│                                                              │
│  ↓ 호출                                                       │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│ authApi.ts                                                   │
├─────────────────────────────────────────────────────────────┤
│  export const login = async (                                │
│    request: LoginRequest                                     │
│  ): Promise<ApiResponse<LoginResponseData>> => {            │
│    return client.post('/auth/login', request)               │
│  }                                                           │
│                                                              │
│  ↓ client.post() 호출                                        │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│ client.ts - Request Interceptor                             │
├─────────────────────────────────────────────────────────────┤
│  config.headers.Authorization = `Bearer ${token}`           │
│                                                              │
│  ↓ HTTP 요청                                                 │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│ 백엔드 서버 (Spring Boot)                                     │
├─────────────────────────────────────────────────────────────┤
│  POST /api/v1/auth/login                                     │
│                                                              │
│  ↓ 응답 (JSON)                                               │
│  {                                                           │
│    "success": true,                                          │
│    "data": {                                                 │
│      "accessToken": "eyJhbGc...",                           │
│      "userId": "abc-123",                                    │
│      "username": "testuser",                                 │
│      "role": "USER"                                          │
│    },                                                        │
│    "error": null,                                            │
│    "timestamp": "2025-12-26T10:30:00"                        │
│  }                                                           │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│ Axios                                                        │
├─────────────────────────────────────────────────────────────┤
│  AxiosResponse = {                                           │
│    data: { ← 백엔드 JSON이 여기에!                            │
│      success: true,                                          │
│      data: { accessToken, userId, ... },                     │
│      error: null,                                            │
│      timestamp: "..."                                        │
│    },                                                        │
│    status: 200,                                              │
│    headers: {...}                                            │
│  }                                                           │
│                                                              │
│  ↓ Response Interceptor로 전달                               │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│ client.ts - Response Interceptor                            │
├─────────────────────────────────────────────────────────────┤
│  return response.data  // ApiResponse 전체 반환              │
│                                                              │
│  반환값:                                                      │
│  {                                                           │
│    success: true,                                            │
│    data: { accessToken, userId, ... },                       │
│    error: null,                                              │
│    timestamp: "..."                                          │
│  }                                                           │
│                                                              │
│  ↓ authApi.login()으로 반환                                  │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│ LoginPage.tsx                                                │
├─────────────────────────────────────────────────────────────┤
│  const response = {                                          │
│    success: true,                                            │
│    data: {                                                   │
│      accessToken: "eyJhbGc...",                             │
│      userId: "abc-123",                                      │
│      username: "testuser",                                   │
│      role: "USER"                                            │
│    },                                                        │
│    error: null,                                              │
│    timestamp: "2025-12-26T10:30:00"                          │
│  }                                                           │
│                                                              │
│  if (response.success && response.data) {                    │
│    const token = response.data.accessToken  // ✅ 올바름     │
│    login(token, response.data.userId, ...)                   │
│  }                                                           │
└─────────────────────────────────────────────────────────────┘
```

### 핵심 정리

| 위치 | 변수명 | 타입 | 설명 |
|------|--------|------|------|
| 백엔드 | JSON 응답 | `ApiResponse<LoginResponseData>` | `{ success, data, error, timestamp }` |
| Axios | `response.data` | `ApiResponse<LoginResponseData>` | 백엔드 JSON 그대로 |
| Interceptor | `return response.data` | `ApiResponse<LoginResponseData>` | 그대로 반환 |
| API 함수 | `return client.post(...)` | `Promise<ApiResponse<LoginResponseData>>` | 그대로 반환 |
| 컴포넌트 | `const response = await login(...)` | `ApiResponse<LoginResponseData>` | 최종 사용 |

**접근 방법**:
```typescript
// ✅ 올바른 접근
response.success         // boolean
response.data            // LoginResponseData | null
response.data.accessToken // string (data가 null이 아닐 때)
response.error           // ApiError | null
response.timestamp       // string

// ❌ 잘못된 접근
response.accessToken     // undefined
response.data.data       // 없음!
```

