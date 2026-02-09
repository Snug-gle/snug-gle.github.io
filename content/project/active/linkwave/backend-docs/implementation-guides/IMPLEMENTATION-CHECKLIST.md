---
created: 2025-12-26
---
# LinkWave Backend 구현 체크리스트 및 학습 가이드

이 문서는 `/docs/implementation-guides`의 모든 가이드를 기반으로 **실제 구현해야 할 파일 리스트**와 **핵심 학습 인사이트**를 정리한 종합 문서입니다.

---

## 📋 목차

1. [현재 구현 상태](#현재-구현-상태)
2. [Phase별 구현 체크리스트](#phase별-구현-체크리스트)
3. [핵심 아키텍처 학습 포인트](#핵심-아키텍처-학습-포인트)
4. [실무 적용 인사이트](#실무-적용-인사이트)

---

## 현재 구현 상태

### ✅ 이미 구현된 파일

```
src/main/java/io/iotree/linkwave/
├── application/
│   ├── dto/
│   │   ├── request/
│   │   │   ├── LoginRequest.java ✅
│   │   │   ├── SignUpRequest.java ✅
│   │   │   ├── UpdateServicePriorityRequest.java ✅
│   │   │   ├── RequestPhoneVerificationRequest.java ✅
│   │   │   └── VerifyPhoneRequest.java ✅
│   │   └── response/
│   │       ├── ApiResponse.java ✅
│   │       ├── ErrorResponse.java ✅
│   │       ├── LoginResponse.java ✅
│   │       ├── UserResponse.java ✅
│   │       └── ServicePriorityResponse.java ✅
│   └── service/
│       └── AuthService.java ✅
├── api/
│   └── AuthController.java ✅
├── common/
│   └── exception/
│       ├── BusinessException.java ✅
│       ├── ErrorCode.java ✅
│       └── GlobalExceptionHandler.java ✅
├── domain/
│   ├── user/
│   │   ├── User.java ✅
│   │   ├── UserRole.java ✅
│   │   ├── UserStatus.java ✅
│   │   └── UserType.java ✅
│   ├── organization/
│   │   ├── Organization.java ✅
│   │   ├── BusinessStatus.java ✅
│   │   └── OrganizationStatus.java ✅
│   └── message/
│       └── ServiceType.java ✅
├── infra/
│   ├── jpa/repository/
│   │   ├── UserRepository.java ✅
│   │   └── OrganizationRepository.java ✅
│   └── ServicePriorityConverter.java ✅
└── LinkwaveApplication.java ✅
```

---

## Phase별 구현 체크리스트

### Phase 0: 아키텍처 이해 (00-architecture-overview.md)

#### 📖 학습 목표
- [x] CQRS 패턴 이해 (Command: JPA, Query: MyBatis)
- [x] 하이브리드 비동기 처리 (Push + Pull)
- [x] Closed-Loop Architecture
- [x] 자기 완결적 이벤트 (Self-Contained Events)

#### 💡 핵심 인사이트

**1. CQRS는 기술 선택이 아닌 책임 분리**
- ❌ 잘못된 이해: "JPA는 Command, MyBatis는 Query용 ORM"
- ✅ 올바른 이해: "데이터 변경(Command)과 조회(Query)의 책임을 명확히 분리하는 패턴"
  - Command: 비즈니스 로직 중심, 트랜잭션 관리 필요 → JPA 선택
  - Query: 성능 최적화, 복잡한 조인 필요 → MyBatis 선택

**2. Event-Driven Architecture의 함정**
- ❌ 흔한 실수: 이벤트에 ID만 전달 → 리스너에서 DB 재조회
  ```java
  // ❌ 나쁜 예
  applicationEventPublisher.publishEvent(new MessageSentEvent(messageId));

  // 리스너에서 DB 재조회 (복제 지연 시 데이터 유실!)
  Message message = messageRepository.findById(messageId).orElseThrow();
  ```

- ✅ Self-Contained Event:
  ```java
  // ✅ 좋은 예
  applicationEventPublisher.publishEvent(
      new MessageSentEvent(messageId, phone, content, userId)  // 필요한 데이터 모두 포함
  );

  // 리스너는 DB 조회 없이 이벤트 데이터로 처리
  ```

**3. 비동기 처리의 선택 기준**
- **Push (Application Event)**: 즉시 처리, 응답 속도 중요
  - 예: 즉시 발송 메시지, 실시간 알림
- **Pull (@Scheduled)**: 정해진 시간, 배치 처리
  - 예: 예약 발송, 통계 집계

---

### Phase 1: 예외 처리 및 공통 구조 (01-EXCEPTION-HANDLING.md)

#### ✅ 구현 완료
- [x] ErrorCode.java
- [x] BusinessException.java
- [x] ErrorResponse.java
- [x] ApiResponse.java
- [x] GlobalExceptionHandler.java

#### 💡 핵심 인사이트

**1. 왜 HTTP 상태 코드와 별도로 에러 코드를 관리하나?**

```java
// ErrorCode.java
USER_NOT_FOUND(404, "U001", "User not found"),
DUPLICATE_EMAIL(409, "U002", "Email already exists")
```

- **HTTP 상태 코드만으로는 부족한 이유:**
  - HTTP 404는 "리소스 없음"만 알려줌
  - 어떤 리소스가 없는지 구분 불가
  - 프론트엔드가 에러별 처리 불가

- **애플리케이션 에러 코드의 이점:**
  ```javascript
  // 프론트엔드에서 에러 코드별 처리
  if (error.errorCode === 'U001') {
    navigate('/signup');  // 사용자 없음 → 회원가입 유도
  } else if (error.errorCode === 'U002') {
    showMessage('이미 사용 중인 이메일입니다');
  }
  ```

**2. Validation 에러 상세 정보의 중요성**

```json
{
  "errorCode": "C001",
  "message": "Invalid input value",
  "fieldErrors": [
    {
      "field": "email",
      "value": "invalid-email",
      "message": "이메일 형식이 올바르지 않습니다"
    }
  ]
}
```

- **사용자 경험 향상:**
  - 어떤 필드가 잘못되었는지 명확히 표시
  - 잘못된 값을 보여주어 수정 용이
  - 프론트엔드가 필드별로 에러 메시지 표시 가능

**3. @RestControllerAdvice의 동작 원리**

```java
@RestControllerAdvice
public class GlobalExceptionHandler {
    @ExceptionHandler(BusinessException.class)
    public ResponseEntity<ApiResponse<Void>> handleBusinessException(BusinessException e) {
        // 모든 Controller에서 발생한 BusinessException을 여기서 처리
    }
}
```

- **장점:**
  - Controller마다 try-catch 불필요
  - 에러 처리 로직 중앙 집중화
  - 일관된 에러 응답 형식

---

### Phase 2: Organization 도메인 (02-ORGANIZATION_DOMAIN.md)

#### ❓ 구현 필요 여부 확인
- [x] Organization.java (이미 존재)
- [ ] PhoneVerification.java (휴대폰 인증 엔티티)
- [ ] PhoneVerificationRepository.java
- [ ] BusinessVerification.java (사업자번호 검증 이력)
- [ ] BusinessVerificationRepository.java
- [ ] PhoneVerificationService.java (SMS 인증 로직)
- [ ] NtsBusinessVerificationService.java (국세청 API 연동)

#### 💡 핵심 인사이트

**1. 개인/법인 통합 테이블 설계의 장단점**

```sql
-- users 테이블에 개인과 법인 모두 저장
CREATE TABLE users (
    user_id VARCHAR(50),
    user_type VARCHAR(20),  -- INDIVIDUAL | BUSINESS
    organization_id VARCHAR(50) NULL,

    CONSTRAINT chk_business_user CHECK (
        (user_type = 'INDIVIDUAL' AND organization_id IS NULL) OR
        (user_type = 'BUSINESS' AND organization_id IS NOT NULL)
    )
);
```

**장점:**
- 단일 인증 시스템 (로그인, JWT 발급)
- 사용자 ID 중복 방지
- 쿼리 단순화 (JOIN 불필요)

**단점:**
- 테이블이 비대해질 수 있음
- 컬럼 중 일부는 특정 타입에만 사용됨

**2. 제약 조건(Constraint)의 실무 활용**

```sql
-- DB 레벨에서 데이터 무결성 보장
CONSTRAINT chk_business_user CHECK (
    (user_type = 'INDIVIDUAL' AND organization_id IS NULL) OR
    (user_type = 'BUSINESS' AND organization_id IS NOT NULL)
)
```

- **중요성:**
  - 애플리케이션 버그로도 잘못된 데이터 삽입 불가
  - 다른 시스템과 DB 공유 시에도 무결성 보장
  - "방어적 프로그래밍"의 핵심

**3. 외부 API 연동 패턴 (국세청 API 예시)**

```java
public class NtsBusinessVerificationService {
    public VerificationResult verifyBusinessNumber(
        String businessNumber,
        String organizationName,
        String representativeName
    ) {
        // 1. API 호출
        NtsApiResponse response = restTemplate.postForObject(...);

        // 2. 응답 저장 (원본 JSON 보관)
        businessVerificationRepository.save(
            BusinessVerification.builder()
                .ntsApiResponse(objectMapper.writeValueAsString(response))
                .build()
        );

        // 3. 비즈니스 로직 처리
        return response.getStatus() == "01"
            ? VerificationResult.SUCCESS
            : VerificationResult.FAIL;
    }
}
```

**배울 점:**
- 외부 API 응답은 **항상 원본 보관** (추후 검증/감사용)
- 실패 응답도 저장 (디버깅, 통계)
- 타임아웃, 재시도 로직 필수

---

### Phase 3: JWT 인프라 (03-JWT-INFRASTRUCTURE.md)

#### 📦 구현 필요 파일
- [ ] JwtTokenProvider.java
- [ ] RefreshToken.java (Entity)
- [ ] RefreshTokenRepository.java
- [ ] CustomUserDetailsService.java
- [ ] JwtAuthenticationFilter.java
- [ ] JwtAuthenticationEntryPoint.java
- [ ] SecurityConfig.java
- [ ] PasswordEncoder Bean 설정

#### 📝 build.gradle.kts 의존성 추가
```kotlin
dependencies {
    // JWT
    implementation("io.jsonwebtoken:jjwt-api:0.12.3")
    runtimeOnly("io.jsonwebtoken:jjwt-impl:0.12.3")
    runtimeOnly("io.jsonwebtoken:jjwt-jackson:0.12.3")
}
```

#### 📝 application.yml 설정 추가
```yaml
linkwave:
  jwt:
    secret: ${JWT_SECRET:YourBase64EncodedSecretKeyMustBeAtLeast256BitsLongForHS256AlgorithmToWorkProperlyAndSecurely}
    access-token-expiration: 3600000      # 1시간 (ms)
    refresh-token-expiration: 604800000   # 7일 (ms)
```

#### 💡 핵심 인사이트

**1. Access Token vs Refresh Token의 존재 이유**

| 구분 | Access Token | Refresh Token |
|------|-------------|---------------|
| 만료 시간 | 짧음 (1시간) | 길음 (7일) |
| 저장 위치 | 메모리/로컬스토리지 | **DB** |
| 용도 | API 요청 인증 | Access Token 재발급 |

**왜 2개의 토큰?**
- **보안:** Access Token 탈취 시 피해 최소화 (1시간 후 자동 만료)
- **사용성:** 매번 로그인 불필요 (Refresh Token으로 자동 갱신)
- **무효화:** DB에서 Refresh Token 삭제 → 로그아웃 구현

**2. JWT Secret의 보안 중요성**

```java
// ❌ 절대 금지: 코드에 하드코딩
private String secretKey = "my-secret-key";

// ✅ 올바른 방법: 환경 변수 + Base64
@Value("${linkwave.jwt.secret}")
private String secretKey;  // 환경 변수에서 주입
```

**Secret 생성 방법:**
```bash
# 512비트 (64바이트) 랜덤 생성 → Base64 인코딩
openssl rand -base64 64
```

**3. Spring Security Filter Chain의 동작 순서**

```
HTTP Request
  ↓
1. JwtAuthenticationFilter (커스텀)
  → Authorization 헤더에서 토큰 추출
  → 토큰 검증
  → SecurityContext에 인증 정보 저장
  ↓
2. UsernamePasswordAuthenticationFilter (Spring 기본)
  ↓
3. Controller 실행
  ↓
4. @PreAuthorize("hasRole('ADMIN')") 권한 검증
```

**핵심:**
- `addFilterBefore()`: JWT 필터를 **먼저** 실행
- SecurityContext에 인증 정보가 있어야 권한 검증 가능

**4. 왜 UserDetailsService를 구현하나?**

```java
@Service
public class CustomUserDetailsService implements UserDetailsService {
    @Override
    public UserDetails loadUserByUsername(String email) {
        // DB에서 사용자 조회
        User user = userRepository.findByEmail(email).orElseThrow();

        // Spring Security의 UserDetails로 변환
        return org.springframework.security.core.userdetails.User.builder()
            .username(user.getEmail())
            .password(user.getPassword())
            .roles(user.getRole().name())
            .build();
    }
}
```

**이유:**
- Spring Security는 `UserDetails` 인터페이스만 이해
- 우리의 `User` 엔티티를 Security가 사용할 수 있게 변환
- 로그인 시 자동 호출되어 비밀번호 검증

---

### Phase 4: User 도메인 및 인증 (04-USER-AUTH.md)

#### ✅ 대부분 구현 완료
- [x] UserRole.java
- [x] UserStatus.java
- [x] UserType.java
- [x] User.java
- [x] UserRepository.java
- [x] SignUpRequest.java
- [x] LoginRequest.java
- [x] LoginResponse.java
- [x] UserResponse.java
- [x] AuthService.java (일부 구현)
- [x] AuthController.java

#### 📦 추가 구현 필요
- [ ] RefreshTokenRequest.java
- [ ] RefreshTokenResponse.java
- [ ] AuthService 완성 (login, refreshAccessToken, logout 메서드)

#### 💡 핵심 인사이트

**1. Entity vs DTO의 분리 원칙**

```java
// ❌ 나쁜 예: Entity를 직접 반환
@PostMapping("/signup")
public User signup(@RequestBody User user) {
    return userRepository.save(user);
}
```

**문제점:**
- `password` 필드가 응답에 노출
- Entity 변경 시 API 스펙 변경
- JPA의 Lazy Loading 문제

```java
// ✅ 좋은 예: DTO 사용
@PostMapping("/signup")
public ApiResponse<UserResponse> signup(@RequestBody SignUpRequest request) {
    User user = authService.signup(request);
    return ApiResponse.success(UserResponse.from(user));  // Entity → DTO 변환
}
```

**2. 비밀번호 보안의 3원칙**

```java
// 1. 암호화 저장
String encodedPassword = passwordEncoder.encode(request.getPassword());

// 2. 검증 시에도 암호화 비교
if (!passwordEncoder.matches(rawPassword, encodedPassword)) {
    throw new BusinessException(ErrorCode.INVALID_CREDENTIALS);
}

// 3. 실패 메시지는 모호하게
// ❌ "비밀번호가 틀렸습니다" → 아이디는 존재한다는 정보 유출
// ✅ "이메일 또는 비밀번호가 잘못되었습니다" → 어느 쪽이 틀렸는지 모름
```

**3. 회원가입 시 첫 번째 사용자는 ADMIN**

```java
// 조직의 첫 가입자인지 확인 → ORGANIZATION_ADMIN 부여
// Command 트랜잭션 내 보조 조회이므로 JPA 사용 (데이터 일관성 보장)
long memberCount = userRepository.countByOrganization(organization);
UserRole role = (memberCount == 0) ? UserRole.ORGANIZATION_ADMIN : UserRole.ORGANIZATION_MEMBER;
```

**실무 적용:**
- 첫 사용자가 자동으로 관리자 권한 획득
- 이후 사용자는 ADMIN이 권한 부여
- B2B SaaS 서비스의 일반적인 패턴

**4. UUID vs Auto Increment PK**

```java
// 현재 User Entity
@Id
@GeneratedValue(strategy = GenerationType.UUID)
private UUID userId;
```

**UUID의 장단점:**

**장점:**
- 분산 시스템에서 ID 충돌 없음
- PK 값으로 생성 순서 추측 불가 (보안)
- 마이그레이션 시 유리

**단점:**
- 인덱스 크기 증가 (36자 vs 8바이트)
- 가독성 낮음
- 조회 성능 약간 저하

**선택 기준:**
- **UUID 권장:** 사용자, 조직 (보안 중요, 외부 노출)
- **Auto Increment 권장:** 내부 로그, 통계 (성능 중요)

---

### Phase 5: 설정 파일 (05-CONFIGURATION.md)

#### 📝 구현 필요 파일
- [ ] build.gradle.kts 의존성 완성
- [ ] application.yml 설정 완성
- [ ] application-local.yml (로컬 개발용)
- [ ] config/.env (환경 변수)
- [ ] .gitignore에 .env 추가

#### 📦 추가할 의존성
```kotlin
dependencies {
    // 기본 스택
    implementation("org.springframework.boot:spring-boot-starter-web")
    implementation("org.springframework.boot:spring-boot-starter-data-jpa")
    implementation("org.springframework.boot:spring-boot-starter-security")
    implementation("org.springframework.boot:spring-boot-starter-validation")

    // Database
    runtimeOnly("com.mysql:mysql-connector-j")

    // JWT (Phase 3에서 추가)
    implementation("io.jsonwebtoken:jjwt-api:0.12.3")
    runtimeOnly("io.jsonwebtoken:jjwt-impl:0.12.3")
    runtimeOnly("io.jsonwebtoken:jjwt-jackson:0.12.3")

    // MyBatis (향후 추가)
    // implementation("org.mybatis.spring.boot:mybatis-spring-boot-starter:3.0.3")
}
```

#### 💡 핵심 인사이트

**1. Profile별 설정 관리**

```yaml
# application.yml (공통 설정)
spring:
  profiles:
    active: ${SPRING_PROFILES_ACTIVE:local}

# application-local.yml (로컬 개발)
spring:
  jpa:
    hibernate:
      ddl-auto: update  # 자동 스키마 업데이트
    show-sql: true

# application-prod.yml (운영 환경)
spring:
  jpa:
    hibernate:
      ddl-auto: validate  # 스키마 검증만
    show-sql: false
```

**실무 활용:**
- 로컬: `ddl-auto: update` (편의성)
- 개발: `ddl-auto: validate` (안정성)
- 운영: `ddl-auto: none` (Flyway/Liquibase로 마이그레이션)

**2. 민감 정보 관리의 3단계**

```yaml
# 1단계: 기본값 제공 (개발 편의)
linkwave:
  jwt:
    secret: ${JWT_SECRET:default-dev-secret-key-base64-encoded}

# 2단계: 환경 변수로 오버라이드
export JWT_SECRET=production-secret-key

# 3단계: .env 파일 사용
# config/.env
JWT_SECRET=production-secret-key-from-file
```

**우선순위:**
1. 환경 변수 (최우선)
2. .env 파일
3. application.yml 기본값

---

### Phase 6: 서비스별 권한 및 우선순위 (05-SERVICE-PERMISSIONS.md)

#### ✅ 이미 구현됨
- [x] ServiceType.java
- [x] ServicePriorityConverter.java
- [x] UpdateServicePriorityRequest.java
- [x] ServicePriorityResponse.java
- [x] User.java에 servicePriority 필드 추가

#### 📦 추가 구현 필요
- [ ] AdminService.java (서비스 우선순위 관리)
- [ ] AdminController.java
- [ ] MessageService.java (Fallback 전송 로직)
- [ ] ServicePermissionInterceptor.java (권한 검증)
- [ ] WebConfig.java (Interceptor 등록)

#### 💡 핵심 인사이트

**1. JSON vs 비트마스크: 실무 설계 결정**

| 요구사항 | 비트마스크 | JSON 배열 | 선택 |
|---------|-----------|----------|------|
| 권한 표현 | ✅ | ✅ | 둘 다 가능 |
| 우선순위 | ❌ | ✅ | **JSON 선택** |
| 성능 | 빠름 | 약간 느림 | 6개 서비스는 무시 가능 |
| 가독성 | 7 = ? | `["SMS", "LMS"]` | **JSON 우세** |
| 확장성 | 32개 제한 | 무제한 | JSON 우세 |

**결론:**
- **비트마스크 적합:** 단순 권한만 필요, 사용자 수백만, 서비스 32개 이하
- **JSON 적합:** 우선순위 필요, 사용자 수백만 이하, 가독성 중요

**2. AttributeConverter의 마법**

```java
// JPA가 Entity ↔ DB 변환 시 자동 호출
@Converter
public class ServicePriorityConverter
    implements AttributeConverter<List<ServiceType>, String> {

    @Override
    public String convertToDatabaseColumn(List<ServiceType> attribute) {
        // Java List → JSON String (DB 저장)
        return objectMapper.writeValueAsString(attribute);
    }

    @Override
    public List<ServiceType> convertToEntityAttribute(String dbData) {
        // JSON String → Java List (DB 조회)
        return objectMapper.readValue(dbData, new TypeReference<>() {});
    }
}
```

**Entity에서 사용:**
```java
@Column(name = "service_priority", columnDefinition = "JSON")
@Convert(converter = ServicePriorityConverter.class)
private List<ServiceType> servicePriority;  // 개발자는 List<ServiceType>만 다룸!
```

**개발자 경험:**
- DB에는 JSON 문자열로 저장
- 코드에서는 `List<ServiceType>`로 사용
- 변환은 JPA가 자동 처리 → 생산성 향상

**3. Fallback 전송 로직의 실무 패턴**

```java
public void sendMessageWithFallback(User user, String phone, String content) {
    List<ServiceType> fallbackOrder = user.getServiceFallbackOrder();

    for (ServiceType serviceType : fallbackOrder) {
        try {
            sendViaService(serviceType, phone, content);
            log.info("메시지 전송 성공: service={}", serviceType);
            return;  // 성공하면 즉시 종료
        } catch (Exception e) {
            log.warn("메시지 전송 실패: service={}, 다음 서비스 시도", serviceType);
            // 다음 서비스로 계속
        }
    }

    throw new BusinessException(ErrorCode.ALL_SERVICES_FAILED);
}
```

**실무 적용:**
- **카카오톡 → SMS → LMS** 우선순위
- 카카오톡 API 장애 시 자동으로 SMS로 발송
- 사용자 설정에 따라 동적으로 Fallback
- 로그로 각 단계 추적 (통계, 디버깅)

---

## 핵심 아키텍처 학습 포인트

### 1. 하이브리드 JPA + MyBatis 아키텍처

#### 도메인 분리 전략
```
User Domain (JPA)
└── users, organizations, sender_numbers, address_book
    → 비즈니스 로직 중심, CRUD, 트랜잭션 관리

Message Domain (MyBatis)
└── ums_msg, ums_log_{YYYYMM}, stats
    → 대량 삽입, 복잡한 쿼리, 성능 최적화
```

#### 안전한 패턴
```java
// ✅ 패턴 1: 단일 도메인 접근 (가장 안전)
@Service
public class UserService {
    private final UserRepository userRepository;  // JPA만
}

// ✅ 패턴 2: 도메인 교차 읽기 (안전)
@Transactional(readOnly = true)
public UserStatistics getUserStats(UUID userId) {
    User user = userRepository.findById(userId).orElseThrow();  // JPA
    MessageStats stats = umsMsgMapper.getStatsByUserId(userId);  // MyBatis
    return new UserStatistics(user, stats);
}

// ⚠️ 패턴 3: 도메인 교차 쓰기 (flush 필수)
@Transactional
public void updateUserAndSendMessage(UUID userId) {
    User user = userRepository.findById(userId).orElseThrow();
    user.incrementMessageCount();

    entityManager.flush();  // ⭐ 필수! MyBatis가 최신 데이터를 볼 수 있게

    umsMsgMapper.insertMessage(...);
}
```

### 2. API 응답 구조의 일관성

```java
// 모든 API는 ApiResponse<T>로 래핑
public record ApiResponse<T>(
    boolean success,
    T data,
    ErrorResponse error,
    LocalDateTime timestamp
) {
    public static <T> ApiResponse<T> success(T data) {
        return new ApiResponse<>(true, data, null, LocalDateTime.now());
    }

    public static <T> ApiResponse<T> error(ErrorResponse error) {
        return new ApiResponse<>(false, null, error, LocalDateTime.now());
    }
}
```

**프론트엔드에서:**
```javascript
const response = await api.get('/users/me');
if (response.success) {
    setUser(response.data);
} else {
    showError(response.error.message);
}
```

### 3. 트랜잭션 경계의 설계

```java
// ❌ Repository에 @Transactional (안티패턴)
@Repository
public interface UserRepository extends JpaRepository<User, UUID> {
    // JPA Repository는 자체적으로 트랜잭션 관리
}

// ✅ Service에 @Transactional (올바른 패턴)
@Service
public class UserService {
    @Transactional
    public User createUser(SignUpRequest request) {
        // 1. 검증 로직
        // 2. 비즈니스 로직
        // 3. Repository 호출
        // → 하나의 트랜잭션으로 관리
    }
}
```

**원칙:**
- **Service**: 비즈니스 로직 + 트랜잭션 경계
- **Repository**: 데이터 접근만

---

## 실무 적용 인사이트

### 1. 보안 설계의 계층화

```
계층 1: 네트워크 (HTTPS, CORS)
계층 2: 인증 (JWT, Session)
계층 3: 인가 (Role, Permission)
계층 4: 데이터 (암호화, 마스킹)
```

**코드 예시:**
```java
// 계층 2: JWT 인증
@Component
public class JwtAuthenticationFilter extends OncePerRequestFilter { ... }

// 계층 3: 역할 기반 인가
@PreAuthorize("hasRole('ADMIN')")
@PostMapping("/admin/users")
public void createUser() { ... }

// 계층 4: 민감 데이터 마스킹
public class UserResponse {
    private String phone;  // "010-****-5678" (마스킹)
    // password는 응답에 포함하지 않음
}
```

### 2. 테스트 가능한 코드 설계

```java
// ❌ 테스트 어려운 코드
public class AuthService {
    public User signup(SignUpRequest request) {
        String password = BCrypt.hashpw(request.getPassword(), BCrypt.gensalt());
        // BCrypt가 static 메서드 → Mock 불가능
    }
}

// ✅ 테스트 쉬운 코드
public class AuthService {
    private final PasswordEncoder passwordEncoder;  // 주입받음

    public User signup(SignUpRequest request) {
        String password = passwordEncoder.encode(request.getPassword());
        // Mock 가능 → 테스트 쉬움
    }
}
```

### 3. 로깅 전략

```java
// ❌ 나쁜 로깅
log.info("User created");  // 어떤 사용자? 언제?

// ✅ 좋은 로깅
log.info("User signup success: userId={}, username={}, timestamp={}",
    user.getUserId(),
    user.getUsername(),
    LocalDateTime.now()
);

// ⚠️ 민감 정보는 로깅 금지
log.info("Password: {}", password);  // ❌ 절대 금지
```

**실무 팁:**
- **INFO**: 비즈니스 이벤트 (회원가입, 로그인)
- **WARN**: 예상 가능한 에러 (잘못된 입력)
- **ERROR**: 시스템 에러 (DB 연결 실패)
- **DEBUG**: 개발 중 디버깅 (로컬에서만)

### 4. 점진적 기능 개발

```
1단계: 핵심 기능 (MVP)
├── 회원가입/로그인
├── JWT 인증
└── 기본 CRUD

2단계: 보안 강화
├── 이메일 인증
├── 휴대폰 인증
└── 2FA (선택)

3단계: 고도화
├── 권한 관리
├── 서비스 우선순위
└── Fallback 로직

4단계: 운영 최적화
├── 캐싱 (Redis)
├── 비동기 처리
└── 모니터링
```

**핵심:**
- 한 번에 완벽하게 구현 X
- 동작하는 버전을 빠르게 만들고 반복 개선
- 각 단계마다 테스트 + 배포

---

## 다음 단계

### 학습 순서 추천

1. **Phase 1-2 완성** (예외 처리, 기본 도메인)
   - ErrorCode 추가
   - Organization 관련 서비스 구현

2. **Phase 3 구현** (JWT 인프라)
   - 가장 중요하고 배울 게 많은 단계
   - Spring Security 이해 필수

3. **Phase 4 완성** (인증 완성)
   - 로그인/로그아웃/토큰 갱신
   - 실제 API 테스트

4. **Phase 5-6** (고급 기능)
   - 서비스 권한
   - Fallback 로직

### 실습 프로젝트 아이디어

1. **Mini Twitter Clone**
   - 회원가입/로그인 (JWT)
   - 트윗 작성/조회 (CRUD)
   - 팔로우 기능 (M:N 관계)

2. **E-commerce Backend**
   - 상품 관리 (JPA)
   - 주문 처리 (트랜잭션)
   - 재고 관리 (동시성 제어)

3. **메시징 플랫폼** (현재 프로젝트)
   - 다중 채널 발송
   - Fallback 로직
   - 통계 시스템

---

**이 체크리스트를 기반으로 단계별로 구현하면서 실무 경험을 쌓아보세요!** 🚀