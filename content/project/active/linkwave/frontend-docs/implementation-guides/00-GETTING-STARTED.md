---
created: 2025-12-26
---
# LinkWave Frontend 시작하기

## 📚 개요

이 가이드는 LinkWave 프로젝트의 프론트엔드를 **백엔드 API와 연동**하기 위한 환경 설정 및 기본 구조를 안내합니다.

### 🎯 학습 목표

- Vite + TypeScript 환경 설정
- API 클라이언트 (Axios) 구성
- 환경 변수 관리
- 프로젝트 구조 이해

---

## 🏗️ 전체 아키텍처

```
┌─────────────────────────────────────────────────────────────┐
│                    Frontend (React + Vite)                   │
├─────────────────────────────────────────────────────────────┤
│  Pages                                                       │
│  ├── LoginPage, SignupPage (인증)                            │
│  ├── DashboardPage (통계)                                    │
│  └── SmsPage, LmsPage, MmsPage (메시지 발송)                 │
├─────────────────────────────────────────────────────────────┤
│  Stores (Zustand)                                            │
│  ├── authStore (인증 상태, 토큰 관리)                        │
│  └── messageFormStore (메시지 폼 상태)                       │
├─────────────────────────────────────────────────────────────┤
│  API Layer                                                   │
│  ├── client.ts (Axios 인스턴스, Interceptor)                 │
│  ├── authApi.ts (인증 API)                                   │
│  ├── messageApi.ts (메시지 API)                              │
│  └── statisticsApi.ts (통계 API)                             │
└─────────────────────────────────────────────────────────────┘
                          │
                          │ HTTP (Axios)
                          ▼
┌─────────────────────────────────────────────────────────────┐
│                    Backend (Spring Boot)                     │
│  /api/v1/auth, /api/v1/messages, /api/v1/statistics          │
└─────────────────────────────────────────────────────────────┘
```

---

## 📋 사전 준비

### 1. 필수 소프트웨어

```bash
# Node.js 20+ 확인
node -v

# npm 확인
npm -v
```

### 2. 프로젝트 의존성 설치

```bash
cd linkwave-frontend
npm install
```

---

## 🔧 환경 설정

### 1. vite-env.d.ts 생성 ⭐ 필수

`src/vite-env.d.ts` 파일을 생성합니다:

```typescript
/// <reference types="vite/client" />
```

**이 파일이 없으면** `import.meta.env` 에러가 발생합니다.

### 2. 환경 변수 파일

프로젝트 루트에 `.env` 파일 생성:

```bash
# .env.development (로컬 개발)
VITE_API_BASE_URL=http://localhost:8090/api/v1

# .env.production (배포)
VITE_API_BASE_URL=/api/v1
```

### 3. Vite Proxy 설정 (선택)

CORS 문제 해결을 위해 `vite.config.ts`에 proxy 설정:

```typescript
import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'

export default defineConfig({
  plugins: [react()],
  server: {
    port: 3000,
    proxy: {
      '/api': {
        target: 'http://localhost:8090',
        changeOrigin: true
      }
    }
  }
})
```

---

## 📁 프로젝트 구조

```
src/
├── api/                    # API 클라이언트
│   ├── client.ts           # Axios 인스턴스 + Interceptor
│   ├── authApi.ts          # 인증 API
│   ├── messageApi.ts       # 메시지 API
│   └── statisticsApi.ts    # 통계 API
├── types/                  # TypeScript 타입 정의
│   ├── api.ts              # 공통 API 응답 타입
│   ├── login.ts            # 로그인/회원가입 타입
│   ├── signup.ts           # 회원가입 폼 타입
│   ├── message.ts          # 메시지 관련 타입
│   └── user.ts             # 사용자 타입
├── stores/                 # Zustand 상태 관리
│   ├── authStore.ts        # 인증 상태
│   ├── signupStore.ts      # 회원가입 상태
│   └── messageFormStore.ts # 메시지 폼 상태
├── pages/                  # 페이지 컴포넌트
├── routes/                 # TanStack Router
├── components/             # 재사용 컴포넌트
│   ├── ui/                 # shadcn/ui 컴포넌트
│   ├── signup/             # 회원가입 컴포넌트
│   └── message/            # 메시지 컴포넌트
├── hooks/                  # 커스텀 훅
├── utils/                  # 유틸리티 함수
├── App.tsx                 # 앱 진입점
├── main.tsx                # React DOM 렌더링
└── vite-env.d.ts           # Vite 타입 선언 ⭐
```

---

## 💻 API 클라이언트 설정

### client.ts 기본 구조

```typescript
// src/api/client.ts
import axios, { AxiosInstance, InternalAxiosRequestConfig, AxiosResponse } from 'axios'

const client: AxiosInstance = axios.create({
  baseURL: import.meta.env.VITE_API_BASE_URL || '/api/v1',
  timeout: 30000,
  headers: {
    'Content-Type': 'application/json',
  },
})

// Request Interceptor - JWT 토큰 추가
client.interceptors.request.use(
  (config: InternalAxiosRequestConfig) => {
    const token = localStorage.getItem('auth-token')
    if (token && config.headers) {
      config.headers.Authorization = `Bearer ${token}`
    }
    return config
  },
  (error) => Promise.reject(error)
)

// Response Interceptor - 에러 처리
client.interceptors.response.use(
  (response: AxiosResponse) => response.data,
  (error) => {
    if (error.response?.status === 401) {
      // 토큰 만료 시 로그인 페이지로 리다이렉트
      localStorage.removeItem('auth-token')
      localStorage.removeItem('auth-storage')
      window.location.href = '/login'
    }
    return Promise.reject(error)
  }
)

export default client
```

---

## 🔗 백엔드 API 응답 형식

백엔드는 모든 API에서 통일된 응답 형식을 사용합니다:

```typescript
// src/types/api.ts
export interface ApiResponse<T = unknown> {
  success: boolean
  data: T | null
  error: ApiError | null
  timestamp: string
}

export interface ApiError {
  code: string
  message: string
  details?: Record<string, unknown>
}
```

### 성공 응답 예시

```json
{
  "success": true,
  "data": {
    "accessToken": "eyJhbGciOiJIUzI1NiJ9...",
    "tokenType": "Bearer",
    "userId": "user-123",
    "username": "testuser",
    "role": "USER"
  },
  "error": null,
  "timestamp": "2025-12-24T10:30:00"
}
```

### 에러 응답 예시

```json
{
  "success": false,
  "data": null,
  "error": {
    "code": "U001",
    "message": "아이디 또는 비밀번호가 일치하지 않습니다"
  },
  "timestamp": "2025-12-24T10:30:00"
}
```

---

## 🚀 개발 서버 실행

```bash
# 개발 서버 시작
npm run dev

# 빌드
npm run build

# 타입 체크
npx tsc --noEmit

# 린트
npm run lint
```

---

## ✅ 환경 설정 체크리스트

- [ ] Node.js 20+ 설치
- [ ] `npm install` 완료
- [ ] `src/vite-env.d.ts` 생성
- [ ] `.env.development` 파일 생성
- [ ] `npm run dev` 정상 실행
- [ ] 타입 에러 없음 (`npx tsc --noEmit`)

---

## 💡 핵심 인사이트

### 왜 vite-env.d.ts가 필요한가?

```typescript
// ❌ vite-env.d.ts 없이
const baseUrl = import.meta.env.VITE_API_BASE_URL
// Error: Property 'env' does not exist on type 'ImportMeta'

// ✅ vite-env.d.ts 있으면
/// <reference types="vite/client" />
const baseUrl = import.meta.env.VITE_API_BASE_URL // 정상 작동
```

Vite는 `import.meta.env`를 사용하지만, TypeScript는 이를 모릅니다.
`vite/client` 타입 참조를 추가하면 TypeScript가 Vite의 환경 변수를 인식합니다.

### 왜 Interceptor를 사용하는가?

```typescript
// ❌ 모든 API 호출마다 토큰 추가
const response = await axios.get('/api/users', {
  headers: { Authorization: `Bearer ${token}` }
})

// ✅ Interceptor로 자동 처리
const response = await client.get('/users')
// → Request Interceptor가 자동으로 토큰 추가
```

---

## 📚 다음 단계

1. **API 연동 기초**: [01-API-INTEGRATION.md](./01-API-INTEGRATION.md)
2. **인증 API 구현**: [02-AUTH-API.md](./02-AUTH-API.md)
3. **메시지 API 구현**: [03-MESSAGE-API.md](./03-MESSAGE-API.md)

---

**준비되셨나요? [01-API-INTEGRATION.md](./01-API-INTEGRATION.md)로 이동하세요!** 👉

