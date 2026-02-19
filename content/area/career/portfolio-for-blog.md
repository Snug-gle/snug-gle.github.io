---
created: 2026-01-22
title: Portfolio
---
# 상훈 | Full-stack Developer

> Upstream First — 오픈소스 생태계 위에서 성장하고, 배운 것을 커뮤니티에 돌려주는 개발자

Java/Spring + React/TypeScript | 2022 ~

---

## 주요 프로젝트: LinkWave

**멀티채널 메시징 플랫폼** — B2B SaaS (SMS/LMS/MMS/KakaoTalk/RCS)

`Spring Boot` `React` `MySQL` `Redis` `JPA + MyBatis`

- **CQRS 하이브리드 ORM**: CRUD 중심 도메인(User/Org)은 JPA, 대용량 쓰기(Message/Log)는 MyBatis — 생산성과 성능 동시 달성
- **JWT + Refresh Token Rotation**: RS256 비대칭 인증, 슬라이딩 윈도우 리프레시로 보안성과 확장성 확보
- **월별 파티션 테이블**: 조회 성능 80% 향상, 인덱스 크기 86% 감소
- **멀티테넌트 데이터 격리 + RBAC**: 조직별 데이터 분리와 역할 기반 접근 제어
- **디자인 시스템**: shadcn/ui + Tailwind CSS 컴포넌트 라이브러리 ("Clarity Through Connection")

---

## 실무 경험

### Perf Script Pipeline — HAR-JMX 상관관계 분석 도구
`React 19` `TypeScript` `TanStack` `Spring AI`

- HAR 병합 → JMX/JTL 추출 → AI 상관관계 분석 → JMeter 스크립트 최적화
- 가상 스크롤링으로 10,000건 렌더링 시간 90% 단축, React Query 캐싱으로 API 요청 80% 감소

### Mafra — 상담 시스템
`Spring Boot` `Vue.js` `Oracle`

- 15개 이상 기능 개발 (SMS, 콜백, 캠페인 관리, 접속 로그)
- 첫 실무 프로젝트 — Spring CRUD, DB 설계, Git 협업, QA 프로세스 경험

---

## 기술 스택

**Backend**: Java 21, Spring Boot, JPA, MyBatis, MySQL, Redis
**Frontend**: React, TypeScript, TanStack (Query/Router/Table), Tailwind CSS, shadcn/ui
**DevOps**: Docker, Nginx, GitHub Actions, GitLab CI/CD
**Architecture**: CQRS, Multi-tenant, RBAC, DDD

---

## 학습과 성장

- 6권 이상 기술 서적 학습 및 실전 적용 — Real MySQL 8.0 → LinkWave 파티셔닝, TanStack → Perf Script Pipeline 가상화
- PARA 방법론 기반 Obsidian vault로 체계적 지식 관리
- 매일 KPT 회고 작성, 지속적 개선
