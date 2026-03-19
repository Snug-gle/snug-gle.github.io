---
tags:
  - spring
  - event
  - transaction
  - async
  - audit-log
  - transactional-event-listener
  - event-listener
  - backend
category: resource
created: 2026-03-19
related:
  - spring-event-cqrs-sync-pattern
  - spring-internals-bean-lifecycle-event
  - spring-transaction-distributed-lock-redis
---

# 🔍 Spring 이벤트 설계: 도메인 이벤트 vs 인프라 이벤트

> 이벤트 종류 분류 원칙, @EventListener vs @TransactionalEventListener 선택 기준, @TransactionalEventListener와 @Transactional propagation 제약 (Spring 3.x)

---

## 📌 Situation / Symptom

**상황 1 — propagation 에러**

`@TransactionalEventListener` + `@Transactional` 조합으로 이벤트 핸들러를 작성했을 때 Spring 3.x에서 애플리케이션 시작 시 다음 에러 발생:

```
BeanInitializationException: ...
Cannot mix @TransactionalEventListener with @Transactional(REQUIRED)
```

**상황 2 — 감사 로그 미기록**

콘텐츠 위반 감사 로그를 `@TransactionalEventListener(AFTER_COMMIT)` 핸들러로 저장하도록 구현했는데, 위반 메시지 발송 시도 후 DB에 로그가 쌓이지 않음.

---

## 🔍 Technical Analysis

### 1. Spring 이벤트 종류 분류

Spring 이벤트는 **의미**에 따라 두 계층으로 나눌 수 있다.

| 구분 | 도메인 이벤트 (DomainEvent) | 인프라 이벤트 |
|------|----------------------------|--------------|
| 의미 | 도메인 상태 변경을 나타내는 비즈니스 사건 | 부수 효과 기록용 (감사 로그, 알림 등) |
| 예시 | `MessageSendRequestedEvent`, `MessageCompletedEvent` | `ContentViolationEvent` |
| 계층 | 도메인 레이어 | 인프라 레이어 |
| 포트 사용 | EventPublisher 포트 경유 권장 | `ApplicationEventPublisher` 직접 사용 가능 |
| 트랜잭션 의존 | 커밋 후 처리 필요 (AFTER_COMMIT) | 트랜잭션 결과와 무관하게 기록 필요한 경우도 있음 |

**설계 원칙**: 인프라 이벤트를 DomainEvent 계층에서 상속받게 하면 도메인 모델이 인프라 관심사에 오염된다. 별도 클래스로 분리한다.

```java
// 도메인 이벤트 — 비즈니스 의미
public record MessageCompletedEvent(String messageId, String status) {}

// 인프라 이벤트 — 감사 목적, DomainEvent 비상속
public record ContentViolationEvent(
    Long userId,
    String violatingKeyword,
    String content,
    ViolationSourceType sourceType
) {}
```

---

### 2. @TransactionalEventListener vs @EventListener 선택 기준

두 어노테이션의 핵심 차이는 **핸들러 실행 시점**이다.

| 특성 | `@EventListener` | `@TransactionalEventListener(AFTER_COMMIT)` |
|------|------------------|---------------------------------------------|
| 실행 시점 | `publishEvent()` 호출 **즉시** | 발행자 트랜잭션 **커밋 완료 후** |
| 트랜잭션 롤백 시 | 이미 실행됨 (취소 불가) | 핸들러 **미실행** |
| 롤백 직전 이벤트 | 정상 수신 | 수신 안 됨 |
| 적합한 용도 | 트랜잭션 결과와 무관한 기록 (감사 로그, 즉시 알림) | CQRS 읽기 모델 동기화, 외부 시스템 연동 |

#### 콘텐츠 위반 감사 로그 사례 분석

```
checkContent() 호출
    ↓ 위반 키워드 발견
ApplicationEventPublisher.publishEvent(ContentViolationEvent) ← 이벤트 발행
    ↓
ContentFilterException throw
    ↓
@Transactional 롤백 실행
```

이 흐름에서 이벤트는 롤백 **이전**에 발행된다. `AFTER_COMMIT`은 커밋 시에만 핸들러를 실행하므로, 롤백이 발생하면 핸들러가 실행되지 않는다. 감사 로그는 "위반 시도 자체"를 기록해야 하므로 트랜잭션 성공 여부와 무관하게 실행되어야 한다.

> [!tip] Best Practice
> 이벤트 핸들러 선택 기준:
> - "DB 커밋이 성공했을 때만 실행해야 한다" → `@TransactionalEventListener(AFTER_COMMIT)`
> - "트랜잭션 결과와 무관하게 항상 기록해야 한다" → `@EventListener`
> - `@EventListener` + `@Async` 조합 시 핸들러가 새 스레드에서 독립 트랜잭션으로 실행됨

---

### 3. @TransactionalEventListener + @Transactional propagation 제약 (Spring 3.x)

`AFTER_COMMIT` phase 후에는 발행자의 트랜잭션이 이미 종료되어 있다. 이 시점에 `REQUIRED`로 트랜잭션을 요청하면 "이미 닫힌 트랜잭션에 참여"하는 모호한 상황이 되어 Spring 3.x에서 시작 시 검증 오류를 낸다.

| propagation | 허용 여부 | 이유 |
|-------------|-----------|------|
| `REQUIRED` | ❌ Spring 3.x 금지 | AFTER_COMMIT 후 원래 트랜잭션 없음 — 참여 불가 |
| `REQUIRES_NEW` | ✅ | 독립 트랜잭션 새로 시작 — 명확함 |
| `NOT_SUPPORTED` | ✅ | 트랜잭션 없이 실행 — 명확함 |

```java
// ❌ Spring 3.x BeanInitializationException
@TransactionalEventListener(phase = TransactionPhase.AFTER_COMMIT)
@Transactional  // 기본값 REQUIRED
public void handleMessageCompleted(MessageCompletedEvent event) { ... }

// ✅ REQUIRES_NEW — 새 트랜잭션으로 독립 실행
@TransactionalEventListener(phase = TransactionPhase.AFTER_COMMIT)
@Transactional(propagation = Propagation.REQUIRES_NEW)
public void handleMessageCompleted(MessageCompletedEvent event) { ... }
```

> [!warning] @Async와 함께 쓸 때
> `@Async`가 붙으면 새 스레드에서 실행되므로 원래 트랜잭션과 무관하다. 이 경우 `REQUIRES_NEW`가 자연스럽고 올바른 선택이다. `@Async` 없이 `REQUIRES_NEW`를 쓰면 동일 스레드에서 새 물리 트랜잭션이 열리므로 데드락 가능성을 검토해야 한다.

---

### 4. @ConfigurationProperties 빈 등록 패턴

`@ConfigurationProperties` 어노테이션 단독으로는 Spring 빈으로 등록되지 않는다.

```java
// 이것만으로는 빈 등록 안 됨
@ConfigurationProperties(prefix = "linkwave.violation-log-archive")
public record ViolationLogArchiveProperties(int retentionDays, int chunkSize) {}
```

등록 방법 (기존 프로젝트 패턴 확인 후 동일하게 적용):

```java
// 방법 A: 엔트리포인트에 @EnableConfigurationProperties 추가
@SpringBootApplication
@EnableConfigurationProperties({
    ExistingProperties.class,
    ViolationLogArchiveProperties.class  // 신규 추가
})
public class Application { ... }

// 방법 B: @ConfigurationPropertiesScan (루트 패키지 자동 스캔)
@SpringBootApplication
@ConfigurationPropertiesScan
public class Application { ... }
```

> [!tip] Best Practice
> 신규 `@ConfigurationProperties` 추가 시 기존 등록 위치를 먼저 Grep으로 확인한다:
> ```
> Grep("@EnableConfigurationProperties") → 등록 클래스 찾기
> ```
> 프로젝트마다 방법이 다르므로 기존 방식을 미러링하는 것이 일관성 유지에 유리하다.

---

## 🛠 Solution

### 상황 1 해결 — propagation 수정

```java
// QuerySyncEventHandler.java
@TransactionalEventListener(phase = TransactionPhase.AFTER_COMMIT)
@Transactional(propagation = Propagation.REQUIRES_NEW)  // REQUIRED → REQUIRES_NEW
public void handleMessageCompleted(MessageCompletedEvent event) {
    messageHistoryRepository.updateStatus(
        event.messageId(),
        event.status(),
        true  // isSynced = true
    );
}
```

### 상황 2 해결 — 감사 이벤트 핸들러 교체

```java
// ContentViolationEventHandler.java
@Component
public class ContentViolationEventHandler {

    private final ContentViolationLogRepository repository;

    // @TransactionalEventListener 대신 @EventListener 사용
    @EventListener
    @Async  // 새 스레드 + 독립 트랜잭션
    public void handle(ContentViolationEvent event) {
        repository.save(ContentViolationLog.from(event));
    }
}
```

> [!warning] @Async 필수 설정
> `@Async`가 동작하려면 `@EnableAsync` 어노테이션과 `ThreadPoolTaskExecutor` 빈 설정이 필요하다. 기존 비동기 설정을 확인하고 재사용한다.

---

## 🔗 Related Concepts

- [[resource/topics/spring/spring-event-cqrs-sync-pattern|Spring Event 기반 CQRS 동기화 패턴]]
- [[resource/topics/spring/spring-internals-bean-lifecycle-event|Spring Bean 라이프사이클과 이벤트 처리]]
- [[resource/topics/spring/spring-transaction-distributed-lock-redis|Spring 트랜잭션과 분산 락]]
- [[resource/topics/spring/spring-transactional-event-listener-propagation|@TransactionalEventListener propagation 제약]]

---

## 📚 References

- [Spring TransactionalEventListener Javadoc](https://docs.spring.io/spring-framework/docs/current/javadoc-api/org/springframework/transaction/event/TransactionalEventListener.html)
- [Spring ApplicationEventPublisher](https://docs.spring.io/spring-framework/docs/current/javadoc-api/org/springframework/context/ApplicationEventPublisher.html)
- [Spring Boot @ConfigurationProperties](https://docs.spring.io/spring-boot/docs/current/reference/html/configuration-metadata.html)

---

*Last updated: 2026-03-19*
