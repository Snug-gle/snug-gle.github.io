---
tags:
  - spring
  - event
  - cqrs
  - async
  - scheduler
  - transaction
category: resource
created: 2026-03-09
---

# Spring Event 기반 CQRS 동기화 패턴

> Spring의 이벤트 발행/구독 메커니즘과 @TransactionalEventListener를 활용한 CQRS 읽기 모델 동기화 구현 가이드

---

## 개요

다채널 메시지 발송 플랫폼(LinkWave)에서 메시지 발송 상태를 관리하는 시스템을 설계할 때, **트랜잭션 안정성**과 **이벤트 주도 아키텍처**를 결합한 CQRS 패턴을 적용했습니다. 이 문서는 그 핵심 개념과 구현 원리를 정리합니다.

---

## 1. Spring Event 발행/구독 패턴의 핵심

### 1.1 발행자와 구독자의 느슨한 결합

**핵심 원칙**: Publisher는 Subscriber의 존재를 몰라도 된다.

```java
// Publisher (발행자) - 구독자를 알 필요 없음
@Service
@Transactional
public class MessageService {

    private final ApplicationEventPublisher eventPublisher;

    public void sendMessage(SendMessageRequest request) {
        // 1. 메시지 저장
        Message message = Message.create(request);
        messageRepository.save(message);

        // 2. 이벤트 발행 (구독자가 있는지 모름)
        eventPublisher.publishEvent(new MessageSendRequestedEvent(message.getId()));
    }
}

// Subscriber (구독자) - Publisher와 무관하게 동작
@Component
public class QuerySyncEventHandler {

    @TransactionalEventListener(phase = TransactionPhase.AFTER_COMMIT)
    public void handleMessageSendRequested(MessageSendRequestedEvent event) {
        // Publisher가 누구인지 모르고, 독립적으로 처리
    }
}
```

**이점:**
- 기능 추가 시 기존 코드 수정 불필요
- 각 구독자는 독립적으로 수정/추가 가능
- 테스트가 격리됨

---

### 1.2 `@TransactionalEventListener` vs `@EventListener`

| 특성 | @EventListener | @TransactionalEventListener(AFTER_COMMIT) |
|------|--------|-----------|
| 실행 시점 | 이벤트 발행 **즉시** | 트랜잭션 **커밋 완료 후** |
| 트랜잭션 롤백 시 | 핸들러는 이미 실행됨 | 핸들러 미실행 |
| 데이터 일관성 | 위험: DB와 외부 시스템 불일치 | 안전: DB 커밋 확인 후 처리 |
| 사용 사례 | 로깅, 즉시 알림 | CQRS 동기화, 외부 시스템 호출 |

```java
// ❌ 위험한 패턴
@EventListener
public void handleEvent(MessageSendRequestedEvent event) {
    // 이벤트 발행 즉시 실행
    // 만약 이후 DB 롤백되면? → 이미 처리됨!
    messageQueryStore.save(event);
}

// ✅ 안전한 패턴
@TransactionalEventListener(phase = TransactionPhase.AFTER_COMMIT)
public void handleEvent(MessageSendRequestedEvent event) {
    // 트랜잭션 커밋 완료 확인 후 실행
    // DB 상태 = 메모리 상태 보장
    messageQueryStore.save(event);
}
```

**선택 기준:**
- DB 일관성이 중요한가? → `AFTER_COMMIT`
- 장애에 강해야 하는가? → `AFTER_COMMIT` + `@Async`
- 즉시 피드백이 필요한가? → `@EventListener`

---

### 1.3 `@Async` + `@TransactionalEventListener` 조합

```java
@Component
public class QuerySyncEventHandler {

    @TransactionalEventListener(phase = TransactionPhase.AFTER_COMMIT)
    @Async
    public void handleMessageSendRequested(MessageSendRequestedEvent event) {
        // 1. 별도 스레드에서 비동기 처리
        // 2. 이벤트 핸들러 실패가 메인 로직에 영향 없음
        // 3. 메인 트랜잭션은 즉시 종료됨

        messageHistoryRepository.save(new MessageHistory(
            event.getMessageId(),
            MessageStatus.PENDING,
            false  // isSynced
        ));
    }
}
```

**이점:**
- 메인 로직 처리 시간 단축
- 이벤트 핸들러의 느린 작업 (외부 API 호출 등)이 블로킹하지 않음
- 핸들러 예외가 메인 트랜잭션을 롤백시키지 않음

**주의사항:**
- @Async는 반드시 별도의 ThreadPoolTaskExecutor 설정 필요
- 비동기 작업이 여러 번 실행될 수 있으므로 멱등성 확보 필수

---

## 2. CQRS 읽기 모델 동기화 흐름

### 2.1 전체 아키텍처

```
┌─────────────────────────────────────────────────────────────┐
│                      API 요청 (메시지 발송)                   │
└──────────────┬──────────────────────────────────────────────┘
               │
               ▼
┌─────────────────────────────────────────────────────────────┐
│  MessageService.sendMessage() @Transactional                 │
│  ├─ INSERT ums_msg (status='ready')                         │
│  ├─ PUBLISH MessageSendRequestedEvent                       │
│  └─ COMMIT 성공                                             │
└──────────────┬──────────────────────────────────────────────┘
               │
        ┌──────┴────────┬─────────────┐
        │               │             │
        ▼               ▼             ▼
  ┌──────────┐  ┌──────────────────┐  ┌──────────┐
  │ Event    │  │ SNAP Simulator   │  │ Batch   │
  │ Handler  │  │ Scheduler        │  │ Process │
  └────┬─────┘  └────┬─────────────┘  └──┬───────┘
       │             │                    │
       ▼             ▼                    ▼
  [Query Layer]  [Processing]      [Status Sync]
```

---

### 2.2 3개 서브시스템의 역할

#### 1️⃣ QuerySyncEventHandler (이벤트 기반)

**언제 실행**: MessageSendRequestedEvent 발행 후 트랜잭션 커밋 완료 시
**역할**: CQRS 읽기 모델 초기화

```java
@Component
public class QuerySyncEventHandler {

    @TransactionalEventListener(phase = TransactionPhase.AFTER_COMMIT)
    @Async
    public void handleMessageSendRequested(MessageSendRequestedEvent event) {
        // message_history 테이블에 레코드 생성
        messageHistoryRepository.save(new MessageHistory(
            event.getMessageId(),
            MessageStatus.PENDING,
            false  // isSynced = false
        ));
    }
}
```

**데이터 흐름:**
- ums_msg (쓰기) → 메시지 발송 상태 저장
- message_history (읽기) → 사용자에게 보여줄 상태 저장

---

#### 2️⃣ SnapSimulatorScheduler (배치 처리)

**언제 실행**: `@Scheduled(fixedDelay = 2000)` — 매 2초마다 (완료 후 대기)
**역할**: 메시지 발송 시뮬레이션 및 로그 기록

```java
@Component
public class SnapSimulatorScheduler {

    @Scheduled(fixedDelay = 2000)  // 이전 작업 완료 후 2초 대기
    public void processDirectToComplete() {
        // 1. ums_log_{YYYYMM} 테이블 생성 확인
        ensureLogTable();

        // 2. ready 상태의 메시지 조회
        List<UmsMsg> readyMessages = umsMsgRepository.findByStatus(MSG_STATUS_READY);

        // 3. 로그 엔트리 생성 (성공/실패 난수 결정)
        List<UmsLogEntry> logEntries = buildLogEntries(readyMessages);

        // 4. 로그 저장
        umsLogRepository.insertBatch(logEntries);

        // 5. ums_msg 상태 업데이트 (ready → complete)
        umsMsgRepository.updateStatusToComplete(readyMessages);

        // 6. complete 상태 메시지 삭제
        umsMsgRepository.deleteByStatus(MSG_STATUS_COMPLETE);
    }

    private List<UmsLogEntry> buildLogEntries(List<UmsMsg> messages) {
        return messages.stream()
            .map(msg -> {
                boolean isSuccess = Math.random() < msg.getSuccessRate();
                String telco = pickRandomTelco();

                return UmsLogEntry.builder()
                    .messageId(msg.getId())
                    .status(isSuccess ? "success" : "fail")
                    .telco(telco)
                    .build();
            })
            .collect(Collectors.toList());
    }

    private String pickRandomTelco() {
        double rand = Math.random();
        if (rand < 0.3) return "SKT";      // 30%
        if (rand < 0.7) return "KT";       // 40%
        return "LG";                       // 30%
    }
}
```

**데이터 흐름:**
- ums_msg (ready) → ums_log_{YYYYMM} (로그 삽입)
- ums_msg 상태 변경 (ready → complete)
- 삭제 (메모리 해제)

---

#### 3️⃣ MessageStatusSyncScheduler (상태 동기화)

**언제 실행**: `@Scheduled(fixedDelay = 10000)` — 매 10초마다 (완료 후 대기)
**역할**: DB 쓰기 모델 → 읽기 모델 상태 동기화

```java
@Component
public class MessageStatusSyncScheduler {

    @Scheduled(fixedDelay = 10000)  // 이전 작업 완료 후 10초 대기
    @Transactional
    public void syncMessageStatus() {
        // 1. 아직 동기화 안 된 메시지 조회
        List<MessageHistory> unsyncedMessages =
            messageHistoryRepository.findByIsSyncedFalse();

        // 2. 각 메시지의 최종 상태를 ums_log에서 조회
        for (MessageHistory history : unsyncedMessages) {
            String finalStatus = fetchStatusFromUmsLog(history.getMessageId());

            if (finalStatus != null) {
                // 3. 상태에 따라 이벤트 발행
                if ("success".equals(finalStatus)) {
                    eventPublisher.publishEvent(
                        new MessageCompletedEvent(history.getMessageId(), "SUCCESS")
                    );
                } else {
                    eventPublisher.publishEvent(
                        new MessageCompletedEvent(history.getMessageId(), "FAILED")
                    );
                }
            }
        }
    }
}
```

**이벤트 핸들러:**

```java
@Component
public class QuerySyncEventHandler {

    @TransactionalEventListener(phase = TransactionPhase.AFTER_COMMIT)
    public void handleMessageCompleted(MessageCompletedEvent event) {
        // message_history 최종 상태 업데이트
        messageHistoryRepository.update(
            event.getMessageId(),
            event.getStatus(),  // SUCCESS or FAILED
            true                // isSynced = true
        );
    }
}
```

---

### 2.3 타이밍 다이어그램

```
T=0s   │ API 요청
       ├─ MessageService.sendMessage()
       ├─ ums_msg INSERT (ready)
       ├─ MessageSendRequestedEvent 발행
       └─ @COMMIT 완료
            ↓ (비동기)
       ├─ QuerySyncEventHandler 실행
       └─ message_history INSERT (PENDING, isSynced=false)

T=2s   │ SnapSimulatorScheduler 실행 (fixedDelay=2s)
       ├─ ums_msg (ready) 조회
       ├─ ums_log_{YYYYMM} 삽입
       ├─ ums_msg 상태 업데이트 (complete)
       └─ 삭제 (완료된 데이터)

T=10s  │ MessageStatusSyncScheduler 실행 (fixedDelay=10s)
       ├─ message_history (isSynced=false) 조회
       ├─ ums_log에서 최종 상태 확인
       ├─ MessageCompletedEvent 발행
       │   ├─ status = SUCCESS or FAILED
       │   └─ @COMMIT
       │       ↓ (동기)
       │   └─ QuerySyncEventHandler.handleMessageCompleted()
       │       └─ message_history 업데이트 (isSynced=true)
       └─ 최종 상태: message_history (SUCCESS/FAILED, isSynced=true)
```

---

## 3. Spring @Component와 프록시 패턴

### 3.1 왜 @Component가 필요한가?

**핵심 원리**: Spring은 `@Transactional` 메서드가 있는 빈을 **프록시로 감싸서** 컨테이너에 등록합니다.

```java
// 1️⃣ 원본 클래스
@Component  // ← 이 어노테이션이 필수!
public class QuerySyncEventHandler {

    @Transactional
    public void handleEvent(Event event) {
        // 트랜잭션 처리
    }
}

// 2️⃣ Spring이 생성하는 프록시 클래스 (CGLIB)
public class QuerySyncEventHandler$$EnhancerByCGLIB$$xxx extends QuerySyncEventHandler {

    @Override
    public void handleEvent(Event event) {
        // 트랜잭션 시작
        Transaction tx = transactionManager.begin();
        try {
            super.handleEvent(event);  // 원본 메서드 호출
            tx.commit();               // 커밋
        } catch (Exception e) {
            tx.rollback();             // 롤백
            throw e;
        }
    }
}

// 3️⃣ Spring 컨테이너에 등록되는 것은 프록시 객체
applicationContext.getBean("querySyncEventHandler")  // → 프록시 객체
```

**@Component 없으면 발생하는 일:**
```
❌ @Component 없음
  → 컨테이너에 빈으로 등록 안 됨
  → 프록시 생성 안 됨
  → @Transactional 무시됨
  → @Scheduled도 실행 안 됨
  → @TransactionalEventListener도 등록 안 됨
```

---

### 3.2 @Scheduled + @Transactional 동작 원리

```java
@Component
public class MessageStatusSyncScheduler {

    @Scheduled(fixedDelay = 10000)
    @Transactional
    public void syncMessageStatus() {
        // ...
    }
}
```

**Spring의 내부 동작:**

1. **애플리케이션 시작 시**
   - ComponentScan으로 MessageStatusSyncScheduler 발견
   - BeanPostProcessor가 @Scheduled, @Transactional 감지
   - 프록시 객체 생성 및 컨테이너 등록
   - 스케줄러에 메서드 등록

2. **지정된 시간마다**
   - 스케줄러가 프록시 객체의 syncMessageStatus() 호출
   - 프록시의 @Transactional 처리
     - 트랜잭션 시작
     - 원본 메서드 실행
     - 커밋/롤백 처리

---

## 4. fixedDelay vs fixedRate

| 특성 | fixedRate | fixedDelay |
|------|-----------|-----------|
| 기준 | **이전 실행 시작** 후 N ms | **이전 실행 완료** 후 N ms |
| 누적 가능 | 예 (처리 시간 > 간격) | 아니오 |
| 블로킹 | 없음 (다음 실행 예약됨) | 있음 (완료까지 대기) |
| 적합한 경우 | 정확한 주기 필요 | 안전한 순차 처리 필요 |

```
fixedRate=5초 (처리 시간 3초)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
0s  ┌─── 3s  ┌─── 3s  ┌─── 3s
    │ 처리    │ 처리   │ 처리
    └─── 5s  └─── 10s └─── 15s
    실행1    실행2    실행3
    (동시 실행 가능 → DB 중복 처리 위험)

fixedDelay=5초 (처리 시간 3초)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
0s  ┌─── 3s  8s ┌─── 3s  16s ┌─── 3s
    │ 처리    │대기   │ 처리    │대기   │ 처리
    └─── 8s ─└──  11s ───└──  19s
    실행1         실행2         실행3
    (순차 실행 보장 → 안전)
```

**SNAP 시뮬레이터는 fixedDelay 사용:**
```java
@Scheduled(fixedDelay = 2000)  // 2초마다
public void processDirectToComplete() {
    // 이전 배치 완료 → 2초 대기 → 다음 배치 실행
    // → DB 중복 처리 방지
}
```

---

## 5. 설계 결정 사항

### 5.1 ums_msg 삭제 vs 상태 유지

**결정**: 완료 후 **삭제**

```sql
-- ums_msg는 일시적 상태 테이블
-- complete 상태로 업데이트 후 즉시 삭제
DELETE FROM ums_msg
WHERE MSG_STATUS = 'complete'
  AND CLIENT_KEY IN (?, ?, ?, ...)  -- 내가 처리한 것만 삭제
```

**이유:**
- ums_msg는 "발송 대기" 상태만 필요
- complete 상태는 ums_log에 이미 저장됨 (중복 저장 불필요)
- 메모리 절약 (매일 증가하지 않음)
- 삭제 조건에 CLIENT_KEY 포함 → 데이터 정합성 (내가 처리한 것만 삭제)

---

### 5.2 UmsLogEntry (쓰기) vs UmsLogResult (읽기) 분리

```java
// DTO 계층: 도메인 언어 분리
@Data
public class UmsLogEntry {
    private Long messageId;
    private String status;        // success, fail
    private String telco;         // SKT, KT, LG
    private LocalDateTime sentAt;
}

@Data
public class UmsLogResult {
    private Long messageId;
    private String status;
    private String telco;
    private LocalDateTime sentAt;
    // 읽기 전용 필드 추가 가능
}
```

**이점:**
- 쓰기 모델과 읽기 모델의 독립적 변경 가능
- DB 스키마와 도메인 언어 분리
- 미래 확장성 확보 (쓰기에는 더 많은 필드, 읽기에는 필요한 필드만)

---

### 5.3 이벤트 발행 책임 분리

**MessageSendRequestedEvent**: SnapSimulatorScheduler가 발행하지 않음
- 이유: SnapSimulatorScheduler는 상태 변경만 담당
- 이벤트는 도메인 변화가 발생했을 때만 발행

**MessageCompletedEvent**: MessageStatusSyncScheduler가 발행
- 이유: CQRS 동기화는 상태 동기화 스케줄러가 감지
- 읽기 모델 업데이트는 이벤트로 처리

---

## 6. 실무 체크리스트

### 6.1 이벤트 기반 CQRS 구현

- [ ] `@Component` 어노테이션 확인 (빈 등록 필수)
- [ ] `@TransactionalEventListener(phase = AFTER_COMMIT)` 사용
- [ ] 이벤트 클래스는 `@Component` 불필요 (DTO)
- [ ] 비동기 처리 필요 시 `@Async` 추가
- [ ] ThreadPoolTaskExecutor 설정 확인

### 6.2 배치 스케줄러 구현

- [ ] `@Scheduled(fixedDelay = ...)` 선택 (fixedRate는 위험)
- [ ] 스케줄러도 `@Component` + `@Transactional`
- [ ] 멱등성 확보 (중복 실행 대비)
- [ ] 삭제/업데이트 조건에 명확한 WHERE 절

### 6.3 읽기/쓰기 모델 분리

- [ ] 쓰기: Repository + @Transactional (JPA)
- [ ] 읽기: QueryMapper (MyBatis)
- [ ] 동기화: 이벤트로 처리
- [ ] DTO 분리 (Entry vs Result)

---

## 7. 관련 개념

- [[resource/topics/spring/spring-internals-bean-lifecycle-event|Spring Bean 라이프사이클과 이벤트 처리]]
- [[resource/topics/spring/역할 기반 분리 CQRS|역할 기반 CQRS 패턴]]
- [[resource/topics/spring/spring-transaction-distributed-lock-redis|Spring 트랜잭션과 분산 락]]

---

## 8. 참고 자료

- [Spring ApplicationEventPublisher](https://docs.spring.io/spring-framework/docs/current/javadoc-api/org/springframework/context/ApplicationEventPublisher.html)
- [TransactionalEventListener](https://docs.spring.io/spring-framework/docs/current/javadoc-api/org/springframework/transaction/event/TransactionalEventListener.html)
- [Spring @Scheduled](https://docs.spring.io/spring-framework/docs/current/javadoc-api/org/springframework/scheduling/annotation/Scheduled.html)
- [CQRS Pattern - Martin Fowler](https://martinfowler.com/bliki/CQRS.html)

---

*Last updated: 2026-03-09*
