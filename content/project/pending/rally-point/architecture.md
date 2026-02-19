---
created: 2026-02-09
---
---
tags:
  - project
  - rally-point
  - msa
  - spring
  - kafka
  - redis
  - architecture
category: project
status: in-progress
created: 2025-06-25
modified: 2025-10-29
---
# 🎾 RallyPoint 프로젝트 아키텍처 문서

### 1. 프로젝트 개요

- **이름**: RallyPoint
    
- **목적**: 테니스 코트 예약, 사용자 매칭, 중고 거래, 공지, 회원 관리 등 통합 플랫폼 제공
    
- **구성**: MSA 아키텍처 기반의 모듈형 시스템
    
- **스택**:
    
    - Backend: Spring Boot, Java 21, Kotlin (각 도메인은 언어별로 분리된 프로젝트로 구성)
        
    - 비동기/이벤트: Kafka, Redis
        
    - 스케줄링/배치: Spring Batch
        
    - 네트워킹: OpenFeign, WebFlux
        
    - 검색: Elasticsearch (예약/상품 등 검색 기능에 사용)
        
    - 빌드/관리: Gradle (Kotlin DSL)
        

---

### 2. 도메인 설계 (Bounded Context)

|서비스 이름|주요 기능|언어|비고|
|---|---|---|---|
|`user-service`|회원가입, 로그인, 권한|Java|인증, 세션 관리 포함|
|`court-service`|테니스장, 예약, 취소|Kotlin|분산락, Redis 캐싱|
|`match-service`|매칭 신청, 결과 저장|Kotlin|이벤트 기반 추천|
|`market-service`|중고거래, 매물 등록, 경매 기능 포함|Java|입찰 관련 연계, 경매 그래프 구현 고려|
|`bid-service`|입찰 처리, 낙찰 스케줄링|Java|Kafka, WebSocket 기반 실시간 입찰 처리|
|`notification-service`|알림 전송 (SMS, Push)|Java|Kafka Consumer 기반|
|`search-service`|Elasticsearch 기반 검색|Kotlin|상품, 예약, 입찰 색인|
|`batch-service`|Spring Batch 작업 전용|Kotlin|예약 정리, 보고서 등|
|`gateway-service`|API Gateway|Java|Spring Cloud Gateway|
|`notice-service`|공지사항 등록 및 노출|Kotlin|단순 CMS 역할|
|**`common-config`**|공통 설정, 보안, 유틸, DTO, 예외 처리|Kotlin/Java 혼합|모든 서비스에서 참조하는 라이브러리 모듈|

---

### 3. Redis 활용 전략

#### ✅ 캐싱

- 테니스장 예약 현황 빠른 조회를 위한 Redis 캐싱
    
- Key 예시: `court:{courtId}:reservations`
    
- TTL 관리 및 변경 이벤트 발생 시 캐시 무효화 필요
    

#### ✅ 세션 관리

- Redis에 사용자 세션 저장, JWT 인증 토큰 관리와 연동
    

#### ✅ 분산 락

- 동시 예약 방지
    
- Key 예시: `lock:reservation:{date}:{time}:{courtId}`
    
- `SETNX` 또는 `Redisson`으로 구현, TTL과 재시도 전략 필요
    

#### ✅ 대기열 관리

- 예약 실패 사용자 대기 리스트 구현 (Redis List 자료구조)
    
- 예약 취소 시 대기열 사용자에게 자동 알림
    

---

### 4. Kafka 활용 전략

#### ✅ 예약 이벤트 처리

- 예약 생성/취소 시 Kafka 이벤트 발행 (Topic: `reservation-events`)
    
- 이벤트 구조:
    

```json
{
  "type": "RESERVATION_CREATED",
  "reservationId": "abc123",
  "userId": "user456",
  "courtId": "courtA",
  "timestamp": "2024-06-25T15:00:00Z"
}
```

#### ✅ 알림 시스템

- Kafka Consumer가 알림 시스템으로 메시지를 전달 (SMS, Push 등)
    
- 실패 처리와 재시도 전략 필요 (DLQ 등 활용)
    

#### ✅ 사용자 행동 분석

- Kafka → 로그 적재 시스템 → 분석 (혼잡 시간 예측 등)
    

#### ✅ 도메인 간 이벤트 전파

- 예약 완료 → 매칭 자동 트리거 → 알림 전파
    

---

### 5. Spring Batch 활용 전략

#### ✅ 만료 예약 정리

- 일정 시간 체크인 없는 예약 → 상태 "만료됨"으로 변경
    

#### ✅ 보고서 생성

- 일/주/월 단위 예약, 매칭, 사용자 통계 보고서
    

#### ✅ 대기열 일괄 처리

- 공석 발생 시 대기열 사용자 일괄 배정 로직
    

#### ✅ 데이터 아카이빙

- 장기 보관이 필요한 예약 데이터 백업 처리
    

---

### 6. 보완 및 체크리스트

#### 🔐 인증/보안

- JWT + Redis 세션 + Refresh Token 전략 적용
    
- `@PreAuthorize`, Role 기반 권한 체크
    

#### ⚙️ 운영 툴 도입 추천

- Redis Insight (캐시 모니터링)
    
- Kafka UI (Conduktor, Kowl)
    
- Spring Batch 대시보드 (Spring Boot Admin 연동 가능)
    
- Elasticsearch 대시보드 (Kibana)
    

#### 📦 메시지 보장

- Kafka: at-least-once + idempotent 처리
    
- Redis: TTL, 캐시 일관성 정책 정리 필요
    

#### 📘 문서화 도구

- Spring REST Docs, Swagger/OpenAPI
    
- Kafka 스키마: Confluent Schema Registry 또는 JSON 명세화
    

---

### 7. 통합 흐름 요약 (시나리오 기반)

1. 사용자가 예약 요청  
    → Redis 캐시 확인 → DB → 예약 성공 → Kafka 이벤트 발행 → 알림
    
2. 예약 변경/취소 발생  
    → Redis 캐시 무효화 → Kafka로 변경 이벤트 발행 → UI/알림 갱신
    
3. 일정 간격 배치 실행  
    → 만료된 예약 처리 → 대기열 처리 → 예약 재배정
    
4. Elasticsearch 연동  
    → 예약 및 상품 데이터 색인 저장 → 키워드 기반 검색 처리
    

---

### 8. 향후 고려 사항

- Kafka 기반 이벤트소싱으로 전환할지 여부
    
- Redis Streams 기반 실시간 데이터 처리 구조 도입
    
- 데이터 분석을 위한 ELK 또는 Clickhouse 기반 데이터 웨어하우스 연계
    
- MSA 간 인증/인가 통합을 위한 API Gateway 및 OIDC 서버 도입
    
- Elasticsearch 기반 추천 시스템 또는 검색 최적화 구조 고도화
    
- 입찰 기능 연동 시 WebSocket 및 Kafka를 통한 실시간 가격 반영과 낙찰 확정 처리 구조
    
- 입찰 그래프 시각화를 위한 프론트 연계 고려 (Chart.js, D3.js 등 활용)
    

---

**작성일**: 2025-06-25  
**작성자**: @상훈  
**상태**: 초안 (v1.2)