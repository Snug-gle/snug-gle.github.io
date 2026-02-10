---
created: 2026-02-10
tags:
  - linkwave
  - backend
  - message-inbox
  - on-premise
---

> 이 문서는 linkwave-docs의 MESSAGE-INBOX-ONPREMISE-DESIGN.md를 요약한 것입니다.

# Message Inbox On-Premise Design

## 1. 개요

메시지 수신함(Inbox) 기능의 온프레미스 환경 설계. 발송된 메시지의 상태 추적, 이력 조회, 통계 제공.

### 핵심 요구사항
- 발송 메시지의 실시간 상태 추적 (ready → request → complete/fail)
- 월별 파티션 테이블(ums_log_{YYYYMM})에서 이력 조회
- 대시보드용 통계 데이터 제공

---

## 2. 아키텍처

### 데이터 흐름

```
발송 요청 → ums_msg (실시간 상태)
                ↓ SNAP 처리 후
           ums_log_{YYYYMM} (이력)
                ↓ @Scheduled 집계
           ums_stats_daily (통계)
```

### 조회 전략

| 조회 유형 | 데이터 소스 | 기술 |
|----------|-----------|------|
| 실시간 상태 | ums_msg | MyBatis (실시간 쿼리) |
| 발송 이력 | ums_log_{YYYYMM} | MyBatis (월별 파티션) |
| 통계/대시보드 | ums_stats_daily | MyBatis (사전 집계) |

---

## 3. 테이블 설계

### ums_msg (발송 요청 — 실시간)
- SNAP 표준 스키마 준수
- MSG_STATUS: ready → request → complete/fail
- 인덱스: MSG_STATUS + REQ_DATE (폴링 최적화)

### ums_log_{YYYYMM} (발송 이력 — 월별)
- 월별 자동 생성 (ums_log_202601, ums_log_202602, ...)
- SNAP이 발송 완료 후 자동 INSERT
- 인덱스: USER_ID + REQ_DATE, PHONE, CLIENT_KEY

### ums_stats_daily (일별 통계 — 집계)
```sql
CREATE TABLE ums_stats_daily (
    stat_date DATE,
    user_id VARCHAR(50),
    svc_type VARCHAR(10),      -- SMS/LMS/MMS
    total_count INT,
    success_count INT,
    fail_count INT,
    total_cost DECIMAL(10,2),
    PRIMARY KEY (stat_date, user_id, svc_type)
);
```

---

## 4. MyBatis 쿼리 설계

### 메시지 목록 조회
- 파라미터: userId, startDate, endDate, status, messageType, page, size
- 동적 SQL: `<if>` 조건부 WHERE
- 월별 테이블 동적 매핑: `ums_log_${yearMonth}`

### 통계 조회
- 기간별 집계: 일별/주별/월별
- 메시지 타입별 분류
- 성공률 계산

---

## 5. 성능 최적화

### 파티션 전략
- 월별 파티션으로 대용량 이력 관리
- 쿼리 시 기간 필터 필수 → 파티션 프루닝

### 통계 사전 집계
- @Scheduled (매일 새벽): ums_log → ums_stats_daily 집계
- 대시보드는 사전 집계 테이블에서 조회 (빠름)
- 실시간 데이터는 오늘치만 ums_log에서 직접 집계

### 인덱스 전략
- ums_msg: `idx_status_reqdate` (MSG_STATUS, REQ_DATE)
- ums_log: `idx_user_date` (USER_ID, REQ_DATE), `idx_phone`
- ums_stats_daily: PK가 곧 인덱스

---

## 6. 온프레미스 고려사항

- DB 백업: 일별 full backup + binlog 증분
- 파티션 관리: 오래된 파티션 아카이브 (12개월 이후)
- 모니터링: ums_msg 적체 감시, 디스크 용량 관리

---

## Related Documents

- [[snap-integration|SNAP Integration]]
- [[backend-architecture|Backend Architecture]]
