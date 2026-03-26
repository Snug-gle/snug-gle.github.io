---
tags:
  - spring
  - ioc
  - di
  - bean
  - singleton
  - multithreading
  - backend
category: resource
created: 2026-03-26
related:
  - spring-internals-bean-lifecycle-event
  - spring-aop-proxy-self-invocation
  - spring-cache-caffeine
---

# 🔍 Spring IoC/DI와 Bean 생명주기 — 철학부터 멀티스레딩까지

> "Spring이 왜 안전한가"를 이해하기 위한 IoC 철학, Singleton Bean의 메모리 모델, 스타트업 초기화 패턴

---

## 📌 Situation / Symptom

Spring 코드를 쓰면서 자연스럽게 `@Service`, `@RequiredArgsConstructor`, `final` 필드 패턴을 사용했지만 "왜 안전한가?"를 설명하지 못했다. Singleton Bean을 수백 개 스레드가 공유하는데 어떻게 Thread-safe한가? `@PostConstruct`와 `ApplicationRunner`는 뭐가 다른가?

---

## 🔍 Technical Analysis

### 1. IoC — 제어의 역전이란

IoC(Inversion of Control)는 **객체의 생성과 관리 권한을 개발자에서 프레임워크(Spring)로 이전**하는 설계 원칙이다.

**IoC 이전:**
```java
// 개발자가 직접 생성, 직접 연결
public class OrderService {
    private final UserRepository userRepo = new UserRepository();  // 직접 생성
    private final PaymentService payment = new PaymentService(new PgClient());  // 의존성 수동 연결
}
```

**IoC 이후:**
```java
// 선언만. 생성·연결은 Spring이 처리
@Service
@RequiredArgsConstructor
public class OrderService {
    private final UserRepository userRepo;      // "필요하다"는 선언
    private final PaymentService paymentService; // Spring이 주입
}
```

IoC의 핵심 이점은 생성·연결 로직에서 해방되는 것이 아니라, **Spring이 관리하는 Bean만이 AOP, 트랜잭션, 캐시 등 Spring 기능의 수혜를 받는다**는 점이다. `new`로 직접 생성한 객체는 Spring 컨테이너 밖에 있으므로 `@Transactional`, `@Cacheable`이 동작하지 않는다.

### 2. DI — 의존성 주입 패턴

DI(Dependency Injection)는 IoC를 구현하는 방법이다. "나는 이것이 필요하다"고 선언하면 Spring이 적절한 Bean을 찾아 주입해준다.

**생성자 주입 (권장):**
```java
@Service
@RequiredArgsConstructor  // final 필드 생성자 자동 생성 (Lombok)
public class ContentFilterService {
    private final KeywordCacheRepository cacheRepo;  // final → 불변 보장
    private final ContentFilterKeywordStore keywordStore;
}
```

**생성자 주입을 권장하는 이유:**

| 항목 | 필드 주입 (@Autowired) | 생성자 주입 |
|------|----------------------|------------|
| `final` 사용 | 불가 | 가능 → 불변 보장 |
| 초기화 시점 | 객체 생성 후 (리플렉션) | 객체 생성 시 |
| NPE 위험 | 주입 전 접근 시 가능 | 없음 (생성 완료 = 주입 완료) |
| 순환 의존성 발견 | 런타임 | 앱 시작 시점 (빠른 발견) |
| 테스트 | 리플렉션 필요 | `new Service(mockRepo)` |

### 3. Bean 생명주기 — ApplicationContext 초기화 흐름

```
main() → SpringApplication.run()
    │
    ├─ 1. 클래스패스 스캔
    │       @Component, @Service, @Repository, @Configuration 탐색
    │
    ├─ 2. Bean 정의(BeanDefinition) 생성
    │       "어떻게 만들고 연결할지" 설계도
    │
    ├─ 3. Bean 인스턴스화 (의존성 그래프 순서)
    │       의존성 없는 Bean 먼저 → 의존하는 Bean 나중
    │
    ├─ 4. 의존성 주입 (DI)
    │
    ├─ 5. BeanPostProcessor 처리
    │       └─ AOP 프록시 생성 (@Cacheable, @Transactional 등)
    │
    ├─ 6. @PostConstruct 실행  ←── 개별 Bean 초기화
    │       트랜잭션 컨텍스트 미보장
    │
    ├─ 7. 내장 웹 서버 기동 (Tomcat)
    │
    ├─ 8. ApplicationRunner.run() 실행  ←── 전체 준비 완료 후
    │       모든 Bean + 인프라 준비된 상태
    │
    └─ 9. 트래픽 수신 시작
```

**5단계에서 AOP 프록시가 생성된다**는 점이 중요하다. 이 때문에 `@PostConstruct`에서 `this.cacheableMethod()`를 호출하면 프록시가 생성되기 전이 아니라 생성된 후이므로 원리상 동작하지만, `@PostConstruct`는 트랜잭션 컨텍스트가 없으므로 DB 접근이 위험하다.

### 4. @PostConstruct vs ApplicationRunner

```java
// @PostConstruct — Bean 초기화 직후
@Service
public class SomeService {
    @PostConstruct
    public void init() {
        // Bean은 생성됐지만 다른 Bean들이 아직 준비 중일 수 있음
        // 트랜잭션 컨텍스트 미보장
        // DB 조회 → 예외 발생 가능
    }
}

// ApplicationRunner — 모든 준비 완료 후
@Component
public class SomeWarmUp implements ApplicationRunner {
    @Override
    public void run(ApplicationArguments args) {
        // 모든 Bean, DB 연결, 트랜잭션 컨텍스트 준비 완료
        // DB 조회 안전
    }
}
```

| | @PostConstruct | ApplicationRunner |
|--|----------------|-------------------|
| **실행 시점** | Bean 초기화 완료 직후 | ApplicationContext refresh 완료 후 |
| **트랜잭션 컨텍스트** | 미보장 | 보장 |
| **실패 시** | Bean 생성 실패 | 앱 기동 중단 (throw 시) |
| **적합한 용도** | 간단한 필드 초기화, 유효성 검사 | DB 조회, 캐시 워밍업, 네트워크 의존 초기화 |

**Fail-Fast 원칙**: 캐시 워밍업처럼 앱이 정상 동작하기 위해 필수적인 초기화가 실패하면 예외를 `throw`해서 기동을 중단해야 한다. 실패한 채로 서비스를 시작하면 더 심각한 문제(금지 키워드 필터 우회 등)가 발생한다.

### 5. Singleton Bean의 Thread-Safety — Heap vs Stack

Spring Bean은 기본적으로 Singleton이다. 수백 개의 스레드가 하나의 Bean 인스턴스를 동시에 사용한다. 어떻게 안전한가?

```
힙(Heap) — 모든 스레드 공유
├── OrderService Bean (Singleton)
│     ├── userRepo (참조, 불변)
│     └── paymentService (참조, 불변)
└── 다른 Bean들

스레드 A 스택          스레드 B 스택
├── userId = "user1"   ├── userId = "user2"
├── order (지역변수)   ├── order (지역변수)
└── 호출 프레임        └── 호출 프레임
```

**Stateless 객체가 안전한 이유**: 메서드 실행 중 생성하는 지역변수는 각 스레드의 스택에 독립적으로 존재한다. 스레드 A의 `userId`와 스레드 B의 `userId`는 다른 스택에 있어 서로 접근할 수 없다.

**인스턴스 필드에 상태를 저장하면 위험한 이유**:

```java
// 위험한 예 — 인스턴스 변수에 상태 저장
@Service
public class BadOrderService {
    private String currentUserId;  // 힙에 존재 → 스레드 공유

    public Order getOrder(String userId) {
        this.currentUserId = userId;  // 스레드 A가 "user1"을 씀
        // 이 순간 스레드 B가 "user2"로 덮어씀
        return orderRepository.findBy(this.currentUserId);  // user2의 주문 반환
    }
}
```

```java
// 안전한 예 — 메서드 파라미터와 지역변수만 사용
@Service
public class GoodOrderService {
    public Order getOrder(String userId) {  // 스레드 스택에 독립 저장
        return orderRepository.findBy(userId);  // 자신의 스택 참조
    }
}
```

> [!tip] Best Practice
> Spring Bean 서비스 클래스는 Stateless로 설계한다. 인스턴스 변수에는 불변 의존성(다른 Bean 참조)만 둔다. 가변 상태가 필요하다면 메서드 파라미터로 전달하거나 ThreadLocal을 사용한다.

### 6. Bean 등록 방법과 Scope

**등록 방법:**
```java
@Component    // 일반 컴포넌트
@Service      // 비즈니스 로직 (의미론적 구분, 기능은 동일)
@Repository   // 데이터 접근 (+ PersistenceExceptionTranslation 적용)
@Controller / @RestController  // MVC 컨트롤러
@Bean         // @Configuration 클래스 안에서 수동 등록
```

**기본 Scope = Singleton:**
```java
// 기본 (Singleton): 힙에 1개 인스턴스
@Service
public class OrderService { ... }

// Prototype: 요청마다 새 인스턴스
@Service
@Scope("prototype")
public class StatefulProcessor { ... }

// Request: HTTP 요청마다 새 인스턴스
@Service
@Scope(value = WebApplicationContext.SCOPE_REQUEST, proxyMode = TARGET_CLASS)
public class RequestContext { ... }
```

---

## 🛠 Solution

**요약 — Spring Bean이 안전한 이유:**

1. **DI로 주입받은 의존성은 불변** (`final`): 생성 후 변경 불가
2. **메서드 지역변수는 스레드 스택에 독립 저장**: 공유되지 않음
3. **Bean 자체에 가변 상태가 없음**: 모든 데이터는 파라미터/지역변수

**ApplicationRunner를 써야 하는 상황:**
- DB 조회가 필요한 초기화
- 캐시 워밍업
- 외부 서비스 연결 확인
- JPA/Hibernate가 완전히 초기화된 후 실행해야 하는 작업

> [!warning] @PostConstruct에서 DB 조회
> `@PostConstruct`에서 JPA Repository를 통해 DB를 조회하면 트랜잭션 컨텍스트 없이 실행되거나, JPA 레이지 초기화 문제가 발생할 수 있다. DB 접근이 필요한 초기화는 `ApplicationRunner`로 이전해야 한다.

---

## 🔗 Related Concepts

- [[spring-internals-bean-lifecycle-event|Spring Bean 라이프사이클과 이벤트]] — Bean 초기화 전체 흐름과 이벤트/비동기 처리 내부 동작 (심층 분석)
- [[spring-aop-proxy-self-invocation|Spring AOP 프록시와 Self-Invocation 함정]] — Bean을 프록시로 감싸는 시점과 self-invocation 문제
- [[spring-cache-caffeine|Spring Cache 추상화와 Caffeine 전략]] — ApplicationRunner를 활용한 캐시 워밍업 패턴
- [[spring-transactional-deep-dive|Spring @Transactional 심층 분석]] — 트랜잭션 컨텍스트와 Bean 생명주기의 관계

---

## 📚 References

- [Spring Framework — IoC Container](https://docs.spring.io/spring-framework/reference/core/beans.html)
- [Spring Boot — ApplicationRunner](https://docs.spring.io/spring-boot/docs/current/api/org/springframework/boot/ApplicationRunner.html)
- [Baeldung — Spring Bean Scopes](https://www.baeldung.com/spring-bean-scopes)
