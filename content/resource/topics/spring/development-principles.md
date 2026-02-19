---
created: 2026-02-13
---
---
tags:
  - spring
  - java
  - architecture
  - best-practices
  - ddd
category: spring
up: "[[resource/topics/spring/_Spring MOC]]"
status: in-progress
created: 2025-10-29
modified: 2025-10-29
---
# RallyPoint User Service - 개발 원칙

## 1. 아키텍처 원칙

### 1.1 레이어드 아키텍처 (Layered Architecture)

프로젝트는 명확한 레이어 분리를 따릅니다:

```
domain (도메인 계층)
  ├── vo/        # Value Objects (불변 도메인 객체)
  ├── table/     # JPA Entity (영속성 모델)
  └── service/   # 도메인 서비스

application (애플리케이션 계층)
  ├── dto/       # Data Transfer Objects
  ├── service/   # 애플리케이션 서비스 (유스케이스)
  └── rest/      # REST API Controllers

infra (인프라 계층)
  └── jpa/       # JPA Repository

common (공통 계층)
  ├── config/    # 설정
  ├── security/  # 보안
  ├── handler/   # 핸들러
  ├── mapper/    # 매퍼
  └── exception/ # 예외 처리
```

#### 레이어별 의존성 규칙

```
application → domain
infra → domain
common → (모든 레이어에서 사용 가능)

❌ domain → application (금지)
❌ domain → infra (금지)
```

### 1.2 DDD (Domain-Driven Design) 적용

#### Value Object vs Entity 분리

- **Value Object (VO)**: 비즈니스 로직을 담는 불변 객체
  - `User`, `UserRole`, `UserStatus`
  - 동등성(equality)은 속성 값으로 판단
  - 비즈니스 메서드 포함

- **JPA Entity**: 영속성 관리를 위한 객체
  - `UserJpaEntity`, `UserProfileJpaEntity`, `UserCredentialJpaEntity`
  - ID로 식별
  - 영속성 관련 메타데이터 포함

#### Mapper 패턴

MapStruct를 사용한 명시적 변환:
- `UserPersistenceMapper`: VO ↔ JpaEntity
- `UserValidationMapper`: DTO ↔ VO

```java
// Good: 명시적 변환
User user = userMapper.toDomain(userJpaEntity);

// Bad: 직접 변환 로직
User user = new User(
  userJpaEntity.getId(),
  userJpaEntity.getEmail(),
  // ...
);
```

---

## 2. 코딩 컨벤션

### 2.1 Java 코드 스타일

- **포맷터**: Google Java Format 준수
- **들여쓰기**: 공백 2칸
- **줄 길이**: 최대 100자
- **import 정리**: 사용하지 않는 import 제거

### 2.2 네이밍 컨벤션

#### 클래스명

```java
// Controller
UserCreateController
AuthApiController

// Service
UserApplicationService
AuthService

// Repository
UserCrudRepository

// DTO
UserCreateRequestDTO
UserResponseUserDTO

// Entity
UserJpaEntity
UserProfileJpaEntity

// VO
User
UserRole
UserStatus
```

#### 메서드명

- **CRUD 메서드**: `create`, `read`, `update`, `delete`
- **조회 메서드**: `findBy*`, `getBy*`, `existsBy*`
- **검증 메서드**: `validate*`, `check*`, `is*`
- **변환 메서드**: `to*`, `from*`, `convert*`

```java
// Good
User findByEmail(String email);
boolean existsByUserId(Long userId);
void validateUserStatus(User user);
UserResponseDTO toResponseDTO(User user);

// Bad
User getUser(String email);        // findByEmail이 더 명확
User retrieveByEmail(String email); // 불필요하게 복잡
```

#### 변수명

```java
// 명확하고 의미 있는 이름 사용
User authenticatedUser;
String encodedPassword;
LocalDateTime lastLoginAt;

// Bad: 약어나 불명확한 이름
User u;
String pwd;
LocalDateTime ldt;
```

### 2.3 애노테이션 사용 규칙

#### 필수 애노테이션

```java
// Entity
@Entity
@Table(name = "users")
@NoArgsConstructor(access = AccessLevel.PROTECTED)
@Getter
public class UserJpaEntity extends BaseEntity {
  // ...
}

// Service
@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class UserApplicationService {

  @Transactional
  public User createUser(UserCreateRequestDTO dto) {
    // ...
  }
}

// Controller
@RestController
@RequestMapping("/api/v1/users")
@RequiredArgsConstructor
public class UserCreateController {

  @PostMapping
  @ResponseStatus(HttpStatus.CREATED)
  public UserResponseDTO createUser(@Valid @RequestBody UserCreateRequestDTO dto) {
    // ...
  }
}
```

---

## 3. 보안 원칙

### 3.1 인증 및 인가

#### JWT 토큰 관리

```java
// JWT Secret Key는 반드시 환경변수로 관리
@Value("${security.jwt.secretKey}")
private String secretKey;

// 토큰 유효시간 설정
@Value("${security.jwt.expireTime}")
private long expireTime;

// Access Token + Refresh Token 전략
// - Access Token: 15분 (짧은 유효기간)
// - Refresh Token: 7일 (긴 유효기간, Redis 저장)
```

#### 권한 체크

```java
// Method Security 활용
@PreAuthorize("hasRole('ADMIN')")
public void deleteUser(Long userId) {
  // ...
}

// Custom Security Expression
@PreAuthorize("@userSecurityService.isOwner(#userId)")
public void updateProfile(Long userId, ProfileUpdateDTO dto) {
  // ...
}
```

### 3.2 비밀번호 관리

```java
// BCrypt 사용 (strength 12)
PasswordEncoder encoder = new BCryptPasswordEncoder(12);

// 비밀번호 변경 시 반드시 현재 비밀번호 확인
public void changePassword(Long userId, String currentPassword, String newPassword) {
  User user = findById(userId);

  if (!encoder.matches(currentPassword, user.getPassword())) {
    throw new InvalidPasswordException();
  }

  // 비밀번호 재사용 방지 체크
  validatePasswordHistory(user, newPassword);

  user.updatePassword(encoder.encode(newPassword));
}
```

### 3.3 입력 검증

```java
// DTO 레벨 검증
public record UserCreateRequestDTO(
  @NotBlank(message = "이메일은 필수입니다")
  @Email(message = "유효한 이메일 형식이 아닙니다")
  String email,

  @NotBlank(message = "비밀번호는 필수입니다")
  @Pattern(
    regexp = "^(?=.*[A-Za-z])(?=.*\\d)(?=.*[@$!%*#?&])[A-Za-z\\d@$!%*#?&]{8,}$",
    message = "비밀번호는 8자 이상, 영문, 숫자, 특수문자를 포함해야 합니다"
  )
  String password,

  @NotBlank(message = "이름은 필수입니다")
  @Size(min = 2, max = 50, message = "이름은 2-50자 사이여야 합니다")
  String name
) {}
```

---

## 4. 데이터베이스 원칙

### 4.1 JPA 사용 규칙

#### Open-In-View 비활성화

```yaml
spring:
  jpa:
    open-in-view: false  # OSIV 비활성화로 N+1 문제 명시적 해결
```

#### N+1 문제 해결

```java
// Bad: N+1 발생
List<User> users = userRepository.findAll();
users.forEach(user -> {
  user.getProfile();  // 추가 쿼리 발생
});

// Good: Fetch Join 사용
@Query("SELECT u FROM UserJpaEntity u JOIN FETCH u.profile")
List<UserJpaEntity> findAllWithProfile();

// Good: EntityGraph 사용
@EntityGraph(attributePaths = {"profile", "credential"})
List<UserJpaEntity> findAll();
```

#### Dirty Checking vs Query 직접 실행

```java
// 소수의 엔티티 수정: Dirty Checking
@Transactional
public void updateUserStatus(Long userId, UserStatus status) {
  UserJpaEntity user = userRepository.findById(userId)
    .orElseThrow(UserNotFoundException::new);
  user.updateStatus(status);
}

// 대량 데이터 수정: Bulk Update
@Transactional
@Modifying(clearAutomatically = true)
@Query("UPDATE UserJpaEntity u SET u.status = :status WHERE u.lastLoginAt < :date")
int updateInactiveUsersStatus(@Param("status") UserStatus status, @Param("date") LocalDateTime date);
```

### 4.2 트랜잭션 관리

```java
// 조회 전용 서비스는 readOnly = true
@Transactional(readOnly = true)
public User findByEmail(String email) {
  // ...
}

// 쓰기 작업은 명시적으로 @Transactional
@Transactional
public User createUser(UserCreateRequestDTO dto) {
  // ...
}

// 트랜잭션 전파 레벨 명시
@Transactional(propagation = Propagation.REQUIRES_NEW)
public void createAuditLog(Long userId, String action) {
  // 별도 트랜잭션으로 실행
}
```

---

## 5. 테스트 원칙

### 5.1 테스트 레벨

#### 단위 테스트 (Unit Test)

```java
@ExtendWith(MockitoExtension.class)
class UserApplicationServiceTest {

  @Mock
  private UserCrudRepository userRepository;

  @Mock
  private PasswordEncoder passwordEncoder;

  @InjectMocks
  private UserApplicationService userService;

  @Test
  @DisplayName("이메일로 사용자를 조회할 수 있다")
  void findByEmail_Success() {
    // given
    String email = "test@example.com";
    UserJpaEntity entity = createUserEntity(email);
    when(userRepository.findByEmail(email)).thenReturn(Optional.of(entity));

    // when
    User user = userService.findByEmail(email);

    // then
    assertThat(user.getEmail()).isEqualTo(email);
    verify(userRepository).findByEmail(email);
  }
}
```

#### 통합 테스트 (Integration Test)

```java
@SpringBootTest
@AutoConfigureMockMvc
@Transactional
class UserCreateControllerIntegrationTest {

  @Autowired
  private MockMvc mockMvc;

  @Autowired
  private ObjectMapper objectMapper;

  @Test
  @DisplayName("회원 가입 API 통합 테스트")
  void createUser_Integration() throws Exception {
    // given
    UserCreateRequestDTO dto = new UserCreateRequestDTO(
      "test@example.com",
      "Password123!",
      "테스트"
    );

    // when & then
    mockMvc.perform(post("/api/v1/users")
        .contentType(MediaType.APPLICATION_JSON)
        .content(objectMapper.writeValueAsString(dto)))
      .andExpect(status().isCreated())
      .andExpect(jsonPath("$.email").value("test@example.com"));
  }
}
```

### 5.2 테스트 데이터 관리

```java
// Test Fixture 클래스 사용
public class UserFixtures {

  public static UserJpaEntity createUserEntity(String email) {
    return UserJpaEntity.builder()
      .email(email)
      .password("encodedPassword")
      .name("테스트 사용자")
      .status(UserStatus.ACTIVE)
      .build();
  }

  public static UserCreateRequestDTO createUserRequestDTO() {
    return new UserCreateRequestDTO(
      "test@example.com",
      "Password123!",
      "테스트"
    );
  }
}
```

### 5.3 테스트 커버리지 목표

- **단위 테스트**: 80% 이상
- **통합 테스트**: 주요 API 100%
- **Service 레이어**: 90% 이상
- **Controller 레이어**: 80% 이상

---

## 6. 예외 처리 원칙

### 6.1 Custom Exception 정의

```java
// 도메인별 최상위 예외
public class UserException extends RuntimeException {
  public UserException(String message) {
    super(message);
  }
}

// 구체적인 예외
public class UserNotFoundException extends UserException {
  public UserNotFoundException(Long userId) {
    super(String.format("사용자를 찾을 수 없습니다. userId=%d", userId));
  }
}

public class DuplicateEmailException extends UserException {
  public DuplicateEmailException(String email) {
    super(String.format("이미 사용 중인 이메일입니다. email=%s", email));
  }
}
```

### 6.2 Global Exception Handler

```java
@RestControllerAdvice
@Slf4j
public class GlobalExceptionHandler {

  @ExceptionHandler(UserNotFoundException.class)
  @ResponseStatus(HttpStatus.NOT_FOUND)
  public ErrorResponse handleUserNotFound(UserNotFoundException ex) {
    log.warn("User not found: {}", ex.getMessage());
    return ErrorResponse.of("USER_NOT_FOUND", ex.getMessage());
  }

  @ExceptionHandler(MethodArgumentNotValidException.class)
  @ResponseStatus(HttpStatus.BAD_REQUEST)
  public ErrorResponse handleValidationException(MethodArgumentNotValidException ex) {
    Map<String, String> errors = new HashMap<>();
    ex.getBindingResult().getFieldErrors().forEach(error ->
      errors.put(error.getField(), error.getDefaultMessage())
    );
    return ErrorResponse.of("VALIDATION_ERROR", errors);
  }

  @ExceptionHandler(Exception.class)
  @ResponseStatus(HttpStatus.INTERNAL_SERVER_ERROR)
  public ErrorResponse handleException(Exception ex) {
    log.error("Unexpected error occurred", ex);
    return ErrorResponse.of("INTERNAL_SERVER_ERROR", "서버 오류가 발생했습니다");
  }
}
```

---

## 7. 로깅 원칙

### 7.1 로깅 레벨

- **ERROR**: 즉시 대응이 필요한 오류
- **WARN**: 잠재적 문제 상황
- **INFO**: 중요 비즈니스 이벤트
- **DEBUG**: 디버깅 정보
- **TRACE**: 상세한 추적 정보

### 7.2 로깅 가이드

```java
@Slf4j
@Service
public class UserApplicationService {

  public User createUser(UserCreateRequestDTO dto) {
    log.info("Creating new user. email={}", dto.email());  // 민감정보 제외

    try {
      // 비즈니스 로직
      User user = // ...

      log.info("User created successfully. userId={}", user.getId());
      return user;

    } catch (DuplicateEmailException ex) {
      log.warn("Duplicate email attempt. email={}", dto.email());
      throw ex;

    } catch (Exception ex) {
      log.error("Failed to create user. email={}", dto.email(), ex);
      throw new UserCreationException(ex);
    }
  }
}
```

#### 민감 정보 로깅 금지

```java
// ❌ Bad: 비밀번호 로깅
log.info("User login attempt. email={}, password={}", email, password);

// ✅ Good: 민감 정보 제외
log.info("User login attempt. email={}", email);

// ❌ Bad: 전체 DTO 로깅 (민감정보 포함 가능)
log.info("User data: {}", dto.toString());

// ✅ Good: 필요한 정보만 로깅
log.info("Processing user request. userId={}, action={}", userId, action);
```

---

## 8. API 설계 원칙

### 8.1 RESTful API 규칙

#### URL 패턴

```
POST   /api/v1/users              # 회원가입
GET    /api/v1/users/{userId}     # 사용자 조회
PUT    /api/v1/users/{userId}     # 사용자 전체 수정
PATCH  /api/v1/users/{userId}     # 사용자 부분 수정
DELETE /api/v1/users/{userId}     # 사용자 삭제

POST   /api/v1/auth/login         # 로그인
POST   /api/v1/auth/logout        # 로그아웃
POST   /api/v1/auth/refresh       # 토큰 갱신
```

#### HTTP Status Code

```
200 OK                - 조회 성공
201 Created           - 생성 성공
204 No Content        - 삭제 성공

400 Bad Request       - 잘못된 요청
401 Unauthorized      - 인증 실패
403 Forbidden         - 권한 없음
404 Not Found         - 리소스 없음
409 Conflict          - 중복 데이터

500 Internal Server Error - 서버 오류
```

### 8.2 Response 포맷

```json
// 성공 응답
{
  "data": {
    "userId": 1,
    "email": "test@example.com",
    "name": "테스트"
  }
}

// 에러 응답
{
  "error": {
    "code": "USER_NOT_FOUND",
    "message": "사용자를 찾을 수 없습니다",
    "timestamp": "2025-10-29T10:30:00Z"
  }
}

// Validation 에러
{
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "입력 값 검증 실패",
    "fields": {
      "email": "유효한 이메일 형식이 아닙니다",
      "password": "비밀번호는 8자 이상이어야 합니다"
    }
  }
}
```

---

## 9. 성능 최적화 원칙

### 9.1 캐싱 전략

```java
// Redis 캐싱 활용
@Cacheable(value = "users", key = "#userId")
public User findById(Long userId) {
  return userRepository.findById(userId)
    .map(userMapper::toDomain)
    .orElseThrow(() -> new UserNotFoundException(userId));
}

@CacheEvict(value = "users", key = "#userId")
public void updateUser(Long userId, UserUpdateDTO dto) {
  // ...
}
```

### 9.2 페이징 처리

```java
// Cursor-based Pagination (대용량 데이터)
public List<User> findUsers(Long lastUserId, int size) {
  return userRepository.findByIdGreaterThanOrderByIdAsc(lastUserId,
    PageRequest.of(0, size));
}

// Offset-based Pagination (소규모 데이터)
public Page<User> findUsers(Pageable pageable) {
  return userRepository.findAll(pageable)
    .map(userMapper::toDomain);
}
```

---

## 10. 코드 리뷰 체크리스트

### 10.1 필수 확인 사항

- [ ] 비즈니스 로직이 도메인 레이어에 있는가?
- [ ] 레이어 의존성 규칙을 따르는가?
- [ ] DTO와 Entity가 명확히 분리되어 있는가?
- [ ] 모든 public 메서드에 Javadoc이 작성되었는가?
- [ ] 예외 처리가 적절한가?
- [ ] 트랜잭션 범위가 적절한가?
- [ ] N+1 문제가 없는가?
- [ ] 테스트 코드가 작성되었는가?
- [ ] 민감 정보가 로그에 남지 않는가?
- [ ] 입력 검증이 적절한가?

### 10.2 성능 확인 사항

- [ ] 불필요한 DB 쿼리가 없는가?
- [ ] 대용량 데이터 처리 시 페이징을 사용하는가?
- [ ] 캐싱이 필요한 부분에 적용되었는가?
- [ ] Lazy Loading이 적절히 사용되는가?

---

**작성일**: 2025-10-29
**작성자**: Claude Code
**상태**: 초안 (v1.0)
