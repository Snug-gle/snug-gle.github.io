---
created: 2025-12-26
---
# Phase 8: 고급 패턴 및 최적화

## 📖 개념 설명

성능 최적화 및 UX 개선을 위한 고급 패턴입니다.

---

## 🎯 구현 목표

- [ ] `src/hooks/useAuth.ts` - 인증 훅
- [ ] `src/hooks/useDebounce.ts` - 디바운스 훅
- [ ] `src/components/ErrorBoundary.tsx` - 에러 경계
- [ ] `src/components/Loading/SkeletonLoader.tsx` - 스켈레톤 로더
- [ ] Code splitting 설정
- [ ] Lazy loading 적용

---

## 📝 Step 1: Custom Hooks

### 파일: `src/hooks/useAuth.ts`

```typescript
import { useAuthStore } from '@/stores/authStore'
import { useUserStore } from '@/stores/userStore'
import { useNavigate } from '@tanstack/react-router'
import { login as loginApi, logout as logoutApi } from '@/api/authApi'

export const useAuth = () => {
  const navigate = useNavigate()
  const { login, logout, isAuthenticated } = useAuthStore()
  const { user, setUser, clearUser } = useUserStore()

  const handleLogin = async (username: string, password: string) => {
    const response = await loginApi({ username, password })
    
    if (response.success && response.data) {
      const { accessToken, userId, userType, ...userData } = response.data
      login(accessToken, userId, userType || 'INDIVIDUAL')
      setUser({ ...userData, userId })
      navigate({ to: '/dashboard' })
    }
    
    return response
  }

  const handleLogout = () => {
    logout()
    clearUser()
    navigate({ to: '/login' })
  }

  return {
    user,
    isAuthenticated,
    login: handleLogin,
    logout: handleLogout,
  }
}
```

### 파일: `src/hooks/useDebounce.ts`

```typescript
import { useEffect, useState } from 'react'

export const useDebounce = <T>(value: T, delay: number = 500): T => {
  const [debouncedValue, setDebouncedValue] = useState<T>(value)

  useEffect(() => {
    const handler = setTimeout(() => {
      setDebouncedValue(value)
    }, delay)

    return () => {
      clearTimeout(handler)
    }
  }, [value, delay])

  return debouncedValue
}
```

**사용 예시**:

```typescript
const SearchPage = () => {
  const [search, setSearch] = useState('')
  const debouncedSearch = useDebounce(search, 500)

  useEffect(() => {
    // 500ms 후에 검색 실행
    if (debouncedSearch) {
      fetchResults(debouncedSearch)
    }
  }, [debouncedSearch])

  return (
    <input
      value={search}
      onChange={(e) => setSearch(e.target.value)}
    />
  )
}
```

---

## 📝 Step 2: Error Boundary

### 파일: `src/components/ErrorBoundary.tsx`

```typescript
import { Component, type ReactNode } from 'react'

interface Props {
  children: ReactNode
  fallback?: ReactNode
}

interface State {
  hasError: boolean
  error: Error | null
}

class ErrorBoundary extends Component<Props, State> {
  constructor(props: Props) {
    super(props)
    this.state = { hasError: false, error: null }
  }

  static getDerivedStateFromError(error: Error): State {
    return { hasError: true, error }
  }

  componentDidCatch(error: Error, errorInfo: any) {
    console.error('ErrorBoundary caught error:', error, errorInfo)
  }

  render() {
    if (this.state.hasError) {
      return this.props.fallback || (
        <div className="min-h-screen flex items-center justify-center">
          <div className="text-center">
            <h1 className="text-2xl font-bold mb-4">문제가 발생했습니다</h1>
            <p className="text-muted-foreground mb-4">
              {this.state.error?.message}
            </p>
            <button
              onClick={() => window.location.reload()}
              className="px-4 py-2 bg-primary text-white rounded"
            >
              새로고침
            </button>
          </div>
        </div>
      )
    }

    return this.props.children
  }
}

export default ErrorBoundary
```

**사용**:

```typescript
// main.tsx
import ErrorBoundary from './components/ErrorBoundary'

root.render(
  <ErrorBoundary>
    <App />
  </ErrorBoundary>
)
```

---

## 📝 Step 3: Code Splitting

### 파일: `vite.config.ts`

```typescript
import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'

export default defineConfig({
  plugins: [react()],
  build: {
    rollupOptions: {
      output: {
        manualChunks: {
          // React 관련
          'react-vendor': ['react', 'react-dom'],
          
          // TanStack 관련
          'tanstack-vendor': ['@tanstack/react-router', '@tanstack/react-query'],
          
          // UI 라이브러리
          'ui-vendor': ['framer-motion', 'lucide-react'],
        }
      }
    }
  }
})
```

---

## 📝 Step 4: Lazy Loading

```typescript
import { lazy, Suspense } from 'react'
import { Loader2 } from 'lucide-react'

// Lazy load pages
const DashboardPage = lazy(() => import('@/pages/DashboardPage'))
const SmsPage = lazy(() => import('@/pages/SmsPage'))

const App = () => (
  <Suspense fallback={
    <div className="flex items-center justify-center min-h-screen">
      <Loader2 className="size-8 animate-spin" />
    </div>
  }>
    <Routes>
      <Route path="/dashboard" element={<DashboardPage />} />
      <Route path="/sms" element={<SmsPage />} />
    </Routes>
  </Suspense>
)
```

---

## ✅ 완료 체크리스트

- [ ] Custom Hooks 작성
- [ ] Error Boundary 구현
- [ ] Code splitting 설정
- [ ] Lazy loading 적용
- [ ] Lighthouse 성능 점수 90+
- [ ] 접근성 점수 90+

---

## 💡 학습 포인트

### 1. React.memo로 리렌더링 최적화

```typescript
const MessageCard = React.memo(({ message }: { message: Message }) => {
  return <div>{message.content}</div>
}, (prevProps, nextProps) => {
  // true 반환 시 리렌더링 스킵
  return prevProps.message.id === nextProps.message.id
})
```

### 2. useMemo로 비용 높은 계산 캐싱

```typescript
const ExpensiveComponent = ({ items }: { items: Item[] }) => {
  const total = useMemo(() => {
    return items.reduce((sum, item) => sum + item.price, 0)
  }, [items]) // items가 변경될 때만 재계산

  return <div>Total: {total}</div>
}
```

### 3. useCallback으로 함수 메모이제이션

```typescript
const Parent = () => {
  const [count, setCount] = useState(0)

  // 함수를 메모이제이션
  const handleClick = useCallback(() => {
    setCount(c => c + 1)
  }, []) // 의존성 없음

  return <Child onClick={handleClick} />
}
```

---

## 🎉 모든 Phase 완료!

축하합니다! LinkWave 프론트엔드 구현 가이드를 모두 완료했습니다.

이제 실제로 API와 타입 파일을 직접 작성하면서 TypeScript와 React를 학습하세요!
