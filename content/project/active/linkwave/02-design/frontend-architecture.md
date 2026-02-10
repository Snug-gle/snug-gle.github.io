---
created: 2026-02-10
tags:
  - linkwave
  - frontend
  - architecture
---

> 이 문서는 linkwave-docs의 frontend/ARCHITECTURE.md를 요약한 것입니다.

# LinkWave 프론트엔드 설계

## 1. 개요

SMS, LMS, MMS 메시지를 입력하고 발송 요청할 수 있는 웹 인터페이스.

### 기술 스택

| 영역 | 스택 |
|---|---|
| Core | React 19+, TypeScript, Vite 7.x |
| 상태 관리 | Zustand (클라이언트), TanStack Query (서버) |
| Routing | TanStack Router |
| UI | Tailwind CSS v4, shadcn/ui, lucide-react, framer-motion |
| Form | React Hook Form + Zod |
| HTTP | Axios |

---

## 2. 프로젝트 구조

```
src/
├── api/              # Axios 인스턴스 및 API 모듈
├── components/
│   ├── common/       # Header, Sidebar, Footer, Button, Input, Modal, Spinner
│   ├── message/      # MessageTypeNav, RecipientInput, ContentEditor, SenderNumberSelector
│   ├── forms/        # SmsForm, LmsForm, MmsForm
│   ├── history/      # MessageTable, MessageFilter, Pagination
│   ├── dashboard/    # StatisticsCard, TypeChart, TimelineChart
│   └── addressBook/  # AddressBookList, AddressBookForm, GroupSelector
├── pages/            # LoginPage, DashboardPage, Sms/Lms/MmsPage, HistoryPage
├── hooks/            # useAuth, useSendMessage, useMessageList, useAddressBook
├── stores/           # authStore, messageFormStore, uiStore
├── utils/            # validation, formatting, storage, constants
└── routeTree.gen.ts  # TanStack Router 자동 생성
```

---

## 3. 주요 화면

### 네비게이션
대시보드 | SMS | LMS | MMS | 발송이력 | 주소록 | 설정

### SMS 발송 화면
- **수신자 입력**: 직접입력 / 주소록 / 엑셀업로드
- **발신번호 선택**: 드롭다운
- **메시지 내용**: 텍스트 에디터 + 바이트 카운터 (90byte, 초과 시 LMS 전환 옵션)
- **발송 옵션**: 즉시/예약 발송, 중복 방지 (10분 이내)
- **액션**: 임시저장, 미리보기, 발송

### MMS 추가 요소
- 제목 입력 필드, 첨부파일 업로드 (JPG/PNG, 최대 300KB)

### 발송 이력
- 필터: 기간, 상태, 타입 / 테이블: CLIENT_KEY, 타입, 수신자 수, 상태

### 대시보드
- 요약 카드: 발송 통계, 성공률, 총 비용
- 타입별/시간대별 차트, 기간 선택

---

## 4. 상태 관리

### Zustand 스토어

**인증 스토어**: `user`, `token`, `isAuthenticated` — `zustand/persist`로 관리

**메시지 폼 스토어**:

```typescript
interface MessageFormState {
  messageType: 'SMS' | 'LMS' | 'MMS'
  senderNumber: string
  recipients: Recipient[]
  content: string
  title?: string
  scheduledAt?: Date
  dedupEnabled: boolean
  files: File[]
}
```

### TanStack Query 훅

| 훅 | 용도 | 설정 |
|---|---|---|
| `useSendMessage` | 메시지 발송 (mutation) | 성공 시 캐시 무효화 |
| `useMessageList` | 메시지 목록 조회 | staleTime: 30s |
| `useMessageDetail` | 메시지 상세 조회 | `enabled: !!clientKey` |
| `useAddressBook` | 주소록 조회/추가 | 추가 성공 시 무효화 |
| `useStatistics` | 통계 조회 | staleTime: 60s |

---

## 5. API 통신

### Axios 클라이언트
- baseURL: `VITE_API_BASE_URL` (기본 `http://localhost:8080/api/v1`)
- Request Interceptor: `Authorization: Bearer` 헤더 자동 추가
- Response Interceptor: 401 시 자동 로그아웃

### 핵심 타입

```typescript
interface MessageRequest {
  messageType: 'SMS' | 'LMS' | 'MMS'
  senderNumber: string
  recipients: Recipient[]
  content: string
  title?: string
  scheduledAt?: string
  trafficType?: 'real' | 'normal' | 'batch'
  dedupEnabled?: boolean
}

interface MessageResponse {
  clientKey: string
  status: string
  trafficType: string
  recipientCount: number
  estimatedCost?: number
}
```

---

## 6. 환경 설정

| 변수 | 설명 | 기본값 |
|---|---|---|
| `VITE_API_BASE_URL` | 백엔드 API URL | `http://localhost:8080/api/v1` |
| `VITE_MAX_FILE_SIZE` | 최대 파일 크기 | 10MB |
| `VITE_ENABLE_KAKAO` | 카카오톡 기능 | false |
| `VITE_ENABLE_RCS` | RCS 기능 | false |

---

## 7. 배포

- 빌드: `npm run build` → `dist/`
- Nginx: SPA fallback + `/api` 리버스 프록시

---

## 부록: 기술 선택 이유

| 기술 | 선택 이유 |
|---|---|
| **Zustand** | 간단한 API, 보일러플레이트 최소화 |
| **TanStack Query** | 서버 상태 자동 관리, 캐싱/리페칭 |
| **Vite** | 빠른 HMR, 프로덕션 빌드 최적화 |
| **TypeScript** | 타입 안정성, IDE 자동완성 |
