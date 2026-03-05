---
tags:
  - backend
  - messaging
  - design-pattern
  - configuration
category: implementation
created: 2026-03-05
---

# 통신사 결과 코드 yml 분리 패턴

## 상황 / 문제

### 초기 상황

LG U+ MessageHub의 결과 코드를 처리하는 로직이 코드베이스 곳곳에 하드코딩되어 있었다:

```java
// 나쁜 예 1: QuerySyncEventHandler.java
if ("0000".equals(resultCode)) { // 오류: LG U+는 10000이 성공코드
    status = "SUCCESS";
}

// 나쁜 예 2: SentMessagesPage.tsx
if (resultCode === "0000") { // 하드코딩
    return <Badge>성공</Badge>;
}

// 나쁜 예 3: SnapSimulatorScheduler.java
private static final String SUCCESS = "10000";
// 다른 통신사로 바뀌면 코드 수정 필수
```

### 문제점

1. **하드코딩된 상수**: 통신사 변경 시 Java 코드 재컴파일 필요
2. **분산된 정의**: 성공 코드가 여러 파일에 중복 정의
3. **비즈니스 로직과 설정의 혼재**: 코드가 통신사 특정 정보에 의존
4. **테스트 어려움**: mock 시 하드코딩 값을 추적해야 함

### 발견: LG U+ 성공 코드는 `10000`

기존 코드베이스가 `"0000"`을 성공으로 가정하는 것은 **오류**였다. LG U+ 공식 문서에서:
- 유일한 성공 코드: **`10000`**
- 나머지: 모두 실패 (재시도 불가능)

---

## 기술적 분석

### 통신사 결과 코드 체계

#### LG U+ MessageHub

```
10000             ← 유일한 성공
20000 ~ 20999    ← 공통 오류 (필수 파라미터 누락 등)
30000 ~ 39999    ← 발송 오류 (단말 거부, 스팸 등)
50000 ~ 59999    ← RCS 오류
60000 ~ 69999    ← RBC 오류
```

예:
- `20001`: 필수 파라미터 누락 (실패)
- `30122`: 단말기 착신거부 (실패)
- `32114`: KKO 성공 불확실 → SNAP이 최종 결정 후 기록 (성공 또는 실패)

#### 다른 통신사 (가설)

```
0000              ← 성공 (SMS Hub 등)
1000 ~ 9999      ← 다양한 실패 코드
```

**핵심 교훈**: 통신사마다 코드 체계가 완전히 다르다. 같은 숫자라도 의미가 다를 수 있다.

### 상태 분류 설계

#### 처음 제안: 4가지 상태

```
SUCCESS    ← 발송 성공
FAILED     ← 발송 실패 (재시도 불가)
RETRYABLE  ← 일시적 오류 (재시도 가능)
UNCERTAIN  ← 상태 불확실 (대기 필요)
```

#### 논의를 통한 정리

| 상태 | 필요? | 이유 |
| :--- | :--- | :--- |
| SUCCESS | ✓ | 필요 |
| FAILED | ✓ | 필요 |
| RETRYABLE | ✗ 제거 | ums_log에 기록될 시점은 SMSC/SNAP이 이미 최종 처리 완료. 재시도 대상 아님 |
| UNCERTAIN | ✗ 제거 | SMS/MMS는 SMSC가 내부적으로 대기/재시도 처리 후 최종값만 리포트. KKO도 SNAP이 최종 결정 후 기록 |

**최종 결론**: **SUCCESS / FAILED 2가지로 충분**

---

## 해결 방안

### 패턴: yml 기반 설정 분리

**핵심 아이디어:**
- 통신사별 성공 코드를 yml에 정의
- 코드에서는 Properties 객체만 참조
- 통신사 변경 시: yml만 수정, 코드 수정 없음

### 1. CarrierResultCodeProperties 클래스

**`config/CarrierResultCodeProperties.java`**

```java
@Configuration
@ConfigurationProperties(prefix = "linkwave.carrier")
@Data
public class CarrierResultCodeProperties {
    private Map<String, CarrierConfig> providers = new HashMap<>();

    @Data
    public static class CarrierConfig {
        private List<String> successCodes = new ArrayList<>();
    }

    /**
     * 주어진 통신사의 결과 코드가 성공인지 판정
     */
    public boolean isSuccess(String carrier, String resultCode) {
        return providers.getOrDefault(carrier, new CarrierConfig())
            .getSuccessCodes()
            .contains(resultCode);
    }

    /**
     * 주어진 통신사의 성공 코드 목록 반환
     */
    public List<String> getSuccessCodes(String carrier) {
        return providers.getOrDefault(carrier, new CarrierConfig())
            .getSuccessCodes();
    }
}
```

### 2. yml 설정

**`application.yml`**

```yaml
linkwave:
  carrier:
    msg-hub-lgu:
      success-codes:
        - "10000"
    sms-hub:  # 향후 추가 통신사
      success-codes:
        - "0000"
    kakao-biz:
      success-codes:
        - "1000"
```

**`application-local.yml`**

```yaml
linkwave:
  carrier:
    msg-hub-lgu:
      success-codes:
        - "10000"
```

**`application-prod.yml`**

```yaml
linkwave:
  carrier:
    msg-hub-lgu:
      success-codes:
        - "10000"
    # 프로덕션에서만 다른 통신사 추가 가능
```

### 3. 사용처 1: QuerySyncEventHandler

**수정 전:**

```java
@Service
public class QuerySyncEventHandler {
    public void handle(QuerySyncCompletedEvent event) {
        String status = "0000".equals(event.resultCode()) ? "SUCCESS" : "FAILED";
        messageHistory.updateCompletion(event.messageId(), status, event.resultCode());
    }
}
```

**수정 후:**

```java
@Service
public class QuerySyncEventHandler {
    private final CarrierResultCodeProperties resultCodeProps;

    public void handle(QuerySyncCompletedEvent event) {
        String carrier = event.carrier(); // "msg-hub-lgu"
        String resultCode = event.resultCode();

        String status = resultCodeProps.isSuccess(carrier, resultCode)
            ? "SUCCESS"
            : "FAILED";

        messageHistory.updateCompletion(
            event.messageId(),
            status,
            resultCode
        );
    }
}
```

### 4. 사용처 2: MessageHistory

**수정 전:**

```java
@Repository
public class MessageHistory {
    public void updateCompletion(String messageId, String resultCode) {
        // 기존: status를 항상 "COMPLETED"로 하드코딩
        query.update()
            .set("status", "COMPLETED")
            .where("message_id = ?")
            .execute();
    }
}
```

**수정 후:**

```java
@Repository
public class MessageHistory {
    public void updateCompletion(String messageId, String status, String resultCode) {
        // 외부에서 status (SUCCESS / FAILED)를 받아서 저장
        query.update()
            .set("status", status)
            .set("result_code", resultCode)
            .where("message_id = ?")
            .execute();
    }
}
```

### 5. 사용처 3: SnapSimulatorScheduler

```java
@Component
public class SnapSimulatorScheduler {
    private final CarrierResultCodeProperties resultCodeProps;

    @Scheduled(fixedDelayString = "${linkwave.snap-simulator.outbound-interval:2000}")
    public void processOutbound() {
        List<SnapMsgDto> messages = mapper.findPendingMessages(100);

        for (SnapMsgDto msg : messages) {
            // yml에서 읽은 성공 코드 사용
            String successCode = resultCodeProps.getSuccessCodes("msg-hub-lgu")
                .get(0); // "10000"

            String resultCode = (Math.random() > 0.1)
                ? successCode
                : "30122"; // 실패: 단말기 착신거부

            mapper.updateMessageResult(msg.msgId(), resultCode);
        }
    }
}
```

### 6. 사용처 4: 프론트엔드 (SentMessagesPage.tsx)

**수정 전:**

```typescript
const getStatusBadge = (resultCode: string) => {
  if (resultCode === "0000") return <Badge>성공</Badge>;
  return <Badge variant="destructive">실패</Badge>;
};
```

**수정 후:**

```typescript
const getStatusBadge = (resultCode: string, status: string) => {
  if (status === "SUCCESS") return <Badge>성공</Badge>;
  return <Badge variant="destructive">실패</Badge>;
};

// 또는 백엔드에서 status 필드를 이미 포함해서 전송
// MessageHistory API: { messageId, status, resultCode, ... }
```

---

## 구현 요점

### 1. 통신사 식별자 정의

yml에서 prefix를 통신사명으로 사용:
- `msg-hub-lgu`: LG U+ MessageHub
- `sms-hub`: 일반 SMS Hub (가상)
- `kakao-biz`: 카카오 비즈니스

**통신사 추가 시 처리:**

```yaml
# 신규 통신사 Twilio 추가
linkwave:
  carrier:
    msg-hub-lgu:
      success-codes: ["10000"]
    twilio:
      success-codes: ["0"]  # Twilio는 0이 성공
```

```java
// 코드 수정 없음
boolean isSuccess = resultCodeProps.isSuccess("twilio", "0");
```

### 2. 타입 안정성

Properties 클래스를 Autowire하면 컴파일 타임에 타입 체크:

```java
@Service
public class MyService {
    @Autowired
    private CarrierResultCodeProperties props; // 타입 안정

    public void process(String carrier, String code) {
        props.isSuccess(carrier, code); // 메소드 완성도 (IDE)
    }
}
```

### 3. 테스트

**단위 테스트:**

```java
@Test
public void testIsSuccess() {
    CarrierResultCodeProperties props = new CarrierResultCodeProperties();

    CarrierConfig config = new CarrierConfig();
    config.setSuccessCodes(List.of("10000"));
    props.getProviders().put("msg-hub-lgu", config);

    assertTrue(props.isSuccess("msg-hub-lgu", "10000"));
    assertFalse(props.isSuccess("msg-hub-lgu", "30122"));
}
```

**통합 테스트:**

```java
@SpringBootTest
public class CarrierResultCodeIntegrationTest {
    @Autowired
    private CarrierResultCodeProperties props;

    @Test
    public void testYmlConfiguration() {
        // yml에서 로드된 값 검증
        assertTrue(props.isSuccess("msg-hub-lgu", "10000"));
    }
}
```

---

## 마이그레이션 체크리스트

### Phase 1: Properties 클래스 생성
- [ ] `CarrierResultCodeProperties` 클래스 작성
- [ ] yml 설정 추가 (모든 환경)
- [ ] 단위 테스트 작성

### Phase 2: 기존 로직 업데이트
- [ ] `QuerySyncEventHandler` 수정
- [ ] `MessageHistory.updateCompletion()` 시그니처 변경
- [ ] `SnapSimulatorScheduler` 수정
- [ ] 통합 테스트 작성

### Phase 3: 프론트엔드 업데이트
- [ ] API 응답에 `status` 필드 포함 확인
- [ ] `SentMessagesPage.tsx` 결과 코드 표시 로직 수정
- [ ] 컴포넌트 테스트

### Phase 4: 배포 및 모니터링
- [ ] 스테이징 환경에서 end-to-end 테스트
- [ ] 프로덕션 배포
- [ ] 로그 모니터링 (result_code 필드)

---

## 설계 원칙

> [!tip] 설정 vs 코드
> - **설정**: 통신사, 성공 코드, 타이밍 (yml에 저장)
> - **코드**: 비즈니스 로직, 흐름 제어 (Java에 저장)

> [!tip] DRY 원칙
> 성공 코드 정의는 **한 곳**에만. yml의 `linkwave.carrier.*`에만 정의.

> [!tip] 향후 확장성
> 새 통신사 추가 → yml에 prefix 추가 → Autowire된 Properties가 자동으로 로드 → 코드 수정 없음

---

## 추가 고려사항

### 1. 결과 코드 매핑 테이블 (Optional)

향후 UI에서 사용자 친화적 메시지를 표시하려면:

```yaml
linkwave:
  carrier:
    msg-hub-lgu:
      success-codes: ["10000"]
      error-messages:
        "20001": "필수 파라미터 누락"
        "30122": "단말기 착신거부"
```

### 2. 통신사별 재시도 정책

RETRYABLE을 나중에 추가해야 한다면:

```yaml
linkwave:
  carrier:
    msg-hub-lgu:
      success-codes: ["10000"]
      retryable-codes: ["30000"] # 가상 일시적 오류
```

### 3. 로그 레벨 조정

결과 코드별로 로그 레벨을 다르게:

```java
if (props.isSuccess(carrier, code)) {
    log.debug("Message sent successfully: {}", code);
} else {
    log.warn("Message failed: carrier={}, code={}", carrier, code);
}
```

---

## 관련 개념

- [[snap-simulator-guide|SNAP 시뮬레이터 구현 가이드]]
- [[msghub-result-codes|LG U+ MessageHub 결과 코드 레퍼런스]]
- [[../../02-design/snap-integration|SNAP Integration]]

---

## 참고 자료

- Spring Boot `@ConfigurationProperties` [공식 문서](https://docs.spring.io/spring-boot/docs/current/reference/html/features.html#features.external-config.typesafe-configuration-properties)
- 12-Factor App [Config 섹션](https://12factor.net/config)
