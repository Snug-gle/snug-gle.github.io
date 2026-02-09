---
created: 2025-12-26
---
# 06. UMS 메시지 발송 시스템

## 📌 학습 목표

이 가이드를 통해 다음을 학습합니다:

1. **SNAP Agent 연동 아키텍처** 이해
2. **ums_msg 테이블** 직접 활용 방법
3. **즉시/예약/대량 발송** 구현
4. **예약 발송 취소** 처리
5. **통계 테이블** 설계 및 집계

---

## 🎯 비즈니스 요구사항

| 요구사항 | 설명 |
|----------|------|
| 발송 유형 | 즉시 발송, 예약 발송, 대량 발송 |
| 발송 채널 | SMS, LMS, MMS, 카카오톡, RCS, PUSH |
| 발송 취소 | 예약된 메시지만 취소 가능 |
| 재발송 | SNAP Agent에서 처리 (구현 불필요) |
| 발송량 | 일 10만건 이상 |
| 통계 | 별도 테이블로 대시보드 지원 |

---

## 🏗️ 시스템 아키텍처

### 최종 결정: ums_msg 직접 연동

```
┌─────────────────────────────────────────────────────────────────────────┐
│                           LinkWave Backend                              │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│  [MessageService]                                                       │
│       │                                                                 │
│       ├── 즉시 발송 ─────────► [ums_msg] ──► [SNAP] ──► [ums_log]       │
│       │   REQ_DATE = NOW()        ▲                         │          │
│       │                           │                         │          │
│       ├── 예약 발송 ─────────► [ums_msg]                     │          │
│       │   REQ_DATE = 미래시간      │                         │          │
│       │                           │                         │          │
│       ├── 예약 취소 ──────── DELETE (ready만)                │          │
│       │                                                     │          │
│       │                                                     ▼          │
│       │                                             [@Scheduled]       │
│       │                                                     │          │
│       │                                                     ▼          │
│       └── 통계 조회 ◄──────────────────────────── [ums_stats_daily]    │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘
```

### 왜 중간 테이블(ums_request)이 불필요한가?

| 기능 | ums_msg 직접 사용 | 해결 방법 |
|------|:----------------:|-----------|
| 즉시 발송 | ✅ | `REQ_DATE = NOW()` |
| 예약 발송 | ✅ | `REQ_DATE = 미래시간` → SNAP이 자동 처리 |
| 대량 발송 | ✅ | `TRAFFIC_TYPE = 'batch'` + 배치 INSERT |
| 발송 취소 | ✅ | `MSG_STATUS = 'ready'`인 것만 DELETE |
| 사용자 추적 | ✅ | `ETC1~ETC4` 필드 활용 |

---

## 📊 테이블 설계

### 1. ums_msg (기존 SNAP 테이블 활용)

**ETC 필드 활용 규칙**:

| 필드 | 용도 | 예시 |
|------|------|------|
| `ETC1` | 사용자 ID | `user_hong` |
| `ETC2` | 조직 ID | `org_iotree` |
| `ETC3` | 발송 그룹 ID | `GRP_20251223_001` |
| `ETC4` | 발송 타입 | `IMMEDIATE`, `SCHEDULED`, `BULK` |
| `ETC5` | 캠페인 ID | `CAMP_XMAS` |
| `ETC6` | 중복 체크 해시 | `DEDUP_HASH` (MD5) |

**중복 방지 필드** (프로토타입용):

| 필드 | 타입 | 용도 |
|------|------|------|
| `DEDUP_HASH` | VARCHAR(32) | MD5(phone\|message) - 중복 체크용 |

```sql
-- 중복 체크 인덱스 추가
CREATE INDEX idx_dedup_hash_date ON ums_msg(DEDUP_HASH, REQ_DATE);
```

**중복 방지 전략**:
- **프로토타입 (서버 1대)**: MySQL SELECT 기반
- **프로덕션 (서버 N대)**: Redis TTL 기반 (나중에 전환)

### 2. ums_stats_daily (신규 생성)

```sql
CREATE TABLE ums_stats_daily (
    stat_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    stat_date DATE NOT NULL COMMENT '통계 날짜',
    user_id VARCHAR(50) NOT NULL COMMENT '사용자 ID (ETC1)',
    organization_id VARCHAR(50) COMMENT '조직 ID (ETC2)',
    req_ch VARCHAR(10) NOT NULL COMMENT '발송 채널',
    traffic_type VARCHAR(10) NOT NULL DEFAULT 'normal',
    
    -- 발송 현황
    total_count INT NOT NULL DEFAULT 0,
    pending_count INT NOT NULL DEFAULT 0,
    
    -- 결과 통계
    success_count INT NOT NULL DEFAULT 0,
    fail_count INT NOT NULL DEFAULT 0,
    
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    UNIQUE KEY uk_daily_stats (stat_date, user_id, req_ch, traffic_type),
    INDEX idx_user_date (user_id, stat_date),
    INDEX idx_org_date (organization_id, stat_date)
) COMMENT '일별 발송 통계';
```

---

## 💻 구현 가이드

### 1. Entity 클래스

#### UmsMsg.java

```java
package io.iotree.linkwave.domain.message;

import jakarta.persistence.*;
import lombok.*;
import java.time.LocalDateTime;

@Entity
@Table(name = "ums_msg")
@Getter
@NoArgsConstructor(access = AccessLevel.PROTECTED)
@AllArgsConstructor
@Builder
public class UmsMsg {

    @Id
    @Column(name = "CLIENT_KEY", length = 40)
    private String clientKey;

    @Column(name = "REQ_CH", length = 10, nullable = false)
    private String reqCh;

    @Builder.Default
    @Column(name = "TRAFFIC_TYPE", length = 10, nullable = false)
    private String trafficType = "normal";

    @Builder.Default
    @Column(name = "MSG_STATUS", length = 10, nullable = false)
    private String msgStatus = "ready";

    @Column(name = "REQ_DATE", nullable = false)
    private LocalDateTime reqDate;

    @Column(name = "CALLBACK_NUMBER", length = 16)
    private String callbackNumber;

    @Column(name = "PHONE", length = 16)
    private String phone;

    @Column(name = "MSG", length = 2000)
    private String msg;

    @Column(name = "TITLE", length = 100)
    private String title;

    // Fallback 설정
    @Column(name = "FB_CH", length = 10)
    private String fbCh;

    @Column(name = "FB_MSG", length = 4000)
    private String fbMsg;

    // LinkWave 활용 필드
    @Column(name = "ETC1", length = 50)
    private String etc1;  // 사용자 ID

    @Column(name = "ETC2", length = 50)
    private String etc2;  // 조직 ID

    @Column(name = "ETC3", length = 50)
    private String etc3;  // 발송 그룹 ID

    @Column(name = "ETC4", length = 50)
    private String etc4;  // 발송 타입

    @Column(name = "ETC5", length = 50)
    private String etc5;  // 캠페인 ID

    // ⭐ 중복 방지 필드 (프로토타입용)
    @Column(name = "DEDUP_HASH", length = 32)
    private String dedupHash;  // MD5(phone|message)

    // 결과 필드 (SNAP이 업데이트)
    @Column(name = "DONE_CH", length = 10)
    private String doneCh;

    @Column(name = "DONE_CODE", length = 10)
    private String doneCode;

    @Column(name = "DONE_DATE")
    private LocalDateTime doneDate;
}
```

#### UmsStatsDaily.java

```java
package io.iotree.linkwave.domain.statistics;

import jakarta.persistence.*;
import lombok.*;
import java.time.LocalDate;
import java.time.LocalDateTime;

@Entity
@Table(name = "ums_stats_daily")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class UmsStatsDaily {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "stat_id")
    private Long statId;

    @Column(name = "stat_date", nullable = false)
    private LocalDate statDate;

    @Column(name = "user_id", length = 50, nullable = false)
    private String userId;

    @Column(name = "organization_id", length = 50)
    private String organizationId;

    @Column(name = "req_ch", length = 10, nullable = false)
    private String reqCh;

    @Builder.Default
    @Column(name = "traffic_type", length = 10, nullable = false)
    private String trafficType = "normal";

    @Builder.Default
    @Column(name = "total_count", nullable = false)
    private Integer totalCount = 0;

    @Builder.Default
    @Column(name = "pending_count", nullable = false)
    private Integer pendingCount = 0;

    @Builder.Default
    @Column(name = "success_count", nullable = false)
    private Integer successCount = 0;

    @Builder.Default
    @Column(name = "fail_count", nullable = false)
    private Integer failCount = 0;

    @Column(name = "created_at")
    private LocalDateTime createdAt;

    @Column(name = "updated_at")
    private LocalDateTime updatedAt;

    // 통계 업데이트 메서드
    public void incrementTotal(int count) {
        this.totalCount += count;
        this.pendingCount += count;
    }

    public void decrementPending(int count) {
        this.pendingCount = Math.max(0, this.pendingCount - count);
    }

    public void updateResults(int success, int fail) {
        this.successCount += success;
        this.failCount += fail;
        this.pendingCount = Math.max(0, this.pendingCount - success - fail);
    }
}
```

---

### 2. Service 구현

#### MessageService.java

```java
package io.iotree.linkwave.application.service;

import io.iotree.linkwave.application.dto.request.*;
import io.iotree.linkwave.application.dto.response.*;
import io.iotree.linkwave.common.exception.BusinessException;
import io.iotree.linkwave.common.exception.ErrorCode;
import io.iotree.linkwave.domain.message.UmsMsg;
import io.iotree.linkwave.infra.mybatis.mapper.UmsMsgMapper;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.apache.commons.codec.digest.DigestUtils;
import org.apache.commons.lang3.RandomStringUtils;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

@Slf4j
@Service
@RequiredArgsConstructor
public class MessageService {

    private final UmsMsgMapper umsMsgMapper;
    private final StatisticsService statisticsService;

    /**
     * 메시지 발송 (즉시/예약)
     *
     * ⚠️ 트랜잭션 주의사항:
     * - JpaTransactionManager가 @Primary여야 함
     * - MyBatis(ums_msg) + JPA(statistics) 함께 롤백 보장
     */
    @Transactional  // JpaTransactionManager가 관리
    public SendResponse sendMessage(SendRequest request, String userId, String organizationId) {
        String groupId = generateGroupId();
        LocalDateTime reqDate = request.isScheduled()
            ? request.getScheduledAt()
            : LocalDateTime.now();

        log.info("메시지 발송 요청: userId={}, channel={}, type={}, count={}",
            userId, request.getChannel(), request.getSendType(), request.getPhones().size());

        List<UmsMsg> messages = new ArrayList<>();
        int duplicateCount = 0;

        for (String phone : request.getPhones()) {

            // ⭐ 중복 체크 (프로토타입용 - MySQL)
            String dedupHash = generateDedupHash(phone, request.getMessage());

            if (request.isCheckDuplicate()) {
                boolean isDuplicate = umsMsgMapper.existsByDedupHashWithinMinutes(
                    dedupHash,
                    request.getDedupWindowMinutes()  // 기본 10분
                );

                if (isDuplicate) {
                    log.warn("중복 발송 차단: phone={}, hash={}", phone, dedupHash);
                    duplicateCount++;
                    continue;  // 건너뛰기
                }
            }

            UmsMsg msg = UmsMsg.builder()
                .clientKey(generateClientKey(userId))
                .reqCh(request.getChannel())
                .trafficType(request.isBulk() ? "batch" : "normal")
                .msgStatus("ready")
                .reqDate(reqDate)
                .callbackNumber(request.getCallback())
                .phone(phone)
                .msg(request.getMessage())
                .title(request.getTitle())
                .dedupHash(dedupHash)  // ⭐ 중복 해시 저장
                .fbCh(request.getFallbackChannel())
                .fbMsg(request.getFallbackMessage())
                .etc1(userId)
                .etc2(organizationId)
                .etc3(groupId)
                .etc4(request.getSendType())
                .etc5(request.getCampaignId())
                .build();

            messages.add(msg);
        }

        // 배치 INSERT
        if (!messages.isEmpty()) {
            umsMsgMapper.batchInsert(messages);

            // 통계 테이블 업데이트 (같은 트랜잭션)
            statisticsService.incrementPending(
                reqDate.toLocalDate(),
                userId,
                organizationId,
                request.getChannel(),
                messages.size()
            );
        }

        log.info("메시지 발송 요청 완료: groupId={}, sent={}, duplicate={}",
            groupId, messages.size(), duplicateCount);

        return SendResponse.builder()
            .groupId(groupId)
            .totalCount(request.getPhones().size())
            .successCount(messages.size())
            .duplicateCount(duplicateCount)
            .scheduledAt(request.isScheduled() ? reqDate : null)
            .status(request.isScheduled() ? "SCHEDULED" : "QUEUED")
            .build();
    }

    /**
     * 예약 발송 취소
     */
    @Transactional
    public CancelResponse cancelScheduledMessages(String groupId, String userId) {
        log.info("예약 발송 취소 요청: groupId={}, userId={}", groupId, userId);

        // 1. ready 상태인 메시지 조회
        List<UmsMsg> pendingMessages = umsMsgMapper.findByGroupIdAndStatus(groupId, "ready");

        if (pendingMessages.isEmpty()) {
            throw new BusinessException(ErrorCode.NO_CANCELLABLE_MESSAGES,
                "취소 가능한 메시지가 없습니다. (이미 발송되었거나 발송 중)");
        }

        // 2. 권한 확인
        UmsMsg firstMsg = pendingMessages.get(0);
        if (!firstMsg.getEtc1().equals(userId)) {
            throw new BusinessException(ErrorCode.FORBIDDEN, "다른 사용자의 발송을 취소할 수 없습니다.");
        }

        // 3. DELETE
        int deletedCount = umsMsgMapper.deleteByGroupIdAndStatus(groupId, "ready");

        // 4. 통계 테이블 업데이트
        statisticsService.decrementPending(
            firstMsg.getReqDate().toLocalDate(),
            userId,
            firstMsg.getReqCh(),
            deletedCount
        );

        log.info("예약 발송 취소 완료: groupId={}, deletedCount={}", groupId, deletedCount);

        return CancelResponse.builder()
            .groupId(groupId)
            .cancelledCount(deletedCount)
            .message(deletedCount + "건의 예약 발송이 취소되었습니다.")
            .build();
    }

    /**
     * CLIENT_KEY 생성
     * 형식: LW_{날짜시간}_{사용자ID}_{랜덤6자}
     */
    private String generateClientKey(String userId) {
        String timestamp = LocalDateTime.now()
            .format(DateTimeFormatter.ofPattern("yyyyMMddHHmmss"));
        String random = RandomStringUtils.randomAlphanumeric(6).toUpperCase();
        String userPart = userId.length() > 10 ? userId.substring(0, 10) : userId;
        return String.format("LW_%s_%s_%s", timestamp, userPart, random);
    }

    /**
     * 발송 그룹 ID 생성
     */
    private String generateGroupId() {
        String date = LocalDateTime.now()
            .format(DateTimeFormatter.ofPattern("yyyyMMdd"));
        return "GRP_" + date + "_" + UUID.randomUUID().toString().substring(0, 8).toUpperCase();
    }

    /**
     * ⭐ 중복 해시 생성 (프로토타입용)
     *
     * 형식: MD5(phone|message)
     *
     * 프로덕션 전환 시:
     * - Redis로 전환 (TTL 자동 만료)
     * - 이 메서드는 그대로 사용 가능
     */
    private String generateDedupHash(String phone, String message) {
        String raw = phone + "|" + message;
        return DigestUtils.md5Hex(raw);  // Apache Commons Codec 필요
    }
}
```

---

### 3. MyBatis Mapper

#### UmsMsgMapper.java

```java
package io.iotree.linkwave.infra.mybatis.mapper;

import io.iotree.linkwave.domain.message.UmsMsg;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;
import java.util.List;

@Mapper
public interface UmsMsgMapper {

    // ⭐ 중복 체크 (프로토타입용 - MySQL)
    boolean existsByDedupHashWithinMinutes(
        @Param("dedupHash") String dedupHash,
        @Param("minutes") int minutes
    );

    // 배치 INSERT
    void batchInsert(@Param("list") List<UmsMsg> messages);

    // 그룹 ID로 조회
    List<UmsMsg> findByGroupIdAndStatus(
        @Param("groupId") String groupId,
        @Param("status") String status
    );

    // 예약 취소 (DELETE)
    int deleteByGroupIdAndStatus(
        @Param("groupId") String groupId,
        @Param("status") String status
    );
}
```

#### UmsMsgMapper.xml

```xml
<?xml version="1.0" encoding="UTF-8" ?>
<!DOCTYPE mapper PUBLIC "-//mybatis.org//DTD Mapper 3.0//EN"
    "http://mybatis.org/dtd/mybatis-3-mapper.dtd">
<mapper namespace="io.iotree.linkwave.infra.mybatis.mapper.UmsMsgMapper">

    <!-- ⭐ 중복 체크 (프로토타입용 - MySQL) -->
    <select id="existsByDedupHashWithinMinutes" resultType="boolean">
        SELECT COUNT(*) > 0
        FROM ums_msg
        WHERE DEDUP_HASH = #{dedupHash}
          AND REQ_DATE >= DATE_SUB(NOW(), INTERVAL #{minutes} MINUTE)
        LIMIT 1
    </select>

    <!-- 배치 INSERT -->
    <insert id="batchInsert" parameterType="list">
        INSERT INTO ums_msg (
            CLIENT_KEY, REQ_CH, TRAFFIC_TYPE, MSG_STATUS, REQ_DATE,
            CALLBACK_NUMBER, PHONE, MSG, TITLE,
            FB_CH, FB_MSG,
            ETC1, ETC2, ETC3, ETC4, ETC5,
            DEDUP_HASH
        ) VALUES
        <foreach collection="list" item="msg" separator=",">
            (
                #{msg.clientKey},
                #{msg.reqCh},
                #{msg.trafficType},
                #{msg.msgStatus},
                #{msg.reqDate},
                #{msg.callbackNumber},
                #{msg.phone},
                #{msg.msg},
                #{msg.title},
                #{msg.fbCh},
                #{msg.fbMsg},
                #{msg.etc1},
                #{msg.etc2},
                #{msg.etc3},
                #{msg.etc4},
                #{msg.etc5},
                #{msg.dedupHash}
            )
        </foreach>
    </insert>

    <!-- 그룹 ID로 조회 -->
    <select id="findByGroupIdAndStatus" resultType="io.iotree.linkwave.domain.message.UmsMsg">
        SELECT
            CLIENT_KEY AS clientKey,
            REQ_CH AS reqCh,
            TRAFFIC_TYPE AS trafficType,
            MSG_STATUS AS msgStatus,
            REQ_DATE AS reqDate,
            PHONE,
            ETC1 AS etc1,
            ETC2 AS etc2,
            ETC3 AS etc3
        FROM ums_msg
        WHERE ETC3 = #{groupId}
          AND MSG_STATUS = #{status}
    </select>

    <!-- 예약 취소 (DELETE) -->
    <delete id="deleteByGroupIdAndStatus">
        DELETE FROM ums_msg
        WHERE ETC3 = #{groupId}
          AND MSG_STATUS = #{status}
    </delete>

</mapper>
```

---

### 4. 통계 집계 배치

#### StatsAggregationService.java

```java
package io.iotree.linkwave.application.service;

import io.iotree.linkwave.infra.mybatis.mapper.UmsLogQueryMapper;
import io.iotree.linkwave.infra.jpa.repository.UmsStatsDailyRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.time.temporal.ChronoUnit;

@Slf4j
@Service
@RequiredArgsConstructor
public class StatsAggregationService {

    private final UmsLogQueryMapper umsLogQueryMapper;
    private final UmsStatsDailyRepository statsDailyRepository;

    /**
     * 매 시간 5분에 이전 시간 결과 집계
     */
    @Scheduled(cron = "0 5 * * * *")
    @Transactional
    public void aggregateHourlyResults() {
        LocalDateTime targetHour = LocalDateTime.now()
            .minusHours(1)
            .truncatedTo(ChronoUnit.HOURS);

        log.info("시간별 결과 집계 시작: {}", targetHour);

        // ums_log에서 시간별 결과 집계
        var results = umsLogQueryMapper.aggregateByHour(
            targetHour,
            targetHour.plusHours(1)
        );

        for (var result : results) {
            // 일별 통계에 반영
            statsDailyRepository.updateResults(
                targetHour.toLocalDate(),
                result.getUserId(),
                result.getReqCh(),
                result.getSuccessCount(),
                result.getFailCount()
            );
        }

        log.info("시간별 결과 집계 완료: {}건 처리", results.size());
    }
}
```

---

### 5. DTO 클래스

#### SendRequest.java

```java
package io.iotree.linkwave.application.dto.request;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.Size;
import lombok.*;
import java.time.LocalDateTime;
import java.util.List;

@Getter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class SendRequest {

    @NotBlank(message = "채널은 필수입니다")
    private String channel;  // SMS, LMS, MMS, ALIMTALK, ...

    @NotBlank(message = "발송 타입은 필수입니다")
    private String sendType;  // IMMEDIATE, SCHEDULED, BULK

    private LocalDateTime scheduledAt;  // 예약 발송 시간

    @NotEmpty(message = "수신번호는 필수입니다")
    @Size(max = 10000, message = "한 번에 최대 10,000건까지 발송 가능합니다")
    private List<String> phones;

    @NotBlank(message = "메시지 내용은 필수입니다")
    @Size(max = 2000, message = "메시지는 2000자 이내여야 합니다")
    private String message;

    private String title;  // LMS, MMS, RCS 제목

    @NotBlank(message = "발신번호는 필수입니다")
    private String callback;

    private String fallbackChannel;  // Fallback 채널
    private String fallbackMessage;  // Fallback 메시지

    private String campaignId;  // 캠페인 ID (선택)

    // ⭐ 중복 체크 옵션 (프로토타입용)
    @Builder.Default
    private boolean checkDuplicate = true;  // 기본: 중복 체크 ON

    @Builder.Default
    private int dedupWindowMinutes = 10;    // 기본: 10분 윈도우

    // 편의 메서드
    public boolean isScheduled() {
        return "SCHEDULED".equals(sendType) && scheduledAt != null;
    }

    public boolean isBulk() {
        return "BULK".equals(sendType) || phones.size() > 100;
    }
}
```

#### SendResponse.java

```java
package io.iotree.linkwave.application.dto.response;

import lombok.*;
import java.time.LocalDateTime;

@Getter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class SendResponse {

    private String groupId;            // 발송 그룹 ID
    private int totalCount;            // 요청 건수
    private int successCount;          // 실제 발송 건수
    private int duplicateCount;        // 중복 차단 건수
    private LocalDateTime scheduledAt; // 예약 시간 (예약 발송 시)
    private String status;             // QUEUED, SCHEDULED
    private String message;            // 응답 메시지

    public static SendResponse immediate(String groupId, int total, int success, int duplicate) {
        return SendResponse.builder()
            .groupId(groupId)
            .totalCount(total)
            .successCount(success)
            .duplicateCount(duplicate)
            .status("QUEUED")
            .message(String.format("%d건 요청, %d건 발송, %d건 중복 차단",
                total, success, duplicate))
            .build();
    }

    public static SendResponse scheduled(String groupId, int total, int success,
                                         int duplicate, LocalDateTime scheduledAt) {
        return SendResponse.builder()
            .groupId(groupId)
            .totalCount(total)
            .successCount(success)
            .duplicateCount(duplicate)
            .scheduledAt(scheduledAt)
            .status("SCHEDULED")
            .message(String.format("%d건 예약 (%s), %d건 중복 차단",
                success, scheduledAt, duplicate))
            .build();
    }
}
```

#### CancelResponse.java

```java
package io.iotree.linkwave.application.dto.response;

import lombok.*;

@Getter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class CancelResponse {

    private String groupId;
    private int cancelledCount;
    private String message;

    public static CancelResponse of(String groupId, int count) {
        return CancelResponse.builder()
            .groupId(groupId)
            .cancelledCount(count)
            .message(count + "건의 예약 발송이 취소되었습니다.")
            .build();
    }
}
```

### 6. Controller

#### MessageController.java

```java
package io.iotree.linkwave.api;

import io.iotree.linkwave.application.dto.request.SendRequest;
import io.iotree.linkwave.application.dto.response.CancelResponse;
import io.iotree.linkwave.application.dto.response.SendResponse;
import io.iotree.linkwave.application.service.MessageService;
import io.iotree.linkwave.common.response.ApiResponse;
import io.iotree.linkwave.common.security.CurrentUser;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.*;

@Slf4j
@RestController
@RequestMapping("/api/v1/messages")
@RequiredArgsConstructor
public class MessageController {

    private final MessageService messageService;

    /**
     * 메시지 발송 (즉시/예약/대량)
     */
    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    public ApiResponse<SendResponse> sendMessage(
        @Valid @RequestBody SendRequest request,
        @CurrentUser String userId,
        @CurrentUser(field = "organizationId") String organizationId
    ) {
        log.info("📨 메시지 발송 요청: userId={}, channel={}, type={}, count={}",
            userId, request.getChannel(), request.getSendType(), request.getPhones().size());

        SendResponse response = messageService.sendMessage(request, userId, organizationId);

        log.info("✅ 메시지 발송 요청 완료: groupId={}", response.getGroupId());
        return ApiResponse.success(response);
    }

    /**
     * 예약 발송 취소
     */
    @DeleteMapping("/scheduled/{groupId}")
    public ApiResponse<CancelResponse> cancelScheduledMessages(
        @PathVariable String groupId,
        @CurrentUser String userId
    ) {
        log.info("🚫 예약 발송 취소 요청: groupId={}, userId={}", groupId, userId);

        CancelResponse response = messageService.cancelScheduledMessages(groupId, userId);

        log.info("✅ 예약 발송 취소 완료: cancelledCount={}", response.getCancelledCount());
        return ApiResponse.success(response);
    }

    /**
     * 발송 그룹 상태 조회
     */
    @GetMapping("/group/{groupId}")
    public ApiResponse<Object> getGroupStatus(
        @PathVariable String groupId,
        @CurrentUser String userId
    ) {
        // TODO: 발송 그룹 상태 조회 구현
        return ApiResponse.success(null);
    }
}
```

#### @CurrentUser 어노테이션 (참고)

```java
package io.iotree.linkwave.common.security;

import java.lang.annotation.*;

@Target(ElementType.PARAMETER)
@Retention(RetentionPolicy.RUNTIME)
@Documented
public @interface CurrentUser {
    String field() default "userId";
}
```

---

## 🧪 테스트 시나리오

### 1. 즉시 발송 테스트

```bash
curl -X POST http://localhost:8090/api/v1/messages \
  -H "Authorization: Bearer {token}" \
  -H "Content-Type: application/json" \
  -d '{
    "channel": "SMS",
    "sendType": "IMMEDIATE",
    "phones": ["01011111111", "01022222222"],
    "message": "테스트 메시지입니다.",
    "callback": "0212345678"
  }'
```

### 2. 예약 발송 테스트

```bash
curl -X POST http://localhost:8090/api/v1/messages \
  -H "Authorization: Bearer {token}" \
  -H "Content-Type: application/json" \
  -d '{
    "channel": "SMS",
    "sendType": "SCHEDULED",
    "scheduledAt": "2025-12-25T10:00:00",
    "phones": ["01011111111"],
    "message": "메리 크리스마스!",
    "callback": "0212345678"
  }'
```

### 3. 예약 취소 테스트

```bash
curl -X DELETE http://localhost:8090/api/v1/messages/scheduled/GRP_20251223_A1B2C3D4 \
  -H "Authorization: Bearer {token}"
```

### 4. 중복 발송 테스트 (프로토타입용)

```bash
# 1차 발송
curl -X POST http://localhost:8090/api/v1/messages \
  -H "Authorization: Bearer {token}" \
  -H "Content-Type: application/json" \
  -d '{
    "channel": "SMS",
    "sendType": "IMMEDIATE",
    "phones": ["01011111111"],
    "message": "테스트 메시지",
    "callback": "0212345678",
    "checkDuplicate": true,
    "dedupWindowMinutes": 10
  }'

# 2차 발송 (10분 내 - 차단되어야 함)
curl -X POST http://localhost:8090/api/v1/messages \
  -H "Authorization: Bearer {token}" \
  -H "Content-Type: application/json" \
  -d '{
    "channel": "SMS",
    "sendType": "IMMEDIATE",
    "phones": ["01011111111"],
    "message": "테스트 메시지",
    "callback": "0212345678",
    "checkDuplicate": true
  }'

# 예상 응답:
# {
#   "groupId": "GRP_20251226_...",
#   "totalCount": 1,
#   "successCount": 0,
#   "duplicateCount": 1,
#   "message": "1건 요청, 0건 발송, 1건 중복 차단"
# }
```

---

## ✅ 구현 체크리스트

### 프로토타입 필수 (우선순위 높음)

#### 의존성
- [ ] build.gradle에 `commons-codec` 추가 (MD5 해시)
```gradle
implementation 'commons-codec:commons-codec:1.16.0'
```

#### 데이터베이스
- [ ] ums_msg 테이블에 `DEDUP_HASH` 컬럼 추가
- [ ] `idx_dedup_hash_date` 인덱스 생성
- [ ] `ums_stats_daily` 테이블 생성

#### 트랜잭션 설정 확인
- [ ] JpaTransactionManager가 @Primary인지 확인
```java
@Configuration
public class DataSourceConfig {
    @Bean
    @Primary  // ⭐ 필수!
    public JpaTransactionManager transactionManager(...) {
        return new JpaTransactionManager(...);
    }
}
```

### 기본 기능

### 테이블
- [ ] `ums_stats_daily` 테이블 생성
- [ ] `ums_stats_hourly` 테이블 생성 (선택)

### Entity
- [ ] `UmsMsg.java` 작성
- [ ] `UmsStatsDaily.java` 작성

### Repository/Mapper
- [ ] `UmsMsgMapper.java` + XML 작성
- [ ] `UmsStatsDailyRepository.java` 작성
- [ ] `UmsLogQueryMapper.java` + XML 작성

### Service
- [ ] `MessageService.java` 작성
- [ ] `StatisticsService.java` 작성
- [ ] `StatsAggregationService.java` 작성

### Controller
- [ ] `MessageController.java` 작성
- [ ] `StatisticsController.java` 작성

### 테스트
- [ ] 즉시 발송 테스트
- [ ] 예약 발송 테스트
- [ ] 예약 취소 테스트
- [ ] 대량 발송 테스트 (10만건)

---

## 💡 핵심 인사이트

### SNAP Agent 활용 포인트

1. **REQ_DATE로 예약 발송**: 별도 스케줄러 없이 SNAP이 자동 처리
2. **ETC 필드 활용**: 사용자/조직/그룹 ID 저장으로 추적 가능
3. **ready 상태에서만 취소**: 이미 처리 중인 메시지는 취소 불가

### ⭐ 프로토타입 단계 주의사항

#### 1. 중복 방지 전략
```
✅ 현재 (프로토타입):
- MySQL DEDUP_HASH + SELECT
- 서버 1대: 충분히 빠름 (0.01초)
- 추가 인프라 불필요

⏸️ 나중에 (프로덕션):
- Redis TTL 기반
- 서버 N대: 필수 (분산 환경)
- 자동 만료, 초고속
```

#### 2. 트랜잭션 관리 필수
```java
⚠️ JpaTransactionManager가 @Primary여야 함!

이유:
- MyBatis(ums_msg) + JPA(statistics) 함께 사용
- 둘 다 롤백 보장 필요
- JPA Dirty Checking 지원 필요
```

#### 3. 서버 확장 시 대비
```
서버 1대 → N대 전환 시:
1. Redis 설치
2. 중복 체크만 Redis로 변경
3. 나머지 코드 변경 없음
```

### 성능 고려사항

1. **배치 INSERT**: 1000건 단위로 분할
2. **통계 집계**: 실시간 아닌 배치 처리 (시간별)
3. **중복 체크 인덱스**: `idx_dedup_hash_date` 필수
4. **서버 1대**: @Scheduled 중복 문제 없음 (락 불필요)

### 자주 하는 실수

1. **CLIENT_KEY 중복**: 고유성 보장 로직 필수
2. **ETC 필드 길이 초과**: 최대 50자
3. **예약 시간 정확도**: SNAP 폴링 주기 고려
4. **트랜잭션 매니저 미설정**: JpaTransactionManager @Primary 누락
5. **중복 체크 인덱스 누락**: 성능 저하

---

## 📚 관련 문서

### 프로토타입 단계
- [SNAP Agent 분석 보고서](../SNAP-AGENT-ANALYSIS.md)
- [SNAP 연동 가이드](../snap/README.md)
- [통계 및 분석 가이드](./07-STATISTICS-ANALYTICS.md)
- [Daily Log: 트랜잭션 & Redis](../daily-log/2025-12-26-transaction-manager-distributed-lock-redis.md)

### 프로덕션 전환 시
- Redis 도입 가이드 (daily-log 참고)
- 분산 락 구현 (ShedLock)
- 성능 최적화 전략

