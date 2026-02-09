---
created: 2025-12-26
---
# Phase 4: 주소록 관리

## 📖 개념 설명

주소록 시스템은 메시지 발송의 효율성을 높이는 핵심 기능입니다.

**주요 기능**:
- 연락처 CRUD (생성, 조회, 수정, 삭제)
- 그룹 관리 (연락처를 그룹으로 분류)
- CSV/Excel import/export
- 중복 연락처 감지 및 병합
- 대량 연락처 검색/필터링

---

## 🎯 구현 목표

- [ ] `src/types/addressBook.ts` - 주소록 타입
- [ ] `src/api/addressBookApi.ts` - 주소록 API
- [ ] `src/stores/addressBookStore.ts` - 주소록 상태
- [ ] `src/pages/AddressBookPage.tsx` - 주소록 화면
- [ ] `src/components/addressBook/ContactList.tsx` - 연락처 목록
- [ ] `src/components/addressBook/GroupManagement.tsx` - 그룹 관리
- [ ] `src/components/addressBook/ImportExport.tsx` - CSV import/export

---

## 📝 Step 1: 주소록 타입 정의

### 파일: `src/types/addressBook.ts`

```typescript
/**
 * 연락처
 */
export interface Contact {
  contactId: string
  name: string
  phone: string
  email?: string
  memo?: string
  groupId?: string
  createdAt: string
  updatedAt?: string
}

/**
 * 그룹
 */
export interface ContactGroup {
  groupId: string
  name: string
  contactCount: number
  createdAt: string
}

/**
 * 연락처 생성 요청
 */
export interface CreateContactRequest {
  name: string
  phone: string
  email?: string
  memo?: string
  groupId?: string
}

/**
 * 연락처 검색 필터
 */
export interface ContactSearchFilter {
  search?: string
  groupId?: string
  page?: number
  size?: number
}
```

---

## 📝 Step 2: 주소록 API 함수

### 파일: `src/api/addressBookApi.ts`

```typescript
import client from './client'
import type { ApiResponse, PaginatedResponse } from '@/types/api'
import type {
  Contact,
  ContactGroup,
  CreateContactRequest,
  ContactSearchFilter,
} from '@/types/addressBook'

/**
 * 연락처 목록 조회
 */
export const getContacts = async (
  filter: ContactSearchFilter
): Promise<ApiResponse<PaginatedResponse<Contact>>> => {
  return client.get('/contacts', { params: filter })
}

/**
 * 연락처 생성
 */
export const createContact = async (
  request: CreateContactRequest
): Promise<ApiResponse<Contact>> => {
  return client.post('/contacts', request)
}

/**
 * 연락처 수정
 */
export const updateContact = async (
  contactId: string,
  request: Partial<CreateContactRequest>
): Promise<ApiResponse<Contact>> => {
  return client.put(`/contacts/${contactId}`, request)
}

/**
 * 연락처 삭제
 */
export const deleteContact = async (
  contactId: string
): Promise<ApiResponse<void>> => {
  return client.delete(`/contacts/${contactId}`)
}

/**
 * 그룹 목록 조회
 */
export const getGroups = async (): Promise<ApiResponse<ContactGroup[]>> => {
  return client.get('/contacts/groups')
}

/**
 * 그룹 생성
 */
export const createGroup = async (
  name: string
): Promise<ApiResponse<ContactGroup>> => {
  return client.post('/contacts/groups', { name })
}

/**
 * CSV 가져오기
 */
export const importContactsFromCSV = async (
  file: File
): Promise<ApiResponse<{ successCount: number; failedCount: number }>> => {
  const formData = new FormData()
  formData.append('file', file)
  
  return client.post('/contacts/import', formData, {
    headers: {
      'Content-Type': 'multipart/form-data'
    }
  })
}

/**
 * CSV 내보내기
 */
export const exportContactsToCSV = async (
  groupId?: string
): Promise<Blob> => {
  const response = await client.get('/contacts/export', {
    params: { groupId },
    responseType: 'blob'
  })
  
  return response as any
}
```

---

## 📝 Step 3: 주소록 상태 관리

### 파일: `src/stores/addressBookStore.ts`

```typescript
import { create } from 'zustand'
import type { Contact, ContactGroup } from '@/types/addressBook'

interface AddressBookState {
  // 상태
  contacts: Contact[]
  groups: ContactGroup[]
  selectedGroupId: string | null
  searchQuery: string

  // 액션
  setContacts: (contacts: Contact[]) => void
  setGroups: (groups: ContactGroup[]) => void
  setSelectedGroupId: (groupId: string | null) => void
  setSearchQuery: (query: string) => void
  addContact: (contact: Contact) => void
  updateContact: (contactId: string, updates: Partial<Contact>) => void
  removeContact: (contactId: string) => void
}

export const useAddressBookStore = create<AddressBookState>((set) => ({
  contacts: [],
  groups: [],
  selectedGroupId: null,
  searchQuery: '',

  setContacts: (contacts) => set({ contacts }),
  setGroups: (groups) => set({ groups }),
  setSelectedGroupId: (selectedGroupId) => set({ selectedGroupId }),
  setSearchQuery: (searchQuery) => set({ searchQuery }),
  
  addContact: (contact) =>
    set((state) => ({
      contacts: [contact, ...state.contacts]
    })),
  
  updateContact: (contactId, updates) =>
    set((state) => ({
      contacts: state.contacts.map((c) =>
        c.contactId === contactId ? { ...c, ...updates } : c
      )
    })),
  
  removeContact: (contactId) =>
    set((state) => ({
      contacts: state.contacts.filter((c) => c.contactId !== contactId)
    })),
}))
```

---

## 📝 Step 4: CSV Import/Export 컴포넌트

### 파일: `src/components/addressBook/ImportExport.tsx`

```typescript
import { useRef } from 'react'
import { importContactsFromCSV, exportContactsToCSV } from '@/api/addressBookApi'
import { Button } from '@/components/ui/button'
import { toast } from 'react-hot-toast'
import { Upload, Download } from 'lucide-react'

const ImportExport = ({ onImportSuccess }: { onImportSuccess: () => void }) => {
  const fileInputRef = useRef<HTMLInputElement>(null)

  const handleImport = async (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0]
    if (!file) return

    // CSV 파일 검증
    if (!file.name.endsWith('.csv')) {
      toast.error('CSV 파일만 업로드 가능합니다')
      return
    }

    try {
      const response = await importContactsFromCSV(file)
      
      if (response.success && response.data) {
        toast.success(`${response.data.successCount}건 가져오기 완료`)
        onImportSuccess()
      } else {
        toast.error(response.error?.message || '가져오기 실패')
      }
    } catch (error) {
      toast.error('가져오기 실패')
    }

    // 파일 입력 초기화
    if (fileInputRef.current) {
      fileInputRef.current.value = ''
    }
  }

  const handleExport = async () => {
    try {
      const blob = await exportContactsToCSV()
      
      // Blob을 다운로드 링크로 변환
      const url = URL.createObjectURL(blob)
      const a = document.createElement('a')
      a.href = url
      a.download = `contacts_${new Date().toISOString().split('T')[0]}.csv`
      a.click()
      
      URL.revokeObjectURL(url)
      toast.success('내보내기 완료')
    } catch (error) {
      toast.error('내보내기 실패')
    }
  }

  return (
    <div className="flex gap-2">
      <input
        ref={fileInputRef}
        type="file"
        accept=".csv"
        onChange={handleImport}
        className="hidden"
      />
      
      <Button
        variant="outline"
        onClick={() => fileInputRef.current?.click()}
      >
        <Upload className="size-4 mr-2" />
        CSV 가져오기
      </Button>
      
      <Button
        variant="outline"
        onClick={handleExport}
      >
        <Download className="size-4 mr-2" />
        CSV 내보내기
      </Button>
    </div>
  )
}

export default ImportExport
```

**인사이트**:
- `FileReader` API로 CSV 파일 읽기
- `Blob`을 다운로드 링크로 변환
- `useRef`로 파일 입력 요소 제어

---

## ✅ 완료 체크리스트

- [ ] 주소록 타입 정의
- [ ] 주소록 API 함수 작성
- [ ] 주소록 상태 관리
- [ ] 연락처 목록 화면
- [ ] 연락처 추가/수정/삭제
- [ ] 그룹 관리
- [ ] CSV import/export

---

## 💡 학습 포인트

### 1. CSV 파일 처리

```typescript
// CSV → JSON 파싱 (Papa Parse 라이브러리)
import Papa from 'papaparse'

Papa.parse(file, {
  header: true,
  complete: (results) => {
    console.log(results.data) // JSON 배열
  }
})
```

### 2. Virtual Scrolling (대량 데이터)

```typescript
// React Virtualized 사용
import { List } from 'react-virtualized'

<List
  width={600}
  height={400}
  rowCount={contacts.length}
  rowHeight={60}
  rowRenderer={({ index, key, style }) => (
    <div key={key} style={style}>
      {contacts[index].name}
    </div>
  )}
/>
```

---

## 📚 다음 단계

**다음**: [05-HISTORY-AND-STATISTICS.md](./05-HISTORY-AND-STATISTICS.md) →
