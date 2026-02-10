---
tags:
  - project
  - rally-point
  - planning
  - msa
  - event-driven
  - roadmap
category: project
status: in-progress
created: 2025-11-16
modified: 2025-11-16
---
# 🎾 RallyPoint 주별 개발 계획

## 프로젝트 현황 분석

### 현재 구현 상태
- **구현 완료**: User Service 기본 기능 (회원가입, JWT 인증, OAuth2 Kakao)
- **프로젝트 규모**: Java 파일 32개 (초기 단계)
- **아키텍처**: MSA 설계 완료, 단일 서비스만 구현됨
- **인프라**: Kafka, Redis, Spring Batch 설계만 완료

### 핵심 비즈니스 요구사항
1. **테니스장 예약 시스템** (Court Service)
   - 실시간 예약 현황 조회
   - 예약 생성/취소
   - 동시 예약 방지 (분산 락)
   - 대기열 관리

2. **매치 중계 시스템** (Match Service)
   - 실시간 매치 생성
   - 사용자 매칭
   - 매치 결과 기록
   - 통계 및 랭킹

3. **MSA 및 이벤트 주도 아키텍처**
   - 서비스 간 느슨한 결합
   - Kafka 기반 이벤트 전파
   - Redis 캐싱 및 세션 관리
   - API Gateway 및 서비스 디스커버리

---

## 📅 주차별 개발 계획 (14주)

> **언어 전략**: 핵심 비즈니스 서비스는 Java로 개발, 부가 서비스(Batch, Search)만 Kotlin 학습 겸 개발
> **개발 순서**: User → Gateway → Court → Notification → Match → Batch/Search (도메인 의존성 및 통합 환경 우선 고려)

### Week 1-2: User Service 완성 + 인프라 구축

#### Week 1 (2025-11-18 ~ 2025-11-24)
**목표**: User Service 핵심 기능 완성

- [ ] **User Service 개발**
  - [ ] JWT Refresh Token 구현
  - [ ] 이메일 인증 프로세스 (AWS SES 연동)
  - [ ] 프로필 확장 (테니스 경력, NTRP 레벨, 프로필 사진)
  - [ ] MSA 내부 API 개발 (`/internal/users/{userId}/verify`)

- [ ] **테스트 강화**
  - [ ] 통합 테스트 작성
  - [ ] 테스트 커버리지 80% 달성

- [ ] **문서화**
  - [ ] Swagger/OpenAPI 설정
  - [ ] API 문서 자동 생성

**학습 목표**:
- Spring Security 심화 (JWT, OAuth2)
- MapStruct 활용 패턴
- 레이어드 아키텍처 실습

#### Week 2 (2025-11-25 ~ 2025-12-01)
**목표**: 로컬 개발 인프라 구축

- [ ] **Docker Compose 환경 구축**
  - [ ] MySQL 컨테이너 설정
  - [ ] Redis 컨테이너 설정
  - [ ] Kafka + Zookeeper 설정
  - [ ] 개발 환경 통합 스크립트

- [ ] **CI/CD 파이프라인**
  - [ ] GitHub Actions 설정
  - [ ] 자동 빌드 및 테스트
  - [ ] 코드 품질 검사 (SonarQube/Checkstyle)

- [ ] **모니터링 준비**
  - [ ] Spring Boot Actuator 설정
  - [ ] 로깅 전략 수립 (Logback)
  - [ ] 메트릭 수집 준비 (Prometheus 호환)

**학습 목표**:
- Docker & Docker Compose
- CI/CD 기본 개념
- 운영 환경 설정 패턴

---

### Week 3-4: Gateway Service 구축 (MSA 통합 환경)

#### Week 3 (2025-12-02 ~ 2025-12-08)
**목표**: API Gateway 기본 구조 및 라우팅 설정

- [ ] **Gateway Service 프로젝트 생성 (Java)**
  - [ ] Spring Cloud Gateway 의존성 추가
  - [ ] 기본 프로젝트 구조 설정
  - [ ] 포트 설정 (8080)

- [ ] **기본 라우팅 설정**
  - [ ] User Service 라우팅 (`/api/v1/users/**`, `/api/v1/auth/**`)
  - [ ] Health Check 엔드포인트
  - [ ] CORS 설정

- [ ] **공통 필터 구현**
  - [ ] 요청/응답 로깅 필터
  - [ ] Global Exception Handler
  - [ ] Request ID 생성 필터

**학습 목표**:
- Spring Cloud Gateway 기본
- Reactive Programming 개념
- Gateway Filter 체인

#### Week 4 (2025-12-09 ~ 2025-12-15)
**목표**: 인증/인가 통합 및 고급 라우팅

- [ ] **JWT 인증 통합**
  - [ ] Gateway에서 JWT 토큰 검증
  - [ ] User Service 연동 (토큰 검증 API)
  - [ ] Authorization Header 전파

- [ ] **고급 라우팅**
  - [ ] Path Rewriting
  - [ ] Rate Limiting (Redis 기반)
  - [ ] Circuit Breaker 기본 설정

- [ ] **서비스 라우팅 추가 (Stub)**
  - [ ] Court Service 라우팅 준비
  - [ ] Match Service 라우팅 준비
  - [ ] 라우팅 테스트

**학습 목표**:
- JWT 검증 Flow
- Rate Limiting 패턴
- Circuit Breaker 기초

---

### Week 5-6: Court Service 개발 (예약 시스템 핵심)

#### Week 5 (2025-12-16 ~ 2025-12-22)
**목표**: Court Service 기본 구조 및 도메인 모델 (Java)

- [ ] **Court Service 프로젝트 생성 (Java)**
  - [ ] Spring Boot 3.3+ 프로젝트 생성
  - [ ] MySQL, Redis 연동
  - [ ] Gateway 라우팅 연결 테스트
  - [ ] 포트 설정 (9091)

- [ ] **도메인 모델링**
  - [ ] Court 엔티티 (테니스장 정보)
  - [ ] Reservation 엔티티 (예약 정보)
  - [ ] TimeSlot VO (시간대 관리)
  - [ ] 엔티티 관계 설정 (JPA)

- [ ] **기본 CRUD API**
  - [ ] 테니스장 등록/조회/수정/삭제
  - [ ] 예약 가능 시간대 조회
  - [ ] 예약 현황 조회
  - [ ] Swagger 문서 생성

**학습 목표**:
- DDD (Domain-Driven Design) 기본
- JPA 엔티티 설계 패턴
- RESTful API 설계

#### Week 6 (2025-12-23 ~ 2025-12-29)
**목표**: 예약 비즈니스 로직 및 Redis 분산 락

- [ ] **예약 시스템 개발**
  - [ ] 예약 생성 API (동시성 제어 포함)
  - [ ] 예약 취소 API
  - [ ] 예약 검증 로직 (중복 방지, 시간 검증)
  - [ ] 예약 가능 여부 확인

- [ ] **Redis 분산 락 구현**
  - [ ] Redisson 의존성 추가
  - [ ] 동시 예약 방지 락 (`lock:reservation:{date}:{time}:{courtId}`)
  - [ ] 락 타임아웃 및 재시도 전략
  - [ ] 동시성 테스트 (JMeter 또는 Gatling)

- [ ] **Redis 캐싱 적용**
  - [ ] 예약 현황 캐싱 (`court:{courtId}:reservations`)
  - [ ] TTL 관리
  - [ ] 캐시 무효화 전략

**학습 목표**:
- Redis 분산 락 (Redisson)
- 동시성 제어 패턴
- 캐싱 전략 (Cache-Aside Pattern)

---

### Week 7-8: Kafka + Notification Service (이벤트 주도 아키텍처)

#### Week 7 (2025-12-30 ~ 2026-01-05)
**목표**: Kafka 인프라 구축 및 기본 이벤트 흐름

- [ ] **Kafka 환경 구축**
  - [ ] Docker Compose에 Kafka + Zookeeper 추가
  - [ ] Kafka UI 도구 설치 (Conduktor 또는 Kafdrop)
  - [ ] Topic 생성 (`reservation-events`, `user-events`)

- [ ] **Court Service에 Kafka Producer 추가**
  - [ ] Spring Kafka 의존성 추가
  - [ ] Producer 설정 (application.yml)
  - [ ] 예약 이벤트 발행 (`RESERVATION_CREATED`, `RESERVATION_CANCELLED`)
  - [ ] 이벤트 스키마 정의 (JSON)

- [ ] **User Service에 Kafka Producer 추가**
  - [ ] 회원가입 이벤트 발행
  - [ ] 회원 정보 변경 이벤트

**학습 목표**:
- Kafka 기본 개념 (Producer, Consumer, Topic, Partition)
- 이벤트 주도 아키텍처 (Event-Driven Architecture)
- 이벤트 스키마 설계

**추천 학습 리소스**:
- 📚 "Kafka: The Definitive Guide" 1-4장
- 🎥 Confluent Kafka 튜토리얼
- 📝 Martin Fowler - Event-Driven Architecture

#### Week 8 (2026-01-06 ~ 2026-01-12)
**목표**: Notification Service 개발 및 신뢰성 강화

- [ ] **Notification Service 개발 (Java)**
  - [ ] 프로젝트 생성 (Spring Boot)
  - [ ] Kafka Consumer 구현
  - [ ] 이벤트 타입별 처리 로직
  - [ ] 알림 이력 저장 (MySQL)

- [ ] **알림 전송 구현 (Stub)**
  - [ ] 이메일 알림 (로그 출력 또는 SendGrid)
  - [ ] SMS 알림 (로그 출력 또는 Twilio)
  - [ ] 알림 템플릿 관리

- [ ] **이벤트 처리 신뢰성**
  - [ ] At-least-once 처리 보장
  - [ ] Idempotent Consumer 구현 (중복 처리 방지)
  - [ ] Dead Letter Queue (DLQ) 설정
  - [ ] 재시도 전략 (Retry Template)

**학습 목표**:
- Kafka Consumer 구현
- Idempotency 패턴
- 분산 시스템 장애 처리

---

### Week 9-10: Match Service 개발 (매칭 및 실시간 중계)

#### Week 9 (2026-01-13 ~ 2026-01-19)
**목표**: Match Service 기본 개발 (Java)

- [ ] **Match Service 개발 (Java)**
  - [ ] 프로젝트 생성 (Spring Boot)
  - [ ] Match 엔티티 설계
  - [ ] MatchParticipant 엔티티 (참가자 관리)
  - [ ] 매치 생성 API
  - [ ] 매치 조회 API
  - [ ] Gateway 라우팅 연결

- [ ] **User Service 연동**
  - [ ] OpenFeign 의존성 추가
  - [ ] User 검증 API 호출
  - [ ] Circuit Breaker 적용 (Resilience4j)
  - [ ] Fallback 전략 구현

- [ ] **Court Service 연동**
  - [ ] 예약 정보 조회 (OpenFeign)
  - [ ] 예약-매치 연계

**학습 목표**:
- OpenFeign을 통한 서비스 간 통신
- Circuit Breaker 패턴
- Fallback 전략

**추천 학습 리소스**:
- 📝 Spring Cloud OpenFeign
- 📚 "Release It!" (Michael Nygard)
- 📝 Resilience4j Documentation

#### Week 10 (2026-01-20 ~ 2026-01-26)
**목표**: WebSocket 실시간 중계 및 Kafka 통합

- [ ] **WebSocket 설정**
  - [ ] Spring WebSocket 의존성 추가
  - [ ] STOMP 프로토콜 설정
  - [ ] WebSocket 엔드포인트 (`/ws`)
  - [ ] 메시지 브로커 구성

- [ ] **실시간 스코어 중계**
  - [ ] 매치 상태 업데이트 API
  - [ ] 스코어 업데이트 로직
  - [ ] WebSocket 메시지 브로드캐스트
  - [ ] 클라이언트 테스트 (Postman/웹 클라이언트)

- [ ] **Kafka 이벤트 통합**
  - [ ] 매치 이벤트 발행 (`MATCH_CREATED`, `MATCH_FINISHED`)
  - [ ] Notification Service 연동 (알림 전송)
  - [ ] 매치 통계 업데이트

**학습 목표**:
- WebSocket & STOMP
- 실시간 통신 패턴
- WebSocket + Kafka 통합

---

### Week 11: Kotlin 기초 학습 및 준비

#### Week 11 (2026-01-27 ~ 2026-02-02)
**목표**: Kotlin 기초 학습 및 Spring Boot와의 통합

- [ ] **Kotlin 기초 문법**
  - [ ] 변수 선언 (val, var)
  - [ ] 함수 정의
  - [ ] 클래스 및 데이터 클래스
  - [ ] Null Safety
  - [ ] 확장 함수 (Extension Functions)

- [ ] **Kotlin + Spring Boot**
  - [ ] Spring Boot Kotlin 프로젝트 생성
  - [ ] JPA Entity with Kotlin
  - [ ] Service & Controller with Kotlin
  - [ ] 간단한 CRUD API 구현

- [ ] **실습 프로젝트**
  - [ ] Todo API (Kotlin으로 구현)
  - [ ] MySQL 연동
  - [ ] 기본 테스트 작성

**학습 목표**:
- Kotlin 기본 문법
- Kotlin과 Java의 차이점
- Kotlin + Spring Boot 프로젝트 구조

**추천 학습 리소스**:
- 📚 "Kotlin in Action"
- 🎥 Kotlin Bootcamp for Programmers (Udacity)
- 📝 Spring Boot with Kotlin Tutorial
- 📝 Baeldung - Kotlin with Spring

---

### Week 12-13: Batch Service 개발 (Kotlin 실전 적용)

#### Week 12 (2026-02-03 ~ 2026-02-09)
**목표**: Spring Batch 기본 및 Kotlin 적용

- [ ] **Batch Service 개발 (Kotlin)**
  - [ ] Spring Batch 프로젝트 생성 (Kotlin)
  - [ ] 기본 Job/Step 구조 이해
  - [ ] ItemReader, ItemProcessor, ItemWriter
  - [ ] Job 파라미터 및 실행 관리

- [ ] **만료 예약 정리 Job**
  - [ ] Court Service DB 연동
  - [ ] 만료된 예약 조회
  - [ ] 상태 업데이트 로직
  - [ ] 스케줄링 설정 (매일 자정)

- [ ] **대기열 처리 Job**
  - [ ] Redis 대기열 조회
  - [ ] 예약 가능한 슬롯 확인
  - [ ] 자동 예약 배정
  - [ ] 스케줄링 설정 (10분마다)

**학습 목표**:
- Spring Batch 기본 개념
- Kotlin으로 Batch 작성
- Chunk-oriented Processing

**추천 학습 리소스**:
- 📚 "Spring Batch in Action"
- 📝 Spring Batch Documentation
- 🎥 Spring Batch Tutorial

#### Week 13 (2026-02-10 ~ 2026-02-16)
**목표**: 통계 보고서 및 Kafka 통합

- [ ] **통계 보고서 생성 Job**
  - [ ] 일별/주별/월별 예약 통계
  - [ ] 사용자 활동 통계
  - [ ] 매치 결과 집계
  - [ ] 스케줄링 설정 (매주 월요일)

- [ ] **Kafka 이벤트 기반 배치**
  - [ ] Kafka Consumer로 이벤트 수집
  - [ ] 배치 처리 트리거
  - [ ] 처리 결과 이벤트 발행

- [ ] **배치 모니터링**
  - [ ] Spring Batch Admin (또는 대시보드)
  - [ ] Job 실행 이력 관리
  - [ ] 실패 알림

**학습 목표**:
- 복잡한 배치 Job 설계
- Kafka + Spring Batch 통합
- 배치 모니터링

---

### Week 14: Search Service 및 통합 테스트

#### Week 14 (2026-02-17 ~ 2026-02-23)
**목표**: Elasticsearch 기반 검색 및 전체 통합

- [ ] **Search Service 개발 (Kotlin)**
  - [ ] Elasticsearch 연동 (Spring Data Elasticsearch)
  - [ ] 인덱스 정의 (Courts, Reservations, Users)
  - [ ] 검색 API 구현
  - [ ] Gateway 라우팅 연결

- [ ] **Kafka → Elasticsearch 파이프라인**
  - [ ] Kafka Consumer 구현
  - [ ] 이벤트 → 인덱스 매핑
  - [ ] 실시간 색인 업데이트

- [ ] **통합 테스트 및 최적화**
  - [ ] End-to-End 시나리오 테스트
  - [ ] 성능 테스트 (JMeter/Gatling)
  - [ ] Redis 캐싱 전략 재검토
  - [ ] 데이터베이스 인덱스 최적화

- [ ] **모니터링 및 문서화**
  - [ ] ELK 스택 설정 (로그 수집)
  - [ ] Prometheus + Grafana (메트릭 수집)
  - [ ] 아키텍처 다이어그램 업데이트
  - [ ] API 문서 통합 (Swagger)

**학습 목표**:
- Elasticsearch 검색 쿼리
- 통합 테스트 전략
- 성능 최적화

---

## 🎯 학습 로드맵: MSA 및 이벤트 주도 아키텍처

### 1단계: 기초 개념 (Week 1-2)
**필수 개념**:
- Microservices Architecture 기본 원칙
- Domain-Driven Design (DDD) 기초
- API Gateway 패턴
- Service Discovery

**추천 리소스**:
- 📚 **"Building Microservices" (Sam Newman)**
  - 1-3장: MSA 기본 개념
  - 4장: 서비스 간 통신
  - 7장: 분산 시스템의 장애 처리

- 📝 **Martin Fowler - Microservices**
  - https://martinfowler.com/articles/microservices.html

- 🎥 **YouTube: "Microservices Explained in 5 Minutes"**

### 2단계: 이벤트 주도 아키텍처 (Week 3-6)
**필수 개념**:
- Event-Driven Architecture (EDA)
- Event Sourcing vs Event Streaming
- Kafka 아키텍처 (Producer, Consumer, Topic, Partition)
- 메시지 신뢰성 (At-least-once, Exactly-once)

**추천 리소스**:
- 📚 **"Kafka: The Definitive Guide"**
  - 1-2장: Kafka 소개
  - 3-4장: Producer & Consumer
  - 6장: 신뢰성 보장

- 📚 **"Designing Data-Intensive Applications" (Martin Kleppmann)**
  - 11장: Stream Processing
  - 12장: The Future of Data Systems

- 📝 **Confluent Kafka Tutorials**
  - https://kafka.apache.org/quickstart

- 🎥 **Udemy/Coursera: Apache Kafka 강의**

### 3단계: 분산 시스템 패턴 (Week 7-10)
**필수 개념**:
- Circuit Breaker
- Saga Pattern
- CQRS (Command Query Responsibility Segregation)
- Event Sourcing
- 분산 트랜잭션 (2PC, Saga)
- CAP 정리

**추천 리소스**:
- 📚 **"Microservices Patterns" (Chris Richardson)**
  - 4장: Saga Pattern
  - 6장: 비즈니스 로직 설계
  - 7장: 데이터 관리

- 📚 **"Release It!" (Michael Nygard)**
  - Circuit Breaker, Bulkhead 패턴

- 📝 **Microsoft Azure - Cloud Design Patterns**
  - https://learn.microsoft.com/en-us/azure/architecture/patterns/

- 📝 **AWS - Distributed Systems Best Practices**

### 4단계: 고급 주제 (Week 11-12)
**필수 개념**:
- 분산 추적 (Distributed Tracing)
- 서비스 메시 (Service Mesh)
- Observability (Metrics, Logs, Traces)
- 성능 최적화 및 확장성

**추천 리소스**:
- 📚 **"The Art of Scalability"**
- 📝 **OpenTelemetry Documentation**
- 📝 **Istio Service Mesh Tutorial**
- 🎥 **CNCF YouTube Channel - Observability**

---

## 📊 주차별 학습 체크리스트

| Week | 핵심 개념 | 실습 과제 | 학습 리소스 | 언어 |
|------|-----------|-----------|-------------|------|
| 1-2 | MSA 기초, DDD, Docker Compose | User Service 완성 + 인프라 | "Building Microservices" 1-3장 | Java |
| 3-4 | Spring Cloud Gateway, Reactive | Gateway 구축 | Spring Cloud Gateway Docs | Java |
| 5-6 | Redis 분산 락, 캐싱 | Court Service + Redis | Redis Documentation | Java |
| 7-8 | Kafka, EDA, Idempotency | Kafka + Notification Service | "Kafka: The Definitive Guide" 1-4장 | Java |
| 9-10 | OpenFeign, Circuit Breaker, WebSocket | Match Service + 실시간 중계 | "Release It!" | Java |
| 11 | **Kotlin 기초 문법** | Todo API (Kotlin) | "Kotlin in Action" | **Kotlin** |
| 12-13 | Spring Batch, Kotlin 실전 | Batch Service (Kotlin) | Spring Batch Documentation | **Kotlin** |
| 14 | Elasticsearch, 통합 테스트 | Search Service + 최적화 | Elasticsearch Guide | **Kotlin** |

---

## 🔧 기술 스택 상세

### Backend Services
- **User Service**: Java 21, Spring Boot 3.3.3, MySQL
- **Court Service**: Kotlin, Spring Boot, MySQL, Redis
- **Match Service**: Kotlin, Spring Boot, MySQL, WebSocket
- **Notification Service**: Java, Spring Boot, Kafka Consumer
- **Batch Service**: Kotlin, Spring Batch
- **Search Service**: Kotlin, Elasticsearch
- **Gateway Service**: Java, Spring Cloud Gateway

### Infrastructure
- **Message Broker**: Apache Kafka
- **Cache & Session**: Redis (Redisson)
- **Search Engine**: Elasticsearch
- **Database**: MySQL 8.0
- **Container**: Docker, Docker Compose
- **CI/CD**: GitHub Actions

### Monitoring & Logging
- **Logging**: Logback, ELK Stack
- **Metrics**: Spring Boot Actuator, Prometheus (예정)
- **Tracing**: Spring Cloud Sleuth
- **Dashboard**: Kibana, Grafana (예정)

---

## 🚀 다음 단계 (Phase 2)

### 13-16주: 고급 기능 및 운영 최적화
- Market Service 개발 (중고 거래)
- Bid Service 개발 (입찰 시스템)
- Redis Streams 도입
- Kubernetes 배포
- Service Mesh (Istio) 도입
- Observability 고도화

### 17-20주: AI 및 추천 시스템
- AI 기반 매칭 추천
- 사용자 행동 분석
- 개인화된 알림
- 예측 분석 (혼잡 시간 예측)

---

## 📝 개발 일지 및 회고

각 주차가 끝날 때마다 다음 질문에 답하며 회고하세요:

1. **이번 주에 달성한 것은?**
2. **새롭게 학습한 개념은?**
3. **어려웠던 점과 해결 방법은?**
4. **다음 주 목표는?**
5. **아키텍처/설계 관련 배운 점은?**

회고는 `/area/log/` 디렉토리에 주차별로 기록하세요.

---

**작성일**: 2025-11-16
**작성자**: Claude Code
**상태**: v1.0
