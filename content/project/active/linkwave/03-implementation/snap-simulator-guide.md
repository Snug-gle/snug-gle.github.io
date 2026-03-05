---
tags:
  - backend
  - messaging
  - snap
  - testing
category: implementation
created: 2026-03-05
---

# SNAP 시뮬레이터 구현 가이드

## 상황 / 배경

**SNAP이란?**
- LG U+ MessageHub의 메시지 발송 중계 에이전트 (외부 JAR)
- 실제 환경에서는 SMPP 또는 HTTPS로 중계 서버(LG U+ 측)와 세션 연결
- 로컬 개발 환경에서는 중계 서버 접근 불가 → 외부 JAR를 시뮬레이트할 수 없음

**해결 과제:**
보낸메세지함, 예약메세지함, 발송이력 페이지를 구현 및 테스트하려면, 실제 SNAP 없이도 DB에 메시지 발송 이력이 기록되는 환경이 필요하다.

---

## 기술적 분석

### SNAP 내부 동작 원리

#### 1. DB 테이블 기반 통신

SNAP은 HTTP API가 아니라 **MySQL 테이블**을 통해 통신한다:

**Outbound (메시지 전송)**
```
LinkWave (Web)
  ↓ INSERT
ums_msg (LG U+ 스키마)
  ↓ (SNAP 폴링, ~1~2초)
SNAP이 읽음 → 통신사 전송 (SMPP/HTTPS)
  ↓
ums_msg DELETE (처리 완료)
```

**Inbound (결과 수신)**
```
통신사 콜백 (수초 ~ 수분)
  ↓
SNAP이 수신 → ums_log_{YYYYMM} 기록
  ↓ (LinkWave 조회 스케줄러, ~1초)
MessageHistory 읽음 → 상태 업데이트
```

#### 2. SNAP 내부 3개 큐 구조

각 큐는 최대 **1000건** 용량:

| 큐 | 역할 | 흐름 |
| :--- | :--- | :--- |
| Outbound | 발송 대기 | ums_msg → 통신사 전송 |
| Inbound | 리포트 수신 | 통신사 콜백 → ums_log 기록 |
| Fault | 장애 버퍼 | overflow 또는 failure recovery |

#### 3. 처리량 특성

- **최대 TPS**: 1000
- **배치 단위**: 1000건 (한 번에 처리)
- **내부 지연**: 1~2초 (폴링 + 큐 처리)
- **통신사 지연**: 수초 ~ 수분 (실제 발송, SMSC 처리)

**설계 의미:**
- 메시지를 ums_msg에 INSERT한 직후에는 아직 ums_log에 기록되지 않음
- 1~2초 후 SNAP이 폴링 → 통신사 전송 → (수초~수분 후) 콜백 수신 → ums_log 기록
- 따라서 MessageHistory 조회 로직은 **ums_log 폴링 형태**로 구현해야 함

---

## 구현 전략

### 시뮬레이터 아키텍처

```
SnapSimulatorScheduler
├── Outbound 스레드
│   └── SELECT ums_msg → 통신사 전송 시뮬 → DELETE ums_msg
└── Inbound 스레드
    └── 일부 메시지 → INSERT ums_log_{YYYYMM}
```

**동작:**
1. **Outbound 스케줄러** (예: 매 2초)
   - `ums_msg`에서 대기 중인 메시지 읽음 (배치 100건)
   - 무작위 성공/실패 결정
   - 성공하면 DELETE, 실패하면 RESULT_CODE만 업데이트

2. **Inbound 스케줄러** (예: 매 3초)
   - 처리 완료된 메시지 중 일부를 선택
   - `ums_log_{YYYYMM}` 테이블에 INSERT
   - LinkWave의 MessageStatusSyncScheduler가 이를 폴링

---

## 구현 가이드

### 1. Properties 클래스 생성

**`config/SnapSimulatorProperties.java`**

```java
@Configuration
@ConfigurationProperties(prefix = "linkwave.snap-simulator")
@Data
public class SnapSimulatorProperties {
    private boolean enabled = false;
    private int batchSize = 100;
    private long outboundIntervalMs = 2000;
    private long inboundIntervalMs = 3000;
}
```

### 2. Mapper 및 DTO 작성

**`infra/mybatis/dto/SnapMsgDto.java`**

```java
public record SnapMsgDto(
    String msgId,
    String userId,
    String phoneNumber,
    String content,
    String msgType,
    LocalDateTime createdAt
) {}
```

**`infra/mybatis/dto/UmsLogEntry.java`**

```java
public record UmsLogEntry(
    String logId,
    String msgId,
    String phoneNumber,
    String resultCode,
    String resultMsg,
    LocalDateTime reportedAt
) {}
```

**`infra/mybatis/mapper/SnapSimulatorMapper.java`**

```java
@Mapper
public interface SnapSimulatorMapper {
    List<SnapMsgDto> findPendingMessages(int limit);
    void updateMessageResult(String msgId, String resultCode);
    void deleteMessage(String msgId);
    void insertUmsLog(UmsLogEntry entry);
}
```

### 3. Scheduler 작성

**`application/scheduler/SnapSimulatorScheduler.java`**

```java
@Component
@ConditionalOnProperty(
    name = "linkwave.snap-simulator.enabled",
    havingValue = "true"
)
@Slf4j
public class SnapSimulatorScheduler {
    private static final String RESULT_CODE_SUCCESS = "10000";
    private static final String RESULT_CODE_FAIL = "30122"; // 단말기 착신거부

    private final SnapSimulatorProperties properties;
    private final SnapSimulatorMapper mapper;

    @Scheduled(fixedDelayString = "${linkwave.snap-simulator.outbound-interval:2000}")
    public void processOutbound() {
        List<SnapMsgDto> messages = mapper.findPendingMessages(properties.getBatchSize());

        for (SnapMsgDto msg : messages) {
            boolean success = Math.random() > 0.1; // 90% 성공률
            String resultCode = success ? RESULT_CODE_SUCCESS : RESULT_CODE_FAIL;

            mapper.updateMessageResult(msg.msgId(), resultCode);
            if (success) {
                mapper.deleteMessage(msg.msgId());
            }
        }

        if (!messages.isEmpty()) {
            log.info("[SNAP Simulator] Processed {} outbound messages", messages.size());
        }
    }

    @Scheduled(fixedDelayString = "${linkwave.snap-simulator.inbound-interval:3000}")
    public void processInbound() {
        // ums_log_{YYYYMM}에 결과 기록 (구현 시 동적 테이블명 필요)
        // ...
    }
}
```

### 4. Application 설정

**`application.yml`**

```yaml
linkwave:
  snap-simulator:
    enabled: false  # 기본값 비활성
    batch-size: 100
    outbound-interval: 2000
    inbound-interval: 3000
```

**`application-local.yml`**

```yaml
linkwave:
  snap-simulator:
    enabled: true  # 로컬 개발에서만 활성화
```

**`LinkwaveApplication.java`**

```java
@SpringBootApplication
@EnableScheduling  // 추가
public class LinkwaveApplication {
    public static void main(String[] args) {
        SpringApplication.run(LinkwaveApplication.class, args);
    }
}
```

---

## 핵심 설계 결정

### 1. `@ConditionalOnProperty`로 활성화 제어

```java
@ConditionalOnProperty(name = "linkwave.snap-simulator.enabled", havingValue = "true")
public class SnapSimulatorScheduler { ... }
```

**이점:**
- 프로덕션에서는 자동 비활성화 (application.yml에서 `enabled: false`)
- 로컬 개발 시에만 `application-local.yml`로 활성화
- 코드 수정 없이 설정만으로 제어

### 2. 무작위 성공/실패 시뮬레이션

```java
boolean success = Math.random() > 0.1; // 90% 성공률
```

**이유:**
- 실제 환경에서도 통신사는 일정 비율의 실패를 반환
- 실패 케이스 처리 로직을 테스트하려면 필수

### 3. `ums_log_{YYYYMM}` 동적 테이블 처리

현재 일자 기준으로 테이블명을 동적으로 생성:

```java
String tableName = "ums_log_" + LocalDate.now().format(DateTimeFormatter.ofPattern("yyyyMM"));
// INSERT INTO ums_log_202603 ...
```

---

## 테스트 시나리오

### 시나리오 1: 보낸메세지함 조회

```sql
-- 1. 메시지 등록
INSERT INTO ums_msg (msg_id, user_id, phone_number, content, ...)
VALUES ('msg-001', 'user-1', '01012345678', '테스트', ...);

-- 2. 시뮬레이터 동작 (2초 후)
-- SNAP Simulator가 outbound 처리 → ums_msg DELETE

-- 3. inbound 처리 (3초 후)
-- SNAP Simulator가 ums_log_202603 INSERT

-- 4. MessageHistory 조회
SELECT * FROM message_history WHERE user_id = 'user-1'
-- 상태: "COMPLETED" (성공) 또는 "FAILED" (실패)
```

### 시나리오 2: 예약메세지함

```sql
-- 1. 예약 메시지 등록
INSERT INTO scheduled_messages (id, user_id, scheduled_at, ...)
VALUES ('sched-001', 'user-1', DATE_ADD(NOW(), INTERVAL 1 HOUR), ...);

-- 2. 스케줄러가 scheduled_at 도래 시
-- → ums_msg에 INSERT (위의 시나리오 1과 동일)
```

---

## 주의사항

> [!warning] Race Condition
> MessageHistory의 메시지 ID가 ums_log에 기록되기 전에 ums_msg가 DELETE될 수 있다. 반드시 읽은 후 DELETE하는 순서를 지켜야 함.

> [!warning] ums_log_{YYYYMM} 파티셔닝
> 월별로 테이블이 나뉘므로, Mapper에서 동적 테이블명을 처리해야 한다. 각 월이 시작할 때 새 테이블 생성이 필요할 수 있다.

> [!warning] Transactional 경계
> Outbound와 Inbound 처리가 같은 트랜잭션에 있으면 안 된다. 각각 별도 트랜잭션으로 처리해서 실제 환경의 비동기 특성을 반영해야 한다.

---

## 다음 단계

1. **Outbound 스케줄러**: 메시지 읽음 → 삭제 로직 완성
2. **Inbound 스케줄러**: ums_log_{YYYYMM} 동적 생성 및 INSERT
3. **MessageStatusSyncScheduler 연동**: ums_log 폴링 → MessageHistory 업데이트
4. **보낸메세지함 페이지**: 결과 코드 및 상태 표시
5. **통합 테스트**: E2E 시뮬레이션 (메시지 생성 → 발송 → 상태 조회)

---

## 관련 개념

- [[snap-integration|SNAP Integration]] — 아키텍처 설계
- [[msghub-result-codes|LG U+ MessageHub 결과 코드]]
- [[message-history-read-model|MessageHistory Read Model]]
- [[event-driven-cqrs|Event-Driven CQRS]]

---

## 참고 자료

- [SNAP 매뉴얼](내부-문서)
- [LG U+ MessageHub 결과 코드](내부-문서)
- Spring Boot `@ConditionalOnProperty` [공식 문서](https://docs.spring.io/spring-boot/docs/current/api/org/springframework/boot/autoconfigure/condition/ConditionalOnProperty.html)
