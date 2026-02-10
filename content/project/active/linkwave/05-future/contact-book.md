---
created: 2026-02-10
tags:
  - linkwave
  - feature
  - contact-book
---

> 이 문서는 linkwave-docs의 CONTACT_BOOK.md를 요약한 것입니다.

# Contact Book Design (수신번호 관리)

## 1. 개요

사용자별 수신번호(연락처) 관리 기능. 효율적인 메시지 발송을 위한 핵심 기능.

### 주요 기능
- 개인 연락처 CRUD
- 그룹/카테고리 정리
- CSV/Excel Import/Export
- 검색 및 필터
- 자주 쓰는 연락처
- 조직 내 연락처 공유 (Business 사용자)

---

## 2. 요구사항

### 기능 요구사항

| ID | 요구사항 | 우선순위 |
|----|----------|----------|
| CB-01 | 연락처 CRUD | High |
| CB-02 | 그룹 관리 | High |
| CB-03 | CSV/Excel Import | High |
| CB-04 | CSV/Excel Export | Medium |
| CB-05 | 이름/번호/그룹 검색 | High |
| CB-06 | 자주 쓰는 연락처 추적 | Medium |
| CB-07 | 조직 내 공유 | Medium |
| CB-08 | 중복 번호 감지 | High |

### 비기능 요구사항
- 검색 응답: < 200ms
- 사용자당 최대 연락처: 10,000
- 사용자당 최대 그룹: 100
- Import 파일 제한: 5MB

---

## 3. 데이터 모델

```
User ──┬──▶ ContactGroup (group_id, user_id, group_name, color)
       │
       └──▶ Contact (contact_id, user_id, phone, name, group_id, memo, use_count)
```

### 핵심 테이블

**contacts**
- contact_id, user_id, phone, name, group_id, memo, use_count, is_favorite
- 인덱스: (user_id, phone) UNIQUE, (user_id, group_id)

**contact_groups**
- group_id, user_id, group_name, description, color, contact_count

---

## 4. API 설계

| Method | Endpoint | 설명 |
|--------|----------|------|
| GET | `/contacts` | 연락처 목록 (검색/필터/페이지) |
| POST | `/contacts` | 연락처 추가 |
| PUT | `/contacts/{id}` | 연락처 수정 |
| DELETE | `/contacts/{id}` | 연락처 삭제 |
| POST | `/contacts/import` | CSV/Excel Import |
| GET | `/contacts/export` | CSV/Excel Export |
| GET | `/contact-groups` | 그룹 목록 |
| POST | `/contact-groups` | 그룹 생성 |

---

## 5. UI/UX

### 메인 화면
- 좌측: 그룹 사이드바 (전체, 즐겨찾기, 그룹별)
- 우측: 연락처 리스트 (검색바, 테이블, 페이지네이션)

### 발송 화면 연동
- 수신자 입력 시 "주소록" 버튼 → 모달로 연락처 선택
- 그룹 단위 선택 지원
- 최근 사용/자주 사용 연락처 빠른 선택

---

## Related Documents

- [[recipient-sender|Recipient/Sender/Template 통합]]
- [[message-template|Message Template]]
