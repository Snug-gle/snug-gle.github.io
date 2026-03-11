---
created: 2026-02-10
tags:
  - linkwave
  - future-development
---

> 이 문서는 linkwave-docs의 future-development/README.md를 기반으로 작성되었습니다.

# Future Development

계획된 기능, 개선사항, 마이그레이션 가이드.

## Planned Features

### Backend

| Feature | Priority | 문서 |
|---------|----------|------|
| RS256 JWT Migration | Medium | [[rs256-migration]] |

### Frontend

| Feature | Priority | 문서 |
|---------|----------|------|
| Store Separation (Zustand) | Medium | [[store-separation]] |

### New Features

| Feature | Priority | 문서 |
|---------|----------|------|
| Contact Book (수신번호 관리) | High | [[contact-book]] |
| Message Templates (템플릿 관리) | High | [[message-template]] |
| Recipient/Sender/Template 통합 | High | [[recipient-sender]] |

---

## Feature: Recipient/Sender/Template Management

### 핵심 기능
1. **수신번호 관리**: 개인별 수신자 전화번호 저장/수정/삭제
2. **발신번호 관리**: 여러 개의 인증된 발신번호 등록 및 관리
3. **메시지 템플릿 관리**: SMS/LMS/MMS 템플릿 저장/수정/삭제
4. **발송화면 연동**: 발신번호/수신번호 선택, 작성 중 템플릿 저장

### Implementation Phases
| Phase | Scope | Priority |
|-------|-------|----------|
| 1 | 발신번호 드롭다운, 주소록 모달, 템플릿 불러오기 | High |
| 2 | 발송화면에서 템플릿 저장, 기본 발신번호 설정 | Medium |
| 3 | 발신번호 라벨 관리, 그룹 단위 선택, 카테고리 | Low |

---

## Priority Levels
- **High**: 핵심 기능에 필요
- **Medium**: 프로덕션 준비에 중요
- **Low**: 있으면 좋지만 연기 가능
