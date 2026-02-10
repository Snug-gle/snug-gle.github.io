---
created: 2026-02-10
tags:
  - linkwave
  - backend
  - cqrs
  - event-driven
---

> 이 문서는 linkwave-docs의 PHASE1-EVENT-DRIVEN-CQRS.md를 요약한 것입니다.

# Phase 1: Event-Driven CQRS Implementation

## 1. 목표

Message 도메인에 Event-Driven CQRS를 도입하여 대용량 메시지 발송 처리의 확장성과 성능을 확보.

### 왜 Message 도메인에만?
- 일 10만건+ 대용량 쓰기
- SNAP Agent 비동기 연동
- Write/Read 비율 불균형 → 독립 확장 필요
- User 도메인은 기존 JPA+MyBatis CQRS 유지

---

## 2. 아키텍처

### Command Side (쓰기)

```
Client → CommandController → MessageCommandService
           ↓                    ↓
     Validation           ums_msg INSERT (JPA)
                               ↓
                         Outbox Table INSERT
                               ↓
                         OutboxProcessor (@Scheduled)
                               ↓
                         RabbitMQ (message.sent event)
```

### Query Side (읽기)

```
RabbitMQ → MessageEventConsumer
              ↓
         Read Model 업데이트 (MySQL)
         Statistics 업데이트 (ums_stats_daily)
              ↓
Client → QueryController → MessageQueryService → Read Model
```

---

## 3. Outbox Pattern

### 왜 Outbox?
- Application Event는 트랜잭션 외부 → 이벤트 유실 가능
- Outbox: DB 트랜잭션과 함께 이벤트 저장 → 유실 방지

### Outbox 테이블
```sql
CREATE TABLE outbox_events (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    aggregate_type VARCHAR(100),     -- 'MESSAGE'
    aggregate_id VARCHAR(100),       -- clientKey
    event_type VARCHAR(100),         -- 'MESSAGE_SENT'
    payload JSON,                    -- 이벤트 데이터
    status VARCHAR(20) DEFAULT 'PENDING',
    created_at DATETIME,
    processed_at DATETIME
);
```

### 처리 흐름
1. Service에서 `ums_msg` INSERT + `outbox_events` INSERT (같은 트랜잭션)
2. OutboxProcessor가 주기적으로 PENDING 이벤트 폴링
3. RabbitMQ로 발행 → status를 PROCESSED로 업데이트
4. 실패 시 재시도 (최대 3회)

---

## 4. 이벤트 종류

| 이벤트 | 발생 시점 | Consumer 동작 |
|--------|----------|---------------|
| `MESSAGE_SENT` | 발송 요청 시 | Read Model 생성, 통계 갱신 |
| `MESSAGE_COMPLETED` | SNAP 발송 완료 | 상태 업데이트, 이력 기록 |
| `MESSAGE_FAILED` | 발송 실패 | 실패 처리, 알림 |

---

## 5. 구현 단계

### Step 1: Outbox 테이블 + Processor
- outbox_events 테이블 생성
- @Scheduled OutboxProcessor 구현

### Step 2: RabbitMQ 연동
- Exchange + Queue 설정
- Producer (OutboxProcessor) + Consumer 구현

### Step 3: Read Model
- 쿼리 전용 테이블/뷰 생성
- MessageEventConsumer에서 Read Model 업데이트

### Step 4: Feature Flag 전환
- `linkwave.cqrs.message.event-driven=true`로 활성화
- 기존 동기식과 병행 운영 후 점진적 전환

---

## 6. 모니터링

- Outbox 미처리 이벤트 수 모니터링
- RabbitMQ DLQ (Dead Letter Queue) 감시
- Read Model과 Write Model 간 지연시간 측정

---

## Related Documents

- [[backend-cqrs-evolution|CQRS Evolution Guide]]
- [[backend-architecture|Backend Architecture]]
