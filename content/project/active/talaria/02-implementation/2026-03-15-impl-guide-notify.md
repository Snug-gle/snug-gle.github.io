---
created: 2026-03-15
tags:
  - talaria
  - talaria-notify
  - kafka
  - structured-concurrency
  - ocp
  - dlq
---

# talaria-notify 구현 가이드

> 원본: `~/Project/talaria/docs/05-impl/talaria-notify.md`

---

## 서비스 역할

Kafka consume → 4채널 병렬 발송 → 결과 추적. **유일한 Kafka Consumer이자 발송 실행자**.

```
Kafka consume → StructuredTaskScope(4채널 병렬) → MySQL + Kafka result/dlq
```

---

## 핵심 설계 결정 (WHY)

### ChannelAdapter OCP 패턴

새 채널 추가 시 `SendNotificationService` 코드 수정 없이 구현체 1개만 추가.

```java
@Component
@ConditionalOnProperty(prefix = "talaria.notify.channels.discord", name = "enabled", havingValue = "true")
public class DiscordAdapter implements ChannelAdapter { ... }
// Spring이 List<ChannelAdapter> 자동 주입 → Map<ChannelType, ChannelAdapter> 변환
```

### Structured Concurrency — 4채널 병렬 발송

```java
try (var scope = new StructuredTaskScope.ShutdownOnFailure()) {
    channels.forEach(ch -> scope.fork(() -> dispatchToChannel(saved, ch)));
    scope.join(); // 모든 subtask 완료 대기
}
```

**Pitfall**: `dispatchToChannel()` 내부에서 예외를 반드시 잡아야 함
→ throw하면 scope가 닫혀 다른 채널에 영향

### DLQ 재시도 상태 머신

```
PENDING → SENDING → SENT           (정상)
                  → FAILED → RETRY (최대 3회, 지수 백오프)
                                  → DLQ (최종 실패)
```

상태 전이는 도메인 메서드(`markSending()`, `markSent()`, `markFailed()`)로만 가능.

### Kafka Deserializer 설정 필수

```yaml
spring.kafka.consumer:
  value-deserializer: org.springframework.kafka.support.serializer.JsonDeserializer
  properties:
    spring.json.trusted.packages: "io.github.snuggle.talaria.common.event"
```

누락 시 `SerializationException` → consumer lag 무한 증가.

### `dispatch.id` 저장 후 세팅 필수

```java
NotificationDispatchEntity saved = dispatchRepo.save(entity);
dispatch.setId(saved.getId()); // ← 누락 시 updateDispatch()가 insert 오동작
```

---

## 구현 단계 체크리스트

- [ ] Step 1: 도메인 모델 + 상태 머신 메서드 (`markSending`, `markSent`, `markFailed`)
- [ ] Step 2: `ChannelAdapter` 구현체 4개 (Slack, Telegram, Kakao, SMS)
- [ ] Step 3: JPA 엔티티 & `NotificationPersistenceAdapter`
- [ ] Step 4: `StockAnalyzedConsumer` — `@KafkaListener`
- [ ] Step 5: `SendNotificationService` — Structured Concurrency 핵심 로직
- [ ] Step 6: `KafkaNotificationEventAdapter` — result/dlq produce
- [ ] Step 7: `DlqRetryConsumer` — 지수 백오프 재시도
- [ ] Step 8: REST Controller (수동 발송, 조회)
- [ ] Step 9: 통합 테스트 (Mock ChannelAdapter, EmbeddedKafka)

---

## 포트폴리오 포인트

1. ChannelAdapter OCP: 새 채널 추가 = 기존 코드 무수정
2. Structured Concurrency: 4채널 동시 발송, 구조적 결과 수집
3. DLQ 상태 머신: 도메인 메서드로 상태 전이 캡슐화
4. Kafka 서비스 간 결합도 제거: invest 장애 ↔ notify 장애 격리
