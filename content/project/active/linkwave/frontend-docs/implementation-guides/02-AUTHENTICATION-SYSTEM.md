---
created: 2025-12-26
---
# Phase 2: 인증 시스템 구현

## 📖 개념 설명

### 왜 이 Phase가 중요한가?

인증 시스템은 애플리케이션의 **보안 기반**입니다. 이 Phase에서는:

1. **JWT 기반 인증**: 토큰 발급, 저장, 검증 플로우
2. **Zustand 상태 관리**: 인증 상태를 전역으로 관리
3. **다단계 회원가입**: 6단계 회원가입 폼 상태 관리
4. **보호된 라우트**: 인증이 필요한 페이지 접근 제어

### JWT 인증 플로우

```
1. 사용자 로그인
   ↓
2. 백엔드가 JWT 토큰 발급
   ↓
3. 프론트엔드가 localStorage에 저장
   ↓
4. 이후 모든 API 요청에 토큰 포함 (Authorization Header)
   ↓
5. 백엔드가 토큰 검증
   ↓
6. 토큰 만료 시 401 에러 → 자동 로그아웃
```

### Zustand vs Redux

**왜 Zustand를 선택했는가?**

```typescript
// Redux: 보일러플레이트 많음
const authSlice = createSlice({
  name: 'auth',
  initialState: { token: null },
  reducers: {
    setToken: (state, action) => {
      state.token = action.payload
    }
  }
})

// Zustand: 간결함
const useAuthStore = create((set) => ({
  token: null,
  setToken: (token) => set({ token })
}))
```

**장점**:
- 보일러플레이트 최소화
- TypeScript 지원 우수
- React Hooks와 자연스럽게 통합
- persist middleware로 localStorage 자동 동기화

---

## 🎯 구현 목표

- [ ] `src/stores/authStore.ts` - 인증 상태 관리 (✅ 이미 구현됨)
- [ ] `src/stores/userStore.ts` - 사용자 정보 관리 (✅ 이미 구현됨)
- [ ] `src/stores/signupStore.ts` - 회원가입 상태 (✅ 이미 구현됨)
- [ ] `src/pages/LoginPage.tsx` - 실제 API 연동
- [ ] `src/pages/signup/*` - 회원가입 6단계 API 연동
- [ ] `src/routes/_authenticated.tsx` - 보호된 라우트 (✅ 이미 구현됨)
- [ ] `src/utils/validation.ts` - 유효성 검사 유틸

---

## 📝 Step 1: authStore 이해하기

### 파일: `src/stores/authStore.ts` (이미 구현됨)

```typescript
import type { UserType } from '@/types/user'
import { create } from 'zustand'
import { persist } from 'zustand/middleware'
import { useUserStore } from './userStore'

interface AuthState {
  // 상태
  token: string | null
  isAuthenticated: boolean
  userId: string | null
  userType: UserType | null
  organizationId: string | null

  // 액션
  login: (token: string, userId: string, userType: UserType, organizationId?: string) => void
  logout: () => void
  updateToken: (token: string) => void
}

export const useAuthStore = create<AuthState>()(
  persist(
    (set) => ({
      token: null,
      isAuthenticated: false,
      userId: null,
      userType: null,
      organizationId: null,

      login: (token, userId, userType, organizationId) => {
        localStorage.setItem('auth-token', token)
        set({
          token,
          userId,
          userType,
          organizationId: organizationId || null,
          isAuthenticated: true,
        })
      },

      logout: () => {
        localStorage.removeItem('auth-token')
        useUserStore.getState().clearUser()
        set({
          token: null,
          userId: null,
          userType: null,
          organizationId: null,
          isAuthenticated: false,
        })
      },

      updateToken: (token) => {
        localStorage.setItem('auth-token', token)
        set({ token })
      },
    }),
    {
      name: 'auth-storage',
      partialize: (state) => ({
        userId: state.userId,
        userType: state.userType,
        organizationId: state.organizationId,
        isAuthenticated: state.isAuthenticated,
      }),
    }
  )
)
```

**인사이트**:
- `persist` middleware: 새로고침 시에도 인증 상태 유지
- `partialize`: 토큰은 localStorage에만 저장 (보안)
- `logout` 시 userStore도 함께 클리어

---

## 📝 Step 2: LoginPage API 연동

### 파일: `src/pages/LoginPage.tsx`

기존 mock 코드를 실제 API 호출로 변경합니다.

```typescript
import { Button } from '@/components/ui/button'
import { Card, CardContent, CardDescription, CardFooter, CardHeader } from '@/components/ui/card'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { useAuthStore } from '@/stores/authStore'
import { useUserStore } from '@/stores/userStore'
import { login as loginApi } from '@/api/authApi'
import { useNavigate } from '@tanstack/react-router'
import { motion } from 'framer-motion'
import { Loader2 } from 'lucide-react'
import { useState, type FormEvent } from 'react'
import { toast } from 'react-hot-toast'

const LoginPage = () => {
  const [username, setUsername] = useState('')
  const [password, setPassword] = useState('')
  const [loading, setLoading] = useState(false)
  const navigate = useNavigate()
  const login = useAuthStore((state) => state.login)
  const setUser = useUserStore((state) => state.setUser)

  const handleSubmit = async (e: FormEvent<HTMLFormElement>) => {
    e.preventDefault()
    setLoading(true)

    try {
      // 실제 API 호출
      const response = await loginApi({ username, password })

      if (response.success && response.data) {
        const { accessToken, userId, username, email, role, userType, organizationId } = response.data

        // authStore 업데이트
        login(accessToken, userId, userType || 'INDIVIDUAL', organizationId)

        // userStore 업데이트
        setUser({
          userId,
          username,
          email: email || `${username}@example.com`,
          name: username,
          role,
          phoneNumber: '',
          userType,
          organizationId,
          createdAt: new Date().toISOString(),
        })

        toast.success('로그인 성공!')
        navigate({ to: '/dashboard' })
      } else {
        toast.error(response.error?.message || '로그인에 실패했습니다.')
      }
    } catch (error: any) {
      const errorMessage = error.response?.data?.error?.message || '로그인에 실패했습니다.'
      toast.error(errorMessage)
    } finally {
      setLoading(false)
    }
  }

  return (
    <div className="min-h-screen flex items-center justify-center bg-background px-4 py-12">
      <motion.div
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ duration: 0.5 }}
        className="w-full max-w-md"
      >
        <Card className="shadow-xl">
          <CardHeader className="text-center space-y-2">
            <div className="flex items-baseline justify-center gap-2 mb-2">
              <span className="text-2xl font-bold text-primary">IOTREE</span>
              <span className="text-3xl font-bold text-foreground">LinkWave</span>
            </div>
            <CardDescription className="text-lg">
              연결의 혁신, 메시지의 미래
            </CardDescription>
          </CardHeader>
          <CardContent>
            <form onSubmit={handleSubmit} className="flex flex-col gap-6">
              <div className="space-y-2">
                <Label htmlFor="username">
                  아이디<span className="text-destructive ml-1">*</span>
                </Label>
                <Input
                  id="username"
                  type="text"
                  value={username}
                  onChange={(e) => setUsername(e.target.value)}
                  placeholder="아이디를 입력하세요"
                  required
                />
              </div>

              <div className="space-y-2">
                <Label htmlFor="password">
                  비밀번호<span className="text-destructive ml-1">*</span>
                </Label>
                <Input
                  id="password"
                  type="password"
                  value={password}
                  onChange={(e) => setPassword(e.target.value)}
                  placeholder="비밀번호를 입력하세요"
                  required
                />
              </div>

              <Button type="submit" disabled={loading} className="w-full mt-2" size="lg">
                {loading && <Loader2 className="size-4 animate-spin mr-2" />}
                로그인
              </Button>
            </form>
          </CardContent>
          <CardFooter className="flex-col">
            <div className="relative w-full flex items-center justify-center text-sm text-muted-foreground my-6">
              <div className="absolute left-0 w-full h-px bg-border" />
              <span className="relative bg-card px-2">또는</span>
            </div>
            <Button
              type="button"
              variant="outline"
              onClick={() => navigate({ to: '/signup' })}
              className="w-full font-semibold border-2 border-primary text-foreground hover:bg-primary/5"
              size="lg"
            >
              회원가입
            </Button>
          </CardFooter>
        </Card>
      </motion.div>
    </div>
  )
}

export default LoginPage
```

**변경 사항**:
1. `loginApi` import 및 호출
2. `response.data`에서 사용자 정보 추출
3. authStore와 userStore 모두 업데이트
4. 에러 처리 개선 (백엔드 에러 메시지 표시)

---

## 📝 Step 3: 회원가입 API 연동

### 파일: `src/pages/signup/Step6Review.tsx`

최종 단계에서 실제 회원가입 API를 호출합니다.

```typescript
import { useState } from 'react'
import { useNavigate } from '@tanstack/react-router'
import { useSignupStore } from '@/stores/signupStore'
import { useAuthStore } from '@/stores/authStore'
import { useUserStore } from '@/stores/userStore'
import { signup as signupApi } from '@/api/authApi'
import { Button } from '@/components/ui/button'
import { toast } from 'react-hot-toast'
import { Loader2 } from 'lucide-react'

const Step6Review = () => {
  const [loading, setLoading] = useState(false)
  const navigate = useNavigate()
  const signupData = useSignupStore((state) => state)
  const login = useAuthStore((state) => state.login)
  const setUser = useUserStore((state) => state.setUser)
  const resetSignup = useSignupStore((state) => state.reset)

  const handleSubmit = async () => {
    setLoading(true)

    try {
      // 회원가입 API 호출
      const response = await signupApi({
        username: signupData.username,
        password: signupData.password,
        name: signupData.name,
        phone: signupData.phone,
        email: signupData.email,
        userType: signupData.userType,
        organizationId: signupData.organizationId,
      })

      if (response.success && response.data) {
        const { accessToken, userId, username, role, userType, organizationId } = response.data

        // 자동 로그인
        login(accessToken, userId, userType || 'INDIVIDUAL', organizationId)
        
        setUser({
          userId,
          username,
          email: signupData.email || '',
          name: signupData.name,
          role,
          phoneNumber: signupData.phone,
          userType,
          organizationId,
          createdAt: new Date().toISOString(),
        })

        // 회원가입 상태 초기화
        resetSignup()

        toast.success('회원가입이 완료되었습니다!')
        navigate({ to: '/dashboard' })
      } else {
        toast.error(response.error?.message || '회원가입에 실패했습니다.')
      }
    } catch (error: any) {
      const errorMessage = error.response?.data?.error?.message || '회원가입에 실패했습니다.'
      toast.error(errorMessage)
    } finally {
      setLoading(false)
    }
  }

  return (
    <div className="space-y-6">
      <h2 className="text-2xl font-bold">정보 확인</h2>
      
      {/* 입력 정보 표시 */}
      <div className="space-y-4">
        <InfoItem label="아이디" value={signupData.username} />
        <InfoItem label="이름" value={signupData.name} />
        <InfoItem label="휴대폰" value={signupData.phone} />
        <InfoItem label="이메일" value={signupData.email} />
        <InfoItem label="회원유형" value={signupData.userType === 'INDIVIDUAL' ? '개인' : '법인'} />
      </div>

      <Button
        onClick={handleSubmit}
        disabled={loading}
        className="w-full"
        size="lg"
      >
        {loading && <Loader2 className="size-4 animate-spin mr-2" />}
        가입 완료
      </Button>
    </div>
  )
}

const InfoItem = ({ label, value }: { label: string; value: string }) => (
  <div className="flex justify-between py-2 border-b">
    <span className="text-muted-foreground">{label}</span>
    <span className="font-medium">{value}</span>
  </div>
)

export default Step6Review
```

---

## 📝 Step 4: 휴대폰 인증 구현

### 파일: `src/pages/signup/Step2Phone.tsx`

```typescript
import { useState } from 'react'
import { useSignupStore } from '@/stores/signupStore'
import { requestPhoneVerification, verifyPhone } from '@/api/authApi'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { toast } from 'react-hot-toast'
import { Loader2 } from 'lucide-react'

const Step2Phone = ({ onNext }: { onNext: () => void }) => {
  const [phone, setPhone] = useState('')
  const [verificationCode, setVerificationCode] = useState('')
  const [codeSent, setCodeSent] = useState(false)
  const [loading, setLoading] = useState(false)
  const [verifyLoading, setVerifyLoading] = useState(false)
  const setPhoneNumber = useSignupStore((state) => state.setPhoneNumber)

  // 인증번호 요청
  const handleRequestCode = async () => {
    if (!phone) {
      toast.error('휴대폰 번호를 입력하세요')
      return
    }

    setLoading(true)
    try {
      const response = await requestPhoneVerification({ phone })
      
      if (response.success) {
        setCodeSent(true)
        toast.success('인증번호가 발송되었습니다')
      } else {
        toast.error(response.error?.message || '인증번호 발송 실패')
      }
    } catch (error: any) {
      toast.error(error.response?.data?.error?.message || '인증번호 발송 실패')
    } finally {
      setLoading(false)
    }
  }

  // 인증번호 확인
  const handleVerifyCode = async () => {
    if (!verificationCode) {
      toast.error('인증번호를 입력하세요')
      return
    }

    setVerifyLoading(true)
    try {
      const response = await verifyPhone({ phone, verificationCode })
      
      if (response.success && response.data) {
        setPhoneNumber(phone)
        toast.success('휴대폰 인증 완료!')
        onNext()
      } else {
        toast.error(response.error?.message || '인증번호가 일치하지 않습니다')
      }
    } catch (error: any) {
      toast.error(error.response?.data?.error?.message || '인증 실패')
    } finally {
      setVerifyLoading(false)
    }
  }

  return (
    <div className="space-y-6">
      <h2 className="text-2xl font-bold">휴대폰 인증</h2>

      <div className="space-y-2">
        <Label htmlFor="phone">휴대폰 번호</Label>
        <div className="flex gap-2">
          <Input
            id="phone"
            type="tel"
            value={phone}
            onChange={(e) => setPhone(e.target.value)}
            placeholder="010-1234-5678"
            disabled={codeSent}
          />
          <Button
            onClick={handleRequestCode}
            disabled={loading || codeSent}
            variant="outline"
          >
            {loading && <Loader2 className="size-4 animate-spin mr-2" />}
            {codeSent ? '발송됨' : '인증번호 발송'}
          </Button>
        </div>
      </div>

      {codeSent && (
        <div className="space-y-2">
          <Label htmlFor="code">인증번호</Label>
          <div className="flex gap-2">
            <Input
              id="code"
              type="text"
              value={verificationCode}
              onChange={(e) => setVerificationCode(e.target.value)}
              placeholder="6자리 인증번호"
              maxLength={6}
            />
            <Button onClick={handleVerifyCode} disabled={verifyLoading}>
              {verifyLoading && <Loader2 className="size-4 animate-spin mr-2" />}
              확인
            </Button>
          </div>
        </div>
      )}
    </div>
  )
}

export default Step2Phone
```

**인사이트**:
- 2단계 인증: 인증번호 요청 → 확인
- 상태 관리: `codeSent` 플래그로 UI 제어
- 에러 처리: 백엔드 에러 메시지를 toast로 표시

---

## 📝 Step 5: 유효성 검사 유틸

### 파일: `src/utils/validation.ts`

```typescript
/**
 * 아이디 유효성 검사 (4-20자, 영문/숫자만)
 */
export const validateUsername = (username: string): boolean => {
  const regex = /^[a-zA-Z0-9_]{4,20}$/
  return regex.test(username)
}

/**
 * 비밀번호 유효성 검사 (8자 이상, 영문/숫자/특수문자 포함)
 */
export const validatePassword = (password: string): boolean => {
  const regex = /^(?=.*[A-Za-z])(?=.*\d)(?=.*[@$!%*#?&])[A-Za-z\d@$!%*#?&]{8,}$/
  return regex.test(password)
}

/**
 * 이메일 유효성 검사
 */
export const validateEmail = (email: string): boolean => {
  const regex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/
  return regex.test(email)
}

/**
 * 휴대폰 번호 유효성 검사 (010-1234-5678)
 */
export const validatePhone = (phone: string): boolean => {
  const regex = /^010-?\d{4}-?\d{4}$/
  return regex.test(phone)
}

/**
 * 사업자등록번호 유효성 검사 (10자리 숫자)
 */
export const validateBusinessNumber = (businessNumber: string): boolean => {
  const regex = /^\d{10}$/
  return regex.test(businessNumber.replace(/-/g, ''))
}
```

---

## ✅ 완료 체크리스트

- [ ] LoginPage API 연동 완료
- [ ] 회원가입 API 연동 완료
- [ ] 휴대폰 인증 구현 완료
- [ ] 유효성 검사 유틸 작성
- [ ] 로그인 성공 시 대시보드 이동 확인
- [ ] 로그아웃 시 상태 초기화 확인
- [ ] 새로고침 시 인증 상태 유지 확인

---

## 🧪 테스트 방법

### 1. 로그인 테스트

```bash
# 개발 서버 실행
npm run dev

# 브라우저에서 http://localhost:3000/login
# 1. 아이디/비밀번호 입력
# 2. 로그인 버튼 클릭
# 3. 대시보드로 이동 확인
# 4. 새로고침 후에도 로그인 상태 유지 확인
```

### 2. 회원가입 테스트

```bash
# 1. 회원가입 버튼 클릭
# 2. 6단계 진행
# 3. 휴대폰 인증 완료
# 4. 가입 완료 후 자동 로그인 확인
```

### 3. Network 탭 확인

- Request Headers에 `Authorization: Bearer ...` 확인
- Response 형식 확인 (`ApiResponse<LoginResponseData>`)

---

## 🔍 자주하는 실수

### ❌ 실수 1: userStore 업데이트 누락

```typescript
// ❌ authStore만 업데이트
login(token, userId, userType)

// ✅ userStore도 함께 업데이트
login(token, userId, userType)
setUser({ userId, username, ... })
```

### ❌ 실수 2: 에러 처리 미흡

```typescript
// ❌ 에러 메시지 무시
catch (error) {
  toast.error('로그인 실패')
}

// ✅ 백엔드 에러 메시지 표시
catch (error: any) {
  const msg = error.response?.data?.error?.message || '로그인 실패'
  toast.error(msg)
}
```

### ❌ 실수 3: persist partialize 설정 오류

```typescript
// ❌ 토큰을 persist에 포함 (보안 위험)
partialize: (state) => ({
  token: state.token, // 위험!
  userId: state.userId
})

// ✅ 토큰은 localStorage에만 저장
partialize: (state) => ({
  userId: state.userId,
  isAuthenticated: state.isAuthenticated
})
```

---

## 💡 학습 포인트

### 1. Zustand persist middleware

```typescript
const useAuthStore = create<AuthState>()(
  persist(
    (set) => ({ /* state */ }),
    {
      name: 'auth-storage', // localStorage 키
      partialize: (state) => ({ /* 저장할 필드만 선택 */ })
    }
  )
)
```

**인사이트**: 
- 새로고침 시에도 상태 유지
- `partialize`로 민감 정보(토큰) 제외

### 2. 다단계 폼 상태 관리

```typescript
// signupStore: 6단계 폼의 모든 상태 관리
const useSignupStore = create((set) => ({
  username: '',
  password: '',
  phone: '',
  email: '',
  userType: 'INDIVIDUAL',
  
  setUsername: (username) => set({ username }),
  setPassword: (password) => set({ password }),
  // ...
  reset: () => set({ /* 초기 상태 */ })
}))
```

### 3. 보호된 라우트 패턴

TanStack Router의 `beforeLoad`를 사용하여 인증 체크:

```typescript
// src/routes/_authenticated.tsx
export const Route = createFileRoute('/_authenticated')({
  beforeLoad: ({ context }) => {
    const { isAuthenticated } = useAuthStore.getState()
    
    if (!isAuthenticated) {
      throw redirect({ to: '/login' })
    }
  }
})
```

---

## 📚 다음 단계

Phase 2 완료! 인증 시스템이 구축되었습니다.

**다음**: [03-MESSAGE-SENDING.md](./03-MESSAGE-SENDING.md) - SMS/LMS/MMS 발송 구현 →
