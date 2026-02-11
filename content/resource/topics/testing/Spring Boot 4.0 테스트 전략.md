---
tags: [spring-boot, testing, test-strategy, junit5]
created: 2026-02-04
modified: 2026-02-04
up: "[[resource/topics/testing/_Testing MOC]]"
---
# Spring Boot 4.0 테스트 전략

## 개요

Spring Boot 4.0에서 효과적인 테스트 전략을 수립하기 위한 가이드입니다. 테스트 피라미드를 기반으로 각 계층별 최적의 테스트 방법을 제시합니다.

## 테스트 피라미드

```
        /\
       /  \
      / E2E \          적음 (느림, 비용 높음)
     /______\
    /        \
   / 통합 테스트 \       중간
  /____________\
 /              \
/   단위 테스트    \     많음 (빠름, 비용 낮음)
/__________________\
```

### 권장 비율
- **단위 테스트**: 70% (Service 로직, Util 클래스)
- **통합 테스트**: 20% (Repository, Controller 슬라이스)
- **E2E 테스트**: 10% (주요 시나리오)

## 1. 순수 단위 테스트 (Unit Test)

### 특징
- Spring 컨텍스트 없음
- 가장 빠른 실행 속도 (0.1초 이하)
- 비즈니스 로직에만 집중

### 설정

```java
@ExtendWith(MockitoExtension.class)
class UserServiceTest {

    @Mock
    private UserRepository userRepository;

    @Mock
    private EmailService emailService;

    @InjectMocks
    private UserService userService;
}
```

### 테스트 예시

```java
@Test
void createUser_성공() {
    // Given
    User user = new User("test@example.com", "홍길동");
    when(userRepository.existsByEmail(user.getEmail())).thenReturn(false);
    when(userRepository.save(any(User.class))).thenReturn(user);

    // When
    User result = userService.createUser(user);

    // Then
    assertThat(result).isNotNull();
    assertThat(result.getName()).isEqualTo("홍길동");
    verify(emailService).sendWelcomeEmail(user.getEmail());
}

@Test
void createUser_이메일중복_예외() {
    // Given
    User user = new User("duplicate@example.com", "홍길동");
    when(userRepository.existsByEmail(user.getEmail())).thenReturn(true);

    // When & Then
    assertThatThrownBy(() -> userService.createUser(user))
        .isInstanceOf(DuplicateEmailException.class)
        .hasMessage("이미 존재하는 이메일입니다.");

    verify(userRepository, never()).save(any());
}
```

### 언제 사용?
- ✅ Service 계층의 비즈니스 로직
- ✅ Util, Helper 클래스
- ✅ Domain 객체 메서드
- ✅ TDD 개발

## 2. Repository 슬라이스 테스트

### 2-1. JPA Repository 테스트

```java
@DataJpaTest
@AutoConfigureTestDatabase(replace = AutoConfigureTestDatabase.Replace.NONE)
class UserRepositoryTest {

    @Autowired
    private UserRepository userRepository;

    @Test
    void findByEmail_존재하는_사용자() {
        // Given
        User user = new User("test@example.com", "홍길동");
        userRepository.save(user);

        // When
        Optional<User> result = userRepository.findByEmail("test@example.com");

        // Then
        assertThat(result).isPresent();
        assertThat(result.get().getName()).isEqualTo("홍길동");
    }

    @Test
    void existsByEmail_중복_체크() {
        // Given
        User user = new User("duplicate@example.com", "홍길동");
        userRepository.save(user);

        // When
        boolean exists = userRepository.existsByEmail("duplicate@example.com");

        // Then
        assertThat(exists).isTrue();
    }
}
```

### 2-2. MyBatis Mapper 테스트

```java
@MybatisTest
@AutoConfigureTestDatabase(replace = AutoConfigureTestDatabase.Replace.NONE)
class UserQueryMapperTest {

    @Autowired
    private UserQueryMapper userQueryMapper;

    @Autowired
    private UserRepository userRepository;  // 테스트 데이터 생성용

    @Test
    void findUserList_페이징_조회() {
        // Given
        userRepository.save(new User("user1@example.com", "사용자1"));
        userRepository.save(new User("user2@example.com", "사용자2"));
        userRepository.save(new User("user3@example.com", "사용자3"));

        UserSearchCondition condition = new UserSearchCondition();
        condition.setPage(0);
        condition.setSize(2);

        // When
        List<UserListDto> result = userQueryMapper.findUserList(condition);

        // Then
        assertThat(result).hasSize(2);
    }

    @Test
    void findUserDetail_Join_조회() {
        // Given
        User user = userRepository.save(new User("test@example.com", "홍길동"));

        // When
        UserDetailDto result = userQueryMapper.findUserDetail(user.getId());

        // Then
        assertThat(result).isNotNull();
        assertThat(result.getName()).isEqualTo("홍길동");
        assertThat(result.getPostCount()).isZero();
    }
}
```

### 언제 사용?
- ✅ JPA 쿼리 메서드 동작 확인
- ✅ MyBatis XML 쿼리 검증
- ✅ 실제 DB 스키마 호환성 확인

## 3. Controller 슬라이스 테스트

### 설정

```java
@WebMvcTest(UserController.class)
class UserControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @MockitoBean
    private UserService userService;

    @Autowired
    private ObjectMapper objectMapper;
}
```

### 테스트 예시

```java
@Test
void createUser_성공() throws Exception {
    // Given
    CreateUserRequest request = new CreateUserRequest("test@example.com", "홍길동");
    UserDto response = new UserDto(1L, "홍길동", "test@example.com");

    when(userService.createUser(any())).thenReturn(response);

    // When & Then
    mockMvc.perform(post("/api/users")
            .contentType(MediaType.APPLICATION_JSON)
            .content(objectMapper.writeValueAsString(request)))
        .andExpect(status().isCreated())
        .andExpect(jsonPath("$.id").value(1))
        .andExpect(jsonPath("$.name").value("홍길동"))
        .andExpect(jsonPath("$.email").value("test@example.com"));

    verify(userService).createUser(any());
}

@Test
void createUser_유효성검증_실패() throws Exception {
    // Given
    CreateUserRequest request = new CreateUserRequest("invalid-email", "");

    // When & Then
    mockMvc.perform(post("/api/users")
            .contentType(MediaType.APPLICATION_JSON)
            .content(objectMapper.writeValueAsString(request)))
        .andExpect(status().isBadRequest())
        .andExpect(jsonPath("$.errors").isArray());

    verify(userService, never()).createUser(any());
}

@Test
void getUser_존재하지않음() throws Exception {
    // Given
    when(userService.getUser(999L))
        .thenThrow(new UserNotFoundException("사용자를 찾을 수 없습니다."));

    // When & Then
    mockMvc.perform(get("/api/users/999"))
        .andExpect(status().isNotFound())
        .andExpect(jsonPath("$.message").value("사용자를 찾을 수 없습니다."));
}
```

### 언제 사용?
- ✅ HTTP 요청/응답 검증
- ✅ Validation 동작 확인
- ✅ 인증/인가 로직 테스트
- ✅ 예외 처리 검증

## 4. 통합 테스트 (Integration Test)

### 설정

```java
@SpringBootTest
@AutoConfigureMockMvc
@Transactional
class UserIntegrationTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private UserRepository userRepository;

    @MockitoBean
    private EmailService emailService;  // 외부 시스템만 Mock
}
```

### 테스트 예시

```java
@Test
void createUser_전체_플로우() throws Exception {
    // Given
    CreateUserRequest request = new CreateUserRequest("test@example.com", "홍길동");

    // When
    MvcResult result = mockMvc.perform(post("/api/users")
            .contentType(MediaType.APPLICATION_JSON)
            .content(objectMapper.writeValueAsString(request)))
        .andExpect(status().isCreated())
        .andReturn();

    // Then
    String responseBody = result.getResponse().getContentAsString();
    UserDto response = objectMapper.readValue(responseBody, UserDto.class);

    // DB 확인
    User savedUser = userRepository.findById(response.getId()).orElseThrow();
    assertThat(savedUser.getName()).isEqualTo("홍길동");
    assertThat(savedUser.getEmail()).isEqualTo("test@example.com");

    // 외부 서비스 호출 확인
    verify(emailService).sendWelcomeEmail("test@example.com");
}

@Test
void updateUser_동시성_테스트() throws Exception {
    // Given
    User user = userRepository.save(new User("test@example.com", "홍길동"));

    // When - 동시에 2번 수정 시도
    CountDownLatch latch = new CountDownLatch(2);
    ExecutorService executor = Executors.newFixedThreadPool(2);

    executor.submit(() -> {
        try {
            mockMvc.perform(put("/api/users/" + user.getId())
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"name\":\"김철수\"}"));
        } catch (Exception e) {
            e.printStackTrace();
        } finally {
            latch.countDown();
        }
    });

    executor.submit(() -> {
        try {
            mockMvc.perform(put("/api/users/" + user.getId())
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"name\":\"이영희\"}"));
        } catch (Exception e) {
            e.printStackTrace();
        } finally {
            latch.countDown();
        }
    });

    latch.await();

    // Then - 마지막 수정이 반영되어야 함
    User updatedUser = userRepository.findById(user.getId()).orElseThrow();
    assertThat(updatedUser.getName()).isIn("김철수", "이영희");
}
```

### 언제 사용?
- ✅ 여러 계층이 함께 동작하는 시나리오
- ✅ 트랜잭션 동작 확인
- ✅ 실제 DB 제약 조건 검증
- ✅ 동시성 문제 테스트

## 5. 테스트 더블 전략

```
외부 의존성 처리 전략
        ↓
    외부 시스템?
        ↓
    ┌───┴───┐
    │       │
  YES      NO
    │       │
    ↓       ↓
@MockitoBean  실제 객체 사용
(SMTP, S3 등)  (Repository 등)
```

### 예시: 외부 서비스 Mock

```java
@SpringBootTest
class OrderIntegrationTest {

    @MockitoBean
    private PaymentService paymentService;  // 외부 결제 API

    @MockitoBean
    private EmailService emailService;      // SMTP

    @Autowired
    private OrderRepository orderRepository;  // 실제 DB

    @Autowired
    private ProductRepository productRepository;  // 실제 DB

    @Test
    void createOrder_결제성공() {
        // Given
        Product product = productRepository.save(new Product("노트북", 1000000));
        when(paymentService.processPayment(any())).thenReturn(new PaymentResult(true));

        // When
        orderService.createOrder(product.getId(), 1);

        // Then
        List<Order> orders = orderRepository.findAll();
        assertThat(orders).hasSize(1);
        verify(emailService).sendOrderConfirmation(any());
    }
}
```

## 6. 테스트 데이터 관리

### 6-1. @Sql 활용

```java
@SpringBootTest
@Sql(scripts = "/test-data.sql", executionPhase = Sql.ExecutionPhase.BEFORE_TEST_METHOD)
@Sql(scripts = "/cleanup.sql", executionPhase = Sql.ExecutionPhase.AFTER_TEST_METHOD)
class UserQueryTest {

    @Test
    void findUserList_미리준비된_데이터() {
        List<UserListDto> users = userQueryMapper.findUserList(new UserSearchCondition());
        assertThat(users).hasSizeGreaterThan(0);
    }
}
```

### 6-2. Test Fixture 패턴

```java
@TestConfiguration
class TestFixtures {

    public static User createUser(String email, String name) {
        return User.builder()
            .email(email)
            .name(name)
            .status(UserStatus.ACTIVE)
            .createdAt(LocalDateTime.now())
            .build();
    }

    public static Product createProduct(String name, int price) {
        return Product.builder()
            .name(name)
            .price(price)
            .stockQuantity(100)
            .build();
    }
}

// 사용
@Test
void test() {
    User user = TestFixtures.createUser("test@example.com", "홍길동");
    userRepository.save(user);
}
```

## 7. 테스트 실행 속도 최적화

### 전략 비교

| 전략 | 실행 시간 | Spring 컨텍스트 | 신뢰도 |
|------|----------|----------------|--------|
| 순수 단위 테스트 | 0.1초 | ❌ | 중간 |
| 슬라이스 테스트 | 1-2초 | ✅ (일부) | 높음 |
| 통합 테스트 | 5-10초 | ✅ (전체) | 매우 높음 |

### 최적화 팁

```java
// ❌ 나쁜 예 - 모든 테스트를 통합 테스트로
@SpringBootTest
class UserServiceTest {
    @Autowired
    private UserService userService;
    // 느림 (Spring 컨텍스트 로딩)
}

// ✅ 좋은 예 - 순수 단위 테스트로
@ExtendWith(MockitoExtension.class)
class UserServiceTest {
    @InjectMocks
    private UserService userService;
    // 빠름 (Spring 없음)
}
```

## 8. 테스트 작성 체크리스트

### Service 테스트
- [ ] 순수 단위 테스트로 작성 (`@Mock` + `@InjectMocks`)
- [ ] 성공 케이스 테스트
- [ ] 예외 케이스 테스트
- [ ] 경계값 테스트
- [ ] Mock 호출 검증 (`verify`)

### Repository 테스트
- [ ] `@DataJpaTest` 또는 `@MybatisTest` 사용
- [ ] 실제 DB 스키마 사용
- [ ] 트랜잭션 롤백 확인
- [ ] 복잡한 쿼리는 실제 데이터로 검증

### Controller 테스트
- [ ] `@WebMvcTest` 사용
- [ ] Service는 `@MockitoBean`으로 Mock
- [ ] HTTP 상태 코드 검증
- [ ] 요청/응답 JSON 검증
- [ ] Validation 동작 확인

### 통합 테스트
- [ ] 핵심 비즈니스 시나리오만 작성
- [ ] 외부 시스템은 Mock
- [ ] DB는 실제 사용
- [ ] 트랜잭션 동작 확인

## 주의사항

> [!warning] 통합 테스트 남용 금지
> 모든 테스트를 `@SpringBootTest`로 작성하면 실행 시간이 기하급수적으로 증가합니다.

> [!tip] 테스트 피라미드 준수
> 단위 테스트 70%, 통합 테스트 20%, E2E 10% 비율을 유지하세요.

## 관련 개념
- [[Mockito 테스트 어노테이션]]
- [[테스트 피라미드]]
- [[TDD 실전 가이드]]
- [[테스트 더블 (Mock, Stub, Fake)]]

## 참고 자료
- Spring Boot Testing Documentation
- JUnit 5 User Guide
- Practical Test Pyramid (Martin Fowler)
