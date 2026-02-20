---
created: 2026-02-10
tags:
  - project
  - linkwave
  - messaging
---

# LinkWave

> 다채널 메시지 발송 플랫폼 — SMS, LMS, MMS, KakaoTalk, RCS

## 프로젝트 개요

LinkWave는 웹 기반 다채널 메시지 발송 플랫폼입니다. 사용자가 웹에서 메시지를 작성하면 DB에 저장하고, SNAP Agent가 자동으로 발송을 처리합니다.

### 기술 스택

| 영역 | 기술 |
|------|------|
| Frontend | React 19, TypeScript, Vite, Zustand, TanStack Query/Router |
| Backend | Spring Boot 4.0, Java 21, JPA + MyBatis (CQRS) |
| Database | MySQL 8.0+, Redis |
| External | SNAP Sending Agent (LG U+ Message Hub) |

---

## 문서 구조

### [[01-scratch/initial-design|01. Scratch]] — 초기 설계
- [[01-scratch/initial-design|Initial Design]] — 원본 설계 문서 요약
- [[01-scratch/system-architecture|System Architecture]] — 전체 시스템 아키텍처

### [[02-design/backend-architecture|02. Design]] — 상세 설계
- [[02-design/backend-architecture|Backend Architecture]] — 백엔드 레이어 구조, CQRS
- [[02-design/backend-cqrs-evolution|CQRS Evolution]] — CQRS 패턴 진화 가이드
- [[02-design/frontend-architecture|Frontend Architecture]] — 프론트엔드 설계
- [[02-design/design-system|Design System]] — UI/UX 디자인 시스템
- [[02-design/api-specifications|API Specifications]] — Auth, Message, User API 명세
- [[02-design/snap-integration|SNAP Integration]] — 발송 에이전트 통합

### [[03-implementation/developer-handbook|03. Implementation]] — 구현 가이드
- [[03-implementation/developer-handbook|Developer Handbook]] — 코딩 표준, Git 워크플로우
- [[03-implementation/tdd-guide|TDD Guide]] — 테스트 주도 개발 가이드
- [[03-implementation/event-driven-cqrs|Event-Driven CQRS]] — 이벤트 기반 CQRS 구현
- [[03-implementation/message-history-read-model|Message History Read Model]] — 영구 Read Model 아키텍처 결정 (2026-02-19)
- [[03-implementation/message-inbox-onpremise|Message Inbox]] — 메시지 수신함 온프레미스 설계
- [[03-implementation/https-certificate|HTTPS Certificate]] — 인증서 설정 가이드

### [[04-deployment/backend-deployment|04. Deployment]] — 배포
- [[04-deployment/backend-deployment|Backend Deployment]] — JAR 배포 + CI/CD
- [[04-deployment/frontend-deployment|Frontend Deployment]] — 정적 파일 배포 + Nginx

### [[05-future/index|05. Future]] — 계획된 기능
- [[05-future/contact-book|Contact Book]] — 수신번호 관리 *(구현 중: Phase 4 Step 2 완료, Step 3 예정)*
- [[05-future/message-template|Message Template]] — 메시지 템플릿
- [[05-future/recipient-sender|Recipient/Sender/Template]] — 통합 관리
- [[05-future/rs256-migration|RS256 Migration]] — JWT 마이그레이션
- [[05-future/store-separation|Store Separation]] — Zustand 스토어 분리

---

## 관련 문서

- [[area/career/portfolio-for-blog|Portfolio (Blog)]]
