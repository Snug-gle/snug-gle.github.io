---
created: 2026-03-12
---
---
created: 2026-03-11
---
---
created: 2026-03-10
updated: 2026-03-10
tags:
  - architecture
  - cqrs
  - jpa
  - mybatis
  - spring
  - linkwave
---

# CQRS 하이브리드 ORM 전략 — LinkWave JPA + MyBatis 설계

> LinkWave(멀티채널 메시징 플랫폼)에서 JPA와 MyBatis를 도메인 특성에 따라 분리한 설계 이유와 구현을 정리합니다.

---

## 배경: 단일 ORM의 한계

프로젝트 초기에는 JPA만 사용하는 것을 고려했습니다. 하지만 두 종류의 상충되는 요구사항이 있었습니다.

**User/Organization 도메인:**
- 기능: 회원가입, 프로필 수정, 조직 관리
- 특징: CRUD 중심, 복잡한 연관관계 탐색 필요, 데이터 수 적음
- 적합: JPA의 영속성 컨텍스트, 더티 체킹, 관계 탐색

**Message/MessageHistory 도메인:**
- 기능: 메시지 발송, 이력 조회, 통계
- 특징: 일 10만+ 건 INSERT, 복잡한 동적 필터링 쿼리, 커서 페이징
- 적합: MyBatis의 SQL 제어권, 성능 최적화

하나의 ORM으로 양쪽을 만족시키기 어렵다고 판단했고, **각 도메인에 맞는 ORM을 분리**하기로 결정했습니다.

---

## ORM 역할 분리 기준표

| 도메인 | ORM | 이유 |
|--------|-----|------|
| User, Organization | JPA | 관계 탐색 빈번(`@ManyToOne`, `@OneToMany`), 더티 체킹으로 변경 감지 |
| Message (발송 명령) | JPA | 발송 요청 저장 — Write Model |
| MessageHistory (이력) | MyBatis | 대용량 SELECT, 동적 쿼리, 커서 페이징 — Read Model |
| Contact (주소록) | MyBatis | 대량 임포트, 복잡한 검색 필터 |

---

## MybatisConfig.java — UUID 타입 핸들러 등록

```java
@Configuration
@MapperScan(basePackages = "com.example.messaging.infra.mybatis.mapper")
public class MybatisConfig {

  @Bean
  public ConfigurationCustomizer mybatisConfigurationCustomizer() {
    return configuration ->
        configuration
            .getTypeHandlerRegistry()
            .register(java.util.UUID.class, UuidTypeHandler.class);
  }
}
```

JPA는 UUID를 자동으로 처리하지만, MyBatis는 `UUID.class`에 대한 TypeHandler를 직접 등록해야 합니다. `UuidTypeHandler`는 UUID를 MySQL `BINARY(16)` 또는 `VARCHAR(36)` 형식으로 변환합니다.

`@MapperScan`으로 MyBatis Mapper 패키지를 명시 지정하면, JPA Repository와 패키지가 겹치는 혼동 없이 각자의 영역이 명확하게 분리됩니다.

---

## Event-Driven CQRS — 읽기 모델 동기화

CQRS의 핵심은 Write Model과 Read Model의 분리입니다. LinkWave에서는 Spring ApplicationEvent를 활용하여 두 모델을 동기화합니다.

### 이벤트 흐름

```
MessageSendCommand (HTTP 요청)
    │
    ▼
MessageService (JPA — Write Model)
    │ ApplicationEventPublisher.publishEvent()
    ▼
Spring ApplicationEvent
    │
    ▼
QuerySyncEventHandler (비동기)
    │ @TransactionalEventListener(AFTER_COMMIT)
    ▼
message_history 테이블 (MyBatis — Read Model)
```

### QuerySyncEventHandler.java

```java
@Slf4j
@Component
@RequiredArgsConstructor
public class QuerySyncEventHandler {

  private final MessageHistoryRepository messageHistoryRepository;
  private final CarrierResultCodeProperties carrierResultCodeProperties;

  /**
   * 메시지 발송 요청 이벤트 → Read Model에 PENDING 상태로 저장
   */
  @Async
  @TransactionalEventListener(phase = TransactionPhase.AFTER_COMMIT)
  public void handleMessageSendRequested(MessageSendRequestedEvent event) {
    log.debug("Handling MessageSendRequestedEvent: {}", event.clientKey());
    try {
      MessageHistory history = MessageHistory.builder()
          .clientKey(event.clientKey())
          .userId(event.userId())
          .batchKey(event.batchKey())
          .senderNumber(event.senderNumber())
          .recipientPhone(event.recipientPhone())
          .messageType(event.messageType())
          .content(event.content())
          .status("PENDING")
          .requestedAt(event.occurredAt())
          .scheduledAt(event.scheduledAt())
          .isScheduled(event.isScheduled())
          .isSynced(false)
          .build();

      messageHistoryRepository.save(history);
    } catch (Exception e) {
      log.error("Failed to sync message history: {}", event.clientKey(), e);
      // TODO: Dead Letter Queue 또는 재시도 로직 추가
    }
  }

  /**
   * 발송 완료 이벤트 → Read Model 상태를 SUCCESS/FAILED로 업데이트
   */
  @Async
  @TransactionalEventListener(phase = TransactionPhase.AFTER_COMMIT)
  public void handleMessageCompleted(MessageCompletedEvent event) {
    String status = carrierResultCodeProperties.isSuccess(event.resultCode())
        ? "SUCCESS" : "FAILED";

    messageHistoryRepository.findByClientKey(event.clientKey())
        .ifPresentOrElse(
            history -> {
              history.updateCompletion(
                  status, event.resultCode(), event.resultMessage(),
                  event.resultChannel(), event.telco(),
                  event.completedAt(), event.cost());
              history.markAsSynced();
              messageHistoryRepository.save(history);
            },
            () -> log.warn("Message history not found for: {}", event.clientKey()));
  }

  /**
   * 예약 취소 이벤트 → Read Model 상태를 CANCELLED로 업데이트
   */
  @Async
  @TransactionalEventListener(phase = TransactionPhase.AFTER_COMMIT)
  public void handleMessageCancelled(MessageCancelledEvent event) {
    messageHistoryRepository.findByClientKey(event.clientKey())
        .ifPresent(history -> {
          history.cancel();
          messageHistoryRepository.save(history);
        });
  }
}
```

---

## @TransactionalEventListener 설계 결정

### TransactionPhase.AFTER_COMMIT을 선택한 이유

| Phase | 동작 | 문제 |
|-------|------|------|
| `BEFORE_COMMIT` | Write 트랜잭션 커밋 전 실행 | Write 실패 시 Read Model도 롤백 필요 → 복잡도 증가 |
| `AFTER_COMMIT` ✅ | Write 트랜잭션 커밋 후 실행 | Write 성공이 보장된 후 Read Model 업데이트 |
| `AFTER_ROLLBACK` | Write 롤백 시 실행 | Read Model 보상 트랜잭션에 활용 |

`AFTER_COMMIT`을 선택하면 Write 트랜잭션이 확정된 후에만 Read Model이 갱신되어 데이터 불일치가 발생하지 않습니다.

### @Async를 함께 사용하는 이유

이벤트 핸들러가 동기로 실행되면 Write 경로의 응답 지연이 발생합니다. `@Async`로 별도 스레드에서 비동기 실행하면:
1. 메시지 발송 요청 응답이 즉시 반환됨
2. Read Model 동기화는 백그라운드에서 처리

단, `@Async` + `@TransactionalEventListener` 조합에서는 Read Model 동기화가 실패해도 Write 트랜잭션이 이미 커밋된 상태이므로, 실패 시 재처리 전략(TODO 주석으로 표시)이 필요합니다.

---

## Phase별 확장 계획

```
Phase 1 (현재): Spring ApplicationEvent
    장점: 추가 인프라 없음, 구현 단순
    단점: 단일 프로세스, 재시도 어려움

Phase 2 (계획): RabbitMQ / Kafka Consumer
    장점: 프로세스 분리, 메시지 보장, 재시도 가능
    단점: 인프라 추가 필요
```

Spring Event → 메시지 브로커로 전환 시 `QuerySyncEventHandler`만 수정하면 되도록 인터페이스를 설계했습니다. 이 점을 주석으로 명시해두었습니다:

```java
/**
 * Phase 1: Spring Event 기반
 * Phase 2: RabbitMQ Consumer로 전환
 */
```

---

## 설계 결과

### 장점
- **JPA 도메인**: 더티 체킹, 연관관계 탐색, 영속성 컨텍스트 완전 활용
- **MyBatis 도메인**: 복잡한 동적 쿼리 제어, 커서 페이징, 성능 최적화
- **이벤트 기반 동기화**: Write/Read 결합도 최소화

### 주의사항
- `message_history`(Read Model)와 `message`(Write Model) 간 일시적 불일치 가능 → 최종 일관성(Eventual Consistency) 허용 설계
- `@Async` 실패 시 Read Model이 갱신되지 않을 수 있음 → DLQ 또는 배치 보정 필요

---

## 참고

- [[database/cursor-pagination-linkwave|커서 페이징 구현기]]
- [[spring/역할 기반 분리 CQRS|역할 기반 분리 CQRS]]
- [[spring/spring-event-cqrs-sync-pattern|Spring Event CQRS 패턴]]
