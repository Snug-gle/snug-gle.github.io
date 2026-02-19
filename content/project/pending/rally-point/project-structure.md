---
created: 2026-02-09
---
---
tags:
  - project
  - rally-point
  - msa
  - architecture
  - structure
category: project
status: in-progress
created: 2025-11-16
modified: 2025-11-16
---
# 🏗️ RallyPoint 프로젝트 구조

## 프로젝트 개요

RallyPoint는 MSA 아키텍처로 설계된 테니스 코트 예약 및 매칭 플랫폼입니다. 각 도메인은 독립적인 프로젝트로 관리되며, 서로 느슨하게 결합되어 있습니다.

---

## 📁 프로젝트 디렉토리 구조

```
~/Project/IdeaProjects/
├── rallypoint-plus-user/          # ✅ 현재 구현 중 (Java)
├── rallypoint-plus-court/         # 📋 Week 3-4에 생성 예정 (Kotlin)
├── rallypoint-plus-match/         # 📋 Week 7-8에 생성 예정 (Kotlin)
├── rallypoint-plus-notification/  # 📋 Week 5-6에 생성 예정 (Java)
├── rallypoint-plus-gateway/       # 📋 Week 9에 생성 예정 (Java)
├── rallypoint-plus-batch/         # 📋 Week 11에 생성 예정 (Kotlin)
├── rallypoint-plus-search/        # 📋 Week 11에 생성 예정 (Kotlin)
└── rallypoint-plus-common/        # 📋 Week 2에 생성 예정 (Java/Kotlin 공통)
```

---

## 🎯 서비스별 상세 정보

### 1. rallypoint-plus-user (User Service)
**현재 상태**: ✅ 개발 중

**책임**:
- 회원가입, 로그인, 인증/인가
- 사용자 프로필 관리
- OAuth2 소셜 로그인
- JWT 토큰 발급 및 검증
- MSA 내부 사용자 검증 API

**기술 스택**:
- Language: Java 21
- Framework: Spring Boot 3.3.3
- Database: MySQL
- Security: Spring Security, JWT, OAuth2
- Build: Gradle (Kotlin DSL)

**프로젝트 경로**: `/Users/sanghoon/Project/IdeaProjects/rallypoint-plus-user`

**주요 API**:
```
POST   /api/v1/users/sign-up
POST   /api/v1/auth/login
GET    /api/v1/auth/me
POST   /api/v1/auth/refresh
GET    /internal/users/{userId}/verify
```

**데이터베이스 테이블**:
- `users`
- `user_profiles`
- `user_credentials`

---

### 2. rallypoint-plus-gateway (Gateway Service)
**현재 상태**: 📋 Week 3-4에 생성 예정

**책임**:
- 요청 라우팅
- 인증/인가 통합 (JWT 검증)
- Rate Limiting
- CORS 설정
- Request/Response 로깅

**기술 스택**:
- Language: Java 21
- Framework: Spring Cloud Gateway
- Cache: Redis (Rate Limiting)
- Build: Gradle (Kotlin DSL)

**프로젝트 경로**: `/Users/sanghoon/Project/IdeaProjects/rallypoint-plus-gateway` (생성 예정)

**주요 라우팅**:
```yaml
/api/v1/users/** → User Service (9090)
/api/v1/auth/** → User Service (9090)
/api/v1/courts/** → Court Service (9091)
/api/v1/reservations/** → Court Service (9091)
/api/v1/matches/** → Match Service (9092)
```

---

### 3. rallypoint-plus-court (Court Service)
**현재 상태**: 📋 Week 5-6에 생성 예정

**책임**:
- 테니스 코트 정보 관리
- 예약 생성/조회/취소
- 예약 가능 시간대 관리
- 동시 예약 방지 (분산 락)
- 예약 대기열 관리

**기술 스택**:
- Language: Java 21 (Kotlin에서 변경)
- Framework: Spring Boot 3.3+
- Database: MySQL
- Cache: Redis (예약 현황 캐싱, 분산 락)
- Message Broker: Kafka (예약 이벤트 발행)
- Build: Gradle (Kotlin DSL)

**프로젝트 경로**: `/Users/sanghoon/Project/IdeaProjects/rallypoint-plus-court` (생성 예정)

**주요 API**:
```
GET    /api/v1/courts
POST   /api/v1/courts
GET    /api/v1/courts/{courtId}
POST   /api/v1/reservations
GET    /api/v1/reservations/{reservationId}
DELETE /api/v1/reservations/{reservationId}
GET    /api/v1/courts/{courtId}/availability
```

**데이터베이스 테이블**:
- `courts` (코트 정보)
- `reservations` (예약 정보)
- `time_slots` (시간대 관리)
- `waiting_list` (대기열)

**Kafka Topics**:
- `reservation-events` (Producer)

**Redis Keys**:
- `court:{courtId}:reservations` (캐싱)
- `lock:reservation:{date}:{time}:{courtId}` (분산 락)
- `waitlist:{courtId}:{date}` (대기열)

---

### 4. rallypoint-plus-notification (Notification Service)
**현재 상태**: 📋 Week 7-8에 생성 예정

**책임**:
- 알림 전송 (이메일, SMS, Push)
- Kafka 이벤트 구독 및 처리
- 알림 이력 관리
- 알림 템플릿 관리

**기술 스택**:
- Language: Java 21
- Framework: Spring Boot 3.3+
- Database: MySQL (알림 이력)
- Message Broker: Kafka (Consumer)
- External: AWS SES (이메일), AWS SNS (SMS)
- Build: Gradle (Kotlin DSL)

**프로젝트 경로**: `/Users/sanghoon/Project/IdeaProjects/rallypoint-plus-notification` (생성 예정)

**주요 API**:
```
POST   /api/v1/notifications/send
GET    /api/v1/notifications/{userId}
```

**데이터베이스 테이블**:
- `notifications`
- `notification_templates`
- `processed_events` (Idempotency)

**Kafka Topics (Consumer)**:
- `reservation-events`
- `match-events`
- `user-events`

---

### 5. rallypoint-plus-match (Match Service)
**현재 상태**: 📋 Week 9-10에 생성 예정

**책임**:
- 매치 생성 및 관리
- 사용자 매칭
- 실시간 스코어 업데이트 (WebSocket)
- 매치 결과 기록
- 사용자 통계 및 랭킹

**기술 스택**:
- Language: Java 21 (Kotlin에서 변경)
- Framework: Spring Boot 3.3+
- Database: MySQL
- Real-time: WebSocket (STOMP)
- Message Broker: Kafka (매치 이벤트 발행)
- Build: Gradle (Kotlin DSL)

**프로젝트 경로**: `/Users/sanghoon/Project/IdeaProjects/rallypoint-plus-match` (생성 예정)

**주요 API**:
```
POST   /api/v1/matches
GET    /api/v1/matches/{matchId}
PATCH  /api/v1/matches/{matchId}/score
POST   /api/v1/matches/{matchId}/finish
GET    /api/v1/users/{userId}/stats
GET    /api/v1/rankings
```

**WebSocket Endpoints**:
```
CONNECT /ws
SUBSCRIBE /topic/matches/{matchId}
SEND /app/matches/{matchId}/update-score
```

**데이터베이스 테이블**:
- `matches`
- `match_participants`
- `match_scores`
- `user_statistics`

**Kafka Topics**:
- `match-events` (Producer)

---


### 6. rallypoint-plus-batch (Batch Service)
**현재 상태**: 📋 Week 12-13에 생성 예정 (Kotlin 학습 겸)

**책임**:
- 만료 예약 정리
- 대기열 자동 배정
- 통계 보고서 생성
- 데이터 아카이빙

**기술 스택**:
- Language: Kotlin
- Framework: Spring Batch
- Database: MySQL
- Scheduler: Spring Scheduler
- Build: Gradle (Kotlin DSL)

**프로젝트 경로**: `/Users/sanghoon/Project/IdeaProjects/rallypoint-plus-batch` (생성 예정)

**배치 작업**:
- `expiredReservationCleanupJob` (매일 자정)
- `waitingListProcessingJob` (10분마다)
- `statisticsReportJob` (매주 월요일)

---

### 7. rallypoint-plus-search (Search Service)
**현재 상태**: 📋 Week 14에 생성 예정 (Kotlin 학습 겸)

**책임**:
- Elasticsearch 기반 검색
- 예약 검색
- 코트 검색
- 사용자 검색

**기술 스택**:
- Language: Kotlin
- Framework: Spring Boot 3.3+
- Search Engine: Elasticsearch
- Message Broker: Kafka (색인 업데이트)
- Build: Gradle (Kotlin DSL)

**프로젝트 경로**: `/Users/sanghoon/Project/IdeaProjects/rallypoint-plus-search` (생성 예정)

**주요 API**:
```
GET    /api/v1/search/courts?q={query}
GET    /api/v1/search/reservations?q={query}
GET    /api/v1/search/users?q={query}
```

**Elasticsearch Indices**:
- `courts`
- `reservations`
- `users`

---

### 8. rallypoint-plus-common (Common Library)
**현재 상태**: 📋 Week 2에 생성 예정

**책임**:
- 공통 DTO
- 공통 예외 클래스
- 공통 유틸리티
- 보안 설정
- Kafka 설정

**기술 스택**:
- Language: Java/Kotlin 혼합
- Type: Library Module
- Build: Gradle (Kotlin DSL)

**프로젝트 경로**: `/Users/sanghoon/Project/IdeaProjects/rallypoint-plus-common` (생성 예정)

**포함 내용**:
```
common/
├── dto/
│   ├── ErrorResponse.java
│   ├── ApiResponse.java
│   └── PageResponse.java
├── exception/
│   ├── BusinessException.java
│   ├── NotFoundException.java
│   └── ValidationException.java
├── util/
│   ├── DateTimeUtil.java
│   └── StringUtil.java
├── security/
│   └── JwtUtil.java
└── kafka/
    ├── KafkaProducerConfig.java
    └── KafkaConsumerConfig.java
```

---

## 🔄 서비스 간 통신

### 1. 동기 통신 (OpenFeign)
- **Court Service → User Service**
  - 사용자 검증 (`/internal/users/{userId}/verify`)

- **Match Service → User Service**
  - 사용자 정보 조회

### 2. 비동기 통신 (Kafka)

#### Kafka Topics 및 이벤트 흐름

**reservation-events**:
```
Producer: Court Service
Consumers: Notification Service, Search Service, Batch Service

Events:
- RESERVATION_CREATED
- RESERVATION_CANCELLED
- RESERVATION_EXPIRED
```

**match-events**:
```
Producer: Match Service
Consumers: Notification Service, User Service (통계 업데이트)

Events:
- MATCH_CREATED
- MATCH_STARTED
- MATCH_FINISHED
- SCORE_UPDATED
```

**user-events**:
```
Producer: User Service
Consumers: Notification Service, Search Service

Events:
- USER_REGISTERED
- USER_PROFILE_UPDATED
- USER_DELETED
```

---

## 🗄️ 데이터베이스 전략

### 데이터베이스 분리
각 서비스는 독립적인 데이터베이스를 가집니다:

```
MySQL Instance 1 (localhost:3304):
├── rallypoint_user (User Service)
├── rallypoint_court (Court Service)
├── rallypoint_match (Match Service)
├── rallypoint_notification (Notification Service)
└── rallypoint_batch (Batch Service)
```

### 데이터 동기화
- Kafka 이벤트를 통한 Eventual Consistency
- 필요시 OpenFeign으로 실시간 조회

---

## 🐳 로컬 개발 환경 (Docker Compose)

Week 2에 구축 예정:

```yaml
version: '3.8'
services:
  mysql:
    image: mysql:8.0
    ports:
      - "3304:3306"
    environment:
      MYSQL_ROOT_PASSWORD: root
      MYSQL_DATABASE: rallypoint

  redis:
    image: redis:7
    ports:
      - "6379:6379"

  zookeeper:
    image: confluentinc/cp-zookeeper:7.4.0
    environment:
      ZOOKEEPER_CLIENT_PORT: 2181

  kafka:
    image: confluentinc/cp-kafka:7.4.0
    ports:
      - "9092:9092"
    depends_on:
      - zookeeper

  elasticsearch:
    image: elasticsearch:8.10.0
    ports:
      - "9200:9200"
    environment:
      - discovery.type=single-node

  kibana:
    image: kibana:8.10.0
    ports:
      - "5601:5601"
    depends_on:
      - elasticsearch
```

---

## 🚀 서비스 포트 할당

| Service | Port | Status | Week |
|---------|------|--------|------|
| User Service | 9090 | ✅ Running | Current |
| Gateway Service | 8080 | 📋 Planned (Java) | Week 3-4 |
| Court Service | 9091 | 📋 Planned (Java) | Week 5-6 |
| Notification Service | 9093 | 📋 Planned (Java) | Week 7-8 |
| Match Service | 9092 | 📋 Planned (Java) | Week 9-10 |
| Batch Service | 9094 | 📋 Planned (Kotlin) | Week 12-13 |
| Search Service | 9095 | 📋 Planned (Kotlin) | Week 14 |

---

## 📝 프로젝트 생성 가이드

### 새 서비스 프로젝트 생성 체크리스트

1. **IntelliJ에서 프로젝트 생성**
   - [ ] File → New → Project
   - [ ] Spring Initializr 선택
   - [ ] Group: `com.rallypointplus`
   - [ ] Artifact: `rallypoint-plus-{service-name}`
   - [ ] Package name: `com.rallypointplus.{service}`
   - [ ] Java/Kotlin 선택
   - [ ] Gradle (Kotlin DSL)

2. **필수 의존성 추가**
   - [ ] Spring Web
   - [ ] Spring Data JPA
   - [ ] MySQL Driver
   - [ ] Lombok (Java) / Kotlin Standard Library
   - [ ] Spring Boot Actuator

3. **프로젝트 구조 생성**
   ```
   src/main/{java|kotlin}/com/rallypointplus/{service}/
   ├── domain/
   ├── application/
   ├── infra/
   └── common/
   ```

4. **설정 파일 작성**
   - [ ] `application.yml` 기본 설정
   - [ ] Database 연결 정보
   - [ ] 포트 설정

5. **Git 연동**
   - [ ] Git 저장소 초기화
   - [ ] `.gitignore` 설정
   - [ ] 첫 커밋

6. **Common 라이브러리 연동**
   - [ ] `build.gradle.kts`에 의존성 추가

---

## 🔗 관련 문서

- [[architecture]] - 전체 MSA 아키텍처
- [[weekly-development-plan]] - 주별 개발 계획
- [[msa-event-driven-learning-guide]] - MSA 학습 가이드
- [[user-domain]] - User Service 상세
- [[business-requirements]] - 비즈니스 요구사항

---

**작성일**: 2025-11-16
**작성자**: Claude Code
**상태**: v1.0
