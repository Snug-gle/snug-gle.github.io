---
created: 2025-12-26
---
# 프론트엔드 컴포넌트 개선 제안서

## 개요
프론트엔드 컴포넌트를 검토한 결과, 개선이 필요한 영역과 구체적인 제안사항을 정리했습니다.

---

## 🔴 높은 우선순위

### 1. 에러 처리 및 사용자 피드백 통일

#### 문제점
- **일관성 없는 에러 처리**: 각 컴포넌트마다 에러 처리 방식이 다름
- **로딩 상태 불일치**: 일부는 `isLoading`, 일부는 `loading`, 일부는 `isPending` 사용
- **Toast 메시지 형식 불일치**: 성공/실패 메시지 형식이 제각각

#### 개선 제안

**1.1 공통 에러 바운더리 컴포넌트 생성**
```tsx
// components/common/ErrorBoundary.tsx
// React Error Boundary로 예상치 못한 에러 처리
```

**1.2 공통 로딩 컴포넌트**
```tsx
// components/common/LoadingSpinner.tsx
// 일관된 로딩 UI 제공
interface LoadingSpinnerProps {
  size?: 'sm' | 'md' | 'lg'
  message?: string
}
```

**1.3 공통 에러 메시지 컴포넌트**
```tsx
// components/common/ErrorMessage.tsx
// 일관된 에러 메시지 표시
interface ErrorMessageProps {
  error: Error | string
  onRetry?: () => void
}
```

**1.4 Toast 메시지 유틸리티**
```tsx
// utils/toast.ts
export const showSuccess = (message: string) => toast.success(message)
export const showError = (message: string, error?: Error) => {
  const errorMessage = error?.message || message
  toast.error(errorMessage)
}
export const showInfo = (message: string) => toast.info(message)
```

**1.5 React Query 에러 핸들러 통일**
```tsx
// api/queryClient.ts
// 전역 에러 핸들러 설정
queryClient.setQueryDefaults(['*'], {
  onError: (error) => {
    // 일관된 에러 처리
  }
})
```

---

### 2. 타입 안정성 강화

#### 문제점
- **`any` 타입 사용**: `SmsPage.tsx`, `SignupVerifyPage.tsx`에서 `any` 사용
- **타입 정의 중복**: `MessageStatus`, `MessageType` 등이 여러 파일에 중복 정의
- **타입 가드 부족**: 런타임 타입 검증 부족

#### 개선 제안

**2.1 공통 타입 파일 정리**
```tsx
// types/message.ts - 이미 존재하지만 사용되지 않는 타입 정리
// types/api.ts - API 응답 타입 정의
// types/error.ts - 에러 타입 정의
```

**2.2 타입 가드 함수 추가**
```tsx
// utils/typeGuards.ts
export const isApiError = (error: unknown): error is ApiError => {
  return typeof error === 'object' && error !== null && 'response' in error
}
```

**2.3 `any` 타입 제거**
```tsx
// SmsPage.tsx의 mutationFn에서 any 제거
// 명확한 타입 정의 필요
interface SendMessageRequest {
  messageType: MessageType
  senderNumber: string
  recipients: Recipient[]
  // ...
}
```

---

### 3. 컴포넌트 재사용성 향상

#### 문제점
- **로딩 스피너 중복**: 여러 페이지에서 동일한 로딩 UI 반복
- **폼 검증 로직 중복**: 각 폼마다 유사한 검증 로직
- **에러 메시지 표시 중복**: 동일한 에러 UI 반복

#### 개선 제안

**3.1 공통 폼 컴포넌트**
```tsx
// components/forms/FormField.tsx
// 라벨, 입력, 에러 메시지를 포함한 재사용 가능한 폼 필드
interface FormFieldProps {
  label: string
  error?: string
  required?: boolean
  children: React.ReactNode
}
```

**3.2 폼 검증 훅**
```tsx
// hooks/useFormValidation.ts
// 재사용 가능한 폼 검증 로직
export const useFormValidation = <T extends Record<string, any>>(
  schema: ZodSchema<T>
) => {
  // 검증 로직
}
```

**3.3 공통 페이지 레이아웃**
```tsx
// components/layouts/PageLayout.tsx
// 페이지 제목, 로딩, 에러를 포함한 공통 레이아웃
interface PageLayoutProps {
  title: string
  isLoading?: boolean
  error?: Error | null
  children: React.ReactNode
}
```

---

## 🟡 중간 우선순위

### 4. 성능 최적화

#### 문제점
- **불필요한 리렌더링**: Zustand store 구독 시 전체 컴포넌트 리렌더링
- **메모이제이션 부족**: 계산 비용이 높은 값들이 매번 재계산
- **이미지/파일 최적화 부족**: 파일 업로드 시 최적화 없음

#### 개선 제안

**4.1 Zustand 선택적 구독**
```tsx
// 현재: useMessageFormStore() - 전체 store 구독
// 개선: useMessageFormStore((state) => state.content) - 필요한 값만 구독
```

**4.2 React.memo 활용**
```tsx
// 자주 리렌더링되는 컴포넌트에 memo 적용
export const MessageCard = React.memo(({ message }: Props) => {
  // ...
})
```

**4.3 useMemo, useCallback 활용**
```tsx
// 계산 비용이 높은 값들 메모이제이션
const filteredMessages = useMemo(() => {
  return messages.filter(/* ... */)
}, [messages, filter])
```

**4.4 이미지 최적화**
```tsx
// 파일 업로드 시 이미지 압축
// utils/imageOptimization.ts
export const compressImage = async (file: File): Promise<File> => {
  // 이미지 압축 로직
}
```

---

### 5. 접근성 개선

#### 문제점
- **키보드 네비게이션**: 일부 컴포넌트에서 키보드 접근 불가
- **ARIA 레이블 부족**: 스크린 리더 지원 부족
- **포커스 관리**: 모달, 드롭다운에서 포커스 트랩 부족

#### 개선 제안

**5.1 ARIA 레이블 추가**
```tsx
<Button
  aria-label="메시지 발송"
  aria-describedby="send-message-help"
>
  발송하기
</Button>
```

**5.2 키보드 단축키 지원**
```tsx
// hooks/useKeyboardShortcut.ts
export const useKeyboardShortcut = (
  key: string,
  callback: () => void,
  deps?: React.DependencyList
) => {
  // 키보드 단축키 처리
}
```

**5.3 포커스 관리**
```tsx
// 모달, 드롭다운에서 포커스 트랩
// shadcn/ui의 Dialog, Popover는 이미 지원하지만 확인 필요
```

---

### 6. 사용자 경험 개선

#### 문제점
- **폼 검증 피드백**: 실시간 검증 피드백 부족
- **로딩 상태 표시**: 일부 작업에서 로딩 표시 없음
- **에러 복구 옵션**: 에러 발생 시 재시도 옵션 부족

#### 개선 제안

**6.1 실시간 폼 검증**
```tsx
// 입력 중 실시간 검증 및 피드백
<Input
  onBlur={handleBlur}
  onChange={handleChange}
  className={errors.field ? 'border-destructive' : ''}
/>
{errors.field && (
  <p className="text-sm text-destructive mt-1">{errors.field}</p>
)}
```

**6.2 낙관적 업데이트**
```tsx
// React Query의 낙관적 업데이트 활용
useMutation({
  onMutate: async (newData) => {
    // 즉시 UI 업데이트
  },
  onError: (err, newData, context) => {
    // 에러 시 롤백
  }
})
```

**6.3 재시도 메커니즘**
```tsx
// 에러 발생 시 재시도 버튼 제공
<ErrorMessage
  error={error}
  onRetry={() => refetch()}
/>
```

---

## 🟢 낮은 우선순위 (장기 개선)

### 7. 코드 일관성

#### 문제점
- **파일 구조**: 컴포넌트 파일 위치가 일관되지 않음
- **네이밍 컨벤션**: 일부는 camelCase, 일부는 PascalCase 혼용
- **주석 부족**: 복잡한 로직에 주석 없음

#### 개선 제안

**7.1 파일 구조 가이드라인**
```
components/
  common/        # 공통 컴포넌트
  forms/         # 폼 관련 컴포넌트
  layout/        # 레이아웃 컴포넌트
  [feature]/     # 기능별 컴포넌트
```

**7.2 네이밍 컨벤션 문서화**
- 컴포넌트: PascalCase
- 함수/변수: camelCase
- 상수: UPPER_SNAKE_CASE
- 타입/인터페이스: PascalCase

---

### 8. 테스트 코드

#### 문제점
- **테스트 코드 부재**: 단위 테스트, 통합 테스트 없음
- **테스트 유틸리티 부재**: 테스트 헬퍼 함수 없음

#### 개선 제안

**8.1 테스트 설정**
```tsx
// vitest 설정
// MSW를 활용한 API 모킹 (이미 선호사항에 있음)
```

**8.2 주요 컴포넌트 테스트**
- 폼 컴포넌트 검증 테스트
- API 호출 테스트
- 상태 관리 테스트

---

## 📋 구체적인 개선 작업 목록

### 즉시 적용 가능 (1-2일)

1. ✅ **공통 로딩 컴포넌트 생성**
   - `components/common/LoadingSpinner.tsx`
   - 모든 페이지에서 사용

2. ✅ **공통 에러 메시지 컴포넌트 생성**
   - `components/common/ErrorMessage.tsx`
   - 일관된 에러 UI

3. ✅ **Toast 유틸리티 함수 생성**
   - `utils/toast.ts`
   - 일관된 메시지 형식

4. ✅ **타입 정의 정리**
   - `any` 타입 제거
   - 공통 타입 파일 정리

### 단기 개선 (1주)

5. ✅ **폼 컴포넌트 재사용성 향상**
   - `FormField` 컴포넌트
   - 폼 검증 훅

6. ✅ **Zustand 선택적 구독 적용**
   - 성능 최적화

7. ✅ **접근성 개선**
   - ARIA 레이블 추가
   - 키보드 네비게이션 확인

### 중기 개선 (2-4주)

8. ✅ **에러 바운더리 구현**
   - React Error Boundary
   - 전역 에러 처리

9. ✅ **성능 최적화**
   - React.memo 적용
   - useMemo, useCallback 활용

10. ✅ **테스트 코드 작성**
    - 주요 컴포넌트 테스트
    - API 통합 테스트

---

## 🎯 우선순위별 추천 작업

### 이번 주 (즉시)
1. 공통 로딩/에러 컴포넌트 생성
2. Toast 유틸리티 함수 생성
3. `any` 타입 제거

### 다음 주
4. 폼 컴포넌트 재사용성 향상
5. Zustand 선택적 구독 적용
6. 접근성 기본 개선

### 이번 달
7. 에러 바운더리 구현
8. 성능 최적화
9. 테스트 코드 작성 시작

---

## 📝 참고사항

- 모든 개선사항은 기존 코드와의 호환성을 유지하면서 점진적으로 적용
- 각 개선사항은 독립적으로 적용 가능하도록 설계
- 디자인 시스템 문서와 일관성 유지
- 사용자 경험을 해치지 않는 범위에서 개선

