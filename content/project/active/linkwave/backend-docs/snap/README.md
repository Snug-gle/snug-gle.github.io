---
created: 2025-12-26
---
# SNAP Agent 연동 가이드

## 📌 개요

이 문서는 LinkWave Backend에서 SNAP Agent와 연동하는 방법을 안내합니다.

> **상세 분석 문서**: [SNAP-AGENT-ANALYSIS.md](../SNAP-AGENT-ANALYSIS.md)

---

## 1. 연동 구조

```
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│  LinkWave API   │────▶│    ums_msg      │────▶│   SNAP Agent    │
│  (발송 요청)     │     │   (발송 큐)      │     │   (발송 처리)    │
└─────────────────┘     └─────────────────┘     └────────┬────────┘
                                                         │
                                                         ▼
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│  ums_stats_*    │◀────│   @Scheduled    │◀────│    ums_log      │
│  (통계 테이블)   │     │   (집계 배치)    │     │   (발송 로그)    │
└─────────────────┘     └─────────────────┘     └─────────────────┘
```

---

## 2. 테이블 구조

### 2.1 ums_msg (발송 대기)

SNAP Agent가 폴링하는 발송 큐 테이블입니다.

```sql
-- 주요 컬럼만 표시
CREATE TABLE ums_msg (
    CLIENT_KEY VARCHAR(40) PRIMARY KEY,       -- 메시지 고유 ID
    REQ_CH VARCHAR(10) NOT NULL,              -- 발송 채널 (SMS, LMS, MMS, ...)
    TRAFFIC_TYPE VARCHAR(10) DEFAULT 'normal', -- 메시지 유형
    MSG_STATUS VARCHAR(10) DEFAULT 'ready',   -- 발송 상태
    REQ_DATE DATETIME NOT NULL,               -- 발송 요청 시간 (예약 발송)
    CALLBACK_NUMBER VARCHAR(16),              -- 발신번호
    PHONE VARCHAR(16),                        -- 수신번호
    MSG VARCHAR(2000),                        -- 메시지 내용
    TITLE VARCHAR(100),                       -- 제목
    
    -- LinkWave 활용 필드
    ETC1 VARCHAR(50),   -- 사용자 ID
    ETC2 VARCHAR(50),   -- 조직 ID
    ETC3 VARCHAR(50),   -- 발송 그룹 ID
    ETC4 VARCHAR(50),   -- 발송 타입 (IMMEDIATE/SCHEDULED/BULK)
    ETC5 VARCHAR(50),   -- 캠페인 ID
    ETC6 VARCHAR(50),   -- 예비
    
    -- Fallback 설정
    FB_CH VARCHAR(10),     -- Fallback 채널
    FB_MSG VARCHAR(4000),  -- Fallback 메시지
    
    -- 발송 결과 (SNAP이 업데이트)
    DONE_CH VARCHAR(10),        -- 발송 성공 채널
    DONE_CODE VARCHAR(10),      -- 결과 코드
    DONE_DATE DATETIME          -- 완료 시간
);
```

### 2.2 ums_log (발송 로그)

발송 완료 후 데이터가 이동되는 로그 테이블입니다.
- 구조: `ums_msg`와 동일
- 테이블명: `ums_log` 또는 `ums_log_{YYYYMM}` (월별 파티션)

---

## 3. 발송 구현

### 3.1 즉시 발송

```java
public void sendImmediate(SendRequest request) {
    UmsMsg msg = UmsMsg.builder()
        .clientKey(generateClientKey())           // LW_20251223_U001_00001
        .reqCh(request.getChannel())              // SMS, LMS, MMS, ...
        .trafficType("normal")
        .msgStatus("ready")
        .reqDate(LocalDateTime.now())             // ⭐ 현재 시간 = 즉시 발송
        .callbackNumber(request.getCallback())
        .phone(request.getPhone())
        .msg(request.getMessage())
        .etc1(request.getUserId())
        .etc2(request.getOrganizationId())
        .etc3(generateGroupId())
        .etc4("IMMEDIATE")
        .build();
    
    umsMsgRepository.save(msg);
}
```

### 3.2 예약 발송

```java
public void sendScheduled(SendRequest request) {
    UmsMsg msg = UmsMsg.builder()
        .clientKey(generateClientKey())
        .reqCh(request.getChannel())
        .trafficType("normal")
        .msgStatus("ready")
        .reqDate(request.getScheduledAt())        // ⭐ 미래 시간 = 예약 발송
        .callbackNumber(request.getCallback())
        .phone(request.getPhone())
        .msg(request.getMessage())
        .etc1(request.getUserId())
        .etc3(generateGroupId())
        .etc4("SCHEDULED")
        .build();
    
    umsMsgRepository.save(msg);
}
```

### 3.3 대량 발송

```java
@Transactional
public void sendBulk(BulkSendRequest request) {
    String groupId = generateGroupId();
    
    List<UmsMsg> messages = request.getPhones().stream()
        .map(phone -> UmsMsg.builder()
            .clientKey(generateClientKey())
            .reqCh(request.getChannel())
            .trafficType("batch")                  // ⭐ 대량 발송
            .msgStatus("ready")
            .reqDate(LocalDateTime.now())
            .callbackNumber(request.getCallback())
            .phone(phone)
            .msg(request.getMessage())
            .etc1(request.getUserId())
            .etc3(groupId)
            .etc4("BULK")
            .build())
        .toList();
    
    // 배치 INSERT (1000건씩)
    umsMsgRepository.batchInsert(messages);
}
```

### 3.4 예약 발송 취소

```java
@Transactional
public int cancelScheduled(String groupId, String userId) {
    // ready 상태인 것만 취소 가능
    return umsMsgRepository.deleteByEtc3AndMsgStatusAndEtc1(
        groupId, "ready", userId
    );
}
```

---

## 4. CLIENT_KEY 생성 규칙

```java
public String generateClientKey() {
    // 형식: LW_{날짜시간}_{사용자ID}_{랜덤}
    // 예시: LW_20251223143052_U001_A1B2C3
    return String.format("LW_%s_%s_%s",
        LocalDateTime.now().format(DateTimeFormatter.ofPattern("yyyyMMddHHmmss")),
        getCurrentUserId(),
        RandomStringUtils.randomAlphanumeric(6).toUpperCase()
    );
}
```

**규칙**:
- 최대 40자
- 고유성 보장
- 추적 가능한 정보 포함

---

## 5. 발송 결과 확인

### 5.1 DONE_CODE 결과 코드

| 코드 | 설명 |
|------|------|
| `0000` | 성공 |
| `1xxx` | 통신사 오류 |
| `2xxx` | 메시지허브 오류 |
| `3xxx` | 기타 오류 |

### 5.2 ums_log 조회

```java
// MyBatis Mapper
@Mapper
public interface UmsLogQueryMapper {
    
    // 사용자별 발송 이력 조회
    List<UmsLogDto> findByUserIdAndDateRange(
        @Param("userId") String userId,
        @Param("startDate") LocalDateTime startDate,
        @Param("endDate") LocalDateTime endDate
    );
    
    // 통계 집계
    List<DailyStatsDto> aggregateByDate(@Param("date") LocalDate date);
}
```

---

## 6. Fallback 설정

RCS/카카오 발송 실패 시 자동으로 SMS/LMS/MMS로 Fallback됩니다.

```java
UmsMsg msg = UmsMsg.builder()
    .reqCh("ALIMTALK")                    // 1차: 알림톡
    .msg("카카오 메시지 내용")
    .fbCh("SMS")                          // 2차: SMS Fallback
    .fbMsg("SMS 메시지 내용")
    // ...
    .build();
```

---

## 7. 설정 파일 위치

```
docs/snap/config/
├── application.yml        # SNAP 메인 설정
└── mapper/
    └── mysql/
        └── lgu/
            ├── ums.xml    # UMS 매퍼 (SMS+RCS+카카오+PUSH)
            ├── sms.xml    # SMS 전용 매퍼
            └── mms.xml    # MMS 전용 매퍼
```

---

## 8. 주의사항

### 8.1 발송 취소 제한

- `MSG_STATUS = 'ready'` 상태에서만 취소(DELETE) 가능
- `pre-send`, `request` 상태는 이미 SNAP이 처리 중
- 대량 발송 시 일부만 취소될 수 있음

### 8.2 ETC 필드 길이

- 각 ETC 필드는 최대 **50자**
- 초과 시 데이터 잘림 발생

### 8.3 REQ_DATE 정확도

- SNAP 폴링 주기에 따라 약간의 지연 발생 가능
- 정확한 시간 발송이 필요하면 여유 시간 고려

---

## 9. 참고 링크

- [SNAP Agent 분석 보고서](../SNAP-AGENT-ANALYSIS.md)
- [UMS 메시지 발송 가이드](../implementation-guides/06-UMS-MESSAGE-FLOW.md)
- [통계 및 분석 가이드](../implementation-guides/07-STATISTICS-ANALYTICS.md)

