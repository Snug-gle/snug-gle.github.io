---
created: 2026-02-10
tags:
  - linkwave
  - feature
  - message-template
---

> 이 문서는 linkwave-docs의 MESSAGE_TEMPLATE.md를 요약한 것입니다.

# Message Template System Design

## 1. 개요

메시지 템플릿 저장/관리 기능. 자주 사용하는 메시지를 템플릿으로 저장하여 재사용.

### 주요 기능
- 템플릿 CRUD (SMS/LMS/MMS 타입별)
- 카테고리 분류
- 치환 변수 지원 (`#{이름}`, `#{회사명}`)
- 발송 화면에서 불러오기/저장
- 공유 템플릿 (조직 레벨)

---

## 2. 요구사항

| ID | 요구사항 | 우선순위 |
|----|----------|----------|
| MT-01 | 템플릿 CRUD | High |
| MT-02 | 메시지 타입별 분류 (SMS/LMS/MMS) | High |
| MT-03 | 카테고리 관리 | Medium |
| MT-04 | 치환 변수 지원 | High |
| MT-05 | 발송 화면에서 불러오기 | High |
| MT-06 | 발송 화면에서 바로 저장 | Medium |
| MT-07 | 조직 공유 템플릿 | Medium |
| MT-08 | 미리보기 (치환 결과) | Medium |

---

## 3. 데이터 모델

```
User ──▶ MessageTemplate
           ├── template_id (PK)
           ├── user_id (FK)
           ├── message_type (SMS/LMS/MMS)
           ├── category_id (FK)
           ├── title
           ├── content (본문, 치환 변수 포함)
           ├── subject (LMS/MMS 제목)
           ├── is_shared (조직 공유 여부)
           └── use_count

User ──▶ TemplateCategory
           ├── category_id (PK)
           ├── user_id (FK)
           ├── category_name
           └── sort_order
```

---

## 4. API 설계

| Method | Endpoint | 설명 |
|--------|----------|------|
| GET | `/templates` | 템플릿 목록 (타입/카테고리 필터) |
| POST | `/templates` | 템플릿 생성 |
| PUT | `/templates/{id}` | 템플릿 수정 |
| DELETE | `/templates/{id}` | 템플릿 삭제 |
| GET | `/template-categories` | 카테고리 목록 |
| POST | `/templates/{id}/preview` | 미리보기 (치환 적용) |

---

## 5. 치환 변수 처리

### 템플릿 예시
```
#{이름}님, #{회사명}에서 안내드립니다.
#{날짜} #{시간}에 예정된 미팅을 확인해 주세요.
```

### 처리 흐름
1. 템플릿 저장 시 `#{변수명}` 패턴 파싱 → 변수 목록 추출
2. 발송 시 수신자별 variables 매핑
3. `#{변수명}`을 실제 값으로 치환

---

## 6. UI/UX

### 템플릿 관리 화면
- 좌측: 카테고리 사이드바 + 메시지 타입 필터
- 우측: 템플릿 리스트 + 미리보기 패널

### 발송 화면 연동
- "템플릿" 버튼 → 모달로 템플릿 선택 → 본문 자동 입력
- 현재 작성 중인 내용 → "템플릿으로 저장" 버튼

---

## Related Documents

- [[contact-book|Contact Book]]
- [[recipient-sender|Recipient/Sender/Template 통합]]
