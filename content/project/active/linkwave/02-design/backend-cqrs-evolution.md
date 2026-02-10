---
created: 2026-02-10
tags:
  - linkwave
  - backend
  - cqrs
---

> 이 문서는 linkwave-docs의 backend/CQRS-EVOLUTION-GUIDE.md를 요약한 것입니다.

# LinkWave CQRS 아키텍처 진화 가이드

## 1. 개요

LinkWave는 두 가지 CQRS 패턴을 **도메인별로 분리**하여 사용:

| 도메인 | CQRS 패턴 | 이유 |
|--------|----------|------|
| **User, Contact, SenderNumber** | 기존 (JPA + MyBatis) | 관계 중심, CRUD 중심, 실시간 일관성 |
| **Message** | Event-Driven CQRS | 대용량, SNAP 연동, 비동기, 확장성 |

---

## 2. 두 패턴 비교

### 기존 패턴: JPA + MyBatis CQRS (동기식)

```
Client → Controller → Service
                        ├── Repository (JPA) ← Command
                        └── QueryMapper (MyBatis) ← Query
                              ↓
                          MySQL (동일 DB, 즉시 반영)
```

- Command와 Query가 **동일 DB** → 즉시 일관성 (Strong Consistency)
- 단순하고 직관적

### Event-Driven CQRS (비동기)

```
COMMAND SIDE:
  Client → CommandController → CommandService
                                  ├── Write DB (ums_msg)
                                  └── Outbox Table → OutboxProcessor → RabbitMQ

QUERY SIDE:
  RabbitMQ → Event Consumers
               ├── Read Model (MySQL/ES)
               ├── Statistics (ums_stats)
               └── Notification (WebSocket)
  Client → QueryController → QueryService → Read Model
```

- Command와 Query **물리적 분리** → 최종 일관성 (Eventual Consistency)
- 이벤트 기반 비동기, 확장성 높음

---

## 3. 도메인별 적용 근거

### User/Contact 도메인 → 기존 CQRS
- 데이터량: 수천~수만 (제한적)
- 일관성: 즉시 필요 (로그인 후 바로 반영)
- CRUD 중심, 복잡한 관계 (JPA가 적합)

### Message 도메인 → Event-Driven CQRS
- 데이터량: 일 10만건+ (대용량)
- SNAP Agent와 비동기 연동
- Write/Read 비율 불균형 (쓰기 폭주 시 읽기 영향 X)
- Outbox Pattern으로 이벤트 유실 방지

---

## 4. 진화 단계

### Phase 1: 기존 CQRS (현재)
- 모든 도메인에 JPA + MyBatis CQRS 적용
- 단일 DB, 즉시 일관성

### Phase 2: Message 도메인 Event-Driven 전환
- Message만 Event-Driven CQRS로 전환
- Outbox Pattern + RabbitMQ
- Feature Flag로 점진적 마이그레이션

### Phase 3: 고급 최적화 (선택적)
- Read Model을 Elasticsearch로 확장
- WebSocket 기반 실시간 알림
- 통계 전용 Read Model

---

## 5. Feature Flag 전략

```java
@Value("${linkwave.cqrs.message.event-driven:false}")
private boolean eventDrivenEnabled;
```

- `false` (기본): 기존 CQRS → 안정적인 동기 처리
- `true`: Event-Driven → 새로운 패턴 활성화
- 무중단 롤백 가능

---

## 핵심 원칙

1. **도메인 특성에 맞는 패턴 선택** — 만능 해결책은 없음
2. **점진적 진화** — 한 번에 모든 것을 바꾸지 않음
3. **단순함 우선** — 필요할 때만 복잡도를 수용
4. **Feature Flag** — 안전한 전환과 롤백

---

## Related Documents

- [[backend-architecture|Backend Architecture]]
- [[event-driven-cqrs|Event-Driven CQRS Implementation]]
