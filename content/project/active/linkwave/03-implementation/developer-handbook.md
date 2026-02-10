---
created: 2026-02-10
tags:
  - linkwave
  - backend
  - developer-guide
---

> 이 문서는 linkwave-docs의 backend/DEVELOPER-HANDBOOK.md를 요약한 것입니다.

# LinkWave Backend 개발자 핸드북

## 1. 코딩 표준

### Google Java Style Guide
- **포맷터**: Spotless (Google Java Format)
  - `./gradlew spotlessApply` (적용)
  - `./gradlew spotlessCheck` (검증)
- 들여쓰기: 2 spaces, 최대 라인: 100자, K&R 스타일

### 네이밍 컨벤션

| 타입 | 패턴 | 예시 |
|------|------|------|
| Controller | `{Domain}Controller` | `MessageController` |
| Service | `{Domain}Service` | `MessageService` |
| Repository | `{Entity}Repository` | `UserRepository` |
| DTO (Request) | `{Domain}RequestDto` | `MessageRequestDto` |
| DTO (Response) | `{Domain}ResponseDto` | `MessageResponseDto` |
| Entity | `{TableName}` | `User`, `Organization` |
| 상수 | `UPPER_SNAKE_CASE` | `MAX_MESSAGE_LENGTH` |
| 패키지 | `lowercase` | `io.iotree.linkwave.api` |

---

## 2. 개발 환경 구동

### 필수 요구사항
- Java 21 (LTS), Gradle 8.5+, MySQL 8.0+, Redis

### 구동 순서
```bash
# 1. MySQL + Redis 실행 (Docker)
docker compose up -d

# 2. 빌드 및 테스트
./gradlew clean build

# 3. 실행
./gradlew bootRun --args='--spring.profiles.active=local'
```

### Gradle 주요 태스크
| 태스크 | 설명 |
|--------|------|
| `./gradlew build` | 전체 빌드 + 테스트 |
| `./gradlew bootRun` | 개발 서버 실행 |
| `./gradlew spotlessApply` | 코드 포맷 적용 |
| `./gradlew test` | 테스트 실행 |

---

## 3. Git 워크플로우

### 브랜치 전략
- `main`: 프로덕션
- `develop`: 개발 통합
- `feature/{issue-number}-{description}`: 기능 개발
- `hotfix/{description}`: 긴급 수정

### 커밋 메시지 (Conventional Commits)
```
<type>(<scope>): <subject>

type: feat, fix, refactor, test, docs, chore, style
scope: auth, message, user, config
```

### PR 규칙
- feature → develop (코드 리뷰 필수)
- 테스트 통과 필수
- Spotless check 통과 필수

---

## 4. 아키텍처 원칙

### 레이어 아키텍처
```
API Layer (Controller) → Application Layer (Service) → Domain Layer (Entity)
                                                     → Infrastructure Layer (JPA/MyBatis)
```

### CQRS: JPA + MyBatis Hybrid
- **Command** (쓰기): JPA Repository — `save()`, `delete()`
- **Query** (읽기): MyBatis Mapper — `findByXxx()`, `selectList()`
- 원칙: 같은 테이블에 두 기술 혼용 금지

### DIP (의존성 역전)
- Service는 Repository/Mapper 인터페이스에 의존
- 구현체는 Infrastructure 레이어

### Entity Factory Method
```java
User.createForSignUp(username, password, email, phone, role, organization)
```
- `new` 대신 팩토리 메서드로 엔티티 생성
- 생성 로직 캡슐화, 불변식 보장

---

## 5. 테스트 작성

### 테스트 전략
| 레벨 | 대상 | 도구 |
|------|------|------|
| Unit | Service, Entity | JUnit 5 + Mockito |
| Integration | Repository, API | TestContainers + RestAssured |
| E2E | 전체 플로우 | (수동) |

### 테스트 네이밍
```java
@Test
void 회원가입_성공() { ... }

@Test
void 중복_아이디로_회원가입시_예외발생() { ... }
```

### 테스트 패턴
- Given-When-Then 구조
- `@MockitoExtension` for unit tests
- `@SpringBootTest` + TestContainers for integration tests

---

## 6. 문제 해결

| 증상 | 원인 | 해결 |
|------|------|------|
| 빌드 실패 | Spotless 포맷 | `./gradlew spotlessApply` |
| DB 연결 실패 | Docker 미실행 | `docker compose up -d` |
| 테스트 실패 | TestContainers | Docker Desktop 실행 확인 |
| JWT 인증 실패 | 토큰 만료 | `/auth/refresh` 호출 |

---

## Related Documents

- [[backend-architecture|Backend Architecture]]
- [[tdd-guide|TDD Guide]]
- [[backend-deployment|Backend Deployment]]
