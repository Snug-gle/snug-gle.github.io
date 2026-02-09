---
created: 2025-12-26
---
# 07. 통계 및 분석 시스템

## 📌 학습 목표

이 가이드를 통해 다음을 학습합니다:

1. **OLTP/OLAP 분리** 아키텍처 이해
2. **ums_stats_daily** 테이블 설계
3. **배치 집계** 구현 (`@Scheduled`)
4. **대시보드 API** 구현

---

## 🎯 비즈니스 요구사항

| 요구사항 | 설명 |
|----------|------|
| 일별 통계 | 채널별, 사용자별 발송 현황 |
| 실시간 현황 | 발송 대기 건수 (pending_count) |
| 결과 통계 | 성공/실패 건수 (배치 집계) |
| 대시보드 | 빠른 조회 (10만건/일 대응) |

---

## 🏗️ 아키텍처: OLTP/OLAP 분리

### 왜 분리하는가?

**❌ 잘못된 방식**: `ums_log` 직접 조회

```sql
-- 매번 수백만 건 스캔 → 느림, 부하
SELECT COUNT(*) FROM ums_log 
WHERE ETC1 = 'user_hong' AND DONE_DATE >= '2025-12-01';
```

**✅ 올바른 방식**: 통계 테이블 조회

```sql
-- 미리 집계된 데이터 → 빠름, 부하 없음
SELECT * FROM ums_stats_daily 
WHERE user_id = 'user_hong' AND stat_date >= '2025-12-01';
```

### 데이터 흐름

```
┌───────────────────────────────────────────────────────────────────┐
│                        통계 집계 흐름                              │
├───────────────────────────────────────────────────────────────────┤
│                                                                   │
│  [MessageService]                                                 │
│       │                                                           │
│       ├── 발송 요청 ──────► ums_msg INSERT                        │
│       │                          │                                │
│       │                          ├─► ums_stats_daily              │
│       │                          │   (total_count++,              │
│       │                          │    pending_count++)            │
│       │                                                           │
│       ├── 예약 취소 ──────► ums_msg DELETE                        │
│       │                          │                                │
│       │                          └─► ums_stats_daily              │
│       │                              (pending_count--)            │
│                                                                   │
│  [StatsAggregationService] @Scheduled(매시 5분)                   │
│       │                                                           │
│       └── 결과 집계 ──────► ums_log 조회                          │
│                                  │                                │
│                                  └─► ums_stats_daily              │
│                                      (success_count++,            │
│                                       fail_count++,               │
│                                       pending_count--)            │
│                                                                   │
│  [StatisticsController]                                           │
│       │                                                           │
│       └── 대시보드 조회 ◄──── ums_stats_daily                     │
│                                                                   │
└───────────────────────────────────────────────────────────────────┘
```

---

## 📊 테이블 설계

### ums_stats_daily

```sql
CREATE TABLE ums_stats_daily (
    stat_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    stat_date DATE NOT NULL COMMENT '통계 날짜',
    user_id VARCHAR(50) NOT NULL COMMENT '사용자 ID (ETC1)',
    organization_id VARCHAR(50) COMMENT '조직 ID (ETC2)',
    req_ch VARCHAR(10) NOT NULL COMMENT '발송 채널',
    traffic_type VARCHAR(10) NOT NULL DEFAULT 'normal',
    
    -- 발송 현황 (실시간 업데이트)
    total_count INT NOT NULL DEFAULT 0 COMMENT '총 발송 요청 건수',
    pending_count INT NOT NULL DEFAULT 0 COMMENT '발송 대기 건수',
    
    -- 결과 통계 (배치 집계)
    success_count INT NOT NULL DEFAULT 0 COMMENT '발송 성공 건수',
    fail_count INT NOT NULL DEFAULT 0 COMMENT '발송 실패 건수',
    
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    UNIQUE KEY uk_daily_stats (stat_date, user_id, req_ch, traffic_type),
    INDEX idx_user_date (user_id, stat_date),
    INDEX idx_org_date (organization_id, stat_date)
) COMMENT '일별 발송 통계';
```

### ums_stats_hourly (선택)

```sql
CREATE TABLE ums_stats_hourly (
    stat_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    stat_datetime DATETIME NOT NULL COMMENT '통계 시간 (시 단위)',
    user_id VARCHAR(50) NOT NULL,
    req_ch VARCHAR(10) NOT NULL,
    
    total_count INT NOT NULL DEFAULT 0,
    success_count INT NOT NULL DEFAULT 0,
    fail_count INT NOT NULL DEFAULT 0,
    
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    
    UNIQUE KEY uk_hourly_stats (stat_datetime, user_id, req_ch),
    INDEX idx_user_datetime (user_id, stat_datetime)
) COMMENT '시간별 발송 통계 (대시보드용, 7일 보관)';
```

---

## 💻 구현 가이드

### 1. Entity

```java
package io.iotree.linkwave.domain.statistics;

import jakarta.persistence.*;
import lombok.*;
import java.time.LocalDate;
import java.time.LocalDateTime;

@Entity
@Table(name = "ums_stats_daily")
@Getter
@NoArgsConstructor(access = AccessLevel.PROTECTED)
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

    // 비즈니스 메서드
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

### 2. Repository (JPA)

```java
package io.iotree.linkwave.infra.jpa.repository;

import io.iotree.linkwave.domain.statistics.UmsStatsDaily;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import java.time.LocalDate;
import java.util.List;
import java.util.Optional;

public interface UmsStatsDailyRepository extends JpaRepository<UmsStatsDaily, Long> {

    Optional<UmsStatsDaily> findByStatDateAndUserIdAndReqChAndTrafficType(
        LocalDate statDate, String userId, String reqCh, String trafficType
    );

    List<UmsStatsDaily> findByUserIdAndStatDateBetween(
        String userId, LocalDate startDate, LocalDate endDate
    );

    // 발송 요청 시 통계 업데이트
    @Modifying
    @Query("""
        UPDATE UmsStatsDaily s 
        SET s.totalCount = s.totalCount + :count, 
            s.pendingCount = s.pendingCount + :count 
        WHERE s.statDate = :statDate 
          AND s.userId = :userId 
          AND s.reqCh = :reqCh
    """)
    int incrementPending(
        @Param("statDate") LocalDate statDate,
        @Param("userId") String userId,
        @Param("reqCh") String reqCh,
        @Param("count") int count
    );

    // 배치 집계 결과 반영
    @Modifying
    @Query("""
        UPDATE UmsStatsDaily s 
        SET s.successCount = s.successCount + :success, 
            s.failCount = s.failCount + :fail,
            s.pendingCount = s.pendingCount - :success - :fail
        WHERE s.statDate = :statDate 
          AND s.userId = :userId 
          AND s.reqCh = :reqCh
    """)
    int updateResults(
        @Param("statDate") LocalDate statDate,
        @Param("userId") String userId,
        @Param("reqCh") String reqCh,
        @Param("success") int success,
        @Param("fail") int fail
    );
}
```

### 3. MyBatis Mapper (ums_log 집계용)

```java
package io.iotree.linkwave.infra.mybatis.mapper;

import io.iotree.linkwave.infra.mybatis.dto.HourlyResultDto;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;
import java.time.LocalDateTime;
import java.util.List;

@Mapper
public interface UmsLogQueryMapper {

    /**
     * 시간별 발송 결과 집계
     * DONE_CODE = '0000' → 성공, 그 외 → 실패
     */
    List<HourlyResultDto> aggregateByHour(
        @Param("startTime") LocalDateTime startTime,
        @Param("endTime") LocalDateTime endTime
    );
}
```

```xml
<?xml version="1.0" encoding="UTF-8" ?>
<!DOCTYPE mapper PUBLIC "-//mybatis.org//DTD Mapper 3.0//EN"
    "http://mybatis.org/dtd/mybatis-3-mapper.dtd">
<mapper namespace="io.iotree.linkwave.infra.mybatis.mapper.UmsLogQueryMapper">

    <select id="aggregateByHour" resultType="io.iotree.linkwave.infra.mybatis.dto.HourlyResultDto">
        SELECT 
            ETC1 AS userId,
            REQ_CH AS reqCh,
            DATE(DONE_DATE) AS statDate,
            SUM(CASE WHEN DONE_CODE = '0000' THEN 1 ELSE 0 END) AS successCount,
            SUM(CASE WHEN DONE_CODE != '0000' THEN 1 ELSE 0 END) AS failCount
        FROM ums_log
        WHERE DONE_DATE >= #{startTime}
          AND DONE_DATE &lt; #{endTime}
          AND ETC1 IS NOT NULL
        GROUP BY ETC1, REQ_CH, DATE(DONE_DATE)
    </select>

</mapper>
```

### 4. 배치 집계 Service

```java
package io.iotree.linkwave.application.service;

import io.iotree.linkwave.infra.jpa.repository.UmsStatsDailyRepository;
import io.iotree.linkwave.infra.mybatis.mapper.UmsLogQueryMapper;
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
        LocalDateTime now = LocalDateTime.now();
        LocalDateTime targetHour = now.minusHours(1).truncatedTo(ChronoUnit.HOURS);

        log.info("⏰ 시간별 결과 집계 시작: {}", targetHour);

        try {
            var results = umsLogQueryMapper.aggregateByHour(
                targetHour,
                targetHour.plusHours(1)
            );

            int updatedCount = 0;
            for (var result : results) {
                int updated = statsDailyRepository.updateResults(
                    result.getStatDate(),
                    result.getUserId(),
                    result.getReqCh(),
                    result.getSuccessCount(),
                    result.getFailCount()
                );
                updatedCount += updated;
            }

            log.info("✅ 시간별 결과 집계 완료: {}건 처리, {}건 업데이트", 
                results.size(), updatedCount);

        } catch (Exception e) {
            log.error("❌ 시간별 결과 집계 실패: {}", e.getMessage(), e);
            throw e;
        }
    }
}
```

### 5. 통계 Service

```java
package io.iotree.linkwave.application.service;

import io.iotree.linkwave.application.dto.response.DailyStatsResponse;
import io.iotree.linkwave.application.dto.response.DashboardResponse;
import io.iotree.linkwave.domain.statistics.UmsStatsDaily;
import io.iotree.linkwave.infra.jpa.repository.UmsStatsDailyRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.util.List;

@Service
@RequiredArgsConstructor
public class StatisticsService {

    private final UmsStatsDailyRepository statsDailyRepository;

    /**
     * 발송 요청 시 통계 업데이트
     */
    @Transactional
    public void incrementPending(
        LocalDate statDate,
        String userId,
        String organizationId,
        String reqCh,
        int count
    ) {
        // 기존 레코드가 있으면 업데이트, 없으면 생성
        var stats = statsDailyRepository
            .findByStatDateAndUserIdAndReqChAndTrafficType(
                statDate, userId, reqCh, "normal")
            .orElseGet(() -> statsDailyRepository.save(
                UmsStatsDaily.builder()
                    .statDate(statDate)
                    .userId(userId)
                    .organizationId(organizationId)
                    .reqCh(reqCh)
                    .trafficType("normal")
                    .build()
            ));

        stats.incrementTotal(count);
    }

    /**
     * 예약 취소 시 통계 업데이트
     */
    @Transactional
    public void decrementPending(
        LocalDate statDate,
        String userId,
        String reqCh,
        int count
    ) {
        statsDailyRepository
            .findByStatDateAndUserIdAndReqChAndTrafficType(
                statDate, userId, reqCh, "normal")
            .ifPresent(stats -> stats.decrementPending(count));
    }

    /**
     * 대시보드 조회
     */
    @Transactional(readOnly = true)
    public DashboardResponse getDashboard(String userId, LocalDate startDate, LocalDate endDate) {
        List<UmsStatsDaily> statsList = statsDailyRepository
            .findByUserIdAndStatDateBetween(userId, startDate, endDate);

        int totalCount = statsList.stream().mapToInt(UmsStatsDaily::getTotalCount).sum();
        int pendingCount = statsList.stream().mapToInt(UmsStatsDaily::getPendingCount).sum();
        int successCount = statsList.stream().mapToInt(UmsStatsDaily::getSuccessCount).sum();
        int failCount = statsList.stream().mapToInt(UmsStatsDaily::getFailCount).sum();

        List<DailyStatsResponse> dailyStats = statsList.stream()
            .map(DailyStatsResponse::from)
            .toList();

        return DashboardResponse.builder()
            .totalCount(totalCount)
            .pendingCount(pendingCount)
            .successCount(successCount)
            .failCount(failCount)
            .successRate(totalCount > 0 ? (successCount * 100.0 / totalCount) : 0)
            .dailyStats(dailyStats)
            .build();
    }
}
```

### 6. Controller

```java
package io.iotree.linkwave.api;

import io.iotree.linkwave.application.dto.response.DashboardResponse;
import io.iotree.linkwave.application.service.StatisticsService;
import io.iotree.linkwave.common.response.ApiResponse;
import lombok.RequiredArgsConstructor;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;

@RestController
@RequestMapping("/api/v1/statistics")
@RequiredArgsConstructor
public class StatisticsController {

    private final StatisticsService statisticsService;

    /**
     * 대시보드 조회
     */
    @GetMapping("/dashboard")
    public ApiResponse<DashboardResponse> getDashboard(
        @AuthenticationPrincipal String userId,
        @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate startDate,
        @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate endDate
    ) {
        return ApiResponse.success(
            statisticsService.getDashboard(userId, startDate, endDate)
        );
    }
}
```

---

## 🧪 테스트

### API 테스트

```bash
# 대시보드 조회
curl -X GET "http://localhost:8090/api/v1/statistics/dashboard?startDate=2025-12-01&endDate=2025-12-23" \
  -H "Authorization: Bearer {token}"
```

### 응답 예시

```json
{
  "success": true,
  "data": {
    "totalCount": 15000,
    "pendingCount": 500,
    "successCount": 14200,
    "failCount": 300,
    "successRate": 94.67,
    "dailyStats": [
      {
        "date": "2025-12-23",
        "channel": "SMS",
        "total": 5000,
        "pending": 100,
        "success": 4800,
        "fail": 100
      }
    ]
  }
}
```

---

## ✅ 구현 체크리스트

### 테이블
- [ ] `ums_stats_daily` 테이블 생성
- [ ] `ums_stats_hourly` 테이블 생성 (선택)

### Entity/Repository
- [ ] `UmsStatsDaily.java` 작성
- [ ] `UmsStatsDailyRepository.java` 작성

### MyBatis
- [ ] `UmsLogQueryMapper.java` 작성
- [ ] `UmsLogQueryMapper.xml` 작성
- [ ] `HourlyResultDto.java` 작성

### Service
- [ ] `StatisticsService.java` 작성
- [ ] `StatsAggregationService.java` 작성

### Controller
- [ ] `StatisticsController.java` 작성

### 스케줄러
- [ ] `@EnableScheduling` 설정 확인
- [ ] cron 표현식 테스트

---

## 💡 핵심 인사이트

### 실시간 vs 배치

| 시점 | 처리 방식 | 업데이트 대상 |
|------|----------|--------------|
| 발송 요청 | 실시간 | total_count, pending_count |
| 예약 취소 | 실시간 | pending_count |
| 결과 반영 | 배치 (매시) | success_count, fail_count, pending_count |

### 성능 고려사항

1. **ums_log 조회 최소화**: 배치로만 접근
2. **인덱스 활용**: `idx_user_date`로 빠른 조회
3. **캐싱 고려**: Redis로 대시보드 캐싱 (향후)

### 자주 하는 실수

1. **pending_count 음수**: `Math.max(0, ...)` 처리 필수
2. **스케줄러 중복 실행**: 서버 클러스터링 시 주의
3. **시간대 불일치**: 서버/DB 시간대 통일

---

## 📚 관련 문서

- [06-UMS-MESSAGE-FLOW.md](./06-UMS-MESSAGE-FLOW.md) - 메시지 발송 가이드
- [SNAP Agent 분석](../SNAP-AGENT-ANALYSIS.md) - ums_log 구조 참고
- [backend-design.md](../backend-design.md) - 전체 설계

