---
tags: [career, portfolio, about]
category: career
created: 2026-01-22
title: Portfolio
description: 상훈 Backend Developer 포트폴리오 — LinkWave, 실무 경험, 기술 스택
---
# 상훈 | Backend Developer

> Upstream First (목표) — Star는 열심히 눌렀다. PR은 준비 중이다. 오픈소스 생태계에서 배우며 언젠간 돌려줄 개발자

Java/Spring + React/TypeScript | 2022 ~

---

## 주요 프로젝트: LinkWave

**멀티채널 메시징 플랫폼** — 구축형 (SMS/LMS/MMS/KakaoTalk/RCS)

`Spring Boot` `React` `MySQL` `Redis` `JPA + MyBatis`

- **이벤트 기반 CQRS + 하이브리드 ORM**: Write Model(`UmsMsg`/MyBatis 배치 삽입) → `MessageSendRequestedEvent` 발행 → `@TransactionalEventListener(AFTER_COMMIT) + @Async` → Read Model(`MessageHistory`/JPA) 동기화. CRUD 도메인은 JPA, 복잡한 조회는 MyBatis QueryMapper 분리 → [[resource/topics/architecture/cqrs-hybrid-orm-linkwave|구현 상세]]
- **커서 기반 페이징 (Keyset Pagination)**: 이중 커서(requestedAt + clientKey)로 후반 페이지도 O(1) 성능, Base64 불투명 커서 → [[resource/topics/database/cursor-pagination-linkwave|구현 상세]]
- **JWT HS256 기반 인증 + Refresh Token Rotation**: HMAC-SHA256 대칭키 인증, 슬라이딩 윈도우 리프레시로 보안성 확보
- **월별 파티션 테이블**: 조회 성능 80% 향상, 인덱스 크기 86% 감소
- **멀티테넌트 데이터 격리 + RBAC**: 조직별 데이터 분리와 역할 기반 접근 제어
- **디자인 시스템**: shadcn/ui + Tailwind CSS 컴포넌트 라이브러리 ("Clarity Through Connection")

→ [[area/career/projects/linkwave|자세히 보기]]

---

## 실무 경험

### LinkWave — 멀티채널 메시징 플랫폼
`Spring Boot` `React` `MySQL` `Redis` `JPA + MyBatis`
**2025.12 ~ 현재 | 본사**

- 이벤트 기반 CQRS + 하이브리드 ORM 설계 및 구현
- 커서 기반 페이징, JWT 인증, 월별 파티션 테이블, 멀티테넌트 RBAC 구축

→ [[area/career/projects/linkwave|자세히 보기]]

### Perf Script Pipeline — AI 성능 테스트 자동화
`React 19` `TypeScript` `TanStack` `Spring AI`
**2025.08 ~ 2025.11 | 제이드크로스 (Kbank)**

- HAR 병합 → JMX/JTL 추출 → AI 상관관계 분석 → JMeter 스크립트 최적화
- 가상 스크롤링으로 10,000건 렌더링 시간 90% 단축, React Query 캐싱으로 API 요청 80% 감소
- Spring AI + VectorDB 활용 JMeter 스크립트 지능형 검색 프로토타입 구현

→ [[area/career/projects/perf-script-pipeline|자세히 보기]]

### 콜센터 고객상담 웹서비스
`Spring Boot` `Vue.js` `MariaDB` `AUIGrid`
**2025.04 ~ 2025.07 | 위컴즈 (농림부)**

- 악성민원관리 도메인 추가, 콜백 자동 분배 기능 구현
- 스케줄러 → Redis Pub/Sub → WebSocket 파이프라인으로 실시간 알림 구현

→ [[area/career/projects/webconsole|자세히 보기]]

### 기업 메시징 유지보수
`Spring Boot` `Vue.js` `MyBatis` `Oracle/MySQL`
**2023.05 ~ 2025.03 (약 2년) | LGU+**

- Uplus 문자 발송 에이전트 커스터마이징·버전 관리·배포, 고객사 서버 이전 지원
- (기업은행) 외부 암호화 모듈 연동, (한화생명) 문자 발송 프로토콜(bind4) 규격 추가
- UMS 웹 템플릿 통합 메시지 발송 API 구현 및 UI 추가

### 초기 경력 (2022.07 ~ 2023.04)
`Spring Framework` `JSP` `Oracle` `MyBatis`

- **가톨릭학원** (2022.11~2023.04): Tomcat 9 → 10.1 마이그레이션, Jakarta EE 전환 이슈 해결
- **마켓컬리** (2022.07~2022.10): 대량 발송 PL/SQL 반복문 쿼리 작성 및 테스트

---

## 기술 스택

**Backend**: Java 21, Spring Boot, JPA, MyBatis, MySQL, Redis
**Frontend**: React, TypeScript, TanStack (Query/Router/Table), Tailwind CSS, shadcn/ui
**DevOps**: Docker, Nginx, GitHub Actions, GitLab CI/CD
**Architecture**: CQRS, Multi-tenant, RBAC, DDD

---

## 팀 스터디 — Attiead

[github.com/Attiead](https://github.com/Attiead)

Spring Cloud 기반 MSA 과외 플랫폼 팀 프로젝트 (2023.08 ~ 2024.06) + 서적 스터디 (2023.02 ~ 2023.04)

- **Notice 도메인** (Java/Spring Boot/JPA): 공지사항·첨부파일 관리 API
- **Student 도메인** (Kotlin/Spring Boot): 피과외자 CRUD, Spring REST Docs, Detekt
- **서적 스터디**: 도메인 주도 설계 · 클린 아키텍처 · 아파치 카프카 · LLM 실전 AI 애플리케이션 개발
