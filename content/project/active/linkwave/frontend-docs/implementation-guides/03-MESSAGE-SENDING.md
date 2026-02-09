---
created: 2025-12-26
---
# Phase 3: 메시지 발송 시스템

## 📖 개념 설명

### SMS/LMS/MMS 차이점

| 구분 | 최대 글자 수 | 최대 바이트 | 특징 |
|------|-------------|------------|------|
| **SMS** | 한글 45자 | 90 bytes | 단문 메시지 |
| **LMS** | 한글 1,000자 | 2,000 bytes | 장문 메시지, 제목 가능 |
| **MMS** | 한글 1,000자 | 2,000 bytes | 이미지/동영상 첨부 가능 |

**바이트 계산**:
- 한글/한자: 3 bytes
- 영문/숫자: 1 byte
- 특수문자: 1-3 bytes

### 메시지 발송 플로우

```
1. 사용자가 메시지 작성
   ↓
2. 바이트 계산 → SMS/LMS 자동 판별
   ↓
3. 수신자 목록 업로드 (CSV/Excel)
   ↓
4. 예약 발송 시간 설정 (선택)
   ↓
5. API 호출 (POST /api/v1/messages)
   ↓
6. 백엔드가 메시지 큐에 등록
   ↓
7. 발송 결과 조회 (GET /api/v1/messages/group/{groupId})
```

---

## 🎯 구현 목표

- [ ] `src/api/messageApi.ts` - 메시지 API 함수
- [ ] `src/stores/messageFormStore.ts` - 메시지 폼 상태
- [ ] `src/pages/SmsPage.tsx` - SMS 발송 화면 API 연동
- [ ] `src/pages/LmsPage.tsx` - LMS 발송 화면 (새로 작성)
- [ ] `src/pages/MmsPage.tsx` - MMS 발송 화면 (새로 작성)
- [ ] `src/hooks/useFileUpload.ts` - 파일 업로드 훅
- [ ] `src/utils/byteCalculator.ts` - 바이트 계산 유틸

---

## 📝 Step 1: 메시지 API 함수

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
 */
export const sendMessage = async (
  request: MessageSendRequest
): Promise<ApiResponse<MessageSendResponseData>> => {
  return client.post('/messages', request)
}

/**
 * 예약 메시지 취소
 */
export const cancelScheduledMessage = async (
  groupId: string
): Promise<ApiResponse<void>> => {
  return client.delete(`/messages/scheduled/${groupId}`)
}

/**
 * 메시지 그룹 상태 조회
 */
export const getMessageGroupStatus = async (
  groupId: string
): Promise<ApiResponse<MessageSendResponseData>> => {
  return client.get(`/messages/group/${groupId}`)
}
```

---

## 📝 Step 2: 바이트 계산 유틸

### 파일: `src/utils/byteCalculator.ts`

```typescript
/**
 * 문자열의 바이트 수 계산
 * - 한글/한자: 3 bytes
 * - 영문/숫자: 1 byte
 * - 특수문자: 1-3 bytes
 */
export const calculateBytes = (text: string): number => {
  let bytes = 0
  
  for (let i = 0; i < text.length; i++) {
    const char = text.charAt(i)
    const code = text.charCodeAt(i)
    
    if (code >= 0xAC00 && code <= 0xD7A3) {
      // 한글
      bytes += 3
    } else if (code >= 0x4E00 && code <= 0x9FFF) {
      // 한자
      bytes += 3
    } else if (code < 128) {
      // ASCII (영문, 숫자, 기본 특수문자)
      bytes += 1
    } else {
      // 기타 유니코드
      bytes += 3
    }
  }
  
  return bytes
}

/**
 * 바이트 수에 따라 메시지 타입 판별
 */
export const getMessageType = (bytes: number): 'SMS' | 'LMS' => {
  return bytes <= 90 ? 'SMS' : 'LMS'
}

/**
 * 남은 바이트 계산
 */
export const getRemainingBytes = (text: string, maxBytes: number): number => {
  const currentBytes = calculateBytes(text)
  return Math.max(0, maxBytes - currentBytes)
}
```

---

## 📝 Step 3: 메시지 폼 상태 관리

### 파일: `src/stores/messageFormStore.ts`

```typescript
import { create } from 'zustand'
import type { MessageType } from '@/types/message'

interface MessageFormState {
  // 메시지 내용
  type: MessageType
  from: string
  to: string[]
  subject: string
  content: string
  scheduledAt: string | null

  // 액션
  setType: (type: MessageType) => void
  setFrom: (from: string) => void
  setTo: (to: string[]) => void
  setSubject: (subject: string) => void
  setContent: (content: string) => void
  setScheduledAt: (scheduledAt: string | null) => void
  addRecipient: (phone: string) => void
  removeRecipient: (phone: string) => void
  reset: () => void
}

const initialState = {
  type: 'SMS' as MessageType,
  from: '',
  to: [],
  subject: '',
  content: '',
  scheduledAt: null,
}

export const useMessageFormStore = create<MessageFormState>((set) => ({
  ...initialState,

  setType: (type) => set({ type }),
  setFrom: (from) => set({ from }),
  setTo: (to) => set({ to }),
  setSubject: (subject) => set({ subject }),
  setContent: (content) => set({ content }),
  setScheduledAt: (scheduledAt) => set({ scheduledAt }),
  
  addRecipient: (phone) =>
    set((state) => ({
      to: [...state.to, phone]
    })),
  
  removeRecipient: (phone) =>
    set((state) => ({
      to: state.to.filter((p) => p !== phone)
    })),
  
  reset: () => set(initialState),
}))
```

---

## 📝 Step 4: SMS 발송 화면 API 연동

### 파일: `src/pages/SmsPage.tsx`

```typescript
import { useState } from 'react'
import { sendMessage } from '@/api/messageApi'
import { useMessageFormStore } from '@/stores/messageFormStore'
import { calculateBytes, getMessageType } from '@/utils/byteCalculator'
import { Button } from '@/components/ui/button'
import { Textarea } from '@/components/ui/textarea'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { toast } from 'react-hot-toast'
import { Loader2 } from 'lucide-react'

const SmsPage = () => {
  const [loading, setLoading] = useState(false)
  const { from, to, content, setFrom, setContent, addRecipient, reset } = useMessageFormStore()

  const bytes = calculateBytes(content)
  const messageType = getMessageType(bytes)
  const maxBytes = 90

  const handleAddRecipient = (phone: string) => {
    if (!phone) {
      toast.error('휴대폰 번호를 입력하세요')
      return
    }
    
    if (!/^010-?\d{4}-?\d{4}$/.test(phone)) {
      toast.error('올바른 휴대폰 번호 형식이 아닙니다')
      return
    }
    
    addRecipient(phone)
  }

  const handleSend = async () => {
    if (!from) {
      toast.error('발신번호를 입력하세요')
      return
    }
    
    if (to.length === 0) {
      toast.error('수신자를 추가하세요')
      return
    }
    
    if (!content) {
      toast.error('메시지 내용을 입력하세요')
      return
    }

    setLoading(true)
    try {
      const response = await sendMessage({
        type: 'SMS',
        from,
        to,
        content,
      })

      if (response.success && response.data) {
        toast.success(`메시지 발송 완료! (${response.data.successCount}건 성공)`)
        reset()
      } else {
        toast.error(response.error?.message || '발송 실패')
      }
    } catch (error: any) {
      toast.error(error.response?.data?.error?.message || '발송 실패')
    } finally {
      setLoading(false)
    }
  }

  return (
    <div className="container mx-auto px-4 py-8">
      <h1 className="text-3xl font-bold mb-8">SMS 발송</h1>

      <div className="max-w-2xl space-y-6">
        {/* 발신번호 */}
        <div className="space-y-2">
          <Label>발신번호</Label>
          <Input
            value={from}
            onChange={(e) => setFrom(e.target.value)}
            placeholder="010-1234-5678"
          />
        </div>

        {/* 수신자 목록 */}
        <div className="space-y-2">
          <Label>수신자 ({to.length}명)</Label>
          <div className="flex gap-2">
            <Input
              placeholder="010-1234-5678"
              onKeyDown={(e) => {
                if (e.key === 'Enter') {
                  handleAddRecipient(e.currentTarget.value)
                  e.currentTarget.value = ''
                }
              }}
            />
            <Button variant="outline">추가</Button>
          </div>
          <div className="flex flex-wrap gap-2 mt-2">
            {to.map((phone, index) => (
              <div key={index} className="bg-muted px-3 py-1 rounded-full text-sm">
                {phone}
              </div>
            ))}
          </div>
        </div>

        {/* 메시지 내용 */}
        <div className="space-y-2">
          <div className="flex justify-between">
            <Label>메시지 내용</Label>
            <span className={`text-sm ${bytes > maxBytes ? 'text-destructive' : 'text-muted-foreground'}`}>
              {bytes} / {maxBytes} bytes ({messageType})
            </span>
          </div>
          <Textarea
            value={content}
            onChange={(e) => setContent(e.target.value)}
            placeholder="메시지를 입력하세요"
            rows={6}
          />
        </div>

        {/* 발송 버튼 */}
        <Button
          onClick={handleSend}
          disabled={loading || bytes > maxBytes}
          className="w-full"
          size="lg"
        >
          {loading && <Loader2 className="size-4 animate-spin mr-2" />}
          발송하기
        </Button>
      </div>
    </div>
  )
}

export default SmsPage
```

---

## 📝 Step 5: 파일 업로드 훅 (MMS용)

### 파일: `src/hooks/useFileUpload.ts`

```typescript
import { useState } from 'react'
import { toast } from 'react-hot-toast'

interface UseFileUploadOptions {
  maxSize?: number // bytes (기본: 5MB)
  allowedTypes?: string[] // MIME types
  maxFiles?: number
}

export const useFileUpload = (options: UseFileUploadOptions = {}) => {
  const {
    maxSize = 5 * 1024 * 1024, // 5MB
    allowedTypes = ['image/jpeg', 'image/png', 'image/gif'],
    maxFiles = 3,
  } = options

  const [files, setFiles] = useState<File[]>([])
  const [previews, setPreviews] = useState<string[]>([])

  const validateFile = (file: File): boolean => {
    // 파일 크기 체크
    if (file.size > maxSize) {
      toast.error(`파일 크기는 ${maxSize / 1024 / 1024}MB 이하여야 합니다`)
      return false
    }

    // 파일 타입 체크
    if (!allowedTypes.includes(file.type)) {
      toast.error('지원하지 않는 파일 형식입니다')
      return false
    }

    return true
  }

  const addFiles = (newFiles: FileList | File[]) => {
    const fileArray = Array.from(newFiles)

    // 최대 파일 개수 체크
    if (files.length + fileArray.length > maxFiles) {
      toast.error(`최대 ${maxFiles}개까지 업로드 가능합니다`)
      return
    }

    // 파일 검증
    const validFiles = fileArray.filter(validateFile)

    // 파일 추가
    setFiles((prev) => [...prev, ...validFiles])

    // 미리보기 생성
    validFiles.forEach((file) => {
      const reader = new FileReader()
      reader.onloadend = () => {
        setPreviews((prev) => [...prev, reader.result as string])
      }
      reader.readAsDataURL(file)
    })
  }

  const removeFile = (index: number) => {
    setFiles((prev) => prev.filter((_, i) => i !== index))
    setPreviews((prev) => prev.filter((_, i) => i !== index))
  }

  const reset = () => {
    setFiles([])
    setPreviews([])
  }

  return {
    files,
    previews,
    addFiles,
    removeFile,
    reset,
  }
}
```

---

## ✅ 완료 체크리스트

- [ ] 메시지 API 함수 작성
- [ ] 바이트 계산 유틸 작성
- [ ] SMS 발송 화면 API 연동
- [ ] LMS 발송 화면 작성
- [ ] MMS 발송 화면 작성 (파일 업로드 포함)
- [ ] 예약 발송 기능 구현
- [ ] 발송 이력 조회 기능 구현

---

## 🧪 테스트 방법

### 1. SMS 발송 테스트

```bash
# 1. /sms 페이지 접속
# 2. 발신번호 입력
# 3. 수신자 추가
# 4. 메시지 내용 입력 (90 bytes 이하)
# 5. 발송 버튼 클릭
# 6. Network 탭에서 POST /api/v1/messages 확인
```

### 2. 바이트 계산 테스트

```typescript
// 콘솔에서 테스트
import { calculateBytes } from '@/utils/byteCalculator'

console.log(calculateBytes('안녕')) // 6 (한글 2자 * 3 bytes)
console.log(calculateBytes('Hello')) // 5 (영문 5자 * 1 byte)
console.log(calculateBytes('안녕 Hello')) // 12 (6 + 1 + 5)
```

---

## 🔍 자주하는 실수

### ❌ 실수 1: 바이트 계산 오류

```typescript
// ❌ 문자 수로 계산
const bytes = text.length

// ✅ 바이트 수로 계산
const bytes = calculateBytes(text)
```

### ❌ 실수 2: 중복 발송 방지 미흡

```typescript
// ❌ 버튼만 disable
<Button disabled={loading}>발송</Button>

// ✅ 로딩 중 추가 요청 차단
const handleSend = async () => {
  if (loading) return // 중복 방지
  setLoading(true)
  try {
    await sendMessage(...)
  } finally {
    setLoading(false)
  }
}
```

### ❌ 실수 3: 휴대폰 번호 검증 누락

```typescript
// ❌ 검증 없이 추가
addRecipient(phone)

// ✅ 형식 검증 후 추가
if (!/^010-?\d{4}-?\d{4}$/.test(phone)) {
  toast.error('올바른 형식이 아닙니다')
  return
}
addRecipient(phone)
```

---

## 💡 학습 포인트

### 1. FormData를 활용한 파일 업로드

```typescript
// MMS 발송 시
const formData = new FormData()
formData.append('type', 'MMS')
formData.append('from', from)
formData.append('content', content)
files.forEach((file) => {
  formData.append('files', file)
})

await client.post('/messages', formData, {
  headers: {
    'Content-Type': 'multipart/form-data'
  }
})
```

### 2. Debounce 패턴

```typescript
// 바이트 계산 성능 최적화
import { useMemo } from 'react'

const SmsPage = () => {
  const content = useMessageFormStore((state) => state.content)
  
  // content가 변경될 때만 재계산
  const bytes = useMemo(() => calculateBytes(content), [content])
  
  return <div>{bytes} bytes</div>
}
```

---

## 📚 다음 단계

**다음**: [04-ADDRESS-BOOK.md](./04-ADDRESS-BOOK.md) - 주소록 관리 →
