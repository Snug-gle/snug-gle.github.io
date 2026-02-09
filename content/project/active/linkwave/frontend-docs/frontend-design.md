---
created: 2025-12-26
---
# Iotree LinkWave - 프론트엔드 설계

## 1. 개요

### 1.1 목적
문자 메시지(SMS, LMS, MMS)를 입력하고 발송 요청할 수 있는 웹 인터페이스 제공

**LinkWave**는 다양한 메시지 채널(SMS → LMS → MMS → RCS → 카카오톡 → 푸시)의 확장성을 표현하며,
메시지가 파도처럼 연결되어 전파되는 의미를 담고 있습니다.

### 1.2 기술 스택

**Core Framework**
- React 18+
- JavaScript (ES6+)
- Vite 5.x

**상태 관리**
- Zustand (전역 상태 관리)
- TanStack Query (서버 상태 관리)

**Routing**
- React Router v6

**UI 라이브러리**
- (추천) shadcn/ui (컴포넌트 라이브러리)
- (추천) Headless UI (접근성)

**Form 관리**
- (추천) React Hook Form (폼 상태 관리)
- (추천) Zod (스키마 검증)

**HTTP Client**
- Axios

**유틸리티**
- date-fns (날짜 처리)
- (추천) clsx (클래스 이름 관리)
- (추천) react-hot-toast (알림)

**차트/시각화**
- (추천) Recharts (통계 차트)

**파일 처리**
- (추천) react-dropzone (파일 업로드)

**개발 도구**
- ESLint
- Prettier
- (추천) Husky (Git hooks)

---

## 2. 프로젝트 구조

```
iotree-linkwave-frontend/
├── public/
│   └── favicon.ico
├── src/
│   ├── api/
│   │   ├── client.js              # Axios 인스턴스
│   │   ├── messageApi.js          # 메시지 API
│   │   ├── addressBookApi.js      # 주소록 API
│   │   ├── statisticsApi.js       # 통계 API
│   │   └── senderNumberApi.js     # 발신번호 API
│   ├── components/
│   │   ├── common/
│   │   │   ├── Header.jsx
│   │   │   ├── Sidebar.jsx
│   │   │   ├── Footer.jsx
│   │   │   ├── Button.jsx
│   │   │   ├── Input.jsx
│   │   │   ├── Modal.jsx
│   │   │   ├── Spinner.jsx
│   │   │   └── ErrorBoundary.jsx
│   │   ├── message/
│   │   │   ├── MessageTypeNav.jsx
│   │   │   ├── RecipientInput.jsx
│   │   │   ├── ContentEditor.jsx
│   │   │   ├── SenderNumberSelector.jsx
│   │   │   ├── ScheduleSelector.jsx
│   │   │   ├── FileUploader.jsx
│   │   │   ├── DedupOption.jsx
│   │   │   └── SendButton.jsx
│   │   ├── forms/
│   │   │   ├── SmsForm.jsx
│   │   │   ├── LmsForm.jsx
│   │   │   └── MmsForm.jsx
│   │   ├── history/
│   │   │   ├── MessageTable.jsx
│   │   │   ├── MessageFilter.jsx
│   │   │   ├── MessageDetailModal.jsx
│   │   │   └── Pagination.jsx
│   │   ├── dashboard/
│   │   │   ├── StatisticsCard.jsx
│   │   │   ├── TypeChart.jsx
│   │   │   ├── TimelineChart.jsx
│   │   │   └── PeriodSelector.jsx
│   │   └── addressBook/
│   │       ├── AddressBookList.jsx
│   │       ├── AddressBookForm.jsx
│   │       ├── GroupSelector.jsx
│   │       └── ImportExcel.jsx
│   ├── pages/
│   │   ├── LoginPage.jsx
│   │   ├── DashboardPage.jsx
│   │   ├── SmsPage.jsx
│   │   ├── LmsPage.jsx
│   │   ├── MmsPage.jsx
│   │   ├── HistoryPage.jsx
│   │   ├── AddressBookPage.jsx
│   │   └── SettingsPage.jsx
│   ├── hooks/
│   │   ├── useAuth.js
│   │   ├── useSendMessage.js
│   │   ├── useMessageList.js
│   │   ├── useMessageDetail.js
│   │   ├── useAddressBook.js
│   │   ├── useStatistics.js
│   │   └── useSenderNumbers.js
│   ├── stores/
│   │   ├── authStore.js           # 인증 상태
│   │   ├── messageFormStore.js    # 메시지 작성 상태
│   │   └── uiStore.js              # UI 상태
│   ├── utils/
│   │   ├── validation.js
│   │   ├── formatting.js
│   │   ├── storage.js
│   │   └── constants.js
│   ├── App.jsx
│   ├── main.jsx
│   └── routes.jsx
├── .env.example
├── .eslintrc.cjs
├── .prettierrc
├── vite.config.js
└── package.json
```

---

## 3. 주요 화면 설계

### 3.1 메인 네비게이션

```
┌─────────────────────────────────────────────────────────┐
│ [로고] QuickSend Proto                                   │
│                                                          │
│ [대시보드] [SMS] [LMS] [MMS] [발송이력] [주소록]        │
│                                                   [설정] │
└─────────────────────────────────────────────────────────┘
```

### 3.2 SMS 발송 화면

```
┌─────────────────────────────────────────────────────────┐
│ SMS 발송                                                 │
├─────────────────────────────────────────────────────────┤
│                                                          │
│ ┌─ 수신자 ──────────────────────────────────────────┐  │
│ │                                                    │  │
│ │ [직접입력] [주소록] [엑셀업로드]                   │  │
│ │                                                    │  │
│ │ 전화번호 입력: [010-1234-5678          ]  [추가]  │  │
│ │                                                    │  │
│ │ 선택된 수신자: 3명                                 │  │
│ │ • 홍길동 (010-1234-5678)              [제거]      │  │
│ │ • 김철수 (010-2345-6789)              [제거]      │  │
│ │ • 이영희 (010-3456-7890)              [제거]      │  │
│ └────────────────────────────────────────────────────┘  │
│                                                          │
│ ┌─ 발신번호 ────────────────────────────────────────┐  │
│ │ [02-1234-5678 ▾]                                  │  │
│ └────────────────────────────────────────────────────┘  │
│                                                          │
│ ┌─ 메시지 내용 ─────────────────────────────────────┐  │
│ │                                                    │  │
│ │ [안녕하세요...                                   ] │  │
│ │ [                                                ] │  │
│ │ [                                                ] │  │
│ │ [                                                ] │  │
│ │                                                    │  │
│ │ 90 byte / 90 byte (한글 45자)                     │  │
│ │ ☑ 90byte 초과 시 자동으로 LMS 전환                │  │
│ └────────────────────────────────────────────────────┘  │
│                                                          │
│ ┌─ 발송 옵션 ───────────────────────────────────────┐  │
│ │ ○ 즉시 발송  ● 예약 발송                          │  │
│ │                                                    │  │
│ │ 발송 예정 시간: [2025-12-03] [10:00]             │  │
│ │                                                    │  │
│ │ ☑ 중복 발송 방지 (10분 이내 동일 번호/내용)       │  │
│ └────────────────────────────────────────────────────┘  │
│                                                          │
│ 예상 비용: 60원 (SMS 20원 × 3건)                        │
│                                                          │
│                              [임시저장] [미리보기] [발송] │
└─────────────────────────────────────────────────────────┘
```

### 3.3 MMS 발송 화면

SMS 화면에 추가되는 요소:

```
┌─ 제목 ────────────────────────────────────────────────┐
│ [제목을 입력하세요...                              ] │
└────────────────────────────────────────────────────────┘

┌─ 첨부파일 ────────────────────────────────────────────┐
│ 이미지를 드래그하거나 클릭하여 업로드                 │
│ (JPG, PNG / 최대 300KB)                                │
│                                                        │
│ [업로드된 파일]                                        │
│ • image.jpg (245 KB)                        [제거]    │
└────────────────────────────────────────────────────────┘
```

### 3.4 발송 이력 화면

```
┌─────────────────────────────────────────────────────────┐
│ 발송 이력                                                │
├─────────────────────────────────────────────────────────┤
│                                                          │
│ ┌─ 필터 ───────────────────────────────────────────┐   │
│ │ 기간: [2025-12-01] ~ [2025-12-03]     [조회]    │   │
│ │                                                  │   │
│ │ 상태: [전체▾] 타입: [전체▾]                     │   │
│ └──────────────────────────────────────────────────┘   │
│                                                          │
│ ┌──────────────────────────────────────────────────┐   │
│ │ CLIENT_KEY    │ 타입 │ 수신자 │ 상태 │ 요청시간 │   │
│ ├──────────────────────────────────────────────────┤   │
│ │ 20251202...  │ SMS  │ 100   │ 완료 │ 14:30    │   │
│ │ 20251202...  │ LMS  │ 50    │ 대기 │ 15:00    │   │
│ │ 20251201...  │ MMS  │ 20    │ 완료 │ 10:00    │   │
│ └──────────────────────────────────────────────────┘   │
│                                                          │
│ [◀] 1 2 3 4 5 [▶]                                       │
└─────────────────────────────────────────────────────────┘
```

### 3.5 대시보드 화면

```
┌─────────────────────────────────────────────────────────┐
│ 대시보드                        [오늘] [이번주] [이번달]  │
├─────────────────────────────────────────────────────────┤
│                                                          │
│ ┌─ 발송 통계 ──────┐ ┌─ 성공률 ────┐ ┌─ 총 비용 ───┐  │
│ │                  │ │             │ │             │  │
│ │  1,234건         │ │  97.2%      │ │  246,800원  │  │
│ │                  │ │             │ │             │  │
│ └──────────────────┘ └─────────────┘ └─────────────┘  │
│                                                          │
│ ┌─ 타입별 발송 현황 ────────────────────────────────┐  │
│ │                                                    │  │
│ │  SMS  ████████████████████ 800건 (64.8%)         │  │
│ │  LMS  ██████████ 300건 (24.3%)                   │  │
│ │  MMS  ████ 134건 (10.9%)                         │  │
│ │                                                    │  │
│ └────────────────────────────────────────────────────┘  │
│                                                          │
│ ┌─ 시간대별 발송 추이 ──────────────────────────────┐  │
│ │                                                    │  │
│ │  200│                      ╱╲                     │  │
│ │  150│              ╱╲     ╱  ╲                    │  │
│ │  100│         ╱╲  ╱  ╲   ╱    ╲                   │  │
│ │   50│    ╱╲  ╱  ╲╱    ╲ ╱      ╲                  │  │
│ │    0└────────────────────────────────             │  │
│ │      00 04 08 12 16 20 24                         │  │
│ │                                                    │  │
│ └────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────┘
```

---

## 4. 상태 관리

### 4.1 Zustand 스토어

#### 4.1.1 인증 스토어

```typescript
// stores/authStore.ts
import { create } from 'zustand';
import { persist } from 'zustand/middleware';

interface User {
  userId: string;
  username: string;
  email: string;
  role: string;
  companyId: string;
}

interface AuthState {
  user: User | null;
  token: string | null;
  isAuthenticated: boolean;
  login: (user: User, token: string) => void;
  logout: () => void;
}

export const useAuthStore = create<AuthState>()(
  persist(
    (set) => ({
      user: null,
      token: null,
      isAuthenticated: false,
      login: (user, token) =>
        set({ user, token, isAuthenticated: true }),
      logout: () =>
        set({ user: null, token: null, isAuthenticated: false }),
    }),
    {
      name: 'auth-storage',
    }
  )
);
```

#### 4.1.2 메시지 폼 스토어

```typescript
// stores/messageFormStore.ts
import { create } from 'zustand';

interface Recipient {
  phone: string;
  name?: string;
  variables?: Record<string, string>;
}

interface MessageFormState {
  messageType: 'SMS' | 'LMS' | 'MMS';
  senderNumber: string;
  recipients: Recipient[];
  content: string;
  title?: string;
  scheduledAt?: Date;
  dedupEnabled: boolean;
  files: File[];

  setMessageType: (type: 'SMS' | 'LMS' | 'MMS') => void;
  setSenderNumber: (number: string) => void;
  addRecipient: (recipient: Recipient) => void;
  removeRecipient: (phone: string) => void;
  setContent: (content: string) => void;
  setTitle: (title: string) => void;
  setScheduledAt: (date?: Date) => void;
  setDedupEnabled: (enabled: boolean) => void;
  addFile: (file: File) => void;
  removeFile: (fileName: string) => void;
  reset: () => void;
}

export const useMessageFormStore = create<MessageFormState>((set) => ({
  messageType: 'SMS',
  senderNumber: '',
  recipients: [],
  content: '',
  title: '',
  scheduledAt: undefined,
  dedupEnabled: true,
  files: [],

  setMessageType: (type) => set({ messageType: type }),
  setSenderNumber: (number) => set({ senderNumber: number }),
  addRecipient: (recipient) =>
    set((state) => ({
      recipients: [...state.recipients, recipient],
    })),
  removeRecipient: (phone) =>
    set((state) => ({
      recipients: state.recipients.filter((r) => r.phone !== phone),
    })),
  setContent: (content) => set({ content }),
  setTitle: (title) => set({ title }),
  setScheduledAt: (date) => set({ scheduledAt: date }),
  setDedupEnabled: (enabled) => set({ dedupEnabled: enabled }),
  addFile: (file) =>
    set((state) => ({
      files: [...state.files, file],
    })),
  removeFile: (fileName) =>
    set((state) => ({
      files: state.files.filter((f) => f.name !== fileName),
    })),
  reset: () =>
    set({
      recipients: [],
      content: '',
      title: '',
      scheduledAt: undefined,
      files: [],
    }),
}));
```

### 4.2 TanStack Query 훅

#### 4.2.1 메시지 발송 훅

```typescript
// hooks/useSendMessage.ts
import { useMutation, useQueryClient } from '@tanstack/react-query';
import { messageApi } from '@/api/messageApi';
import { toast } from 'react-hot-toast';

export const useSendMessage = () => {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: messageApi.sendMessage,
    onSuccess: (data) => {
      toast.success(`메시지 발송 요청이 완료되었습니다. (${data.clientKey})`);
      queryClient.invalidateQueries({ queryKey: ['messages'] });
    },
    onError: (error: any) => {
      toast.error(error.response?.data?.message || '발송 요청에 실패했습니다.');
    },
  });
};
```

#### 4.2.2 메시지 목록 조회 훅

```typescript
// hooks/useMessageList.ts
import { useQuery } from '@tanstack/react-query';
import { messageApi } from '@/api/messageApi';

interface MessageListParams {
  page: number;
  size: number;
  status?: string;
  startDate?: string;
  endDate?: string;
}

export const useMessageList = (params: MessageListParams) => {
  return useQuery({
    queryKey: ['messages', params],
    queryFn: () => messageApi.getMessageList(params),
    staleTime: 30000, // 30초
    refetchInterval: 60000, // 1분마다 자동 갱신
  });
};
```

#### 4.2.3 메시지 상세 조회 훅

```typescript
// hooks/useMessageDetail.ts
import { useQuery } from '@tanstack/react-query';
import { messageApi } from '@/api/messageApi';

export const useMessageDetail = (clientKey: string) => {
  return useQuery({
    queryKey: ['message', clientKey],
    queryFn: () => messageApi.getMessageDetail(clientKey),
    enabled: !!clientKey,
  });
};
```

#### 4.2.4 주소록 훅

```typescript
// hooks/useAddressBook.ts
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { addressBookApi } from '@/api/addressBookApi';
import { toast } from 'react-hot-toast';

export const useAddressBook = (params?: any) => {
  return useQuery({
    queryKey: ['addressBook', params],
    queryFn: () => addressBookApi.getAddressBook(params),
  });
};

export const useAddAddressBook = () => {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: addressBookApi.addContact,
    onSuccess: () => {
      toast.success('주소록에 추가되었습니다.');
      queryClient.invalidateQueries({ queryKey: ['addressBook'] });
    },
    onError: () => {
      toast.error('추가에 실패했습니다.');
    },
  });
};
```

#### 4.2.5 통계 훅

```typescript
// hooks/useStatistics.ts
import { useQuery } from '@tanstack/react-query';
import { statisticsApi } from '@/api/statisticsApi';

interface StatisticsParams {
  startDate: string;
  endDate: string;
}

export const useStatistics = (params: StatisticsParams) => {
  return useQuery({
    queryKey: ['statistics', params],
    queryFn: () => statisticsApi.getSummary(params),
    staleTime: 60000, // 1분
  });
};
```

---

## 5. API 통신

### 5.1 Axios 클라이언트 설정

```typescript
// api/client.ts
import axios from 'axios';
import { useAuthStore } from '@/stores/authStore';

const client = axios.create({
  baseURL: import.meta.env.VITE_API_BASE_URL || 'http://localhost:8080/api/v1',
  timeout: 30000,
  headers: {
    'Content-Type': 'application/json',
  },
});

// Request Interceptor
client.interceptors.request.use(
  (config) => {
    const token = useAuthStore.getState().token;
    if (token) {
      config.headers.Authorization = `Bearer ${token}`;
    }
    return config;
  },
  (error) => Promise.reject(error)
);

// Response Interceptor
client.interceptors.response.use(
  (response) => response.data,
  (error) => {
    if (error.response?.status === 401) {
      useAuthStore.getState().logout();
      window.location.href = '/login';
    }
    return Promise.reject(error);
  }
);

export default client;
```

### 5.2 메시지 API

```typescript
// api/messageApi.ts
import client from './client';
import { MessageRequest, MessageResponse, MessageListResponse } from '@/types/message';

export const messageApi = {
  sendMessage: async (request: MessageRequest): Promise<MessageResponse> => {
    return client.post('/messages', request);
  },

  getMessageList: async (params: any): Promise<MessageListResponse> => {
    return client.get('/messages', { params });
  },

  getMessageDetail: async (clientKey: string): Promise<any> => {
    return client.get(`/messages/${clientKey}`);
  },

  cancelScheduled: async (clientKey: string): Promise<void> => {
    return client.delete(`/messages/${clientKey}/schedule`);
  },
};
```

---

## 6. 타입 정의

### 6.1 메시지 타입

```typescript
// types/message.ts
export type MessageType = 'SMS' | 'LMS' | 'MMS';

export interface Recipient {
  phone: string;
  name?: string;
  variables?: Record<string, string>;
}

export interface MessageRequest {
  messageType: MessageType;
  senderNumber: string;
  recipients: Recipient[];
  content: string;
  title?: string;
  scheduledAt?: string;
  trafficType?: 'real' | 'normal' | 'batch';
  dedupEnabled?: boolean;
  dedupWindowMinutes?: number;
  files?: FileUpload[];
}

export interface FileUpload {
  fileName: string;
  fileSize: number;
  fileData: string; // base64
}

export interface MessageResponse {
  clientKey: string;
  status: string;
  trafficType: string;
  requestedAt: string;
  recipientCount: number;
  estimatedCost?: number;
}

export interface MessageListItem {
  clientKey: string;
  messageType: MessageType;
  recipientCount: number;
  status: string;
  requestedAt: string;
}

export interface MessageListResponse {
  content: MessageListItem[];
  totalElements: number;
  totalPages: number;
  currentPage: number;
  size: number;
}

export interface MessageDetail {
  clientKey: string;
  messageType: MessageType;
  content: string;
  status: string;
  requestedAt: string;
  sentAt?: string;
  recipients: RecipientStatus[];
}

export interface RecipientStatus {
  phone: string;
  name?: string;
  status: string;
  sentAt?: string;
}
```

---

## 7. 주요 컴포넌트 구현

### 7.1 메시지 폼 컴포넌트

```typescript
// components/forms/SmsForm.tsx
import React from 'react';
import { useMessageFormStore } from '@/stores/messageFormStore';
import { useSendMessage } from '@/hooks/useSendMessage';
import RecipientInput from '@/components/message/RecipientInput';
import ContentEditor from '@/components/message/ContentEditor';
import SenderNumberSelector from '@/components/message/SenderNumberSelector';
import ScheduleSelector from '@/components/message/ScheduleSelector';
import SendButton from '@/components/message/SendButton';

const SmsForm: React.FC = () => {
  const formState = useMessageFormStore();
  const sendMessage = useSendMessage();

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();

    const request = {
      messageType: 'SMS' as const,
      senderNumber: formState.senderNumber,
      recipients: formState.recipients,
      content: formState.content,
      scheduledAt: formState.scheduledAt?.toISOString(),
      dedupEnabled: formState.dedupEnabled,
    };

    await sendMessage.mutateAsync(request);
    formState.reset();
  };

  return (
    <form onSubmit={handleSubmit} className="space-y-6">
      <RecipientInput />
      <SenderNumberSelector />
      <ContentEditor maxLength={90} messageType="SMS" />
      <ScheduleSelector />

      <div className="flex justify-end space-x-3">
        <button type="button" className="btn-secondary">
          임시저장
        </button>
        <SendButton isLoading={sendMessage.isPending} />
      </div>
    </form>
  );
};

export default SmsForm;
```

### 7.2 수신자 입력 컴포넌트

```typescript
// components/message/RecipientInput.tsx
import React, { useState } from 'react';
import { useMessageFormStore } from '@/stores/messageFormStore';
import { validatePhone } from '@/utils/validation';

const RecipientInput: React.FC = () => {
  const [phone, setPhone] = useState('');
  const { recipients, addRecipient, removeRecipient } = useMessageFormStore();

  const handleAdd = () => {
    if (!validatePhone(phone)) {
      alert('올바른 전화번호를 입력해주세요.');
      return;
    }

    addRecipient({ phone });
    setPhone('');
  };

  return (
    <div className="border rounded-lg p-4">
      <h3 className="font-semibold mb-3">수신자</h3>

      <div className="flex space-x-2 mb-4">
        <input
          type="text"
          value={phone}
          onChange={(e) => setPhone(e.target.value)}
          placeholder="010-1234-5678"
          className="flex-1 px-3 py-2 border rounded"
        />
        <button
          type="button"
          onClick={handleAdd}
          className="px-4 py-2 bg-blue-500 text-white rounded"
        >
          추가
        </button>
      </div>

      <div className="space-y-2">
        <p className="text-sm text-gray-600">
          선택된 수신자: {recipients.length}명
        </p>
        {recipients.map((recipient) => (
          <div
            key={recipient.phone}
            className="flex items-center justify-between p-2 bg-gray-50 rounded"
          >
            <span>
              {recipient.name && `${recipient.name} `}({recipient.phone})
            </span>
            <button
              type="button"
              onClick={() => removeRecipient(recipient.phone)}
              className="text-red-500 text-sm"
            >
              제거
            </button>
          </div>
        ))}
      </div>
    </div>
  );
};

export default RecipientInput;
```

### 7.3 내용 에디터 컴포넌트

```typescript
// components/message/ContentEditor.tsx
import React from 'react';
import { useMessageFormStore } from '@/stores/messageFormStore';
import { calculateByteSize } from '@/utils/formatting';

interface ContentEditorProps {
  maxLength: number;
  messageType: 'SMS' | 'LMS' | 'MMS';
}

const ContentEditor: React.FC<ContentEditorProps> = ({ maxLength, messageType }) => {
  const { content, setContent } = useMessageFormStore();
  const byteSize = calculateByteSize(content);

  const handleChange = (e: React.ChangeEvent<HTMLTextAreaElement>) => {
    setContent(e.target.value);
  };

  return (
    <div className="border rounded-lg p-4">
      <h3 className="font-semibold mb-3">메시지 내용</h3>

      <textarea
        value={content}
        onChange={handleChange}
        placeholder="메시지 내용을 입력하세요..."
        className="w-full h-40 p-3 border rounded resize-none"
      />

      <div className="flex justify-between mt-2 text-sm">
        <span className={byteSize > maxLength ? 'text-red-500' : 'text-gray-600'}>
          {byteSize} byte / {maxLength} byte
        </span>
        {messageType === 'SMS' && (
          <label className="flex items-center space-x-2">
            <input type="checkbox" defaultChecked />
            <span>90byte 초과 시 자동으로 LMS 전환</span>
          </label>
        )}
      </div>
    </div>
  );
};

export default ContentEditor;
```

### 7.4 발송 이력 테이블

```typescript
// components/history/MessageTable.tsx
import React from 'react';
import { useMessageList } from '@/hooks/useMessageList';
import { format } from 'date-fns';

interface MessageTableProps {
  page: number;
  size: number;
  onRowClick: (clientKey: string) => void;
}

const MessageTable: React.FC<MessageTableProps> = ({ page, size, onRowClick }) => {
  const { data, isLoading, error } = useMessageList({ page, size });

  if (isLoading) return <div>로딩 중...</div>;
  if (error) return <div>오류가 발생했습니다.</div>;

  return (
    <div className="overflow-x-auto">
      <table className="w-full border-collapse">
        <thead>
          <tr className="bg-gray-100">
            <th className="px-4 py-2 text-left">CLIENT_KEY</th>
            <th className="px-4 py-2 text-left">타입</th>
            <th className="px-4 py-2 text-left">수신자</th>
            <th className="px-4 py-2 text-left">상태</th>
            <th className="px-4 py-2 text-left">요청시간</th>
          </tr>
        </thead>
        <tbody>
          {data?.content.map((message) => (
            <tr
              key={message.clientKey}
              onClick={() => onRowClick(message.clientKey)}
              className="border-b hover:bg-gray-50 cursor-pointer"
            >
              <td className="px-4 py-2 font-mono text-sm">
                {message.clientKey.substring(0, 20)}...
              </td>
              <td className="px-4 py-2">{message.messageType}</td>
              <td className="px-4 py-2">{message.recipientCount}명</td>
              <td className="px-4 py-2">
                <span
                  className={`px-2 py-1 rounded text-sm ${
                    message.status === 'complete'
                      ? 'bg-green-100 text-green-800'
                      : 'bg-yellow-100 text-yellow-800'
                  }`}
                >
                  {message.status}
                </span>
              </td>
              <td className="px-4 py-2">
                {format(new Date(message.requestedAt), 'yyyy-MM-dd HH:mm')}
              </td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
};

export default MessageTable;
```

---

## 8. 유틸리티 함수

### 8.1 유효성 검사

```typescript
// utils/validation.ts
export const validatePhone = (phone: string): boolean => {
  const phoneRegex = /^01[0-9]-?\d{3,4}-?\d{4}$/;
  return phoneRegex.test(phone.replace(/-/g, ''));
};

export const validateSenderNumber = (number: string): boolean => {
  const senderRegex = /^0\d{1,2}-?\d{3,4}-?\d{4}$/;
  return senderRegex.test(number.replace(/-/g, ''));
};

export const validateEmail = (email: string): boolean => {
  const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
  return emailRegex.test(email);
};
```

### 8.2 포맷팅

```typescript
// utils/formatting.ts
export const calculateByteSize = (text: string): number => {
  let byteSize = 0;
  for (let i = 0; i < text.length; i++) {
    const char = text.charAt(i);
    if (escape(char).length > 4) {
      byteSize += 2; // 한글 등 멀티바이트 문자
    } else {
      byteSize += 1; // 영문, 숫자 등
    }
  }
  return byteSize;
};

export const formatPhone = (phone: string): string => {
  const cleaned = phone.replace(/\D/g, '');
  if (cleaned.length === 11) {
    return cleaned.replace(/(\d{3})(\d{4})(\d{4})/, '$1-$2-$3');
  }
  if (cleaned.length === 10) {
    return cleaned.replace(/(\d{3})(\d{3})(\d{4})/, '$1-$2-$3');
  }
  return phone;
};

export const formatCurrency = (amount: number): string => {
  return new Intl.NumberFormat('ko-KR', {
    style: 'currency',
    currency: 'KRW',
  }).format(amount);
};
```

---

## 9. 환경 설정

### 9.1 .env.example

```bash
# API
VITE_API_BASE_URL=http://localhost:8080/api/v1

# File Upload
VITE_MAX_FILE_SIZE=10485760  # 10MB
VITE_ALLOWED_FILE_TYPES=image/jpeg,image/png

# Features
VITE_ENABLE_KAKAO=false
VITE_ENABLE_RCS=false
```

### 9.2 vite.config.ts

```typescript
import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';
import path from 'path';

export default defineConfig({
  plugins: [react()],
  resolve: {
    alias: {
      '@': path.resolve(__dirname, './src'),
    },
  },
  server: {
    port: 3000,
    proxy: {
      '/api': {
        target: 'http://localhost:8080',
        changeOrigin: true,
      },
    },
  },
});
```

### 9.3 package.json

```json
{
  "name": "iotree-linkwave-frontend",
  "version": "0.1.0",
  "type": "module",
  "scripts": {
    "dev": "vite",
    "build": "tsc && vite build",
    "preview": "vite preview",
    "lint": "eslint . --ext ts,tsx",
    "format": "prettier --write \"src/**/*.{ts,tsx}\""
  },
  "dependencies": {
    "react": "^18.3.1",
    "react-dom": "^18.3.1",
    "react-router-dom": "^6.21.0",
    "zustand": "^4.5.0",
    "@tanstack/react-query": "^5.17.0",
    "axios": "^1.6.5",
    "date-fns": "^3.0.6",
    "react-hook-form": "^7.49.3",
    "zod": "^3.22.4",
    "@hookform/resolvers": "^3.3.4",
    "react-hot-toast": "^2.4.1",
    "clsx": "^2.1.0"
  },
  "devDependencies": {
    "@types/react": "^18.3.1",
    "@types/react-dom": "^18.3.0",
    "@vitejs/plugin-react": "^4.2.1",
    "typescript": "^5.3.3",
    "vite": "^5.0.11",
    "eslint": "^8.56.0",
    "prettier": "^3.1.1",
    "postcss": "^8.4.33"
  }
}
```

---

## 10. 배포 및 빌드

### 10.1 프로덕션 빌드

```bash
# 빌드
npm run build

# 빌드 결과물
dist/
├── index.html
├── assets/
│   ├── index-[hash].js
│   └── index-[hash].css
```

### 10.2 Nginx 설정 (예시)

```nginx
server {
    listen 80;
    server_name quicksend-proto.example.com;

    root /var/www/quicksend-proto/dist;
    index index.html;

    location / {
        try_files $uri $uri/ /index.html;
    }

    location /api {
        proxy_pass http://backend:8080;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
```

---

## 11. 테스트

### 11.1 컴포넌트 테스트 (추천)

```typescript
// components/message/RecipientInput.test.tsx
import { render, screen, fireEvent } from '@testing-library/react';
import RecipientInput from './RecipientInput';

describe('RecipientInput', () => {
  it('should add recipient when valid phone is entered', () => {
    render(<RecipientInput />);

    const input = screen.getByPlaceholderText('010-1234-5678');
    const addButton = screen.getByText('추가');

    fireEvent.change(input, { target: { value: '01012345678' } });
    fireEvent.click(addButton);

    expect(screen.getByText(/01012345678/)).toBeInTheDocument();
  });
});
```

---

## 부록: 기술 선택 이유

### A.1 Zustand vs Redux
- 더 간단한 API
- 보일러플레이트 코드 최소화
- TypeScript 지원 우수
- 프로토타입에 적합한 경량 라이브러리

### A.2 TanStack Query 도입 이유
- 서버 상태 관리 자동화
- 캐싱, 리페칭, 동기화 자동 처리
- 로딩/에러 상태 관리 간소화
- Optimistic Update 지원

### A.3 Vite 선택 이유
- 빠른 개발 서버 시작
- HMR(Hot Module Replacement) 속도 우수
- 프로덕션 빌드 최적화
- 현대적인 개발 경험

### A.4 TypeScript 채택 이유
- 타입 안정성
- IDE 자동완성 지원
- 리팩토링 용이
- 런타임 에러 감소
