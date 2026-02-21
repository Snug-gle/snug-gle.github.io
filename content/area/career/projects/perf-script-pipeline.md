---
created: 2026-02-21
title: Perf Script Pipeline — HAR-JMX 성능 분석 도구
tags: [project, portfolio, react, typescript, tanstack]
---

# Perf Script Pipeline — HAR-JMX 성능 분석 도구

**기간**: 2025.10 ~ 2026.01 (5주) | **역할**: Frontend Developer (전담)

> HAR → JMX/JTL 추출 → AI 상관관계 분석 → JMeter 스크립트 최적화 파이프라인

---

## 프로젝트 개요

웹 애플리케이션 성능 테스트 자동화 도구. QA 엔지니어가 수동으로 작성하던 JMeter 스크립트를 HAR 파일 기반으로 자동 생성하고, AI로 파라미터 상관관계를 분석한다.

**기술 스택**
- React 19, TypeScript, Vite
- TanStack Query, Table, Virtual, Router
- Tailwind CSS, Radix UI, Spring AI (백엔드 연동)

---

## 핵심 기술 결정

### 1. 대용량 테이블 가상화

**문제**: HAR 파싱 결과 10,000건 이상 → 전체 렌더링 시 브라우저 멈춤 (5초+)

**접근 과정**
1. 단순 페이징 (1,000건 단위) → 여전히 느림
2. TanStack Virtual 도입 → 화면에 보이는 행만 DOM에 존재

**결정**: `@tanstack/react-virtual` 가상 스크롤링
```tsx
const rowVirtualizer = useVirtualizer({
  count: rows.length,
  getScrollElement: () => parentRef.current,
  estimateSize: () => 35,
  overscan: 10,
});
```

**결과**: 렌더링 시간 90% 단축 (5초 → 0.5초), 메모리 사용량 70% 감소

---

### 2. React Query 캐싱 전략

**문제**: 중복 API 요청 + 조건 없는 요청 + 무한 루프 → 네트워크 포화

**결정**: staleTime / gcTime / enabled 조합
```tsx
useQuery({
  queryKey: ['har-analysis', fileId],
  queryFn: () => fetchAnalysis(fileId),
  staleTime: 5 * 60 * 1000,   // 5분 캐시 유효
  gcTime: 10 * 60 * 1000,     // 10분 후 GC
  enabled: !!fileId,           // 파일 있을 때만 요청
});
```

**결과**: API 요청 80% 감소

---

### 3. HAR 병합 처리

**문제**: 여러 HAR 파일을 하나의 분석 단위로 합쳐야 함

**결정**: 클라이언트에서 HAR JSON 파싱 후 entries 배열 병합 → 서버 전송량 최소화

---

## 성과 요약

| 지표 | Before | After | 개선율 |
|------|--------|-------|--------|
| 10,000건 렌더링 | 5초+ | 0.5초 | 90% ↓ |
| API 요청 수 | 기준치 | 20% | 80% ↓ |
| 메모리 사용량 | 기준치 | 30% | 70% ↓ |

---

## 배운 점

- TanStack 생태계 (Query/Table/Virtual/Router) 실전 적용
- 성능 측정 → React DevTools Profiler → 병목 특정 → 개선
- 가상화는 "느리면 쓰는 것"이 아니라 데이터 규모가 예측될 때 선제적으로 적용하는 것
