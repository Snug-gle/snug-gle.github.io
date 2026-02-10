---
created: 2026-02-10
tags:
  - linkwave
  - snap
  - integration
---

> 이 문서는 linkwave-docs의 INTEGRATION.md와 AGENT_ANALYSIS.md를 병합·요약한 것입니다.

# LinkWave-SNAP 통합 아키텍처

## 1. 시스템 개요

LinkWave는 웹 기반 메시지 발송 플랫폼. 실제 발송은 **SNAP Agent**를 통해 LG U+ 메시지허브 게이트웨이와 연동.

### 핵심 요구사항
- 사용자 웹 요청 → LinkWave DB 저장 → SNAP 자동 발송
- HTTP 통신 없이 **Database Queue 패턴**
- SNAP은 외부 라이브러리 (커스터마이징 불가) → LinkWave가 SNAP 스키마 준수

### 시스템 구성

```
LinkWave (React → Spring Boot → MySQL)
         ↓ INSERT
    ums_msg (Queue Table)
         ↓ Polling (SELECT)
SNAP Agent (Message Processor → LG U+ Message Hub Gateway)
         ↓ UPDATE
    ums_msg (상태 업데이트) + ums_log (이력 기록)
```

---

## 2. 통합 패턴: Database Queue

| 특징 | 설명 |
|------|------|
| 통신 방식 | DB를 중간 매개체로 사용 (HTTP 없음) |
| 결합도 | 낮음 (Loosely Coupled) |
| 장점 | 시스템 독립성, SNAP 장애 시 LinkWave 정상, 메시지 유실 방지, 병렬 처리 가능 |
| 단점 | 폴링 주기에 의존, DB 부하 |

대안(REST API, MQ)은 SNAP이 외부 라이브러리라 불가능.

---

## 3. 아키텍처 원칙

### 원칙 1: SNAP 스키마가 표준
- `ums_msg`, `ums_log_{YYYYMM}` 테이블은 SNAP 표준 스키마 준수
- LinkWave가 SNAP에 맞춤 (역순 불가)

### 원칙 2: LinkWave는 Insert만
- INSERT INTO ums_msg → SNAP이 폴링 후 처리
- 상태 업데이트/삭제는 SNAP 담당

### 원칙 3: ETC 필드 활용
- ums_msg의 ETC1~ETC5 필드에 LinkWave 메타데이터 저장
- ETC1: CLIENT_KEY, ETC2: TRAFFIC_TYPE, ETC3: DEDUP_HASH 등

---

## 4. SNAP Agent 분석

### 주요 컴포넌트
- **Database Connector**: MySQL/Oracle 연동, 폴링 스케줄러
- **Message Processor**: 메시지 파싱, 발송 채널 라우팅
- **Gateway Client**: LG U+ 메시지허브 HTTP 통신
- **Result Processor**: 발송 결과 DB 업데이트

### 폴링 동작
- 조건: `MSG_STATUS = 'ready' AND REQ_DATE <= NOW()`
- 우선순위: `TRAFFIC_TYPE real > normal > batch`
- 처리 후: `MSG_STATUS → 'request' → 'complete'` 또는 `'fail'`

### 지원 메시지 타입
- SMS, LMS, MMS, KakaoTalk (알림톡/친구톡), RCS, Push

---

## 5. ums_msg 핵심 컬럼

| 컬럼 | 설명 | LinkWave 역할 |
|------|------|---------------|
| MSG_KEY | PK (SNAP 자동생성) | — |
| SVC_TYPE | 메시지 타입 (SMS/LMS/MMS) | INSERT |
| PHONE | 수신번호 | INSERT |
| CALLBACK | 발신번호 | INSERT |
| SUBJECT | 제목 (LMS/MMS) | INSERT |
| MSG | 본문 | INSERT |
| MSG_STATUS | 상태 (ready→request→complete) | INSERT (ready) |
| REQ_DATE | 발송 요청 시간 | INSERT |
| TRAFFIC_TYPE | 우선순위 (real/normal/batch) | INSERT |
| ETC1~5 | 확장 필드 | CLIENT_KEY, DEDUP_HASH 등 |

---

## 6. 월별 발송 이력 (ums_log)

- 테이블명: `ums_log_{YYYYMM}` (월별 파티션)
- SNAP이 발송 완료 후 자동 기록
- LinkWave는 이 테이블에서 발송 이력/통계 조회

---

## Related Documents

- [[system-architecture|System Architecture]]
- [[backend-architecture|Backend Architecture]]
