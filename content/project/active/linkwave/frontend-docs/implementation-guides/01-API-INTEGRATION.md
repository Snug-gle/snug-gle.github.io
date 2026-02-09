---
created: 2025-12-26
---
# 01. API 연동 기초

## 📌 학습 목표

이 가이드를 통해 다음을 학습합니다:

1. **Axios 클라이언트** 설정 및 Interceptor 구현
2. **백엔드 API 응답 형식** 이해 및 타입 정의
3. **에러 처리** 패턴
4. **토큰 관리** (Access Token, Refresh Token)

---

## 🏗️ API 클라이언트 아키텍처

```
┌─────────────────────────────────────────────────────────────────────────┐
│                          API 호출 흐름                                   │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│  Component                                                              │
│      │                                                                  │
│      ▼                                                                  │
│  authApi.login({ username, password })                                  │
│      │                                                                  │
│      ▼                                                                  │
│  client.post('/auth/login', data)                                       │
│      │                                                                  │
│      ├─► Request Interceptor ─── JWT 토큰 헤더 추가                     │
│      │                                                                  │
│      ▼                                                                  │
│  Axios HTTP Request ───────────────────────────► Backend API            │
│      │                                                                  │
│      ◄─── HTTP Response ◄────────────────────────────────────────────── │
│      │                                                                  │
│      ├─► Response Interceptor ── response.data 추출, 에러 처리          │
│      │                                                                  │
│      ▼                                                                  │
│  { success: true, data: { accessToken, ... } }                          │
│      │                                                                  │
│      ▼                                                                  │
│  Component에서 결과 처리                                                │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## 📝 1. 타입 정의

### 공통 API 응답 타입

**파일**: `src/types/api.ts`

```typescript
// 공통 API 응답 타입 (백엔드 ApiResponse<T>와 매칭)
export interface ApiResponse<T = unknown> {
  success: boolean
  data: T | null
  error: ApiError | null
  timestamp: string
}

// 에러 응답
export interface ApiError {
  code: string
  message: string
  details?: Record<string, unknown>
}

// 페이지네이션 파라미터
export interface PaginationParams {
  page: number
  size: number
}

// 페이지네이션 응답
export interface PaginatedResponse<T> {
  content: T[]
  totalElements: number
  totalPages: number
  size: number
  number: number
  first: boolean
  last: boolean
}
```

### 인증 관련 타입

**파일**: `src/types/login.ts`

```typescript
// 로그인 요청
export interface LoginRequest {
  username: string
  password: string
}

// 로그인 응답 (회원가입도 동일)
export interface LoginResponse {
  accessToken: string
  tokenType: string
  userId: string
  username: string
  role: string
}

// 아이디 중복 확인 응답
export interface CheckUsernameResponse {
  available: boolean
  message: string
}

// 인증번호 발송 응답
export interface VerificationResponse {
  success: boolean
  message: string
}

// 인증번호 확인 응답
export interface VerifyCodeResponse {
  verified: boolean
  message: string
  phoneVerificationToken?: string
}
```

---

## 📝 2. API 클라이언트 구현

**파일**: `src/api/client.ts`

```typescript
import axios, { AxiosInstance, InternalAxiosRequestConfig, AxiosResponse, AxiosError } from 'axios'

const client: AxiosInstance = axios.create({
  baseURL: import.meta.env.VITE_API_BASE_URL || '/api/v1',
  timeout: 30000,
  headers: {
    'Content-Type': 'application/json',
  },
})

// ========== Request Interceptor ==========
client.interceptors.request.use(
  (config: InternalAxiosRequestConfig) => {
    // localStorage에서 토큰 가져오기
    const token = localStorage.getItem('auth-token')
    
    if (token && config.headers) {
      config.headers.Authorization = `Bearer ${token}`
    }
    
    // 요청 로깅 (개발 환경)
    if (import.meta.env.DEV) {
      console.log(`📤 [${config.method?.toUpperCase()}] ${config.url}`, config.data)
    }
    
    return config
  },
  (error) => Promise.reject(error)
)

// ========== Response Interceptor ==========
client.interceptors.response.use(
  (response: AxiosResponse) => {
    // 응답 로깅 (개발 환경)
    if (import.meta.env.DEV) {
      console.log(`📥 [${response.status}] ${response.config.url}`, response.data)
    }
    
    // response.data만 반환 (axios wrapper 해제)
    return response.data
  },
  async (error: AxiosError) => {
    const originalRequest = error.config as InternalAxiosRequestConfig & { _retry?: boolean }
    
    // 401 에러 처리
    if (error.response?.status === 401 && !originalRequest._retry) {
      originalRequest._retry = true
      
      // Refresh Token으로 재발급 시도
      const refreshToken = localStorage.getItem('refresh-token')
      if (refreshToken) {
        try {
          const response = await axios.post(
            `${import.meta.env.VITE_API_BASE_URL}/auth/refresh`,
            { refreshToken }
          )
          
          const newAccessToken = response.data.data.accessToken
          localStorage.setItem('auth-token', newAccessToken)
          
          // 원래 요청 재시도
          originalRequest.headers.Authorization = `Bearer ${newAccessToken}`
          return client(originalRequest)
        } catch (refreshError) {
          // Refresh도 실패 → 로그아웃
          localStorage.removeItem('auth-token')
          localStorage.removeItem('refresh-token')
          localStorage.removeItem('auth-storage')
          window.location.href = '/login'
          return Promise.reject(refreshError)
        }
      } else {
        // Refresh Token 없음 → 로그아웃
        localStorage.removeItem('auth-token')
        localStorage.removeItem('auth-storage')
        window.location.href = '/login'
      }
    }
    
    // 에러 로깅
    if (import.meta.env.DEV) {
      console.error(`❌ [${error.response?.status}] ${error.config?.url}`, error.response?.data)
    }
    
    return Promise.reject(error)
  }
)

export default client
```

---

## 📝 3. 인증 API 구현

**파일**: `src/api/authApi.ts`

```typescript
import client from './client'
import type { ApiResponse } from '@/types/api'
import type { 
  LoginRequest, 
  LoginResponse, 
  CheckUsernameResponse,
  VerificationResponse,
  VerifyCodeResponse 
} from '@/types/login'
import type { SignupFormData } from '@/types/signup'

export const authApi = {
  /**
   * 로그인
   * POST /api/v1/auth/login
   */
  login: async (credentials: LoginRequest): Promise<LoginResponse> => {
    const response: ApiResponse<LoginResponse> = await client.post('/auth/login', credentials)
    
    if (!response.success || !response.data) {
      throw new Error(response.error?.message || '로그인에 실패했습니다')
    }
    
    return response.data
  },

  /**
   * 회원가입
   * POST /api/v1/auth/signup
   * 응답 형식: 로그인과 동일
   */
  signup: async (signupData: SignupFormData): Promise<LoginResponse> => {
    // 백엔드 SignUpRequest 형식으로 변환
    const requestBody = {
      username: signupData.username,
      password: signupData.password,
      name: signupData.name,
      phone: signupData.phoneNumber.replace(/-/g, ''), // 하이픈 제거
      email: signupData.email || null,
      displayName: signupData.name,
      userType: signupData.userType,
      organizationId: signupData.userType === 'BUSINESS' ? null : null // TODO: 조직 선택 UI
    }

    const response: ApiResponse<LoginResponse> = await client.post('/auth/signup', requestBody)

    if (!response.success || !response.data) {
      throw new Error(response.error?.message || '회원가입에 실패했습니다')
    }

    return response.data
  },

  /**
   * 아이디 중복 확인
   * GET /api/v1/auth/check-username?username={username}
   */
  checkUsername: async (username: string): Promise<CheckUsernameResponse> => {
    const response: ApiResponse<boolean> = await client.get(
      `/auth/check-username?username=${encodeURIComponent(username)}`
    )

    const available = response.data === true
    return {
      available,
      message: available ? '사용 가능한 아이디입니다' : '이미 사용 중인 아이디입니다'
    }
  },

  /**
   * 휴대폰 인증번호 요청
   * POST /api/v1/auth/phone/request-verification
   */
  sendVerificationCode: async (phone: string): Promise<VerificationResponse> => {
    const response: ApiResponse<void> = await client.post('/auth/phone/request-verification', {
      phone: phone.replace(/-/g, '')
    })

    return {
      success: response.success,
      message: response.success ? '인증번호가 발송되었습니다' : '발송에 실패했습니다'
    }
  },

  /**
   * 휴대폰 인증번호 확인
   * POST /api/v1/auth/phone/verify
   */
  verifyCode: async (phone: string, code: string): Promise<VerifyCodeResponse> => {
    const response: ApiResponse<{ phoneVerificationToken: string }> = await client.post(
      '/auth/phone/verify',
      {
        phone: phone.replace(/-/g, ''),
        verificationCode: code
      }
    )

    return {
      verified: response.success,
      message: response.success ? '인증이 완료되었습니다' : '인증에 실패했습니다',
      phoneVerificationToken: response.data?.phoneVerificationToken
    }
  },

  /**
   * Access Token 재발급
   * POST /api/v1/auth/refresh
   */
  refreshToken: async (refreshToken: string): Promise<{ accessToken: string }> => {
    const response: ApiResponse<{ accessToken: string; tokenType: string; expiresIn: number }> = 
      await client.post('/auth/refresh', { refreshToken })

    if (!response.success || !response.data) {
      throw new Error('토큰 재발급에 실패했습니다')
    }

    return { accessToken: response.data.accessToken }
  },

  /**
   * 로그아웃
   * POST /api/v1/auth/logout
   */
  logout: async (refreshToken: string): Promise<void> => {
    await client.post('/auth/logout', { refreshToken })
  },

  /**
   * 모든 기기에서 로그아웃
   * POST /api/v1/auth/logout-all
   */
  logoutAll: async (): Promise<void> => {
    await client.post('/auth/logout-all')
  }
}
```

---

## 📝 4. 메시지 API 구현

**파일**: `src/api/messageApi.ts`

```typescript
import client from './client'
import type { ApiResponse } from '@/types/api'

// 메시지 발송 요청 타입
export interface SendMessageRequest {
  channel: 'SMS' | 'LMS' | 'MMS' | 'KAKAO' | 'RCS' | 'PUSH'
  sendType: 'IMMEDIATE' | 'SCHEDULED' | 'BULK'
  scheduledAt?: string // ISO 8601 (예약 발송 시)
  phones: string[]
  message: string
  title?: string // LMS, MMS용
  callback: string // 발신번호
  fallbackChannel?: string
  fallbackMessage?: string
  campaignId?: string
}

// 메시지 발송 응답 타입
export interface SendMessageResponse {
  groupId: string
  totalCount: number
  scheduledAt?: string
  status: 'QUEUED' | 'SCHEDULED'
  message: string
}

// 발송 취소 응답 타입
export interface CancelResponse {
  groupId: string
  cancelledCount: number
  message: string
}

export const messageApi = {
  /**
   * 메시지 발송 (즉시/예약/대량)
   * POST /api/v1/messages
   */
  send: async (request: SendMessageRequest): Promise<SendMessageResponse> => {
    const response: ApiResponse<SendMessageResponse> = await client.post('/messages', request)

    if (!response.success || !response.data) {
      throw new Error(response.error?.message || '메시지 발송에 실패했습니다')
    }

    return response.data
  },

  /**
   * 예약 발송 취소
   * DELETE /api/v1/messages/scheduled/{groupId}
   */
  cancelScheduled: async (groupId: string): Promise<CancelResponse> => {
    const response: ApiResponse<CancelResponse> = await client.delete(
      `/messages/scheduled/${groupId}`
    )

    if (!response.success || !response.data) {
      throw new Error(response.error?.message || '예약 취소에 실패했습니다')
    }

    return response.data
  },

  /**
   * 발송 그룹 상태 조회
   * GET /api/v1/messages/group/{groupId}
   */
  getGroupStatus: async (groupId: string): Promise<unknown> => {
    const response: ApiResponse<unknown> = await client.get(`/messages/group/${groupId}`)

    if (!response.success) {
      throw new Error(response.error?.message || '조회에 실패했습니다')
    }

    return response.data
  }
}
```

---

## 📝 5. 통계 API 구현

**파일**: `src/api/statisticsApi.ts`

```typescript
import client from './client'
import type { ApiResponse } from '@/types/api'

// 대시보드 응답 타입
export interface DashboardResponse {
  totalCount: number
  pendingCount: number
  successCount: number
  failCount: number
  successRate: number
  dailyStats: DailyStats[]
}

export interface DailyStats {
  date: string
  channel: string
  total: number
  pending: number
  success: number
  fail: number
}

export const statisticsApi = {
  /**
   * 대시보드 통계 조회
   * GET /api/v1/statistics/dashboard?startDate=2025-12-01&endDate=2025-12-24
   */
  getDashboard: async (startDate: string, endDate: string): Promise<DashboardResponse> => {
    const response: ApiResponse<DashboardResponse> = await client.get(
      `/statistics/dashboard?startDate=${startDate}&endDate=${endDate}`
    )

    if (!response.success || !response.data) {
      throw new Error(response.error?.message || '통계 조회에 실패했습니다')
    }

    return response.data
  }
}
```

---

## 💡 핵심 인사이트

### 1. 왜 response.data를 Interceptor에서 추출하는가?

```typescript
// ❌ 매번 .data 접근
const response = await axios.get('/users')
const users = response.data.data  // response.data (axios) → .data (ApiResponse)

// ✅ Interceptor에서 처리
// Response Interceptor: return response.data
const apiResponse = await client.get('/users')
const users = apiResponse.data  // ApiResponse.data만 접근
```

### 2. 에러 코드별 처리

```typescript
// 컴포넌트에서 에러 처리
try {
  const result = await authApi.login(credentials)
  // 성공 처리
} catch (error) {
  if (axios.isAxiosError(error)) {
    const apiError = error.response?.data?.error
    
    switch (apiError?.code) {
      case 'U001':
        toast.error('사용자를 찾을 수 없습니다')
        break
      case 'U002':
        toast.error('비밀번호가 일치하지 않습니다')
        break
      default:
        toast.error(apiError?.message || '로그인에 실패했습니다')
    }
  }
}
```

### 3. 토큰 자동 갱신 플로우

```
1. API 호출
2. 401 Unauthorized 응답
3. Refresh Token으로 재발급 시도
   ├── 성공 → 새 Access Token 저장 → 원래 요청 재시도
   └── 실패 → 로그아웃 처리 → 로그인 페이지 이동
```

---

## ✅ 구현 체크리스트

### 타입 정의

- [ ] `src/types/api.ts` - ApiResponse, ApiError
- [ ] `src/types/login.ts` - LoginRequest, LoginResponse 등
- [ ] `src/types/signup.ts` - SignupFormData
- [ ] `src/types/message.ts` - SendMessageRequest 등

### API 클라이언트

- [ ] `src/api/client.ts` - Axios 인스턴스, Interceptors
- [ ] `src/api/authApi.ts` - 인증 API 함수
- [ ] `src/api/messageApi.ts` - 메시지 API 함수
- [ ] `src/api/statisticsApi.ts` - 통계 API 함수

### 환경 설정

- [ ] `src/vite-env.d.ts` - Vite 타입 선언
- [ ] `.env.development` - 개발 환경 변수
- [ ] `.env.production` - 배포 환경 변수

---

## 📚 다음 단계

1. **인증 API 상세**: [02-AUTH-API.md](./02-AUTH-API.md)
2. **메시지 API 상세**: [03-MESSAGE-API.md](./03-MESSAGE-API.md)
3. **통계 API 상세**: [04-STATISTICS-API.md](./04-STATISTICS-API.md)

---

**다음 단계**: [02-AUTH-API.md](./02-AUTH-API.md) 👉

