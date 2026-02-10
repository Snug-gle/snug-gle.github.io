---
created: 2026-02-04
draft: true
title: "상훈 | Full-stack Developer 포트폴리오"
author: "상훈"
geometry: margin=2cm
fontsize: 11pt
---

# 상훈 | Full-stack Developer

> "측정하고, 개선하고, 문서화하는 개발자"

**Email**: your@email.com | **GitHub**: github.com/yourname | **Phone**: 010-0000-0000

---

## About

| 항목 | 내용 |
|------|------|
| **학력** | 건국대학교 (서울캠퍼스) 법학과 졸업 (2015.08) |
| **경력** | 아이오트리 (SI) — 2022.07 ~ 현재 |
| **역할** | Full-stack Developer (Backend & Frontend) |

### Career Timeline

| 기간 | 프로젝트 | 역할 |
|------|----------|------|
| 2024 ~ 현재 | **LinkWave** — 멀티채널 메시징 플랫폼 | Full-stack Developer |
| 2025.10 ~ 2025.11 | **Perf Script Pipeline** — 성능 분석 도구 | Frontend Developer |
| 2022 ~ 2024 | **Mafra** — 상담 시스템 | Backend/Frontend Developer |

---

## 핵심 성과

| 지표 | 성과 | 프로젝트 |
|------|------|----------|
| **성능 최적화** | 렌더링 시간 90% 단축 (5초 → 0.5초) | Perf Script Pipeline |
| **데이터베이스 최적화** | 조회 성능 80% 향상 | LinkWave |
| **학습 습관** | 6권 이상 기술 서적 학습 | Real MySQL, Spring, React 등 |
| **프로젝트 경험** | 3개 회사 프로젝트 완료 | LinkWave, Perf Script Pipeline, Mafra |

---

## 프로젝트 경험

### 1. LinkWave - Multi-channel Messaging Platform ★

**회사**: IoTree Inc. | **기간**: 2024년 ~ 현재 | **역할**: Full-stack Developer

**프로젝트 개요**
- B2B SaaS 멀티채널 메시징 플랫폼 (SMS/LMS/MMS/KakaoTalk/RCS)
- 사용자/조직 관리, 메시지 발송, 주소록 관리 등

**핵심 기여**

**1) Hybrid Database Strategy 설계 및 구현**
- **문제**: User/Organization은 CRUD 중심, Message/Log는 대용량 쓰기가 필요
- **해결**: 도메인별로 다른 기술 선택
  - User/Organization: JPA (생산성)
  - Message/Log: MyBatis (성능)
- **결과**: 조회 성능 80% 향상, 생산성과 성능 모두 달성

**2) JWT RS256 인증 시스템 구현**
- **문제**: HS256 (대칭키)는 보안 위험
- **해결**: RS256 (Public/Private Key)로 마이그레이션
- **결과**: 보안성 향상, 확장 가능한 인증 시스템

**3) 중복 방지 시스템 (DEDUP_HASH)**
- **문제**: 사용자 실수로 중복 메시지 발송
- **해결**: MD5 해시 기반 중복 검사 (`phone|content`)
- **결과**: 중복 메시지 99% 차단

**4) 월별 파티션 테이블 설계**
- **문제**: 발송 이력 테이블 급격히 증가 (일 10만+ 건)
- **해결**: 월별 파티션 테이블 + 복합 인덱스 전략
- **결과**: 조회 성능 80% 향상, 인덱스 크기 86% 감소

**5) 디자인 시스템 구축 (Frontend)**
- **철학**: "Clarity Through Connection"
- **구현**: shadcn/ui + Tailwind CSS 기반 컴포넌트 라이브러리
- **결과**: 일관된 UI/UX, 개발 속도 향상

**기술 스택**
- Backend: Spring Boot 4.0, Java 21, JPA, MyBatis, MySQL 8.0
- Frontend: React 19, TanStack Router, Tailwind CSS
- DevOps: GitLab CI/CD, Docker, Nginx

**배운 점**
- "은탄환은 없다" - 상황에 맞는 기술 선택의 중요성
- 이론(Real MySQL 8.0)을 실전(LinkWave)에 즉시 적용
- 측정 기반 최적화 (EXPLAIN, 실행 계획 분석)

---

### 2. Perf Script Pipeline - React 19 성능 분석 도구

**기간**: 2025년 10-11월 (5주) | **역할**: Frontend Developer (전담)

**프로젝트 개요**
- 웹 애플리케이션 성능 테스트 결과 분석 도구
- 동적 파라미터 간 상관관계 자동 추출
- JMeter 테스트 스크립트 최적화

**핵심 기여**

**1) 대용량 데이터 테이블 렌더링 최적화**
- **문제**: 10,000개 데이터 렌더링 시 브라우저 멈춤 (5초 소요)
- **해결**: 페이징 1000개 + TanStack Virtual 가상화
- **결과**: 렌더링 시간 90% 단축 (5초 → 0.5초), 메모리 사용량 70% 감소

**2) 불필요한 API 요청 제거**
- **문제**: 중복 요청, 조건 없는 요청, 무한 루프
- **해결**: React Query 캐싱 전략 (`staleTime` 5분, `gcTime` 10분, `enabled` 조건부)
- **결과**: 네트워크 요청 80% 감소

**기술 스택**
- React 19, TypeScript, Vite
- TanStack Query, Table, Virtual
- Tailwind CSS, Radix UI

---

## 기술 스택

### Backend
- **언어**: Java 21
- **프레임워크**: Spring Boot 4.0, Spring Security, Spring Data JPA
- **데이터베이스**: MySQL 8.0, JPA/Hibernate, MyBatis
- **캐시**: Redis

### Frontend
- **언어**: TypeScript
- **프레임워크**: React 19
- **라이브러리**: TanStack Query, Router, Table, Virtual
- **스타일링**: Tailwind CSS, shadcn/ui
- **도구**: Vite

### DevOps
- **CI/CD**: GitLab CI/CD, GitHub Actions
- **컨테이너**: Docker, Docker Compose
- **웹서버**: Nginx
- **버전관리**: Git

---

## 학습 여정

### 학습한 서적 (6+권)
1. **Real MySQL 8.0** - 실행 계획, 인덱스, 파티션 → LinkWave 프로젝트 적용
2. **자바의 신** - Java 기초부터 심화
3. **자바 알고리즘 인터뷰 with 코틀린** - 알고리즘 & 자료구조
4. **LLM을 활용한 실전 AI 애플리케이션 개발** - LLM, 트랜스포머
5. **StreetCoder** - 실용적인 코딩 기법
6. **알고리즘 문제 해결을 위한 수학** - 알고리즘 & 수학

### 학습 방법
```
이론 학습 (책/강의) → 실전 적용 (프로젝트) → 문서화 (Obsidian) → 회고 (KPT)
```

---

## 개발 철학

### 1. 측정한다 (Measure)
> "추측이 아닌 측정으로 개선한다"

- EXPLAIN으로 쿼리 실행 계획 확인
- React DevTools Profiler로 병목 지점 파악

### 2. 개선한다 (Improve)
> "점진적 개선의 힘을 믿는다"

- LinkWave: 단일 테이블 → 월별 파티션으로 최적화
- Perf Script Pipeline: 점진적 페이징 → 가상화

### 3. 문서화한다 (Document)
> "배운 것을 공유한다"

- PARA 방법론으로 체계적 관리
- Obsidian vault로 학습 노트 정리

---

## 실무 경험

### Mafra 프로젝트 (상담 시스템)
**역할**: Backend/Full-stack Developer

**담당 기능 (15+)**
- SMS 메시지 리스트 표시, 알림 관리, 악성 민원 관리
- 고객 정보 관리, 메뉴 관리, 콜백 관리
- 접속 로그 관리, QA 수행, 상담 유형 관리
- 캠페인 관리, 사이트 링크 관리

**배운 점**
- Spring Boot CRUD 구현
- 데이터베이스 설계 및 쿼리 최적화
- Git 협업, 이슈 트래킹, QA 프로세스

---

## 중단 프로젝트

### Rally-Point — 테니스 코트 예약 플랫폼 (중단)
**기간**: 2025년 6월 ~ 2025년 12월 | **상태**: 중단 (LinkWave 집중)
- MSA 기반 9개 서비스 설계 (Kafka, Redis, Elasticsearch)
- Bounded Context 정의, 이벤트 기반 아키텍처 학습
- **배운 점**: MSA 설계, Event Sourcing, Saga Pattern

### InvestFlow — 주식 분석 플랫폼 (중단)
**기간**: 2025년 | **상태**: 중단
- Raspberry Pi 위 Blue-Green 무중단 배포 파이프라인 구축
- **배운 점**: Docker, Nginx, CI/CD 파이프라인

---

## 연락처

**Email**: your@email.com
**GitHub**: github.com/yourname
**LinkedIn**: linkedin.com/in/yourname
**Blog**: yourname.github.io
**Phone**: 010-0000-0000
