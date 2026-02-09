---
created: 2025-12-26
---
# Phase 4: User 도메인 및 인증

## 📌 학습 목표

이 가이드를 통해 다음을 학습합니다:

1. **User Entity** 설계 (UUID PK, Organization 연관관계)
2. **CQRS 패턴** 적용 (회원가입: JPA, 로그인: MyBatis)
3. **팩토리 메서드 패턴** (엔티티 생성 로직 캡슐화)
4. **개인/법인 사용자** 구분 (UserType)

---

## 🎯 비즈니스 요구사항

| 요구사항    | 설명                                          |
| ----------- | --------------------------------------------- |
| 사용자 유형 | 개인(INDIVIDUAL) / 법인(BUSINESS)             |
| 필수 인증   | 휴대폰 SMS 인증                               |
| 선택 인증   | 이메일 인증 (이메일 입력 시)                  |
| 역할        | USER, ORGANIZATION_ADMIN, ORGANIZATION_MEMBER |
| 상태        | ACTIVE, SUSPENDED, DELETED                    |

---

## 🏗️ 아키텍처: CQRS + Factory Method

### 전체 구조

```
┌─────────────────────────────────────────────────────────────────────────┐
│                              API Layer                                  │
│                          AuthController                                 │
└─────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                         Application Layer                               │
├─────────────────────────────────────────────────────────────────────────┤
│  AuthService                                                            │
│      │                                                                  │
│      ├── UserRepository (JPA) ◄────── Command (저장, 중복체크)          │
│      │                                                                  │
│      └── UserQueryMapper (MyBatis) ◄── Query (로그인 조회)              │
│                                                                         │
│  User.createForSignUp() ◄────────────── 팩토리 메서드 (엔티티 생성)     │
└─────────────────────────────────────────────────────────────────────────┘
                                    │
            ┌───────────────────────┴───────────────────────┐
            │                                               │
            ▼                                               ▼
┌───────────────────────────────┐       ┌───────────────────────────────┐
│     JPA (Command)             │       │     MyBatis (Query)           │
├───────────────────────────────┤       ├───────────────────────────────┤
│  UserRepository               │       │  UserQueryMapper              │
│  - save()                     │       │  - findByUsername()           │
│  - existsByUsername()         │       │                               │
│  - countByOrganization()      │       │                               │
└───────────────────────────────┘       └───────────────────────────────┘
```

### 설계 원칙

| 패턴               | 적용                               | 이점                    |
| ------------------ | ---------------------------------- | ----------------------- |
| **CQRS**           | Command(JPA) / Query(MyBatis) 분리 | 각각 최적화된 기술 사용 |
| **Factory Method** | `User.createForSignUp()`           | 엔티티 생성 로직 캡슐화 |
| **Pragmatic**      | Repository 직접 사용               | 단순함, 빠른 개발       |

---

## 🏗️ 패키지 구조

```
src/main/java/io/iotree/linkwave/
├── domain/
│   └── user/
│       ├── User.java             # Entity + 팩토리 메서드
│       ├── UserType.java         # enum (INDIVIDUAL/BUSINESS)
│       ├── UserRole.java         # enum
│       └── UserStatus.java       # enum
├── application/
│   ├── service/
│   │   └── AuthService.java      # 비즈니스 로직 (CQRS)
│   └── dto/
│       ├── request/
│       │   ├── SignUpRequest.java
│       │   ├── LoginRequest.java
│       │   └── UserLoginQueryDto.java
│       └── response/
│           └── LoginResponse.java
├── infra/
│   ├── jpa/
│   │   └── repository/
│   │       └── UserRepository.java   # Command (JPA)
│   └── mybatis/
│       └── mapper/
│           └── UserQueryMapper.java  # Query (MyBatis)
└── api/
    └── AuthController.java
```

---

## 📝 1~3. Domain Layer (enum)

```java
// domain/user/UserType.java
public enum UserType {
    INDIVIDUAL,  // 개인 사용자
    BUSINESS     // 법인 사용자
}

// domain/user/UserRole.java
public enum UserRole {
    USER,                   // 기본 개인 사용자
    ORGANIZATION_ADMIN,     // 조직 관리자
    ORGANIZATION_MEMBER     // 조직 구성원
}

// domain/user/UserStatus.java
public enum UserStatus {
    ACTIVE,     // 활성
    SUSPENDED,  // 정지
    DELETED     // 삭제됨
}
```

---

## 📝 4. User Entity + Factory Method

**위치**: `src/main/java/io/iotree/linkwave/domain/user/User.java`

### 핵심 필드

| 필드         | 타입         | 설명               | 제약조건         |
| ------------ | ------------ | ------------------ | ---------------- |
| userId       | UUID         | Primary Key        | AUTO_GENERATED   |
| userType     | UserType     | 개인/법인 구분     | NOT NULL         |
| organization | Organization | 소속 조직 (법인만) | NULLABLE         |
| username     | String       | 로그인 아이디      | NOT NULL, UNIQUE |
| password     | String       | BCrypt 암호화      | NOT NULL         |
| role         | UserRole     | 역할               | NOT NULL         |
| status       | UserStatus   | 상태               | NOT NULL         |

### 팩토리 메서드

```java
@Entity
@Table(name = "users")
public class User extends BaseEntity {

    // ... 필드 생략 ...

    /**
     * 회원가입용 User 생성 팩토리 메서드
     */
    public static User createForSignUp(
        String username,
        String encodedPassword,
        String name,
        String phone,
        String email,
        String displayName,
        UserType userType,
        Organization organization,
        UserRole role) {
      return User.builder()
          .username(username)
          .password(encodedPassword)
          .name(name)
          .phone(phone)
          .email(email)
          .displayName(displayName)
          .userType(userType)
          .organization(organization)
          .role(role)
          .status(UserStatus.ACTIVE)
          .build();
    }
}
```

### 팩토리 메서드의 이점

1. **생성 로직 캡슐화**: Builder 호출을 한 곳에서 관리
2. **의도 명확**: `createForSignUp`이라는 이름으로 용도 표현
3. **기본값 보장**: `status = ACTIVE` 등 기본값 설정
4. **Service 간소화**: 10줄 → 1줄

---

## 📝 5. Infrastructure Layer

### UserRepository (JPA - Command)

**위치**: `src/main/java/io/iotree/linkwave/infra/jpa/repository/UserRepository.java`

```java
@Repository
public interface UserRepository extends JpaRepository<User, UUID> {

    Optional<User> findByUsername(String username);

    boolean existsByUsername(String username);

    boolean existsByPhone(String phone);

    boolean existsByEmail(String email);

    long countByOrganization(Organization organization);
}
```

### UserQueryMapper (MyBatis - Query)

**위치**: `src/main/java/io/iotree/linkwave/infra/mybatis/mapper/UserQueryMapper.java`

```java
@Mapper
public interface UserQueryMapper {

    Optional<UserLoginQueryDto> findByUsername(@Param("username") String username);
}
```

**위치**: `src/main/resources/mybatis/mapper/UserQueryMapper.xml`

```xml
<mapper namespace="io.iotree.linkwave.infra.mybatis.mapper.UserQueryMapper">
    <select id="findByUsername" resultType="...UserLoginQueryDto">
        SELECT user_id AS userId, username, password, role, status
        FROM users
        WHERE username = #{username}
    </select>
</mapper>
```

---

## 📝 6. AuthService (Application Layer)

**위치**: `src/main/java/io/iotree/linkwave/application/service/AuthService.java`

```java
@Slf4j
@Service
@RequiredArgsConstructor
public class AuthService {

    private final UserRepository userRepository;           // Command (JPA)
    private final UserQueryMapper userQueryMapper;         // Query (MyBatis)
    private final OrganizationRepository organizationRepository;
    private final PasswordEncoder passwordEncoder;
    private final JwtTokenProvider jwtTokenProvider;

    /**
     * 회원가입 (Command - JPA)
     */
    @Transactional
    public String signupAndIssueToken(SignUpRequest request) {
        log.info("회원가입 시도: username={}", request.username());

        // 1. 유효성 검증
        request.validate();

        // 2. 중복 체크
        validateDuplicate(request);

        // 3. Organization 조회 (법인 회원인 경우)
        Organization organization = findOrganizationIfBusiness(request);

        // 4. 역할 결정
        UserRole role = determineRole(request.userType(), organization);

        // 5. User 생성 및 저장 (팩토리 메서드 사용) ⭐
        User savedUser = userRepository.save(
            User.createForSignUp(
                request.username(),
                passwordEncoder.encode(request.password()),
                request.name(),
                request.phone(),
                request.email(),
                request.displayName(),
                request.userType(),
                organization,
                role));

        log.info("회원가입 완료: userId={}", savedUser.getUserId());

        // 6. JWT 토큰 발급
        return jwtTokenProvider.generateAccessToken(
            savedUser.getUsername(), savedUser.getRole().name());
    }

    /**
     * 로그인 (Query - MyBatis)
     */
    @Transactional(readOnly = true)
    public LoginResponse login(LoginRequest request) {
        log.info("로그인 시도: username={}", request.username());

        // 1. MyBatis로 사용자 조회 (최소 필드만)
        UserLoginQueryDto user = userQueryMapper
            .findByUsername(request.username())
            .orElseThrow(() -> new BusinessException(ErrorCode.INVALID_CREDENTIALS));

        // 2. 비밀번호 검증
        if (!passwordEncoder.matches(request.password(), user.password())) {
            throw new BusinessException(ErrorCode.INVALID_CREDENTIALS);
        }

        // 3. 상태 확인
        if (!"ACTIVE".equals(user.status())) {
            throw new BusinessException(ErrorCode.USER_INACTIVE);
        }

        // 4. JWT 토큰 발급
        String accessToken = jwtTokenProvider.generateAccessToken(
            user.username(), user.role());

        return LoginResponse.builder()
            .accessToken(accessToken)
            .tokenType("Bearer")
            .userId(user.userId())
            .username(user.username())
            .role(user.role())
            .build();
    }

    // ========== Private Methods ==========

    private void validateDuplicate(SignUpRequest request) {
        if (userRepository.existsByUsername(request.username())) {
            throw new BusinessException(ErrorCode.DUPLICATE_EMAIL, "이미 사용 중인 아이디입니다");
        }
        if (userRepository.existsByPhone(request.phone())) {
            throw new BusinessException(ErrorCode.DUPLICATE_EMAIL, "이미 사용 중인 휴대폰 번호입니다");
        }
    }

    private Organization findOrganizationIfBusiness(SignUpRequest request) {
        if (request.userType() == UserType.BUSINESS) {
            return organizationRepository
                .findById(request.organizationId())
                .orElseThrow(() -> new BusinessException(ErrorCode.ORGANIZATION_NOT_FOUND));
        }
        return null;
    }

    private UserRole determineRole(UserType userType, Organization organization) {
        if (userType == UserType.INDIVIDUAL) {
            return UserRole.USER;
        }
        long memberCount = userRepository.countByOrganization(organization);
        return memberCount == 0 ? UserRole.ORGANIZATION_ADMIN : UserRole.ORGANIZATION_MEMBER;
    }
}
```

---

## ✅ 구현 체크리스트

### Domain

- [x] `UserType.java` (INDIVIDUAL/BUSINESS)
- [x] `UserRole.java` (USER/ORGANIZATION_ADMIN/ORGANIZATION_MEMBER)
- [x] `UserStatus.java` (ACTIVE/SUSPENDED/DELETED)
- [x] `User.java` (Entity + Factory Method)

### Infrastructure

- [x] `UserRepository.java` (JPA - Command)
- [x] `UserQueryMapper.java` + XML (MyBatis - Query)

### DTO

- [x] `SignUpRequest.java`
- [x] `LoginRequest.java`
- [x] `UserLoginQueryDto.java`
- [x] `LoginResponse.java`

### Service

- [x] `AuthService.java` (CQRS + Factory Method)

---

## 💡 핵심 인사이트

### CQRS 패턴

| 작업               | 기술    | 이유                         |
| ------------------ | ------- | ---------------------------- |
| 회원가입 (Command) | JPA     | 트랜잭션, Dirty Checking     |
| 로그인 (Query)     | MyBatis | 최소 필드만 조회, SQL 최적화 |

### Factory Method 패턴

```java
// Before: Service에서 Builder 직접 호출 (10줄+)
User user = User.builder()
    .username(request.username())
    .password(passwordEncoder.encode(request.password()))
    // ... 8줄 더
    .build();
User savedUser = userRepository.save(user);

// After: Factory Method 사용 (1줄)
User savedUser = userRepository.save(
    User.createForSignUp(request.username(), encodedPassword, ...));
```

### 왜 Port/Adapter를 사용하지 않나요?

| Port/Adapter           | Factory Method           |
| ---------------------- | ------------------------ |
| 파일 4개 추가          | 파일 추가 없음           |
| 완전한 의존성 역전     | 실용적 단순함            |
| 대규모 프로젝트에 적합 | 중소규모 프로젝트에 적합 |

현재 프로젝트는 **1달 일정 + CQRS로 충분한 분리**가 이루어지므로 Factory Method만 적용했습니다.

---

## 📚 관련 문서

- [02-ORGANIZATION_DOMAIN.md](./02-ORGANIZATION_DOMAIN.md) - Organization 도메인
- [03-JWT-INFRASTRUCTURE.md](./03-JWT-INFRASTRUCTURE.md) - JWT 인프라
- [backend-design.md](../backend-design.md) - 전체 아키텍처

---

**다음 단계**: [05-CONFIGURATION.md](./05-CONFIGURATION.md) 👉
