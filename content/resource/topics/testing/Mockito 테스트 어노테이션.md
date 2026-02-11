---
tags: [testing, mockito, spring-boot, unit-test]
created: 2026-02-04
modified: 2026-02-04
up: "[[resource/topics/testing/_Testing MOC]]"
---
# Mockito 테스트 어노테이션

## 개요

Mockito는 Java에서 가장 널리 사용되는 모킹(Mocking) 프레임워크입니다. 테스트 작성 시 사용하는 주요 어노테이션들의 차이점과 사용법을 정리합니다.

## 주요 어노테이션 비교

| 어노테이션 | 용도 | Spring 컨텍스트 | 사용 시점 |
|-----------|------|----------------|----------|
| `@Mock` | 순수 Mock 객체 생성 | 불필요 | 순수 단위 테스트 |
| `@MockitoBean` | Spring Bean으로 Mock 등록 | 필요 (Spring Boot 4.0+) | Spring 통합 테스트 |
| `@InjectMocks` | Mock 자동 주입 + 테스트 대상 생성 | 불필요 | 순수 단위 테스트 |
| `@Spy` | 실제 객체의 일부만 모킹 | 불필요 | 특수한 경우 |

## 1. @Mock - 순수 Mockito Mock

### 특징
- **순수 가짜 객체** 생성
- Spring 컨텍스트 없이 동작
- 빠른 테스트 실행 (컨텍스트 로딩 불필요)
- `@ExtendWith(MockitoExtension.class)` 필요

### 사용 예시

```java
@ExtendWith(MockitoExtension.class)
class UserServiceTest {

    @Mock
    private UserRepository userRepository;  // 순수 Mock 객체

    @Mock
    private EmailService emailService;      // 순수 Mock 객체

    @InjectMocks
    private UserService userService;        // Mock들이 주입될 테스트 대상

    @Test
    void createUser_성공() {
        // Given
        User user = new User("test@example.com", "홍길동");
        when(userRepository.save(any(User.class))).thenReturn(user);

        // When
        User result = userService.createUser(user);

        // Then
        assertThat(result.getName()).isEqualTo("홍길동");
        verify(emailService).sendWelcomeEmail(user.getEmail());
    }
}
```

### 언제 사용?
- ✅ Service 계층의 순수 비즈니스 로직 테스트
- ✅ Spring 컨텍스트가 필요 없는 단위 테스트
- ✅ 빠른 실행 속도가 중요한 경우

## 2. @MockitoBean - Spring 통합 Mock (Spring Boot 4.0+)

### 특징
- Spring 컨텍스트에 **Mock Bean 등록**
- 기존 Bean을 Mock으로 교체
- Spring Boot 4.0부터 `@MockBean` 대신 사용
- `@SpringBootTest`, `@WebMvcTest` 등과 함께 사용

### 사용 예시

```java
@WebMvcTest(UserController.class)
class UserControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @MockitoBean  // Spring Boot 4.0+ (기존 @MockBean)
    private UserService userService;

    @Test
    void getUser_성공() throws Exception {
        // Given
        UserDto userDto = new UserDto(1L, "홍길동", "test@example.com");
        when(userService.getUser(1L)).thenReturn(userDto);

        // When & Then
        mockMvc.perform(get("/api/users/1"))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.name").value("홍길동"))
            .andExpect(jsonPath("$.email").value("test@example.com"));

        verify(userService).getUser(1L);
    }
}
```

### 언제 사용?
- ✅ Controller 슬라이스 테스트 (`@WebMvcTest`)
- ✅ Service를 Mock으로 교체해야 하는 경우
- ✅ Spring Security, MVC 설정이 필요한 경우

### Spring Boot 3.x vs 4.0 차이

```java
// Spring Boot 3.x
@MockBean
private UserService userService;

// Spring Boot 4.0+
@MockitoBean
private UserService userService;
```

> [!warning] 버전 주의
> Spring Boot 4.0부터 `@MockBean`이 deprecated되고 `@MockitoBean`으로 변경되었습니다.

## 3. @InjectMocks - Mock 자동 주입

### 특징
- **테스트 대상 객체**에 `@Mock`을 자동 주입
- 생성자 주입, Setter 주입, 필드 주입 모두 지원
- Spring 없이도 의존성 주입 효과

### 동작 원리

```java
// 이 코드가...
@Mock
private UserRepository userRepository;

@Mock
private EmailService emailService;

@InjectMocks
private UserService userService;

// 내부적으로 이렇게 동작
UserService userService = new UserService(userRepository, emailService);
```

### 생성자 주입 예시

```java
// UserService.java
@Service
@RequiredArgsConstructor
public class UserService {
    private final UserRepository userRepository;
    private final EmailService emailService;

    // 생성자는 Lombok이 생성
}

// UserServiceTest.java
@ExtendWith(MockitoExtension.class)
class UserServiceTest {

    @Mock
    private UserRepository userRepository;

    @Mock
    private EmailService emailService;

    @InjectMocks
    private UserService userService;  // 생성자로 Mock 주입됨
}
```

### 언제 사용?
- ✅ Spring 없는 순수 단위 테스트
- ✅ Service 로직만 집중해서 테스트
- ✅ 빠른 피드백이 필요한 TDD

## 4. ArgumentCaptor - 인자 캡처

### 특징
- Mock에 전달된 **실제 인자 값**을 검증
- 복잡한 객체의 내부 값 확인 가능

### 사용 예시

```java
@Test
void createUser_이메일전송_검증() {
    // Given
    ArgumentCaptor<String> emailCaptor = ArgumentCaptor.forClass(String.class);
    User user = new User("test@example.com", "홍길동");

    // When
    userService.createUser(user);

    // Then
    verify(emailService).sendWelcomeEmail(emailCaptor.capture());
    String capturedEmail = emailCaptor.getValue();

    assertThat(capturedEmail).isEqualTo("test@example.com");
}

@Test
void updateUser_변경사항_검증() {
    // Given
    ArgumentCaptor<User> userCaptor = ArgumentCaptor.forClass(User.class);
    User user = new User(1L, "old@example.com", "김철수");
    when(userRepository.findById(1L)).thenReturn(Optional.of(user));

    // When
    userService.updateEmail(1L, "new@example.com");

    // Then
    verify(userRepository).save(userCaptor.capture());
    User capturedUser = userCaptor.getValue();

    assertThat(capturedUser.getEmail()).isEqualTo("new@example.com");
    assertThat(capturedUser.getName()).isEqualTo("김철수");  // 이름은 변경 없음
}
```

### 언제 사용?
- ✅ Mock에 전달된 객체의 내부 값 검증
- ✅ 복잡한 DTO나 Entity 검증
- ✅ 메서드 호출 시 변환 로직 검증

## 실전 예시: 전체 조합

```java
@ExtendWith(MockitoExtension.class)
class OrderServiceTest {

    @Mock
    private OrderRepository orderRepository;

    @Mock
    private ProductRepository productRepository;

    @Mock
    private PaymentService paymentService;

    @Mock
    private EmailService emailService;

    @InjectMocks
    private OrderService orderService;

    @Test
    void createOrder_전체_플로우() {
        // Given
        Long productId = 1L;
        int quantity = 3;
        Product product = new Product(productId, "노트북", 1000000);

        when(productRepository.findById(productId))
            .thenReturn(Optional.of(product));
        when(paymentService.processPayment(anyLong()))
            .thenReturn(new PaymentResult(true, "PAY123"));

        ArgumentCaptor<Order> orderCaptor = ArgumentCaptor.forClass(Order.class);

        // When
        orderService.createOrder(productId, quantity, "user@example.com");

        // Then
        // 1. 주문 저장 검증
        verify(orderRepository).save(orderCaptor.capture());
        Order savedOrder = orderCaptor.getValue();
        assertThat(savedOrder.getTotalAmount()).isEqualTo(3000000);

        // 2. 결제 처리 검증
        verify(paymentService).processPayment(3000000L);

        // 3. 이메일 발송 검증
        ArgumentCaptor<String> emailCaptor = ArgumentCaptor.forClass(String.class);
        verify(emailService).sendOrderConfirmation(emailCaptor.capture());
        assertThat(emailCaptor.getValue()).isEqualTo("user@example.com");
    }
}
```

## 테스트 전략 요약

```
테스트 작성 시 판단 기준
        ↓
Spring 컨텍스트 필요?
        ↓
    ┌───┴───┐
   NO       YES
    │        │
    ↓        ↓
@Mock    @MockitoBean
+ @InjectMocks
    │        │
    ↓        ↓
빠른 실행   실제 통합
순수 로직   Spring 기능
```

## 주의사항

> [!warning] @Mock과 @MockitoBean 혼용 금지
> 같은 테스트 클래스에서 두 어노테이션을 섞어 쓰면 안 됩니다. 하나의 전략을 선택하세요.

> [!tip] 순수 단위 테스트 우선
> 가능하면 `@Mock` + `@InjectMocks`로 Spring 없이 테스트하세요. 실행 속도가 10배 이상 빠릅니다.

## 관련 개념
- [[Spring Boot 4.0 테스트 전략]]
- [[테스트 피라미드]]
- [[단위 테스트 vs 통합 테스트]]
- [[TDD 실전 가이드]]

## 참고 자료
- Mockito Official Documentation
- Spring Boot Testing Guide
- Effective Unit Testing (책)
