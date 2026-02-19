---
tags: [spring, bean-lifecycle, di, event, async]
category: spring
created: 2026-02-12
status: complete
description: Spring Bean 생성, 의존성 주입, 이벤트 및 비동기 처리 메커니즘 심층 분석
---

# Spring 내부 동작 심층 분석: Bean 라이프사이클, 의존성 주입, 이벤트 및 @Async

> Spring 컨테이너의 핵심 동작 원리인 Bean 생성 및 관리, 의존성 주입 메커니즘, 그리고 이벤트 및 비동기 처리의 내부 흐름을 상세하게 이해합니다.

---

## 개요
이 문서는 Spring Framework의 핵심인 Bean 라이프사이클, 의존성 주입(DI)의 기술적 특징과 실무적 고려사항을 다룹니다. 또한 `@TransactionalEventListener`와 `@Async` 어노테이션을 중심으로 Spring 이벤트 및 비동기 처리의 동작 원리를 심층적으로 분석하여, 스프링 애플리케이션의 시작부터 런타임까지의 내부 흐름을 단계별로 추적합니다.

## Part 1: Spring Bean 라이프사이클과 의존성 주입 심층 분석 (2026-02-12)

# Spring Bean 라이프사이클과 의존성 주입 심층 분석

## Summary

* Spring 컨테이너의 Bean 생성 및 의존성 주입 메커니즘 심층 분석
* Bean 인스턴스화 순서 결정 기준과 의존성 그래프 이해
* `@Value` 필드 주입 vs 생성자 주입의 기술적 차이점
* 실무에서 생성자 주입을 권장하는 이유

---

## 1. Spring 애플리케이션 시작 시 스레드 실행 순서

### 1.1 전체 흐름 (단일 main 스레드)

```
main 스레드 (단일 스레드로 순차 실행)
│
├─ 1. SpringApplication.run() 호출
│     └─ 정적 메서드로 부트스트랩 시작
│
├─ 2. SpringApplicationRunListeners 생성 및 시작
│     └─ ApplicationStartingEvent 발행
│
├─ 3. Environment 준비
│     ├─ ConfigurableEnvironment 생성
│     ├─ application.yml / application.properties 로드
│     ├─ 시스템 환경변수, JVM 프로퍼티 병합
│     └─ ApplicationEnvironmentPreparedEvent 발행
│
├─ 4. ApplicationContext 생성
│     └─ AnnotationConfigServletWebServerApplicationContext (웹 앱 기준)
│
├─ 5. ApplicationContext 준비
│     ├─ BeanFactoryPostProcessor 등록
│     ├─ @Configuration 클래스 파싱
│     └─ ApplicationContextInitializedEvent 발행
│
├─ 6. ApplicationContext refresh() ⭐ 핵심 단계
│     │
│     ├─ 6-1. BeanFactory 준비
│     │
│     ├─ 6-2. BeanFactoryPostProcessor 실행
│     │       └─ @Value 플레이스홀더 해석 준비
│     │
│     ├─ 6-3. BeanPostProcessor 등록
│     │       └─ AutowiredAnnotationBeanPostProcessor 등록
│     │
│     ├─ 6-4. Bean 인스턴스화 (의존성 순서대로) ⭐
│     │       │
│     │       │  [의존성 그래프 기반 정렬]
│     │       │
│     │       ├─ UserRepository 생성
│     │       ├─ PasswordEncoder 생성
│     │       ├─ JwtProvider 생성
│     │       ├─ AuthService 생성 (위 3개 주입)
│     │       └─ AuthController 생성 (AuthService + @Value 주입)
│     │
│     ├─ 6-5. BeanPostProcessor.postProcessBeforeInitialization()
│     │
│     ├─ 6-6. InitializingBean.afterPropertiesSet() / @PostConstruct
│     │
│     └─ 6-7. BeanPostProcessor.postProcessAfterInitialization()
│           └─ AOP 프록시 생성 등
│
├─ 7. ContextRefreshedEvent 발행
│
├─ 8. 내장 웹 서버 시작 (Tomcat/Netty)
│     └─ 스레드 풀 초기화
│
├─ 9. ApplicationStartedEvent 발행
│
├─ 10. ApplicationRunner / CommandLineRunner 실행
│
└─ 11. ApplicationReadyEvent 발행
      └─ 애플리케이션 준비 완료
```

### 1.2 런타임 시 멀티스레드 동작

```
애플리케이션 시작 완료 후:

main 스레드        → 대기 상태 (또는 종료)

Tomcat 스레드 풀 (기본 200개):
├─ http-nio-8080-exec-1  → /api/v1/auth/login 처리
├─ http-nio-8080-exec-2  → /api/v1/auth/signup 처리
├─ http-nio-8080-exec-3  → /api/v1/users/me 처리
└─ ...

스케줄러 스레드 (있는 경우):
└─ scheduling-1          → @Scheduled 태스크 실행

비동기 스레드 풀 (있는 경우):
└─ task-1, task-2...     → @Async 메서드 실행
```

---

## 2. Bean 인스턴스화 순서 결정 기준

### 2.1 핵심 원칙: 의존성 그래프 (Dependency Graph)

Spring은 **위상 정렬(Topological Sort)** 알고리즘을 사용하여 Bean 생성 순서를 결정한다.

```
의존성이 없는 Bean → 의존성이 있는 Bean 순서로 생성

예시:
UserRepository (의존성 없음)      → 1번째 생성
PasswordEncoder (의존성 없음)     → 2번째 생성 (1번과 병렬 가능하나 실제론 순차)
JwtProvider (의존성 없음)         → 3번째 생성
AuthService (위 3개에 의존)       → 4번째 생성
AuthController (AuthService 의존) → 5번째 생성
```

### 2.2 순서 결정 요소 (우선순위 순)

| 우선순위 | 요소 | 설명 |
|---------|------|------|
| 1 | **생성자/필드 의존성** | `@Autowired`, 생성자 파라미터로 주입되는 Bean |
| 2 | **`@DependsOn`** | 명시적 의존성 선언 |
| 3 | **`@Order` / `Ordered`** | 같은 타입 Bean 간 순서 (리스트 주입 시) |
| 4 | **`@Priority`** | JSR-250 표준 우선순위 |
| 5 | **Bean 이름 알파벳** | 위 조건이 동일할 때 최종 기준 |

### 2.3 의존성 그래프 예시

```java
@RestController
public class AuthController {
    public AuthController(AuthService authService,
                          @Value("${cookie.secure}") boolean secure) {
        // AuthService에 의존 → AuthService가 먼저 생성되어야 함
    }
}

@Service
public class AuthService {
    public AuthController(UserRepository userRepo,
                          PasswordEncoder encoder,
                          JwtProvider jwt) {
        // 3개 Bean에 의존 → 3개 모두 먼저 생성되어야 함
    }
}
```

```
의존성 그래프:

UserRepository ─────┐
PasswordEncoder ────┼──→ AuthService ──→ AuthController
JwtProvider ────────┘
```

### 2.4 순환 의존성 (Circular Dependency)

```java
// ❌ 순환 의존성 - 생성자 주입 시 실패
@Service
public class ServiceA {
    public ServiceA(ServiceB b) { }  // B 필요
}

@Service
public class ServiceB {
    public ServiceB(ServiceA a) { }  // A 필요 → 누가 먼저?
}
```

**에러 메시지:**
```
The dependencies of some of the beans in the application context form a cycle:
┌─────┐
|  serviceA
↑     ↓
|  serviceB
└─────┘
```

**해결 방법:**
1. 설계 재검토 (권장) - 순환 의존이 필요한지 다시 생각
2. `@Lazy` 사용 - 지연 로딩으로 우회
3. Setter/필드 주입 사용 - 비권장, 근본 해결 아님

---

## 3. `@Value` 필드 주입 vs 생성자 주입

### 3.1 왜 `@Value` 필드는 `final`이 불가능한가?

#### Java의 `final` 필드 규칙

```java
public class Example {
    private final String value;  // final 필드

    // final 필드는 반드시 다음 중 하나로 초기화되어야 함:
    // 1. 선언 시점
    // 2. 인스턴스 초기화 블록
    // 3. 모든 생성자
}
```

#### 필드 주입의 문제점

```java
@RestController
public class AuthController {

    @Value("${cookie.secure:true}")
    private final boolean cookieSecure;  // ❌ 컴파일 에러!

    public AuthController() {
        // 생성자에서 cookieSecure를 초기화하지 않음
        // → "final 필드가 초기화되지 않음" 컴파일 에러
    }
}
```

**동작 순서 (필드 주입 시):**

```
1. JVM이 AuthController 인스턴스 생성 (new)
   └─ 이 시점에 모든 final 필드가 초기화되어야 함

2. 생성자 실행 완료

3. Spring이 리플렉션으로 @Value 필드에 값 주입 ← 너무 늦음!
   └─ Field.setAccessible(true)
   └─ Field.set(instance, value)
```

**핵심:** `final` 필드는 **객체 생성 시점**에 초기화되어야 하는데, 필드 주입은 **객체 생성 후**에 발생한다.

#### 생성자 주입은 왜 가능한가?

```java
@RestController
public class AuthController {

    private final boolean cookieSecure;  // ✅ 가능!

    public AuthController(@Value("${cookie.secure:true}") boolean cookieSecure) {
        this.cookieSecure = cookieSecure;  // 생성자에서 초기화
    }
}
```

**동작 순서 (생성자 주입 시):**

```
1. Spring이 @Value 값을 Environment에서 조회
   └─ "${cookie.secure:true}" → true

2. Spring이 생성자 호출하며 값 전달
   └─ new AuthController(true)

3. 생성자 내에서 final 필드 초기화
   └─ this.cookieSecure = true  ← 객체 생성 시점에 완료!
```

### 3.2 기술적 차이 비교표

| 구분 | 필드 `@Value` | 생성자 주입 |
|------|--------------|------------|
| **초기화 시점** | 객체 생성 후 (리플렉션) | 객체 생성 시 (생성자) |
| **`final` 사용** | ❌ 불가능 | ✅ 가능 |
| **불변성 보장** | ❌ 런타임 변경 가능 | ✅ 컴파일 타임 보장 |
| **NPE 가능성** | 주입 전 접근 시 위험 | 없음 (생성 완료 = 주입 완료) |
| **테스트 용이성** | 리플렉션 필요 | `new Controller(value)` |
| **의존성 명시** | 클래스 내부에 숨겨짐 | 생성자 시그니처로 명확 |
| **순환 의존성 감지** | 런타임 (늦은 발견) | 컴파일/시작 시점 (빠른 발견) |

### 3.3 리플렉션으로 필드 주입하는 내부 동작

```java
// Spring의 AutowiredAnnotationBeanPostProcessor 내부 동작 (단순화)
public class AutowiredAnnotationBeanPostProcessor {

    public Object postProcessProperties(Object bean, String beanName) {
        // 1. @Value, @Autowired 필드 찾기
        for (Field field : bean.getClass().getDeclaredFields()) {
            Value valueAnnotation = field.getAnnotation(Value.class);
            if (valueAnnotation != null) {
                // 2. 값 해석
                String placeholder = valueAnnotation.value();
                Object resolvedValue = environment.resolvePlaceholders(placeholder);

                // 3. private 필드 접근 허용 (리플렉션)
                field.setAccessible(true);

                // 4. 값 주입
                field.set(bean, resolvedValue);  // ← 객체 생성 후에 실행됨
            }
        }
        return bean;
    }
}
```

---

## 4. 실무 권장사항: 생성자 주입

### 4.1 Spring 공식 권장

> "Constructor injection should be used for mandatory dependencies."
> - Spring Framework Documentation

Spring 4.3부터 단일 생성자인 경우 `@Autowired` 생략 가능 → 생성자 주입 권장의 신호

### 4.2 권장 이유 요약

1. **불변성 (Immutability)**
   - `final` 키워드로 값 변경 불가
   - 멀티스레드 환경에서 안전

2. **완전한 초기화 보장**
   - 객체 생성 = 모든 의존성 준비
   - `NullPointerException` 원천 차단

3. **테스트 용이성**
   ```java
   // 생성자 주입 - 간단한 테스트
   AuthController controller = new AuthController(mockService, false);

   // 필드 주입 - 리플렉션 필요
   AuthController controller = new AuthController();
   ReflectionTestUtils.setField(controller, "cookieSecure", false);
   ```

4. **순환 의존성 조기 발견**
   - 애플리케이션 시작 시점에 실패 → 빠른 문제 인지

5. **의존성 명시성**
   - 생성자 시그니처만 봐도 의존 관계 파악 가능

### 4.3 현재 AuthController 코드 - 이미 Best Practice

```java
@RestController
@RequestMapping("/api/v1/auth")
public class AuthController {

    private final AuthService authService;      // ✅ final
    private final boolean cookieSecure;         // ✅ final

    public AuthController(
        AuthService authService,
        @Value("${linkwave.cookie.secure:true}") boolean cookieSecure) {
        this.authService = authService;
        this.cookieSecure = cookieSecure;       // ✅ 생성자 주입
    }
    // ...
}
```

**결론:** 현재 구현이 Spring 권장 패턴을 따르고 있으므로 추가 리팩토링 불필요.

---

## 5. 추가 팁: Lombok과 함께 사용

```java
@RestController
@RequestMapping("/api/v1/auth")
@RequiredArgsConstructor  // final 필드에 대한 생성자 자동 생성
public class AuthController {

    private final AuthService authService;

    @Value("${linkwave.cookie.secure:true}")
    private final boolean cookieSecure;  // ❌ 이 방식은 안 됨!
}
```

**주의:** `@RequiredArgsConstructor`와 `@Value`를 함께 쓰려면:

```java
@RestController
@RequiredArgsConstructor
public class AuthController {

    private final AuthService authService;
    private final boolean cookieSecure;

    // application.yml에서 값을 주입받는 별도 @Configuration 필요
    // 또는 현재처럼 명시적 생성자 작성 권장
}
```

---

## References

- [Spring Framework - Dependency Injection](https://docs.spring.io/spring-framework/reference/core/beans/dependencies/factory-collaborators.html)
- [Why field injection is evil](https://odrotbohm.de/2013/11/why-field-injection-is-evil/)
- [Spring Boot Application Startup](https://docs.spring.io/spring-boot/docs/current/reference/html/features.html#features.spring-application)
# Spring 이벤트와 @Async 동작 원리 심층 분석

## 개요
이 문서는 Spring Framework의 `@TransactionalEventListener`와 `@Async` 어노테이션이 어떤 원리로 동작하는지, 스프링 어플리케이션의 시작 시점부터 런타임 시점까지의 내부 흐름을 단계별로 추적하여 설명합니다.

---

### **전제: 컴파일러와 JVM**

*   **컴파일 시점 vs. 런타임 시점:** Java 컴파일러(`javac`)는 `.java` 소스 코드를 JVM이 이해할 수 있는 `.class` 파일(바이트코드)로 변환합니다. 이 과정은 스프링 어플리케이션이 실행되기 **전**에 완료됩니다.
*   **스프링의 역할:** 스프링은 이미 컴파일된 `.class` 파일들을 클래스 로더를 통해 JVM에 로딩한 후, **런타임 시점**에 이 클래스들의 객체(인스턴스)를 만들고, 관계를 맺어주고, 특별한 기능을 부여하는 '프레임워크'입니다. 스프링과 자바 스레드가 다루는 것은 소스 코드가 아닌, JVM 메모리에 로드된 `.class`의 정보입니다.

---

### **Phase 1: 스프링 어플리케이션 시작 시 (The Setup Phase)**

`SpringApplication.run()`이 호출될 때, 스프링 컨테이너는 어플리케이션 구동에 필요한 모든 것을 준비합니다.

#### **1단계: 클래스패스 스캐닝 (Classpath Scanning)**
스프링 컨테이너(`ApplicationContext`)는 컴포넌트 스캔(Component Scan)을 시작하여, 클래스패스 내에 있는 `.class` 파일들을 탐색합니다. `@Component`, `@Service` 등의 어노테이션이 붙은 클래스를 찾아냅니다.
*   이 과정에서 `@Component`가 명시된 `QuerySyncEventHandler.class` 파일이 발견됩니다.

#### **2단계: 빈 정의(Bean Definition) 생성**
발견된 클래스 정보를 바탕으로, 스프링은 '빈 정의(Bean Definition)' 객체를 생성합니다. 이는 해당 객체를 어떻게 생성하고 관리할지에 대한 모든 정보(설계도)를 담고 있습니다.

#### **3단계: 빈 생성 및 후처리 (Bean Instantiation & Post-Processing)**
스프링은 빈 정의를 바탕으로 실제 자바 객체를 생성합니다. 이 객체가 완전한 '빈'으로 등록되기 전, 여러 **`BeanPostProcessor`** 라는 후처리기들이 동작합니다. 이 과정이 스프링의 핵심적인 '마법'을 구현하는 부분입니다.

1.  **`EventListenerMethodProcessor`의 동작:**
    *   이 후처리기는 모든 빈을 검사하여 `@TransactionalEventListener` 어노테이션이 붙은 메소드를 찾습니다.
    *   `QuerySyncEventHandler` 객체에서 `handleMessageSendRequested(...)` 메소드를 발견합니다.
    *   스프링은 이벤트 클래스 타입(`MessageSendRequestedEvent.class`)을 **Key**로, 이 메소드를 실행할 객체와 메소드 정보(`Method` 객체)를 **Value**로 묶어 `ApplicationListener` 어댑터 객체를 생성합니다.
    *   이 어댑터 객체를 이벤트 관리자인 **`ApplicationEventMulticaster`에 등록**합니다. `ApplicationEventMulticaster`는 내부적으로 `Map<Class<?>, ...>` 형태의 자료구조를 유지하며 '이벤트 타입'과 '처리할 리스너 목록'을 맵핑합니다. **이것이 바로 "주소를 등록하는" 과정입니다.**

2.  **`AsyncAnnotationBeanPostProcessor`의 동작:**
    *   이 후처리기는 `@Async` 어노테이션이 붙은 메소드를 찾습니다.
    *   `QuerySyncEventHandler`에 `@Async` 메소드가 있음을 발견하면, 스프링은 **원본 객체를 그대로 사용하지 않고 프록시(Proxy) 객체**를 동적으로 생성합니다. (보통 CGLIB 라이브러리를 사용해 런타임에 부모 클래스를 상속받는 자식 클래스를 생성)
    *   이 프록시 객체는 `@Async` 메소드를 오버라이드(override)하며, 오버라이드된 메소드의 내용은 다음과 같습니다.
        *   "메소드 호출이 들어오면, 실제 로직(원본 객체의 메소드)을 `Runnable` Task로 감싼다."
        *   "이 Task를 백그라운드 스레드 풀(`TaskExecutor`)에 제출한다."
        *   "그리고 즉시 리턴한다."
    *   최종적으로 스프링 컨테이너에는 **원본 `QuerySyncEventHandler` 객체가 아닌, 이 프록시 객체가 'querySyncEventHandler'라는 이름의 빈으로 등록**됩니다.

**시작 단계 완료:** 이제 스프링 컨테이너는 모든 준비를 마쳤습니다. 이벤트 주소록(`ApplicationEventMulticaster`)이 완성되었고, `querySyncEventHandler` 빈은 사실 `@Async` 기능이 추가된 프록시 객체입니다.

---

### **Phase 2: 런타임 시 (Request-Processing Phase)**

#### **1단계: 트랜잭션 시작 및 이벤트 발행**
1.  사용자 요청에 의해 `@Transactional`이 붙은 서비스 메소드가 호출되고, DB 트랜잭션이 시작됩니다.
2.  메소드 내부에서 `applicationEventPublisher.publishEvent(new MessageSendRequestedEvent(...))`가 호출됩니다.
3.  스프링은 현재 활성화된 트랜잭션이 있음을 `TransactionSynchronizationManager`를 통해 확인합니다.
4.  이벤트를 즉시 발행하지 않고, "현재 트랜잭션이 성공적으로 커밋되면 이 이벤트를 발행하라"는 `TransactionSynchronization` 콜백을 `TransactionSynchronizationManager`에 등록합니다.

#### **2단계: 트랜잭션 커밋 및 이벤트 발행**
1.  서비스 메소드가 성공적으로 종료되고, 트랜잭션 매니저가 DB에 `COMMIT`을 요청합니다.
2.  DB 커밋이 성공하면, `TransactionSynchronizationManager`는 등록되어 있던 **`afterCommit` 콜백들을 모두 실행**시킵니다.
3.  이때 등록했던 콜백이 실행되면서, 보류되었던 `MessageSendRequestedEvent` 객체를 드디어 **`ApplicationEventMulticaster`로 전송**합니다.

#### **3단계: 이벤트 수신 및 비동기 실행**
1.  `ApplicationEventMulticaster`는 전달받은 이벤트의 클래스 타입(`MessageSendRequestedEvent.class`)을 확인합니다.
2.  시작 시점에 만들어 둔 맵핑 정보(주소록)를 조회하여, 'querySyncEventHandler' 빈의 `handleMessageSendRequested` 메소드가 이 이벤트를 처리해야 함을 알아냅니다.
3.  `ApplicationEventMulticaster`는 'querySyncEventHandler' 빈의 `handleMessageSendRequested` 메소드를 호출합니다.
4.  **호출되는 대상은 원본 객체가 아닌 `@Async` 프록시 객체**입니다.
5.  프록시 객체의 오버라이드된 `handleMessageSendRequested` 메소드가 실행됩니다. 이 메소드는 실제 로직(원본 객체의 메소드)을 `Runnable` Task로 감싸 별도의 스레드 풀에 던지고 즉시 리턴합니다.
6.  이로 인해 원래의 이벤트 처리 스레드는 즉시 다른 일을 할 수 있게 되고, 백그라운드의 다른 스레드가 실제 `QuerySyncEventHandler`의 로직을 비동기적으로 수행하게 됩니다.

이것이 스프링이 어노테이션 기반으로 여러 고급 기능을 유연하게 제공하는 실제 내부 동작 원리입니다. 핵심은 **①시작 시점의 철저한 준비(빈 후처리기, 프록시, 정보 등록)**와 **②런타임 시점의 가로채기(interception) 및 위임**에 있습니다.