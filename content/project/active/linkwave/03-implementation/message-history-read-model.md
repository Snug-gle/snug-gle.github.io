---
created: 2026-02-19
tags:
  - linkwave
  - backend
  - architecture
  - read-model
  - cqrs
---

# Message History: 영구 Read Model 아키텍처 결정

> **결정일**: 2026-02-19
> **결정 유형**: Architecture Decision Record (ADR)

---

## 1. 배경 및 문제

### 초기 설계 (폐기됨)

초기에는 `message_history` 테이블을 **일시적 캐시**로 설계했다:

- SNAP 발송 결과를 빠르게 조회하기 위해 `message_history`에 캐싱
- 일정 기간 후 `ums_log`(SNAP 원본 로그)에서 폴백(fallback)
- 오래된 레코드는 삭제 스케줄러로 정리

### 문제 발견

`ums_log` 폴백이 실제로 불가능하다는 것을 발견했다:

| 필드 | `ums_log` | `message_history` |
|------|-----------|-------------------|
| user_id | ❌ 없음 | ✅ 있음 |
| 메시지 본문 | ❌ 없음 | ✅ 있음 |
| 수신번호 | ✅ 있음 | ✅ 있음 |
| 발송 결과 | ✅ 있음 | ✅ 동기화됨 |

`ums_log`만으로는 "어느 사용자가 보낸 메시지인지"조차 알 수 없다.

---

## 2. 아키텍처 결정

### 결정: `message_history` = 영구 Read Model

**`message_history`는 단순 캐시가 아닌 독립적인 영구 장부(Permanent Read Model)로 정의한다.**

```
[Command Side]         [External Agent]        [Read Side]
  UmsMsg (쓰기) ──발송→   SNAP Agent ──결과→  ums_log
                                                  ↓ (스케줄러 동기화)
                                            message_history  ← 사용자 조회
                                            (영구 보존, 삭제 없음)
```

### 기각된 대안: Hot/Cold 분리

- **Hot**: 최근 N일 데이터 (`message_history`)
- **Cold**: 오래된 데이터 (`ums_log` 아카이브)

**기각 이유**: 현재 트래픽 수준에서 단일 테이블 영구 보관이 관리 복잡도를 줄이는 데 더 효과적. Hot/Cold 분리는 대규모 트래픽이 발생하는 시점에 재검토.

---

## 3. 스케줄러 설계 (`MessageStatusSyncScheduler`)

`ums_log` → `message_history` 상태 동기화를 담당하는 스케줄러.

### 핵심 파라미터

| 파라미터 | 값 | 이유 |
|---------|-----|------|
| 조회 윈도우 | 최근 3일 | 인덱스 레인지 스캔 강제 (풀 스캔 방지, DB 부하 차단) |
| 페이지 크기 | 500건 | 메모리 보호, OOM 방지 |

**왜 3일인가?**
SNAP의 발송 결과는 보통 수 시간 내 확정된다. 3일 윈도우는 안전 마진을 충분히 확보하면서, `requested_at` 컬럼 인덱스를 활용한 레인지 스캔을 강제한다. 윈도우 없이 전체 조회 시 테이블 풀 스캔으로 DB 부하가 급증한다.

### DateTimeFormatter 최적화

```java
// 잘못된 방식: 매 스케줄 실행마다 객체 생성 (불필요한 GC 압력)
LocalDateTime.now().format(DateTimeFormatter.ofPattern("yyyyMMddHHmmss"));

// 올바른 방식: 불변 객체를 static final 상수로 재사용
private static final DateTimeFormatter FORMATTER =
    DateTimeFormatter.ofPattern("yyyyMMddHHmmss");
```

`DateTimeFormatter`는 스레드 안전(Thread-safe)하고 불변(Immutable)이므로 반드시 상수로 관리해야 한다.

---

## 4. ErrorCode 추가

예약 메시지 취소 실패 시나리오를 세분화하여 클라이언트가 명확히 처리할 수 있도록 했다:

| ErrorCode | 의미 | HTTP Status |
|-----------|------|-------------|
| `CANNOT_CANCEL_MESSAGE` | 취소 불가능한 상태의 메시지 (예: 이미 처리 중) | 400 |
| `MESSAGE_ALREADY_SENT` | 이미 발송 완료된 메시지 | 409 |

---

## 5. AsyncConfig 우아한 종료 (Graceful Shutdown)

비동기 메시지 처리 도중 서버가 종료될 경우 데이터 유실을 방지하기 위한 설계:

```java
@Configuration
@EnableAsync
public class AsyncConfig {
    @Bean
    public ThreadPoolTaskExecutor asyncExecutor() {
        ThreadPoolTaskExecutor executor = new ThreadPoolTaskExecutor();
        // 스레드 풀 설정 (Core / Max / Queue)
        executor.setCorePoolSize(2);
        executor.setMaxPoolSize(5);
        executor.setQueueCapacity(100);

        // 우아한 종료: 진행 중인 비동기 작업이 완료될 때까지 대기
        executor.setWaitForTasksToCompleteOnShutdown(true);
        executor.setAwaitTerminationSeconds(30);
        return executor;
    }
}
```

**`WaitForTasksToCompleteOnShutdown=true` 역할**:
1. SIGTERM 수신 시 즉시 종료하지 않음
2. 현재 진행 중인 비동기 작업이 완료될 때까지 대기 (최대 30초)
3. 메시지 상태 동기화 작업이 중간에 잘리는 것을 방지

---

## 6. DTO → Java Record 전환

```java
// Before: 전통적인 DTO 클래스
public class UmsLogResult {
    private String msgKey;
    private String resultCode;
    private String resultChannel;
    // getter, setter, constructor, equals, hashCode...
}

// After: Java Record (Java 16+)
public record UmsLogResult(
    String msgKey,
    String resultCode,
    String resultChannel,  // done_product 필드 (신규)
    String telco           // done_telco 필드 (신규)
) {}
```

**Record 전환 이점**:
- 불변성(Immutability) 자동 보장
- `equals`, `hashCode`, `toString` 자동 생성
- 데이터 전달 객체(DTO)임을 코드로 명확히 표현

---

## 관련 문서

- [[event-driven-cqrs|Event-Driven CQRS]] — 이벤트 기반 CQRS 전체 설계
- [[../02-design/api-specifications|API Specifications]] — 커서 기반 메시지 조회 API 명세
- [[../02-design/backend-cqrs-evolution|CQRS Evolution]] — CQRS 패턴 진화 과정
