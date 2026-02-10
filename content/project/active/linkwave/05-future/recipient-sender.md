---
created: 2026-02-10
tags:
  - linkwave
  - feature
  - recipient-sender
---

> 이 문서는 linkwave-docs의 RECIPIENT_SENDER_TEMPLATE.md를 요약한 것입니다.

# Recipient/Sender/Template 통합 기능 명세

## 1. 개요

수신번호, 발신번호, 메시지 템플릿을 통합 관리하고 발송 화면과 연동하는 기능.

### 핵심 기능
1. **수신번호 관리**: Contact Book → 발송 화면 연동
2. **발신번호 관리**: 인증된 발신번호 등록/관리 → 드롭다운 선택
3. **메시지 템플릿**: 저장/불러오기 → 발송 화면 자동 입력
4. **발송화면 통합**: 위 3개 기능이 발송 화면에서 매끄럽게 동작

---

## 2. 발신번호 관리

### 현재 (구현 완료)
- 발신번호 목록 조회/등록/삭제
- API: `/api/v1/sender-numbers`

### 추가 기능 (계획)
- 발신번호 인증 (SMS 인증번호)
- 기본 발신번호 설정
- 발신번호 라벨/메모
- 발송 화면에서 드롭다운으로 선택

---

## 3. 수신번호 관리 (Contact Book)

### 발송 화면 연동 흐름
1. 수신자 입력란 옆 "주소록" 버튼 클릭
2. 모달: 연락처 검색 + 그룹 필터
3. 체크박스로 선택 → "확인" → 수신자 목록에 추가
4. 그룹 단위 선택도 가능

---

## 4. 메시지 템플릿

### 발송 화면 연동 흐름

**불러오기**:
1. "템플릿" 버튼 클릭 → 모달
2. 타입(SMS/LMS/MMS) + 카테고리 필터
3. 템플릿 선택 → 본문에 자동 입력

**저장하기**:
1. 메시지 작성 중 "템플릿으로 저장" 클릭
2. 제목, 카테고리 입력 → 저장
3. 현재 내용 + 메시지 타입이 자동 반영

---

## 5. Implementation Phases

### Phase 1 (High Priority)
- 발신번호 드롭다운 (기존 API 활용)
- 주소록 모달 (기본 검색 + 선택)
- 템플릿 불러오기

### Phase 2 (Medium Priority)
- 발송 화면에서 템플릿 저장
- 기본 발신번호 설정
- 자주 쓰는 연락처/템플릿

### Phase 3 (Low Priority)
- 발신번호 라벨 관리
- 그룹 단위 선택 고도화
- 템플릿 카테고리 관리

---

## Related Documents

- [[contact-book|Contact Book]]
- [[message-template|Message Template]]
- [[api-specifications|API Specifications]]
