---
created: 2026-02-10
tags:
  - linkwave
  - design
  - initial-scratch
---

> 이 문서는 linkwave-docs의 common/INITIAL_SCRATCH.md를 요약한 것입니다.

# 문자 발송 웹페이지 설계 (Initial Scratch)

## 1. 개요

### 목적
사용자가 문자 메시지(SMS, LMS, MMS, 카카오톡, RCS)를 입력하고 발송 요청할 수 있는 웹 인터페이스 제공

### 기술 스택
- **프론트엔드**: React, JavaScript
- **백엔드**: Spring Boot 4.0
- **데이터베이스**: MySQL (향후 Oracle, PostgreSQL 확장)

### 역할 범위
웹페이지는 **발송 요청 접수 및 DB 저장**만 담당. 실제 발송은 별도의 발송 에이전트(Snap)가 처리.

---

## 2. 시스템 아키텍처

```
관리자 (본사) → 회사/사용자/발신번호 관리
         ↓
사용자 (고객사)
  React 웹페이지 → REST API → Service Layer
         ↓                        ↓
  Web Service DB            Message DB
  (주소록, 발신번호,       (ums_msg, ums_log_{YYYYMM})
   문자보관함, 공유주소록)
         ↓
  발송 에이전트 (Snap)
  → Message DB 폴링 → 실시간/배치 분리 → 중계서버 발송 → 결과 업데이트
```

### 중복 발송 방지
- **조건**: 전화번호 + 메시지 내용 해시값
- 10분 이내 동일 요청 검증, 사용자 선택으로 중복 허용 가능

---

## 3. 프론트엔드 설계

### 주요 화면
1. **메인 네비게이션**: SMS / LMS / MMS / 카카오톡 / RCS 탭
2. **메시지 작성 화면** (공통):
   - 수신자 입력 (직접/엑셀/주소록/그룹)
   - 발신번호 선택
   - 메시지 내용 (바이트 카운터, 치환 변수 지원)
   - 타입별: MMS(이미지), 카카오(템플릿/버튼), RCS(미디어/카드형)
   - 발송 옵션 (즉시/예약, 중복 제거)
3. **발송 이력**: 상태별 필터, 페이지네이션, 상세 모달, 재발송
4. **통계 대시보드**: 기간별/타입별/시간대별 통계

### 컴포넌트 구조
```
src/
├── components/ (common, MessageForm, MessageList, Dashboard, AddressBook)
├── pages/ (SmsPage, LmsPage, MmsPage, KakaoPage, RcsPage, HistoryPage, Dashboard)
├── services/ (API 호출)
├── hooks/ (useMessageForm, useMessageList)
└── App.jsx
```

---

## 4. 백엔드 설계

### REST API 엔드포인트

| Method | Endpoint | 설명 |
|--------|----------|------|
| POST | `/api/v1/messages` | 메시지 발송 요청 |
| GET | `/api/v1/messages/{messageId}` | 메시지 상세 조회 |
| GET | `/api/v1/messages` | 메시지 목록 조회 (페이지네이션) |

### 데이터베이스 스키마 (13개 테이블)

| 구분 | 테이블 | DB |
|------|--------|-----|
| 관리자(본사) | companies, users, admin_sender_numbers | Web DB |
| 사용자(고객사) | sender_numbers, customer_contacts, personal_address_book, shared_address_book, message_storage | Web DB |
| 발송 처리 | ums_msg, ums_log_{YYYYMM} | Message DB |
| 부가 기능 | message_files, audit_logs, sync_queue | Web DB |

### Hybrid Persistence 전략
- **User Domain** → JPA: users, organizations, address_book
- **Message Domain** → MyBatis: ums_msg, ums_log_{YYYYMM}
- 원칙: 같은 테이블에 두 기술 혼용 금지

---

## 5. 보안

- JWT 기반 인증 (Spring Security)
- 역할: ADMIN, USER, MANAGER
- HTTPS 필수, SQL Injection 방지 (PreparedStatement)

---

## 6. 메시지 처리 흐름

1. 사용자 메시지 작성 → Controller 유효성 검증 (필수값, 바이트, 파일, 중복)
2. MessageService 비즈니스 로직 (TRAFFIC_TYPE 결정, CLIENT_KEY/DEDUP_HASH 생성)
3. Message DB (ums_msg) 저장, MSG_STATUS='ready'
4. 발송 에이전트가 폴링 (우선순위: real > normal > batch)
5. 발송 완료 → ums_msg 상태 업데이트, ums_log 기록

### TRAFFIC_TYPE
- `real`: 고우선순위, 즉시 발송 (<10분)
- `normal`: 표준 큐
- `batch`: 저우선순위 (100명+ 또는 10분+ 예약)

---

## Related Documents

- [[system-architecture|System Architecture]]
- [[backend-architecture|Backend Architecture]]
- [[frontend-architecture|Frontend Architecture]]
- [[api-specifications|API Specifications]]
