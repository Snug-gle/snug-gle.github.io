---
created: 2025-12-26
---
# Phase 5: 발송 이력 및 통계

## 📖 개념 설명

메시지 발송 이력 조회 및 통계 대시보드를 통해 발송 현황을 분석합니다.

**주요 기능**:
- 메시지 발송 이력 조회 (무한 스크롤)
- 발송 상태별 필터링
- 날짜 범위 검색
- 통계 대시보드 (발송 건수, 성공률, 비용 등)
- 실시간 통계 업데이트

---

## 🎯 구현 목표

- [ ] `src/types/statistics.ts` - 통계 타입
- [ ] `src/api/statisticsApi.ts` - 통계 API
- [ ] `src/pages/HistoryPage.tsx` - 발송 이력 화면
- [ ] `src/pages/DashboardPage.tsx` - 통계 대시보드
- [ ] `src/components/dashboard/StatisticsChart.tsx` - 차트
- [ ] `src/components/history/MessageFilter.tsx` - 필터
- [ ] `src/hooks/useInfiniteScroll.ts` - 무한 스크롤 훅

---

## 📝 Step 1: 통계 타입 정의

### 파일: `src/types/statistics.ts`

```typescript
/**
 * 대시보드 통계
 */
export interface DashboardStatistics {
  totalMessages: number
  successMessages: number
  failedMessages: number
  pendingMessages: number
  successRate: number
  totalCost: number
  todayMessages: number
}

/**
 * 일별 통계
 */
export interface DailyStatistics {
  date: string
  smsCount: number
  lmsCount: number
  mmsCount: number
  successCount: number
  failedCount: number
  totalCost: number
}
```

---

## 📝 Step 2: 통계 API 함수

### 파일: `src/api/statisticsApi.ts`

```typescript
import client from './client'
import type { ApiResponse } from '@/types/api'
import type { DashboardStatistics, DailyStatistics } from '@/types/statistics'

/**
 * 대시보드 통계 조회
 */
export const getDashboardStatistics = async (): Promise<
  ApiResponse<DashboardStatistics>
> => {
  return client.get('/statistics/dashboard')
}

/**
 * 일별 통계 조회
 */
export const getDailyStatistics = async (
  startDate: string,
  endDate: string
): Promise<ApiResponse<DailyStatistics[]>> => {
  return client.get('/statistics/daily', {
    params: { startDate, endDate }
  })
}
```

---

## 📝 Step 3: 무한 스크롤 훅

### 파일: `src/hooks/useInfiniteScroll.ts`

```typescript
import { useEffect, useRef, useState } from 'react'

interface UseInfiniteScrollOptions {
  onLoadMore: () => void
  hasMore: boolean
  loading: boolean
}

export const useInfiniteScroll = ({
  onLoadMore,
  hasMore,
  loading
}: UseInfiniteScrollOptions) => {
  const observerRef = useRef<IntersectionObserver | null>(null)
  const loadMoreRef = useRef<HTMLDivElement | null>(null)

  useEffect(() => {
    if (loading || !hasMore) return

    // Intersection Observer 생성
    observerRef.current = new IntersectionObserver(
      (entries) => {
        if (entries[0].isIntersecting) {
          onLoadMore()
        }
      },
      { threshold: 1.0 }
    )

    // 감시 시작
    if (loadMoreRef.current) {
      observerRef.current.observe(loadMoreRef.current)
    }

    // 클린업
    return () => {
      if (observerRef.current) {
        observerRef.current.disconnect()
      }
    }
  }, [loading, hasMore, onLoadMore])

  return { loadMoreRef }
}
```

**인사이트**:
- `IntersectionObserver`: 스크롤 위치 감지
- `threshold`: 1.0 = 요소가 100% 보일 때 트리거

---

## 📝 Step 4: 발송 이력 화면

### 파일: `src/pages/HistoryPage.tsx`

```typescript
import { useState, useEffect } from 'react'
import { useInfiniteScroll } from '@/hooks/useInfiniteScroll'
import type { MessageHistory } from '@/types/message'
import { Loader2 } from 'lucide-react'

const HistoryPage = () => {
  const [messages, setMessages] = useState<MessageHistory[]>([])
  const [page, setPage] = useState(0)
  const [hasMore, setHasMore] = useState(true)
  const [loading, setLoading] = useState(false)

  const loadMessages = async () => {
    setLoading(true)
    try {
      // API 호출 (구현 필요)
      const response = await getMessageHistory({ page, size: 20 })
      
      if (response.success && response.data) {
        setMessages(prev => [...prev, ...response.data.content])
        setHasMore(!response.data.last)
        setPage(prev => prev + 1)
      }
    } catch (error) {
      console.error('Failed to load messages:', error)
    } finally {
      setLoading(false)
    }
  }

  const { loadMoreRef } = useInfiniteScroll({
    onLoadMore: loadMessages,
    hasMore,
    loading
  })

  useEffect(() => {
    loadMessages()
  }, [])

  return (
    <div className="container mx-auto px-4 py-8">
      <h1 className="text-3xl font-bold mb-8">발송 이력</h1>

      <div className="space-y-4">
        {messages.map((message) => (
          <MessageCard key={message.messageId} message={message} />
        ))}

        {/* 무한 스크롤 트리거 */}
        <div ref={loadMoreRef} className="py-4 text-center">
          {loading && <Loader2 className="size-6 animate-spin mx-auto" />}
          {!hasMore && <p className="text-muted-foreground">더 이상 이력이 없습니다</p>}
        </div>
      </div>
    </div>
  )
}

const MessageCard = ({ message }: { message: MessageHistory }) => (
  <div className="border rounded-lg p-4">
    <div className="flex justify-between">
      <div>
        <p className="font-medium">{message.to}</p>
        <p className="text-sm text-muted-foreground">{message.content}</p>
      </div>
      <div className="text-right">
        <span className={`px-2 py-1 rounded text-sm ${
          message.status === 'SENT' ? 'bg-green-100 text-green-800' :
          message.status === 'FAILED' ? 'bg-red-100 text-red-800' :
          'bg-gray-100 text-gray-800'
        }`}>
          {message.status}
        </span>
        <p className="text-sm text-muted-foreground mt-1">
          {new Date(message.createdAt).toLocaleString()}
        </p>
      </div>
    </div>
  </div>
)

export default HistoryPage
```

---

## 📝 Step 5: 통계 대시보드

### 파일: `src/pages/DashboardPage.tsx`

```typescript
import { useEffect, useState } from 'react'
import { getDashboardStatistics } from '@/api/statisticsApi'
import type { DashboardStatistics } from '@/types/statistics'
import { Card } from '@/components/ui/card'

const DashboardPage = () => {
  const [stats, setStats] = useState<DashboardStatistics | null>(null)
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    const loadStatistics = async () => {
      try {
        const response = await getDashboardStatistics()
        if (response.success && response.data) {
          setStats(response.data)
        }
      } catch (error) {
        console.error('Failed to load statistics:', error)
      } finally {
        setLoading(false)
      }
    }

    loadStatistics()
  }, [])

  if (loading) return <div>로딩 중...</div>
  if (!stats) return <div>통계를 불러올 수 없습니다</div>

  return (
    <div className="container mx-auto px-4 py-8">
      <h1 className="text-3xl font-bold mb-8">대시보드</h1>

      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
        <StatCard
          title="총 발송 건수"
          value={stats.totalMessages.toLocaleString()}
          color="blue"
        />
        <StatCard
          title="성공 건수"
          value={stats.successMessages.toLocaleString()}
          color="green"
        />
        <StatCard
          title="실패 건수"
          value={stats.failedMessages.toLocaleString()}
          color="red"
        />
        <StatCard
          title="성공률"
          value={`${stats.successRate.toFixed(1)}%`}
          color="purple"
        />
      </div>
    </div>
  )
}

const StatCard = ({ title, value, color }: {
  title: string
  value: string
  color: string
}) => (
  <Card className="p-6">
    <h3 className="text-sm text-muted-foreground mb-2">{title}</h3>
    <p className={`text-3xl font-bold text-${color}-600`}>{value}</p>
  </Card>
)

export default DashboardPage
```

---

## ✅ 완료 체크리스트

- [ ] 통계 타입 정의
- [ ] 통계 API 함수 작성
- [ ] 무한 스크롤 훅 구현
- [ ] 발송 이력 화면
- [ ] 통계 대시보드
- [ ] 차트 컴포넌트 (Recharts)

---

## 💡 학습 포인트

### 1. TanStack Query의 useInfiniteQuery

```typescript
import { useInfiniteQuery } from '@tanstack/react-query'

const {
  data,
  fetchNextPage,
  hasNextPage,
  isFetchingNextPage
} = useInfiniteQuery({
  queryKey: ['messages'],
  queryFn: ({ pageParam = 0 }) => getMessages({ page: pageParam }),
  getNextPageParam: (lastPage) =>
    lastPage.last ? undefined : lastPage.pageNumber + 1
})
```

### 2. Recharts 사용

```typescript
import { LineChart, Line, XAxis, YAxis, CartesianGrid, Tooltip } from 'recharts'

<LineChart width={600} height={300} data={dailyStats}>
  <CartesianGrid strokeDasharray="3 3" />
  <XAxis dataKey="date" />
  <YAxis />
  <Tooltip />
  <Line type="monotone" dataKey="successCount" stroke="#10b981" />
  <Line type="monotone" dataKey="failedCount" stroke="#ef4444" />
</LineChart>
```

---

## 📚 다음 단계

**다음**: [06-ORGANIZATION-MANAGEMENT.md](./06-ORGANIZATION-MANAGEMENT.md) →
