---
created: 2026-01-22
title: 개발자 포트폴리오
---
# 개발 여정

> 측정하고, 개선하고, 문서화하는 개발자

더 나은 서비스를 만들어 사용자에게 가치를 전달하는 것에서 보람을 느끼며, [[Why Developer|업계의 Best Practice를 학습하고 적용하는 것]]을 커리어 방향의 지표로 삼고 있습니다.

---

## 시작 — CRUD에서 시스템으로

2022년 SI 업체에서 개발자 커리어를 시작했습니다. 첫 프로젝트인 **Mafra**(상담 시스템)에서 15개 이상의 기능 모듈을 개발하며 Spring Boot와 데이터베이스 설계의 기초를 다졌습니다. 고객 정보 관리, 캠페인, 알림 등 다양한 도메인을 경험하면서 "CRUD를 넘어 시스템을 이해하는 것"의 중요성을 체감했습니다.

## 전환점 — 성능이라는 과제

[[performance-tester/README|Performance Tester]] 프로젝트(2025.10~11, 5주)에서 프론트엔드를 전담하면서 전환점을 맞았습니다. 10,000건 이상의 데이터를 브라우저에서 렌더링해야 하는 문제를 만났고, 가상 스크롤링으로 **렌더링 시간을 90% 단축**, React Query 캐싱으로 **API 요청을 80% 감소**시켰습니다.

이 경험을 통해 "추측이 아닌 측정으로 개선한다"는 원칙을 세웠고, React + TypeScript + TanStack 생태계에 대한 실전 역량을 갖추게 됐습니다.

## 현재 — 아키텍처를 설계하는 개발자

현재 집중하고 있는 [[linkwave-project-summary|LinkWave]]는 엔터프라이즈급 멀티채널 메시징 플랫폼입니다. 이 프로젝트에서 **설계부터 구현까지** 전 과정을 주도하고 있습니다.

**풀어낸 기술적 과제들:**
- **하이브리드 ORM** — User 도메인은 JPA, Message 도메인은 MyBatis로 분리하여 CRUD 생산성과 대량 처리 성능을 동시에 달성 (CQRS)
- **JWT + RTR 인증** — Refresh Token Rotation으로 토큰 재사용 공격 방지, Redis 기반 일회용 토큰 관리
- **월별 파티션 테이블** — 수억 건 메시지 로그를 월별로 분리하여 조회 성능 80% 향상, 인덱스 크기 86% 감소
- **멀티테넌트 + RBAC** — 조직별 데이터 격리와 역할 기반 접근 제어

Real MySQL 8.0에서 학습한 실행 계획 분석과 인덱스 전략을 실전에 바로 적용한 프로젝트이기도 합니다.

## 다음 단계 — MSA와 분산 시스템

개인 프로젝트 [[rally-point/architecture|Rally-Point]]에서는 한 단계 더 나아가 MSA 아키텍처를 설계하고 있습니다. Kafka 이벤트 기반 통신, Redis 분산 락, Elasticsearch 검색 등 분산 시스템의 핵심 기술들을 직접 다루고 있습니다.

[[investFlow/README|InvestFlow]]에서는 Raspberry Pi 위에 Blue-Green 무중단 배포 파이프라인을 구축하며 DevOps 역량도 넓혀가고 있습니다.

---

## 기술 스택

**Backend**: Java 21, Spring Boot, JPA, MyBatis, MySQL, Redis
**Frontend**: React, TypeScript, TanStack (Router, Query, Table, Virtual), Tailwind CSS
**DevOps**: Docker, Nginx, GitHub Actions, GitLab CI/CD
**Architecture**: CQRS, MSA, Multi-tenant, RBAC, DDD

---

## 학습 기록

이론을 학습하고, 프로젝트에 적용하고, 문서로 남기는 사이클을 반복하고 있습니다.

- [[RealMySQL 8.0/RealMySQL 8.0|Real MySQL 8.0]] — 실행 계획, 인덱스 최적화 → LinkWave 파티션 설계에 적용
- [[자바 알고리즘 인터뷰 with 코틀린/Index|알고리즘 인터뷰]] — 자료구조, 정렬, 그래프, DP
- [[LLM을 활용한 실전 AI 애플리케이션 개발/Index|LLM 애플리케이션 개발]] — Transformers, Embeddings → Performance Tester AI 기능에 적용
