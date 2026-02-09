---
created: 2025-12-26
---
# SNAP Agent 분석 보고서

## 📌 개요

이 문서는 U+ 메시지허브 연동 에이전트인 **SNAP Agent**를 분석한 결과입니다.
LinkWave Backend와 SNAP Agent 간의 연동 방식을 정의하고, 최적의 아키텍처를 결정하기 위해 작성되었습니다.

---

## 1. SNAP Agent란?

SNAP Agent는 **LG U+ 메시지허브 연동 에이전트**로, DB 폴링 방식으로 발송 테이블을 감시하고 메시지를 발송합니다.

### 1.1 지원 채널

| 채널 | REQ_CH 값 | 설명 |
|------|----------|------|
| SMS | `SMS` | 단문 메시지 |
| LMS | `LMS` | 장문 메시지 |
| MMS | `MMS` | 멀티미디어 메시지 |
| RCS | `RCS` | Rich Communication Services |
| 카카오 알림톡 | `ALIMTALK` | 카카오톡 알림톡 |
| 카카오 친구톡 | `FRIENDTALK` | 카카오톡 친구톡 |
| PUSH | `PUSH` | 모바일 푸시 알림 |
| 통합 발송 | `UMS` | 템플릿 기반 통합 발송 |

### 1.2 동작 방식

```
┌─────────────────────────────────────────────────────────────────┐
│                        SNAP Agent 동작 흐름                      │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  1. [ums_msg] 테이블 폴링                                        │
│     WHERE MSG_STATUS = 'ready'                                  │
│       AND REQ_CH = #{channel}                                   │
│       AND REQ_DATE < NOW()   ← 예약 발송 자동 처리               │
│     LIMIT 1000                                                  │
│                                                                 │
│  2. 조회된 메시지 상태 변경                                       │
│     MSG_STATUS: 'ready' → 'pre-send'                            │
│                                                                 │
│  3. 메시지허브 G/W로 발송 요청                                    │
│     MSG_STATUS: 'pre-send' → 'request'                          │
│                                                                 │
│  4. 발송 결과 수신                                               │
│     MSG_STATUS: 'request' → 'complete'                          │
│     DONE_CODE, DONE_DATE 등 업데이트                             │
│                                                                 │
│  5. 완료된 메시지를 로그 테이블로 이동                             │
│     ums_msg → ums_log (또는 ums_log_{YYYYMM})                   │
│     ums_msg에서 DELETE                                          │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

---

## 2. 핵심 테이블 구조

### 2.1 ums_msg (발송 대기 테이블)

SNAP Agent가 소비하는 발송 큐 테이블입니다.

#### 핵심 컬럼

| 컬럼 | 타입 | 설명 | 필수 |
|------|------|------|:----:|
| `CLIENT_KEY` | VARCHAR(40) | 메시지 고유 ID (PK) | ✅ |
| `REQ_CH` | VARCHAR(10) | 발송 채널 (SMS, LMS, MMS, RCS, ALIMTALK, ...) | ✅ |
| `TRAFFIC_TYPE` | VARCHAR(10) | 메시지 유형 (normal, real, batch) | ✅ |
| `MSG_STATUS` | VARCHAR(10) | 발송 상태 (ready, pre-send, request, complete) | ✅ |
| `REQ_DATE` | DATETIME | 발송 요청 시간 (**미래 시간 = 예약 발송**) | ✅ |
| `CALLBACK_NUMBER` | VARCHAR(16) | 발신번호 | ✅ |
| `PHONE` | VARCHAR(16) | 수신번호 | ✅ |
| `MSG` | VARCHAR(2000) | 메시지 내용 | ✅ |
| `TITLE` | VARCHAR(100) | 제목 (LMS/MMS/RCS) | |
| `FB_CH` | VARCHAR(10) | Fallback 채널 (SMS/LMS/MMS) | |
| `FB_MSG` | VARCHAR(4000) | Fallback 메시지 내용 | |
| `ETC1~ETC6` | VARCHAR(50) | 고객사 예비 필드 | |

#### MSG_STATUS 상태값

| 상태 | 설명 | 설정 주체 |
|------|------|----------|
| `ready` | 발송 대기 (INSERT 시 기본값) | LinkWave |
| `pre-send` | 조회 완료 | SNAP |
| `pre-image` | 이미지 등록 작업 중 | SNAP |
| `request` | 발송 완료 (G/W 전송 완료) | SNAP |
| `complete` | 결과 수신 완료 | SNAP |

#### TRAFFIC_TYPE 유형

| 유형 | 설명 | 용도 |
|------|------|------|
| `normal` | 일반 메시지 (기본값) | 즉시/예약 발송 |
| `real` | 실시간/중요 메시지 | 우선 처리 필요 시 |
| `batch` | 마케팅/광고 메시지 | 대량 발송 |

### 2.2 ums_log (발송 로그 테이블)

발송 완료된 메시지가 이동되는 로그 테이블입니다.

- 구조: `ums_msg`와 동일
- 로그 타입: `month` (월별 파티션: `ums_log_202512`)
- 용도: 발송 이력 조회, 통계 집계

### 2.3 ETC 필드 활용 방안

LinkWave에서 활용할 수 있는 예비 필드입니다:

| 필드 | 용도 | 예시 |
|------|------|------|
| `ETC1` | 사용자 ID | `user_hong` |
| `ETC2` | 조직 ID | `org_iotree` |
| `ETC3` | 발송 그룹 ID | `GRP_20251223_001` |
| `ETC4` | 발송 타입 | `IMMEDIATE`, `SCHEDULED`, `BULK` |
| `ETC5` | 캠페인 ID | `CAMP_XMAS_2025` |
| `ETC6` | 예비 | - |

---

## 3. 예약 발송 메커니즘

### 3.1 핵심 발견

SNAP Agent는 **`REQ_DATE < NOW()` 조건**으로 예약 발송을 자동 처리합니다.

```sql
-- SNAP Agent의 발송 데이터 조회 쿼리 (ums.xml)
SELECT * FROM ums_msg
WHERE MSG_STATUS = 'ready'
  AND REQ_CH = #{channel}
  AND TRAFFIC_TYPE = #{lineType}
  AND REQ_DATE < NOW()   -- ⭐ 현재 시간보다 이전인 것만 조회
LIMIT 1000
```

### 3.2 즉시 발송 vs 예약 발송

| 발송 유형 | REQ_DATE 값 | 동작 |
|----------|------------|------|
| 즉시 발송 | `NOW()` 또는 과거 시간 | INSERT 즉시 SNAP이 조회하여 발송 |
| 예약 발송 | 미래 시간 (예: `2025-12-25 10:00:00`) | 해당 시간이 될 때까지 조회되지 않음 |

### 3.3 예약 발송 취소

예약된 메시지는 `MSG_STATUS = 'ready'` 상태이므로 **직접 DELETE**하여 취소할 수 있습니다.

```sql
-- 예약 발송 취소
DELETE FROM ums_msg
WHERE ETC3 = #{groupId}
  AND MSG_STATUS = 'ready';
```

---

## 4. Fallback 발송

SNAP Agent는 RCS/카카오 발송 실패 시 자동으로 SMS/LMS/MMS로 Fallback합니다.

### 4.1 설정 방법

| 컬럼 | 설명 |
|------|------|
| `FB_CH` | Fallback 채널 (SMS, LMS, MMS) |
| `FB_MSG` | Fallback 메시지 내용 |
| `FB_TITLE` | Fallback 제목 (LMS/MMS) |
| `FB_FILE_LIST` | Fallback MMS 첨부파일 |

### 4.2 Fallback 결과

| 컬럼 | 설명 |
|------|------|
| `DONE_CH` | 실제 발송 성공한 채널 |
| `DONE_FB_DETAIL` | Fallback 처리 상세 (1차 실패 코드 등) |

---

## 5. 인덱스 구조

### 5.1 발송 테이블 (ums_msg)

```sql
-- 발송 데이터 조회용 (SNAP 폴링)
CREATE INDEX ums_msg_IDX1 ON ums_msg (MSG_STATUS, REQ_CH, TRAFFIC_TYPE, REQ_DATE);

-- 수신번호 조회용
CREATE INDEX ums_msg_IDX2 ON ums_msg (PHONE);

-- 결과 코드 조회용
CREATE INDEX ums_msg_IDX3 ON ums_msg (DONE_CODE, REQ_DATE);
```

### 5.2 로그 테이블 (ums_log)

```sql
-- 수신번호 조회용
CREATE INDEX ums_log_IDX1 ON ums_log (PHONE);

-- 결과 코드 조회용
CREATE INDEX ums_log_IDX2 ON ums_log (DONE_CODE, REQ_DATE);
```

---

## 6. LinkWave 연동 아키텍처

### 6.1 최종 결정

| 항목 | 결정 | 이유 |
|------|------|------|
| 중간 테이블 (ums_request) | ❌ 불필요 | SNAP이 예약 발송 지원, ETC 필드 활용 가능 |
| 발송 방식 | `ums_msg` 직접 INSERT | 단순하고 효율적 |
| 예약 취소 | `ums_msg` 직접 DELETE | ready 상태만 취소 가능 |
| 재발송 | SNAP Agent 처리 | 구현 불필요 |
| 통계 | 별도 테이블 (`ums_stats_daily`) | 10만건+ 대응, 빠른 조회 |

### 6.2 데이터 흐름

```
┌─────────────────────────────────────────────────────────────────────────┐
│                           LinkWave Backend                              │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│  [MessageService]                                                       │
│       │                                                                 │
│       ├── 발송 ──────────────► [ums_msg] ──► [SNAP] ──► [ums_log]       │
│       │   (INSERT)                 ▲                         │          │
│       │                            │                         │          │
│       ├── 예약취소 ─────────────── DELETE (ready만)          │          │
│       │                                                      │          │
│       │                                                      ▼          │
│       │                                              [@Scheduled]       │
│       │                                                      │          │
│       │                                                      ▼          │
│       └── 통계조회 ◄───────────────────────────── [ums_stats_daily]     │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## 7. 참고: SNAP 설정 파일

### 7.1 application.yml 주요 설정

```yaml
table:
  use-yn:
    auto-creation: y          # 테이블 자동 생성
  log-type: month             # 로그 테이블 월별 파티션
  name:
    ums:
      send: UMS_MSG           # 발송 테이블명
      log: UMS_LOG            # 로그 테이블명

connection:
  info-list:
    - vendor: msghub
      schema: ums
      line-type: normal
      host: https://api.msghub.uplus.co.kr
      port: 443
      tps: 50                 # 초당 처리량
```

### 7.2 발송 시간 제한

```yaml
agent:
  send-time:
    - day-of-week: '0'        # 0: 매일
      start-time: '1000'      # 10:00
      end-time: '1000'        # 10:00 (제한 없음)
```

---

## 8. 결론

### 8.1 SNAP Agent의 장점

1. **예약 발송 자동 지원**: `REQ_DATE` 컬럼으로 별도 스케줄러 불필요
2. **Fallback 자동 처리**: RCS/카카오 실패 시 SMS/LMS/MMS 자동 전환
3. **ETC 필드 제공**: 고객사 데이터 저장 가능
4. **월별 로그 파티션**: 대용량 데이터 관리 용이

### 8.2 LinkWave 구현 시 고려사항

1. **CLIENT_KEY 생성 규칙**: `LW_{날짜}_{사용자ID}_{순번}`
2. **ETC 필드 활용**: 사용자/조직/그룹 ID 저장
3. **통계 테이블 분리**: `ums_log` 직접 조회 대신 집계 테이블 사용
4. **인덱스 추가 고려**: ETC 필드 기반 조회가 빈번할 경우

---

**작성일**: 2025-12-23  
**분석 대상**: SNAP Agent v1.x (ums.xml, application.yml 기준)

