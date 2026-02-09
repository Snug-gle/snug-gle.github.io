---
created: 2025-12-26
---
# LinkWave Backend 개발자 핸드북

이 문서는 LinkWave Backend 프로젝트의 코딩 표준, 개발 워크플로우, 아키텍처 원칙을 설명합니다.

## 목차

1. [코딩 표준](#1-코딩-표준)
2. [개발 환경 구동](#2-개발-환경-구동)
3. [Git 워크플로우](#3-git-워크플로우)
4. [아키텍처 원칙](#4-아키텍처-원칙)
5. [테스트 작성](#5-테스트-작성)
6. [문제 해결](#6-문제-해결)

---

## 1. 코딩 표준

### 1.1 Google Java Style Guide

LinkWave Backend는 **Google Java Style Guide**를 따릅니다.

**자동 포맷터**: Spotless (Google Java Format)

```bash
# 코드 포맷 적용
./gradlew spotlessApply

# 코드 포맷 검증
./gradlew spotlessCheck
```

**주요 규칙**:
- 들여쓰기: 2 spaces (탭 아님)
- 최대 라인 길이: 100자
- 줄바꿈: K&R 스타일

### 1.2 네이밍 컨벤션

#### 클래스명: `UpperCamelCase`

| 타입 | 패턴 | 예시 |
|------|------|------|
| Controller | `{Domain}Controller` | `MessageController`, `AuthController` |
| Service | `{Domain}Service` | `MessageService`, `AuthService` |
| Repository | `{Entity}Repository` | `UserRepository`, `UmsMsgRepository` |
| DTO (Request) | `{Domain}RequestDto` | `MessageRequestDto`, `SignUpRequest` |
| DTO (Response) | `{Domain}ResponseDto` | `MessageResponseDto`, `ApiResponse` |
| Entity | `{TableName}` | `User`, `Organization`, `UmsMsg` |
| Exception | `{Purpose}Exception` | `BusinessException`, `DuplicateMessageException` |

#### 메서드/변수명: `lowerCamelCase`

```java
// Good
public User findUserByUsername(String username) {
    String encodedPassword = passwordEncoder.encode(password);
    return userRepository.findByUsername(username);
}

// Bad
public User FindUserByUsername(String UserName) {
    String EncodedPassword = PasswordEncoder.encode(Password);
    return UserRepository.findByUsername(UserName);
}
```

#### 상수명: `UPPER_SNAKE_CASE`

```java
public static final int MAX_MESSAGE_LENGTH = 2000;
public static final String DEFAULT_TRAFFIC_TYPE = "normal";
private static final Duration DEDUP_WINDOW = Duration.ofMinutes(10);
```

#### 패키지명: `lowercase`

```java
package io.iotree.linkwave.api;
package io.iotree.linkwave.application.service;
package io.iotree.linkwave.domain.user;
```

### 1.3 클래스 설계 원칙

**크기 제한**:
- 최대 300줄 per class
- 최대 50줄 per method
- 한 클래스는 하나의 책임만 (Single Responsibility Principle)

**Null 처리**:
```java
// Good - Optional 사용
public Optional<User> findUserById(UUID userId) {
    return userRepository.findById(userId);
}

// Bad - null 반환
public User findUserById(UUID userId) {
    return userRepository.findById(userId).orElse(null);
}
```

**반복문**:
```java
// Good - Stream API
List<String> usernames = users.stream()
    .map(User::getUsername)
    .collect(Collectors.toList());

// Acceptable - 복잡한 로직일 경우 전통적 for 루프 사용 가능
for (User user : users) {
    if (complexCondition(user)) {
        // complex operations
    }
}
```

### 1.4 주석 작성

**JavaDoc**:
- Public API (Controller, Service)에는 JavaDoc 필수
- Private 메서드는 필요 시에만

```java
/**
 * 메시지를 발송하고 결과를 반환합니다.
 *
 * @param request 메시지 발송 요청 DTO
 * @return 발송된 메시지의 CLIENT_KEY
 * @throws BusinessException 발신번호 검증 실패, 중복 메시지 등
 */
public String sendMessage(MessageRequestDto request) {
    // implementation
}
```

**인라인 주석**:
- 명확하지 않은 비즈니스 로직에만 사용
- "무엇을"보다 "왜"를 설명

```java
// Good - "왜"를 설명
// MD5는 암호학적으로 안전하지 않지만 중복 검사용으로는 충분
String dedupHash = HashUtil.md5(phone + "|" + content);

// Bad - "무엇을"만 설명
// 해시 생성
String dedupHash = HashUtil.md5(phone + "|" + content);
```

---

## 2. 개발 환경 구동

### 2.1 로컬 환경 설정

#### 사전 준비

1. **Java 21 설치**
   ```bash
   # 버전 확인
   java -version
   # java version "21.0.x"
   ```

2. **MySQL 8.0 설치 (Docker 권장)**
   ```bash
   cd deployment/mysql
   docker-compose up -d
   ```

3. **config 디렉토리 설정**
   ```bash
   mkdir -p config
   # config/.env 파일 생성 (README.md 참고)
   ```

4. **config/.env 파일 생성**
   ```bash
   cat > config/.env <<'EOF'
   SPRING_PROFILE=local
   DB_NAME=linkwave
   DB_USER=linkwave
   DB_PASSWORD=your_password
   DB_ROOT_PASSWORD=your_root_password
   JWT_SECRET=your-256-bit-secret-key-minimum-32-characters-long-for-hs256
   JWT_EXPIRATION=86400000
   FILE_MAX_SIZE=10485760
   MESSAGE_DEDUP_ENABLED=true
   MESSAGE_DEDUP_WINDOW=10
   MESSAGE_BATCH_THRESHOLD=100
   EOF
   ```

### 2.2 빌드 및 실행

```bash
# 전체 빌드
./gradlew clean build

# 실행 (개발 서버)
./gradlew bootRun

# 테스트 실행
./gradlew test

# 코드 포맷 적용
./gradlew spotlessApply

# 테스트 커버리지 리포트
./gradlew test jacocoTestReport
# 리포트 위치: build/reports/jacoco/test/html/index.html
```

### 2.3 IDE 설정 (IntelliJ IDEA)

#### 필수 플러그인 설치

1. **Lombok**
   - Settings → Plugins → "Lombok" 검색 → 설치

2. **Google Java Format**
   - Settings → Plugins → "google-java-format" 검색 → 설치
   - Settings → google-java-format Settings → Enable 체크

3. **Annotation Processing 활성화**
   - Settings → Build, Execution, Deployment → Compiler → Annotation Processors
   - "Enable annotation processing" 체크

#### 코드 스타일 설정

1. Settings → Editor → Code Style → Java
2. Scheme: Default
3. Tabs and Indents:
   - Tab size: 2
   - Indent: 2
   - Continuation indent: 4

#### 저장 시 자동 포맷 (선택 사항)

1. Settings → Tools → Actions on Save
2. "Reformat code" 체크
3. "Optimize imports" 체크

---

## 3. Git 워크플로우

### 3.1 브랜치 전략

**메인 브랜치**:
- `develop`: 개발 브랜치 (기본)
- `main`: 운영 브랜치 (향후)

**작업 브랜치 네이밍**:
```
feature/{issue-number}-{description}
bugfix/{issue-number}-{description}
hotfix/{issue-number}-{description}
refactor/{issue-number}-{description}
docs/{description}
```

**예시**:
```bash
feature/123-user-signup
bugfix/456-null-pointer-fix
hotfix/789-critical-security-patch
refactor/012-message-service-cleanup
docs/update-readme
```

### 3.2 커밋 컨벤션

**커밋 메시지 형식**:
```
<type>: <subject>

[optional body]

[optional footer]
```

**Type**:
- `feat`: 새 기능
- `fix`: 버그 수정
- `docs`: 문서 수정
- `refactor`: 리팩토링 (기능 변경 없음)
- `test`: 테스트 추가/수정
- `chore`: 빌드/설정 변경
- `style`: 코드 포맷 (기능 변경 없음)
- `perf`: 성능 개선

**예시**:
```bash
feat: 회원 가입 API 구현

- User 엔티티에 displayName 필드 추가
- SignUpRequest DTO 생성
- AuthService.signupAndIssueToken() 메서드 구현
- 휴대폰 필수, 이메일 선택 사항으로 설정

Closes #123

---

fix: null pointer exception 수정

UserService.findByUsername()에서 null 체크 누락으로 발생한 NPE 수정

---

docs: README.md 업데이트

프로젝트 구조 및 빠른 시작 가이드 업데이트

---

refactor: 메시지 서비스 로직 단순화

중복 코드 제거 및 메서드 분리로 가독성 향상

---

test: dedup 서비스 유닛 테스트 추가

DedupService.checkDuplicate() 메서드에 대한 테스트 케이스 추가

---

chore: 의존성 업데이트

Spring Boot 4.0.0 → 4.0.1 업데이트
```

### 3.3 작업 플로우

#### 1. Feature 브랜치 생성

```bash
# develop 브랜치에서 최신 상태 pull
git checkout develop
git pull origin develop

# Feature 브랜치 생성
git checkout -b feature/123-user-signup
```

#### 2. 개발 작업

```bash
# 코드 작성
# ...

# 코드 포맷 적용
./gradlew spotlessApply

# 테스트 실행
./gradlew test

# 변경 사항 확인
git status
git diff
```

#### 3. 커밋

```bash
# 스테이징
git add .

# 커밋
git commit -m "feat: 회원 가입 API 구현"
```

#### 4. Push 및 MR/PR 생성

```bash
# 원격 저장소에 push
git push origin feature/123-user-signup

# GitLab/GitHub에서 Merge Request/Pull Request 생성
```

### 3.4 PR/MR 체크리스트

Merge Request 생성 전 확인 사항:

- [ ] `./gradlew spotlessApply` 실행
- [ ] `./gradlew test` 통과
- [ ] 커밋 메시지 컨벤션 준수
- [ ] 코드 리뷰어 지정
- [ ] 충돌(Conflict) 없음
- [ ] MR 설명에 변경 사항 및 테스트 결과 포함
- [ ] develop 브랜치로 머지

**MR/PR Description 템플릿**:
```markdown
## 변경 사항
- 회원 가입 API 구현
- User 엔티티 displayName 필드 추가
- 휴대폰 필수, 이메일 선택 사항

## 테스트
- [x] Unit Tests 통과
- [x] Integration Tests 통과
- [x] 수동 테스트 완료

## 스크린샷 (해당 시)
(Postman 요청/응답 스크린샷 등)

## 관련 이슈
Closes #123
```

### 3.5 코드 리뷰 가이드

**리뷰어 체크사항**:
- 코딩 표준 준수
- 비즈니스 로직 정확성
- 예외 처리 적절성
- 테스트 코드 존재
- 보안 취약점 (SQL Injection, XSS 등)
- 성능 이슈 (N+1 Query 등)

---

## 4. 아키텍처 원칙

### 4.1 레이어드 아키텍처

LinkWave Backend는 엄격한 레이어드 아키텍처를 따릅니다.

```
Controller (API)
    ↓
Service (Business Logic)
    ↓
Repository (Data Access)
    ↓
Database
```

**각 레이어의 책임**:

| 레이어 | 책임 | 예시 |
|--------|------|------|
| **Controller** | HTTP 요청/응답 처리, DTO 검증 | `AuthController`, `MessageController` |
| **Service** | 비즈니스 로직, 트랜잭션 관리 | `AuthService`, `MessageService` |
| **Repository** | 데이터 접근 (JPA 또는 MyBatis) | `UserRepository`, `UmsMsgMapper` |

**원칙**:
- Controller는 Service에만 의존
- Service는 Repository에만 의존
- Repository는 외부 의존성 없음
- **순환 참조 금지**

### 4.2 JPA vs MyBatis 선택 기준

LinkWave Backend는 **Hybrid Strategy**를 사용합니다.

| 도메인 | 기술 | 이유 |
|--------|------|------|
| **User, Organization** | JPA | CRUD 중심, 관계 복잡, 트랜잭션 중요 |
| **Message, Log** | MyBatis | 대용량 데이터, 복잡한 쿼리, 월별 파티션 |

**JPA 사용 예시**:
```java
@Repository
public interface UserRepository extends JpaRepository<User, UUID> {
    Optional<User> findByUsername(String username);
    boolean existsByUsername(String username);
}
```

**MyBatis 사용 예시**:
```java
@Mapper
public interface UmsMsgMapper {
    void insertMessage(UmsMsg umsMsg);
    List<UmsMsg> findMessagesByDateRange(@Param("startDate") LocalDateTime startDate,
                                          @Param("endDate") LocalDateTime endDate);
}
```

### 4.3 트랜잭션 관리

**원칙**:
- `@Transactional`은 **Service 레이어**에만 적용
- Repository에는 적용하지 않음
- Read-only 작업은 `@Transactional(readOnly = true)` 사용

**예시**:
```java
@Service
@RequiredArgsConstructor
public class AuthService {
    private final UserCrudService userCrudService;
    private final PasswordEncoder passwordEncoder;

    @Transactional  // Write 작업
    public String signupAndIssueToken(SignUpRequest request) {
        // 비즈니스 로직
        User user = User.builder()
            .username(request.username())
            .password(passwordEncoder.encode(request.password()))
            .build();
        return userCrudService.save(user).getUserId().toString();
    }

    @Transactional(readOnly = true)  // Read-only 작업
    public User getUserByUsername(String username) {
        return userCrudService.findByUsername(username)
            .orElseThrow(() -> new BusinessException(ErrorCode.USER_NOT_FOUND));
    }
}
```

### 4.4 의존성 역전 원칙 (DIP)

**원칙**:
- Service는 Repository **인터페이스**에 의존
- 구현체는 `infra` 레이어에 위치

**구조**:
```
domain/
  └── user/
      └── UserRepository.java (interface)

infra/
  └── jpa/
      └── repository/
          └── UserJpaRepository.java (implements UserRepository)
```

**예시**:
```java
// Domain layer - interface
public interface UserRepository {
    Optional<User> findByUsername(String username);
    User save(User user);
}

// Infrastructure layer - implementation
@Repository
public class UserJpaRepository implements UserRepository {
    private final UserSpringDataRepository springDataRepository;

    @Override
    public Optional<User> findByUsername(String username) {
        return springDataRepository.findByUsername(username);
    }
}
```

---

## 5. 테스트 작성

### 5.1 Unit Test (Service Layer)

**원칙**:
- Mockito로 Repository 모킹
- 비즈니스 로직만 검증
- 외부 의존성 제거

**메서드 네이밍**:
```
{methodName}_{scenario}
```

**예시**:
```java
@ExtendWith(MockitoExtension.class)
class AuthServiceTest {

    @Mock
    private UserCrudService userCrudService;

    @Mock
    private PasswordEncoder passwordEncoder;

    @InjectMocks
    private AuthService authService;

    @Test
    @DisplayName("회원 가입 성공")
    void signupAndIssueToken_Success() {
        // Given
        SignUpRequest request = new SignUpRequest(
            "testuser", "password123", "홍길동", "01012345678",
            "test@example.com", "테스터", UserType.INDIVIDUAL, null
        );
        when(userCrudService.existsByUsername("testuser")).thenReturn(false);
        when(passwordEncoder.encode("password123")).thenReturn("encoded");
        when(userCrudService.save(any(User.class)))
            .thenReturn(User.builder().userId(UUID.randomUUID()).build());

        // When
        String token = authService.signupAndIssueToken(request);

        // Then
        assertThat(token).isNotNull();
        verify(userCrudService).existsByUsername("testuser");
        verify(passwordEncoder).encode("password123");
        verify(userCrudService).save(any(User.class));
    }

    @Test
    @DisplayName("중복 사용자명으로 회원 가입 실패")
    void signupAndIssueToken_DuplicateUsername() {
        // Given
        SignUpRequest request = new SignUpRequest(...);
        when(userCrudService.existsByUsername("testuser")).thenReturn(true);

        // When & Then
        assertThatThrownBy(() -> authService.signupAndIssueToken(request))
            .isInstanceOf(BusinessException.class)
            .hasMessage(ErrorCode.DUPLICATE_USERNAME.getMessage());
    }
}
```

### 5.2 Integration Test (API Layer)

**원칙**:
- TestContainers로 MySQL 구동
- 전체 플로우 검증
- `@SpringBootTest` 사용

**예시**:
```java
@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
@Testcontainers
class AuthControllerIntegrationTest {

    @Container
    static MySQLContainer<?> mysql = new MySQLContainer<>("mysql:8.0")
        .withDatabaseName("testdb")
        .withUsername("test")
        .withPassword("test");

    @Autowired
    private TestRestTemplate restTemplate;

    @Test
    @DisplayName("회원 가입 API - 성공")
    void signup_Success() {
        // Given
        SignUpRequest request = new SignUpRequest(...);

        // When
        ResponseEntity<ApiResponse> response = restTemplate.postForEntity(
            "/api/v1/auth/signup",
            request,
            ApiResponse.class
        );

        // Then
        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.CREATED);
        assertThat(response.getHeaders().get(HttpHeaders.AUTHORIZATION))
            .isNotNull();
    }
}
```

### 5.3 테스트 커버리지

**목표**: 80% 이상

```bash
# 테스트 실행 및 커버리지 리포트 생성
./gradlew test jacocoTestReport

# 리포트 확인
# build/reports/jacoco/test/html/index.html
```

**커버리지 우선순위**:
1. **Service 레이어**: 90% 이상 (비즈니스 로직 중요)
2. **Controller 레이어**: 70% 이상
3. **Repository 레이어**: 통합 테스트로 커버

---

## 6. 문제 해결

### 6.1 MySQL 연결 오류

**증상**: `Communications link failure`

**확인**:
```bash
# Docker 컨테이너 상태
docker ps | grep mysql

# MySQL 로그
docker logs linkwave-mysql
```

**해결**:
```bash
# application-local.yml 확인
spring:
  datasource:
    url: jdbc:mysql://localhost:3307/linkwave?useSSL=false
```

### 6.2 포트 충돌

**증상**: `Port 8080 is already in use`

**확인**:
```bash
# Windows
netstat -ano | findstr :8080

# Mac/Linux
lsof -i:8080
```

**해결**:
```bash
# application.yml에서 포트 변경
server:
  port: 8081
```

### 6.3 Lombok 미작동

**증상**: `cannot find symbol: method builder()`

**해결**:
1. IntelliJ IDEA → Settings → Plugins → Lombok 설치
2. Settings → Build, Execution, Deployment → Compiler → Annotation Processors
3. "Enable annotation processing" 체크
4. IDE 재시작

### 6.4 Spotless 실패

**증상**: `The following files had format violations`

**해결**:
```bash
# 자동 포맷 적용
./gradlew spotlessApply

# 확인
./gradlew spotlessCheck
```

### 6.5 N+1 Query 문제

**증상**: 성능 저하, 많은 SELECT 쿼리

**확인**:
```yaml
# application-local.yml
logging:
  level:
    org.hibernate.SQL: DEBUG
    org.hibernate.type.descriptor.sql.BasicBinder: TRACE
```

**해결**:
```java
// @EntityGraph 사용
@EntityGraph(attributePaths = {"organization"})
Optional<User> findByUsername(String username);

// JPQL JOIN FETCH 사용
@Query("SELECT u FROM User u JOIN FETCH u.organization WHERE u.username = :username")
Optional<User> findByUsernameWithOrganization(@Param("username") String username);
```

### 6.6 로그 확인

**로컬 개발**:
- 콘솔 출력 (IntelliJ IDEA 하단 Run 탭)

**운영 서버**:
```bash
# 애플리케이션 로그
tail -f /home/sanghpark/app/link-wave/logs/linkwave.log

# 시작 로그
tail -f /home/sanghpark/app/link-wave/logs/application-startup.log
```

---

## 7. 참고 자료

### 7.1 내부 문서

- [README.md](../README.md) - 프로젝트 개요 및 빠른 시작
- [DEPLOYMENT.md](DEPLOYMENT.md) - 배포 가이드
- [ARCHITECTURE.md](ARCHITECTURE.md) - JPA/MyBatis 전략 상세
- [Implementation Guides](implementation-guides/) - 단계별 구현 가이드

### 7.2 외부 참고

- [Google Java Style Guide](https://google.github.io/styleguide/javaguide.html)
- [Spring Boot 4.0 Reference](https://docs.spring.io/spring-boot/reference/)
- [JPA/Hibernate Documentation](https://hibernate.org/orm/documentation/)
- [Conventional Commits](https://www.conventionalcommits.org/)

---

## 8. 자주 묻는 질문 (FAQ)

**Q1. 왜 JPA와 MyBatis를 함께 사용하나요?**
> User/Organization 도메인은 관계가 복잡하고 CRUD 중심이라 JPA가 적합합니다. Message/Log 도메인은 대용량 데이터와 복잡한 집계 쿼리가 많아 MyBatis가 더 효율적입니다.

**Q2. 트랜잭션은 어디에 적용해야 하나요?**
> Service 레이어에만 `@Transactional`을 적용합니다. Repository에는 적용하지 않습니다.

**Q3. DTO와 Entity를 분리해야 하나요?**
> 네, 반드시 분리해야 합니다. Entity는 도메인 모델이고, DTO는 API 계약입니다. Entity를 직접 노출하면 보안 및 유지보수 문제가 발생합니다.

**Q4. Spotless 포맷이 내 코드를 망가뜨리는 것 같아요.**
> Spotless는 Google Java Format을 따릅니다. 팀 전체가 동일한 스타일을 유지하기 위해 필수입니다. IDE 설정에서 google-java-format 플러그인을 활성화하면 저장 시 자동 포맷됩니다.

**Q5. 테스트를 꼭 작성해야 하나요?**
> 네, 특히 Service 레이어의 비즈니스 로직은 반드시 테스트를 작성해야 합니다. 목표는 80% 이상의 커버리지입니다.

---

**문서 버전**: 1.0
**최종 업데이트**: 2024-12-16
