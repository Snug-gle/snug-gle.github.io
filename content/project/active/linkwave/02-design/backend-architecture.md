---
tags: [linkwave, backend, architecture, spring, cqrs]
category: linkwave
created: 2026-02-10
status: complete
description: LinkWave 백엔드 레이어 구조 및 CQRS 설계 요약
---

> 이 문서는 linkwave-docs의 backend/ARCHITECTURE.md를 요약한 것입니다.

# LinkWave 백엔드 설계

## 1. 개요

문자 발송 요청을 접수하고 데이터베이스에 저장하는 백엔드 API 서버.

### 기술 스택

| 영역 | 기술 |
|------|------|
| Core | Spring Boot 4.0, Java 21, Gradle (Kotlin DSL) |
| Database | MySQL 8.0+, JPA/Hibernate, MyBatis |
| Security | Spring Security, OAuth2 Resource Server (JWT) |
| Libraries | Lombok, MapStruct, Apache Commons |
| Testing | JUnit 5, Mockito, TestContainers, RestAssured |
| Monitoring | SLF4J + Logback, Spring Actuator |

---

## 2. 시스템 아키텍처

### 2.1 레이어 구조 (CQRS + Factory Method)

```
┌─────────────────────────────────────────────┐
│              API Layer (Controller)           │
└─────────────────────────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────┐
│            Application Layer                 │
│  Service (비즈니스 로직)                      │
│    ├── Repository (JPA) ← Command            │
│    └── Mapper (MyBatis) ← Query              │
│  Entity.createForXxx() ← Factory Method      │
└─────────────────────────────────────────────┘
          │                       │
          ▼                       ▼
┌─────────────────┐   ┌─────────────────┐
│  JPA Repository  │   │  MyBatis Mapper  │
│  save(), exists  │   │  findBy, select  │
└─────────────────┘   └─────────────────┘
          └───────────┬───────────┘
                      ▼
              MySQL (Web/Message DB)
```

| 패턴 | 적용 | 이점 |
|------|------|------|
| **하이브리드 ORM** | Write + 단순 조회 → JPA / 복잡한 조회 → MyBatis | 쿼리 복잡도 기준으로 기술 분리, 성능·생산성 동시 확보 |
| **Factory Method** | `Entity.createForXxx()` | 엔티티 생성 로직 캡슐화 |
| **Pragmatic** | Repository/Mapper 직접 사용 | 단순함, 빠른 개발 |

**ORM 분리 기준**: 도메인이 아닌 쿼리 복잡도. 단순 CRUD·단건 조회는 JPA 그대로 사용. 메시지 이력 동적 필터링·커서 페이징·통계 집계처럼 SQL 제어가 필요한 경우에만 MyBatis QueryMapper 적용.

**Port/Adapter를 채택하지 않은 이유**: 파일 증가(4개+)로 복잡도 상승, 하이브리드 ORM으로 이미 충분히 분리됨.

### 2.2 메시지 발송 아키텍처

```
[MessageService]
  ├── 즉시 발송 → [ums_msg] → [SNAP] → [ums_log]
  ├── 예약 발송 → [ums_msg] (REQ_DATE = 미래시간)
  ├── 예약 취소 → DELETE (ready 상태만)
  └── 통계 조회 ← [ums_stats_daily] ← @Scheduled 집계
```

| 항목 | 결정 | 이유 |
|------|------|------|
| 중간 테이블 | 불필요 | SNAP이 예약 발송 지원 |
| 발송 방식 | ums_msg 직접 INSERT | 단순하고 효율적 |
| 통계 | 별도 ums_stats_daily | 10만건+ 대응 |

### 2.3 데이터베이스 구조

단일 MySQL 데이터베이스, 테이블을 논리적으로 분리하여 향후 물리적 분리 가능:

- **User 영역**: 주소록, 발신번호, 보관함, 공유 주소록
- **Message 영역**: ums_msg, ums_log_{YYYYMM} (대용량 쓰기 최적화)

---

## 3. 프로젝트 구조

```
src/main/java/io/iotree/linkwave/
├── api/                    # Presentation Layer (Controller)
├── application/            # Application Layer
│   ├── service/            # 비즈니스 로직 (CQRS)
│   └── dto/                # Request/Response DTO
├── domain/                 # Domain Layer (JPA Entity + Factory)
│   ├── user/               # User, UserType, UserRole, UserStatus
│   ├── organization/       # Organization
│   └── message/            # ServiceType
├── infra/                  # Infrastructure Layer
│   ├── jpa/repository/     # Command (JPA)
│   └── mybatis/mapper/     # Query (MyBatis)
├── common/                 # 공통 모듈
│   ├── exception/          # ErrorCode, BusinessException, GlobalExceptionHandler
│   └── security/           # JwtTokenProvider, JwtAuthenticationFilter
└── config/                 # SecurityConfig, MyBatisConfig
```

| 레이어 | 패키지 | 책임 |
|--------|--------|------|
| API | `api/` | HTTP 요청/응답 처리 |
| Application | `application/service/` | 비즈니스 로직, CQRS 오케스트레이션 |
| Domain | `domain/` | JPA 엔티티 + Factory Method |
| Infrastructure | `infra/` | JPA Repository (Command) + MyBatis Mapper (Query) |

---

## 4. REST API 설계

### 인증
- Base URL: `/api/v1`
- JWT Token: `Authorization: Bearer {token}`

### 주요 API

| Method | Endpoint | 설명 |
|--------|----------|------|
| POST | `/api/v1/messages` | 메시지 발송 요청 |
| GET | `/api/v1/messages/{clientKey}` | 메시지 상세 조회 |
| GET | `/api/v1/messages` | 메시지 목록 조회 (페이지네이션) |
| DELETE | `/api/v1/messages/{clientKey}/schedule` | 예약 취소 |

### 발송 요청 핵심 필드
- `messageType`: SMS/LMS/MMS
- `senderNumber`, `recipients[]` (phone, name, variables)
- `content`, `title` (LMS/MMS)
- `trafficType`: real/normal/batch
- `dedupEnabled`, `dedupWindowMinutes`
- `files[]` (MMS)

### 응답 핵심 필드
- `clientKey`: `{timestamp}_{userPrefix}_{random}`
- `status`: ACCEPTED
- `trafficType`, `recipientCount`, `estimatedCost`

---

## 5. 도메인 모델

### User Entity
- Factory: `User.createForSignUp(username, password, email, phone, role, organization)`
- Enum: UserType(LOCAL/LDAP), UserRole(SUPER_ADMIN/ORG_ADMIN/USER), UserStatus(ACTIVE/INACTIVE/LOCKED)

### Organization Entity
- Factory: `Organization.createNew(name, code, businessNumber, ...)`

### Message (MyBatis 기반)
- ums_msg: CLIENT_KEY, SVC_TYPE, PHONE, SUBJECT, MSG, MSG_STATUS, REQ_DATE, TRAFFIC_TYPE, DEDUP_HASH
- ums_log_{YYYYMM}: 월별 파티션, 발송 결과 이력

---

## 6. 보안

- Spring Security + JWT (HS256, 향후 RS256 마이그레이션 예정)
- 역할 기반 접근 제어: SUPER_ADMIN > ORG_ADMIN > USER
- SecurityConfig: 인증 제외 경로 (`/api/v1/auth/**`, actuator, swagger)
- JwtAuthenticationFilter: 토큰 검증 + SecurityContext 설정

---

## Related Documents

- [[system-architecture|System Architecture]]
- [[backend-cqrs-evolution|CQRS Evolution Guide]]
- [[api-specifications|API Specifications]]
- [[developer-handbook|Developer Handbook]]
