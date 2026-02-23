---
created: 2026-02-19
---
# Message History를 영구 Read Model로 재정의한 이유

- **날짜**: 2026-02-19
- **분류**: 아키텍처 결정 / 백엔드
- **키워드**: CQRS, Read Model, 스케줄러 최적화, Java Record

---

## 들어가며

다채널 메시지 발송 플랫폼 LinkWave를 개발하던 중, 메시지 발송 이력(`message_history`) 테이블의 데이터 보존 정책을 전면 재검토하게 됐다. 처음엔 단순한 캐시 테이블로 설계했지만, 구현 과정에서 근본적인 설계 오류를 발견했다.

---

## 문제: 폴백이 불가능한 캐시 설계

초기 설계는 이랬다.

```
message_history (캐시, 최신 N일)
    ↓ 오래되면
ums_log (SNAP 원본 로그, 영구 보관)
```

`message_history`를 일정 기간 후 삭제하고, 오래된 데이터는 `ums_log`에서 폴백(fallback)하려 했다. 그런데 `ums_log`의 실제 스키마를 들여다보니 폴백 자체가 불가능했다.

| 필드 | `ums_log` | `message_history` |
|------|-----------|-------------------|
| user_id (누가 보냈나?) | ❌ 없음 | ✅ 있음 |
| 메시지 본문 (뭘 보냈나?) | ❌ 없음 | ✅ 있음 |
| 수신번호 | ✅ 있음 | ✅ 있음 |
| 발송 결과 코드 | ✅ 있음 | ✅ 동기화됨 |

`ums_log`는 SNAP(외부 발송 에이전트)의 발송 로그로, 인프라 레벨의 원시 데이터다. "누가" 보낸 메시지인지조차 기록되지 않는다. 사용자 화면에서 "내 발송 이력"을 보여주려면 `message_history`가 반드시 필요하다.

---

## 결정: 독립 영구 장부(Permanent Read Model)로 재정의

**`message_history`는 캐시가 아니다. 독립적인 영구 Read Model이다.**

```
[Command Side]               [External]              [Read Side]
  UmsMsg (쓰기 DB) ──발송→  SNAP Agent ──결과→  ums_log
                                                      ↓
                                          MessageStatusSyncScheduler
                                                      ↓
                                             message_history ← 사용자 조회
                                             (삭제 없음, 영구 보존)
```

삭제 스케줄러를 폐기하고, 동기화 스케줄러만 남겼다.

### 고려했지만 기각한 대안: Hot/Cold 분리

최근 데이터(Hot)는 `message_history`, 오래된 데이터(Cold)는 아카이브로 분리하는 방법도 검토했다. 하지만 현재 트래픽 규모에서는 운영 복잡도만 높이는 조기 최적화(Premature Optimization)였다. 대규모 트래픽이 발생하는 시점에 다시 검토하기로 했다.

---

## 스케줄러 최적화: 왜 "3일 윈도우 + 500건 페이징"인가

동기화 스케줄러(`MessageStatusSyncScheduler`)는 `ums_log`에서 발송 결과를 읽어 `message_history`를 갱신한다. 여기서 두 가지 최적화가 핵심이다.

### 1. 3일 윈도우 — 인덱스 레인지 스캔 강제

```java
LocalDateTime since = LocalDateTime.now().minusDays(3);
// SELECT * FROM ums_log WHERE requested_at >= :since
```

윈도우 없이 전체 조회하면 테이블 풀 스캔이 발생한다. `requested_at`에 인덱스가 있더라도 WHERE 절 범위가 없으면 옵티마이저가 풀 스캔을 선택할 수 있다. 3일 제한으로 인덱스 레인지 스캔을 강제하면 수십만 건 테이블에서도 빠르게 조회된다.

SNAP의 발송 결과는 보통 수 시간 내 확정된다. 3일은 충분한 안전 마진이다.

### 2. 500건 페이징 — OOM 방지

하루에도 수천 건의 발송이 이루어질 수 있다. 전체를 한 번에 메모리에 올리면 OOM이 발생할 수 있다. 500건씩 페이징하여 안전하게 처리한다.

---

## DateTimeFormatter는 왜 상수로?

```java
// 잘못된 방식: 스케줄러 실행마다 객체 생성
LocalDateTime.now().format(DateTimeFormatter.ofPattern("yyyyMMddHHmmss"));

// 올바른 방식: static final 상수로 재사용
private static final DateTimeFormatter FORMATTER =
    DateTimeFormatter.ofPattern("yyyyMMddHHmmss");
```

`DateTimeFormatter`는 불변(Immutable)이고 스레드 안전(Thread-safe)하다. 따라서 인스턴스를 공유해도 안전하며, 매번 생성할 필요가 없다. 스케줄러처럼 반복 실행되는 코드에서는 이 패턴이 GC 부하를 줄인다.

---

## DTO에서 Java Record로

이번 작업에서 `UmsLogResult`와 `MessageCompletedEvent`를 전통적인 DTO 클래스에서 Java Record로 전환했다.

```java
// Before: 보일러플레이트 코드가 많은 DTO
public class UmsLogResult {
    private final String msgKey;
    private final String resultCode;

    public UmsLogResult(String msgKey, String resultCode) { ... }
    public String getMsgKey() { return msgKey; }
    // equals, hashCode, toString...
}

// After: Java Record (Java 16+)
public record UmsLogResult(
    String msgKey,
    String resultCode,
    String resultChannel,  // done_product (신규 필드)
    String telco           // done_telco (신규 필드)
) {}
```

Record는 불변성을 자동으로 보장하고, 데이터 전달 객체(DTO)임을 코드 레벨에서 명확히 표현한다. 이벤트 객체처럼 생성 후 변경이 없는 데이터에 이상적이다.

---

## 마치며

"단순해 보이는 캐시 테이블이 사실은 핵심 영구 데이터였다"는 발견이 이번 결정의 출발점이었다. 추상적인 아키텍처 논의보다 실제 스키마를 들여다보는 것이 더 빠른 답을 주었다.

현재 설계:
- ✅ `message_history` = 영구 Read Model (삭제 없음)
- ✅ 스케줄러 = 3일 윈도우 + 500건 페이징으로 안전하게 동기화
- ✅ Hot/Cold 분리 = 트래픽 증가 시 재검토

---

**관련 문서**:
- [message-history-implementation.md](../guides/backend-guides/message/message-history-implementation.md) — 구현 가이드
- [Vault: Message History Read Model](../../../MyJourneyContinues/project/active/linkwave/03-implementation/message-history-read-model.md) — ADR 전체
