---
tags: [java, reflection, jvm, bytecode, oop, framework, performance]
category: java
created: 2026-01-21
status: complete
description: Java Reflection API의 기본 개념부터 심층 동작 원리, Spring 프레임워크 활용 사례, 성능 고려사항 및 실무 사용법까지 완벽하게 이해하는 가이드
---

# Java 리플렉션 완벽 가이드: 기본부터 심층 분석까지

> Java Reflection API의 기본 개념과 Spring 프레임워크에서의 활용 사례, 성능 최적화 전략 및 안전한 사용법을 비유와 예시를 통해 명확하게 제시하는 종합 가이드

---

## 개요
이 문서는 Java Reflection API의 핵심 개념과 동작 원리를 쉽고 명확한 비유를 통해 소개하고, 이어서 Spring Framework와 같은 주요 프레임워크에서 리플렉션이 어떻게 활용되는지 심층적으로 분석합니다. 또한 리플렉션 사용 시 발생할 수 있는 성능 문제, 캡슐화 파괴와 같은 주의사항을 다루며, MethodHandle과 같은 대안 및 실무에서의 올바른 사용 가이드라인을 제공합니다.

## Part 1: Java 리플렉션 쉽게 이해하기 (2026-01-21)

# Java 리플렉션 쉽게 이해하기

> 비유와 예시로 배우는 리플렉션 완벽 가이드

## 학습 목표

- 리플렉션이 무엇인지 쉬운 비유로 이해하기
- Spring에서 @Service가 어떻게 동작하는지 알아보기
- 왜 테스트 클래스에 public을 안 붙여도 되는지 이해하기

---

## 1. 리플렉션이란? - 택배 센터 비유

###상황: 택배 분류 센터

당신이 택배 분류 센터를 운영한다고 생각해보세요.

#### 방법 1: 리플렉션 없이 (수동)

```
택배 직원: "이게 뭐예요?"
당신: "상자를 열어봐!"
직원: "신발이네요."
당신: "그럼 신발 구역으로!"

택배 직원: "이건요?"
당신: "상자를 열어봐!"
직원: "책이네요."
당신: "책 구역으로!"

// 매번 상자를 열어봐야 하고, 수동으로 분류
```

#### 방법 2: 리플렉션 사용 (자동)

```
택배 상자마다 "라벨(메타데이터)"이 붙어있음:
- 내용물: 신발
- 무게: 500g
- 크기: 30x20x10

기계가 라벨만 읽고 자동 분류:
"아, 신발이구나! → 신발 구역으로!"
"아, 책이구나! → 책 구역으로!"

// 상자를 열지 않고도, 라벨만 보고 처리 가능!
```

### Java로 변환하면:

```java
// 방법 1: 리플렉션 없이 (수동) - 타입마다 코드 작성
void processPackage(Shoes shoes) {
    System.out.println("신발 구역으로!");
}
void processPackage(Book book) {
    System.out.println("책 구역으로!");
}
void processPackage(Toy toy) {
    System.out.println("장난감 구역으로!");
}
// 새 상품이 나올 때마다 메서드 추가 필요!

// 방법 2: 리플렉션 (자동) - 하나의 코드로 모든 타입 처리
void processPackage(Object item) {
    String itemType = item.getClass().getSimpleName();  // 라벨 읽기
    System.out.println(itemType + " 구역으로!");
}
// 어떤 상품이 와도 자동으로 처리!
```

---

## 2. 게임 캐릭터 비유

###RPG 게임의 캐릭터 정보창

**게임 개발자 입장:**

```java
// 캐릭터 클래스 (플레이어가 보지 못하는 코드)
class Warrior {
    private int hp = 100;        // private = 숨겨진 능력치
    private int attack = 50;
    private String weapon = "검";
}

// 리플렉션 = 게임 마스터 모드 (모든 정보 볼 수 있음)
void showCharacterInfo(Object character) {
    Class<?> clazz = character.getClass();

    // 숨겨진 능력치도 전부 볼 수 있음!
    Field[] fields = clazz.getDeclaredFields();
    for (Field field : fields) {
        field.setAccessible(true);  // 치트키 사용!
        System.out.println(field.getName() + " = " + field.get(character));
    }
}

// 출력:
// hp = 100
// attack = 50
// weapon = 검
```

**일반 플레이어**: `warrior.getHp()` 같은 public 메서드로만 접근 가능
**게임 마스터(리플렉션)**: 모든 숨겨진 정보까지 다 볼 수 있음!

---

## 3. 핵심 이해

### 클래스 = 설계도

```java
class User {
    private String name;
    private int age;

    public void sayHello() {
        System.out.println("안녕");
    }
}
```

이 코드를 Java가 컴파일하면:

```
User.class 파일 생성됨 (바이트코드)

[설계도 내용]
- 클래스 이름: User
- 필드 목록:
  * name (타입: String, 접근: private)
  * age (타입: int, 접근: private)
- 메서드 목록:
  * sayHello (반환: void, 접근: public)
```

### 리플렉션 = 설계도 읽기

```java
// 설계도를 가져옴
Class<?> blueprint = User.class;

// 설계도를 읽음
System.out.println("클래스 이름: " + blueprint.getName());
System.out.println("필드 개수: " + blueprint.getDeclaredFields().length);
System.out.println("메서드 개수: " + blueprint.getDeclaredMethods().length);

// 출력:
// 클래스 이름: User
// 필드 개수: 2
// 메서드 개수: 1
```

---

## 4. 어떻게 구현되었나?

### Java의 내부 구조

```
[메모리 구조]

┌─────────────────────┐
│   Heap (객체들)      │
│  user1: User        │
│  user2: User        │
└─────────────────────┘
         ↑
         │ 참조
         │
┌─────────────────────┐
│ Method Area         │  ← 여기에 클래스 메타데이터 저장!
│                     │
│ User.class:         │
│  - 클래스 이름      │
│  - 필드 목록        │
│  - 메서드 목록      │
│  - 접근 제어자      │
└─────────────────────┘
```

**컴파일 시점:**
```
User.java → javac → User.class (바이트코드)

User.class 안에는 모든 정보가 담겨있음:
- 클래스 이름, 필드, 메서드, 어노테이션, 접근 제어자 등
```

**실행 시점:**
```java
// JVM이 User.class를 로드할 때
ClassLoader가 User.class 파일을 읽어서
→ Method Area에 "Class 객체" 생성

Class<User> userClass = User.class;  // 이미 메모리에 있는 Class 객체를 가져옴
```

### 실제 구현 (간소화)

```java
// JVM 내부 (C++로 구현되어 있지만, Java로 표현하면)
class Class<T> {
    private String name;           // "User"
    private Field[] fields;        // [name, age]
    private Method[] methods;      // [sayHello]
    private Constructor[] ctors;   // [User()]

    public String getName() {
        return this.name;
    }

    public Field[] getDeclaredFields() {
        return this.fields;  // 미리 파싱해둔 필드 목록 반환
    }
}

class Field {
    private String name;           // "name"
    private Class<?> type;         // String.class
    private int modifiers;         // private = 2
    private Object declaringClass; // User.class

    public Object get(Object obj) {
        // 네이티브 코드로 실제 메모리 주소 접근
        // obj의 메모리에서 이 필드의 offset 위치 읽기
    }
}
```

---

## 5. Spring의 @Service - 완벽 이해

### 시나리오: Spring이 @Service를 찾는 과정

실제 프로젝트의 코드:

```java
@Service
public class AuthService {
    private final UserRepository userRepository;
    private final RefreshTokenStore refreshTokenStore;

    // 생성자
    public AuthService(UserRepository userRepository,
                       RefreshTokenStore refreshTokenStore) {
        this.userRepository = userRepository;
        this.refreshTokenStore = refreshTokenStore;
    }
}
```

### Step 1: 애플리케이션 시작

```bash
./gradlew bootRun

# Spring Boot가 시작되면서...
```

```java
// Spring 내부 (간소화)
public class SpringApplication {
    public void run() {
        // 1. 클래스패스에서 모든 .class 파일 찾기
        scanAllClasses("io.iotree.linkwave");
    }
}
```

### Step 2: 모든 클래스 스캔

```java
void scanAllClasses(String basePackage) {
    // 패키지 경로를 파일 경로로 변환
    // io.iotree.linkwave → io/iotree/linkwave

    // 해당 경로의 모든 .class 파일 찾기
    List<String> classFiles = [
        "io/iotree/linkwave/application/service/AuthService.class",
        "io/iotree/linkwave/application/service/UserService.class",
        "io/iotree/linkwave/infra/redis/RefreshTokenStore.class",
        "io/iotree/linkwave/api/controller/AuthController.class",
        // ... 수백 개의 클래스
    ];

    for (String classFile : classFiles) {
        processClass(classFile);
    }
}
```

### Step 3: 각 클래스를 리플렉션으로 검사

```java
void processClass(String classFile) {
    // 1. 클래스 로드 (설계도 가져오기)
    Class<?> clazz = Class.forName("io.iotree.linkwave.application.service.AuthService");

    // 2. 이 클래스에 @Service가 붙어있나 확인
    if (clazz.isAnnotationPresent(Service.class)) {
        System.out.println("발견! " + clazz.getName() + "에 @Service 있음!");
        registerAsBean(clazz);
    }
}
```

### Step 4: @Service 확인 과정 (상세)

```java
// AuthService.class 파일 내부 구조 (바이트코드를 읽으면)
/*
[Class Info]
이름: io.iotree.linkwave.application.service.AuthService
어노테이션: [@Service, @Slf4j]  ← 여기 저장되어 있음!
필드: [userRepository, refreshTokenStore, ...]
메서드: [login, logout, ...]
*/

// Spring의 검사
Class<?> clazz = AuthService.class;

// 어노테이션 목록 가져오기
Annotation[] annotations = clazz.getAnnotations();
// 결과: [@Service, @Slf4j]

for (Annotation anno : annotations) {
    System.out.println(anno.annotationType().getName());
    // 출력: org.springframework.stereotype.Service
    // 출력: lombok.extern.slf4j.Slf4j
}

// 특정 어노테이션 확인
boolean hasService = clazz.isAnnotationPresent(Service.class);
// 결과: true

if (hasService) {
    System.out.println("이 클래스는 Spring Bean으로 등록해야 함!");
}
```

### Step 5: Bean 등록 (객체 생성)

```java
void registerAsBean(Class<?> clazz) {
    try {
        // 1. 생성자 정보 가져오기
        Constructor<?>[] constructors = clazz.getDeclaredConstructors();
        Constructor<?> constructor = constructors[0];  // 첫 번째 생성자

        // 생성자 파라미터 정보 확인
        Parameter[] params = constructor.getParameters();
        // 결과: [UserRepository, RefreshTokenStore]

        System.out.println("생성자 파라미터:");
        for (Parameter param : params) {
            System.out.println("  - " + param.getType().getName());
        }
        // 출력:
        //   - io.iotree.linkwave.infra.jpa.repository.UserRepository
        //   - io.iotree.linkwave.infra.redis.RefreshTokenStore

        // 2. 의존성 찾기 (Spring Container에서)
        Object[] dependencies = new Object[params.length];
        for (int i = 0; i < params.length;
 i++) {
            Class<?> paramType = params[i].getType();
            dependencies[i] = beanContainer.get(paramType);  // 이미 등록된 Bean 찾기
        }

        // 3. 객체 생성 (생성자 호출)
        Object bean = constructor.newInstance(dependencies);
        // 결과: new AuthService(userRepository, refreshTokenStore)와 동일!

        // 4. Spring Container에 등록
        beanContainer.put("authService", bean);
        beanContainer.put(AuthService.class, bean);

        System.out.println("✅ AuthService 빈 등록 완료!");

    } catch (Exception e) {
        e.printStackTrace();
    }
}
```

### 전체 흐름 요약

```
[1단계] Spring 시작
   ↓
[2단계] 모든 .class 파일 스캔
   ↓
[3단계] 각 클래스를 리플렉션으로 검사
   ↓
   Class<?> clazz = AuthService.class
   ↓
[4단계] @Service 있나 확인
   ↓
   clazz.isAnnotationPresent(Service.class) → true!
   ↓
[5단계] 생성자 파라미터 타입 확인
   ↓
   Constructor.getParameters()
   → [UserRepository, RefreshTokenStore, ...]
   ↓
[6단계] 필요한 의존성 찾기
   ↓
   beanContainer.get(UserRepository.class)
   beanContainer.get(RefreshTokenStore.class)
   ...
   ↓
[7단계] 객체 생성
   ↓
   constructor.newInstance(dependencies)
   ↓
[8단계] Spring Container에 등록
   ↓
   beanContainer.put("authService", bean)
   ↓
[완료] 이제 @Autowired로 주입 가능!
```

---

## 6. 실제 코드로 확인해보기

프로젝트에서 실험해볼 수 있는 코드:

```java
public class ReflectionDemo {
    public static void main(String[] args) throws Exception {
        // 1. AuthService 클래스 정보 가져오기
        Class<?> clazz = Class.forName("io.iotree.linkwave.application.service.AuthService");

        System.out.println("=== 클래스 정보 ===");
        System.out.println("클래스 이름: " + clazz.getName());
        System.out.println("간단한 이름: " + clazz.getSimpleName());

        // 2. 어노테이션 확인
        System.out.println("\n=== 어노테이션 ===");
        Annotation[] annotations = clazz.getAnnotations();
        for (Annotation anno : annotations) {
            System.out.println("  - " + anno.annotationType().getSimpleName());
        }

        // 3. @Service 있는지 확인
        System.out.println("\n=== @Service 체크 ===");
        boolean hasService = clazz.isAnnotationPresent(Service.class);
        System.out.println("@Service 있음? " + hasService);

        // 4. 생성자 정보
        System.out.println("\n=== 생성자 정보 ===");
        Constructor<?>[] constructors = clazz.getDeclaredConstructors();
        for (Constructor<?> ctor : constructors) {
            System.out.println("생성자: " + ctor.getName());
            Parameter[] params = ctor.getParameters();
            for (Parameter param : params) {
                System.out.println("  파라미터: " + param.getType().getSimpleName());
            }
        }

        // 5. 필드 정보
        System.out.println("\n=== 필드 정보 ===");
        Field[] fields = clazz.getDeclaredFields();
        for (Field field : fields) {
            System.out.println("  - " + field.getName() + " (타입: " + field.getType().getSimpleName() + ")");
        }

        // 6. 메서드 정보
        System.out.println("\n=== 메서드 정보 ===");
        Method[] methods = clazz.getDeclaredMethods();
        for (Method method : methods) {
            System.out.println("  - " + method.getName() + "()");
        }
    }
}
```

**실행 결과 예상:**
```
=== 클래스 정보 ===
클래스 이름: io.iotree.linkwave.application.service.AuthService
간단한 이름: AuthService

=== 어노테이션 ===
  - Slf4j
  - Service
  - RequiredArgsConstructor

=== @Service 체크 ===
@Service 있음? true

=== 생성자 정보 ===
생성자: io.iotree.linkwave.application.service.AuthService
  파라미터: UserRepository
  파라미터: OrganizationRepository
  파라미터: UserQueryMapper
  파라미터: PasswordEncoder
  파라미터: JwtTokenProvider
  파라미터: RefreshTokenStore

=== 필드 정보 ===
  - userRepository (타입: UserRepository)
  - organizationRepository (타입: OrganizationRepository)
  - userQueryMapper (타입: UserQueryMapper)
  - passwordEncoder (타입: PasswordEncoder)
  - jwtTokenProvider (타입: JwtTokenProvider)
  - refreshTokenStore (타입: RefreshTokenStore)

=== 메서드 정보 ===
  - signupAndIssueToken()
  - login()
  - refresh()
  - logout()
  - existsByUsername()
  - validateDuplicate()
  - findOrganizationIfBusiness()
  - determineRole()
```

---

## 7. 핵심 포인트

### @Service는 "표지판"

```java
// 당신이 쓴 코드
@Service  // ← 이건 표지판! "나 Spring Bean이야!"
public class AuthService {
    // ...
}

// Spring이 보는 관점
"어? 이 클래스에 @Service 표지판 붙어있네?"
"그럼 자동으로 객체 만들어서 Container에 넣어야지!"
```

### 리플렉션 = 자동화 도구

**리플렉션 없으면:**
```java
// 개발자가 수동으로 해야 함
UserRepository userRepo = new UserRepository(...);
RefreshTokenStore tokenStore = new RefreshTokenStore(...);
AuthService authService = new AuthService(userRepo, tokenStore, ...);
```

**리플렉션 있으면:**
```java
// Spring이 자동으로 해줌
@Service  // ← 이거 하나로 끝!
public class AuthService { ... }
```

### 어노테이션 정보는 어디 있나?

```
AuthService.java (소스 코드)
   ↓ javac 컴파일
AuthService.class (바이트코드) ← 여기에 @Service 정보 포함!
   ↓ JVM 실행
Method Area에 Class<AuthService> 객체 생성 ← 여기서 읽음!
```

---

## 8. 테스트 클래스에 public이 없는 이유

### JUnit 5의 리플렉션 활용

```java
// JUnit 5 스타일 (권장)
class RefreshTokenStoreTest {  // public 없음!
    @Test
    void save_Success() { }  // public 없음!
}

// JUnit 4 스타일 (구식)
public class RefreshTokenStoreTest {
    @Test
    public void save_Success() { }
}
```

### 왜 public이 필요 없나?

1. **JUnit이 리플렉션으로 실행하기 때문**

```java
// JUnit 내부 동작 (간소화)
void runTests(Class<?> testClass) {
    // 1. 테스트 클래스 인스턴스 생성
    Constructor<?> constructor = testClass.getDeclaredConstructor();
    constructor.setAccessible(true);  // package-private도 접근 가능!
    Object testInstance = constructor.newInstance();

    // 2. @Test 붙은 메서드 찾기
    Method[] methods = testClass.getDeclaredMethods();
    for (Method method : methods) {
        if (method.isAnnotationPresent(Test.class)) {
            method.setAccessible(true);  // package-private도 실행 가능!
            method.invoke(testInstance);  // 테스트 메서드 실행
        }
    }
}
```

2. **패키지 접근 (package-private)으로 충분**

```java
// 테스트 대상
package io.iotree.linkwave.infra.redis;
public class RefreshTokenStore { ... }

// 테스트 코드 (같은 패키지)
package io.iotree.linkwave.infra.redis;
class RefreshTokenStoreTest {  // package-private
    // 같은 패키지니까 RefreshTokenStore 접근 가능!
}
```

3. **현대적인 Java 스타일**

```java
// 불필요한 public 제거 = 더 깔끔한 코드
class UserServiceTest {
    @Test
    void createUser_Success() { }
}
```

---

## 9. 실제 사용 사례

### Spring에서 리플렉션이 사용되는 곳

```java
@Service  // ← Spring이 리플렉션으로 찾음
public class AuthService {

    private final RefreshTokenStore refreshTokenStore;  // ← private인데 Spring이 주입

    @Transactional  // ← Spring이 리플렉션으로 프록시 생성
    public void logout(String username) { ... }
}

@Entity  // ← JPA가 리플렉션으로 처리
class User {
    @Id  // ← JPA가 리플렉션으로 찾음
    private UUID userId;

    // 기본 생성자 없어도 JPA가 리플렉션으로 생성
}

class UserServiceTest {
    @Test  // ← JUnit이 리플렉션으로 찾아서 실행
    void testLogin() { ... }
}
```

### 당신이 직접 쓰진 않지만, 매일 사용하는 리플렉션

- `@Service`, `@Component`, `@Repository` → Spring이 리플렉션으로 찾아서 등록
- `@Autowired`, `@Value` → Spring이 리플렉션으로 주입
- `@Entity`, `@Column` → JPA가 리플렉션으로 매핑
- `@Test`, `@BeforeEach` → JUnit이 리플렉션으로 실행
- JSON 변환 → Jackson이 리플렉션으로 처리

---

## 10. 정리

### 리플렉션이란?

**"클래스의 설계도를 읽는 기술"**

1. **읽기**: 클래스의 구조 정보 읽기 (필드, 메서드, 어노테이션 등)
2. **조작**: 그 정보를 바탕으로 객체 생성, 메서드 호출, 필드 값 변경

### 어떻게 구현?

1. **컴파일 타임**: `User.java` → `User.class` (모든 정보 포함된 바이트코드)
2. **런타임**: JVM이 `User.class`를 읽어서 Method Area에 `Class<User>` 객체 생성
3. **리플렉션 사용**: `User.class`로 그 정보에 접근

### 왜 필요?

**프레임워크가 "모든 클래스"를 자동으로 처리하기 위해!**

리플렉션 없으면:
- Spring: 모든 Service마다 수동 등록
- JPA: 모든 Entity마다 SQL 수동 작성
- JUnit: 모든 테스트 메서드를 main에서 수동 호출

리플렉션 있으면:
- "어? 이 클래스에 @Service 붙어있네? 자동 등록!"
- "어? 이 필드에 @Column 붙어있네? 자동 매핑!"
- "어? 이 메서드에 @Test 붙어있네? 자동 실행!"

---

## 11. 추가 학습 자료

- [JAVA-REFLECTION-DEEP-DIVE.md](./JAVA-REFLECTION-DEEP-DIVE.md) - 더 기술적이고 심화된 내용
- [SPRING-BEAN-LIFECYCLE-DI.md](./SPRING-BEAN-LIFECYCLE-DI.md) - Spring Bean 생명주기와 DI

---

**작성일**: 2026-01-21
**학습 난이도**: 초급 → 중급
**예상 학습 시간**: 30분
## Part 2: Java Reflection 심층 분석 (2026-01-21)

# Java Reflection 심층 분석

## Summary

* Java Reflection API의 동작 원리와 내부 메커니즘
* Spring Framework에서 리플렉션 활용 사례
* 리플렉션의 장단점과 성능 고려사항
* 실무에서의 올바른 사용법

---

## 1. Reflection이란?

### 1.1 정의

**리플렉션(Reflection)** 은 런타임에 클래스의 메타데이터를 조사하고, 객체의 필드/메서드에 동적으로 접근할 수 있는 Java API.

```java
// 일반적인 객체 생성
User user = new User("john");  // 컴파일 타임에 타입 확정

// 리플렉션으로 객체 생성
Class<?> clazz = Class.forName("io.iotree.linkwave.domain.user.User");
Object user = clazz.getDeclaredConstructor(String.class).newInstance("john");
// → 런타임에 타입 결정
```

### 1.2 핵심 개념

```
컴파일 타임                              런타임
─────────────                         ─────────
User.java  →  User.class  →  ClassLoader  →  Class<User> 객체
(소스코드)     (바이트코드)      (로딩)          (메타데이터)
                                              │
                                              ├─ 필드 정보
                                              ├─ 메서드 정보
                                              ├─ 생성자 정보
                                              ├─ 애너테이션 정보
                                              └─ 상속 구조
```

---

## 2. Reflection API 핵심 클래스

### 2.1 주요 클래스 계층

```
java.lang.Class<T>           ← 클래스 메타데이터의 진입점
├── java.lang.reflect.Field       ← 필드 정보
├── java.lang.reflect.Method      ← 메서드 정보
├── java.lang.reflect.Constructor ← 생성자 정보
├── java.lang.reflect.Modifier    ← 접근 제어자 (public, private 등)
└── java.lang.annotation.Annotation ← 애너테이션 정보
```

### 2.2 Class 객체 얻는 3가지 방법

```java
// 1. 클래스 리터럴 (.class)
Class<User> clazz1 = User.class;

// 2. 인스턴스에서 얻기 (getClass())
User user = new User();
Class<?> clazz2 = user.getClass();

// 3. 문자열로 동적 로딩 (forName)
Class<?> clazz3 = Class.forName("io.iotree.linkwave.domain.user.User");
```

---

## 3. 실전 리플렉션 사용법

### 3.1 필드 접근 및 수정

```java
public class User {
    private String username;      // private 필드
    private final String id;      // private final 필드

    public User(String id) {
        this.id = id;
    }
}
```

```java
User user = new User("user-123");

// 1. Field 객체 획득
Field usernameField = User.class.getDeclaredField("username");

// 2. private 접근 허용 (접근 제어 우회)
usernameField.setAccessible(true);

// 3. 값 읽기
String currentValue = (String) usernameField.get(user);  // null

// 4. 값 쓰기
usernameField.set(user, "john_doe");

// 확인
System.out.println(usernameField.get(user));  // "john_doe"
```

### 3.2 final 필드도 수정 가능?

```java
Field idField = User.class.getDeclaredField("id");
idField.setAccessible(true);

// Java 8까지: 가능 (위험!)
idField.set(user, "hacked-id");

// Java 9+: 기본적으로 차단됨 (InaccessibleObjectException)
// --add-opens 옵션 필요
```

**주의:** final 필드 수정은 JVM 최적화를 무효화하고 예측 불가능한 동작 유발

### 3.3 메서드 호출

```java
public class AuthService {
    private String generateToken(String username, int expiry) {
        return "token-" + username + "-" + expiry;
    }
}
```

```java
AuthService service = new AuthService();

// 1. Method 객체 획득 (파라미터 타입 명시 필요)
Method method = AuthService.class.getDeclaredMethod(
    "generateToken",
    String.class,
    int.class
);

// 2. private 메서드 접근 허용
method.setAccessible(true);

// 3. 메서드 호출
String result = (String) method.invoke(service, "john", 3600);
System.out.println(result);  // "token-john-3600"
```

### 3.4 생성자로 인스턴스 생성

```java
public class User {
    private final String username;

    private User(String username) {  // private 생성자
        this.username = username;
    }
}
```

```java
// 1. 생성자 획득
Constructor<User> constructor = User.class.getDeclaredConstructor(String.class);

// 2. private 생성자 접근 허용
constructor.setAccessible(true);

// 3. 인스턴스 생성
User user = constructor.newInstance("john");
```

### 3.5 애너테이션 정보 조회

```java
@RestController
@RequestMapping("/api/v1/auth")
public class AuthController {

    @Value("${cookie.secure:true}")
    private boolean cookieSecure;
}
```

```java
// 클래스 레벨 애너테이션
RestController annotation = AuthController.class.getAnnotation(RestController.class);
boolean isRestController = (annotation != null);  // true

// 필드 레벨 애너테이션
Field field = AuthController.class.getDeclaredField("cookieSecure");
Value valueAnnotation = field.getAnnotation(Value.class);
String placeholder = valueAnnotation.value();  // "${cookie.secure:true}"

// 모든 애너테이션 조회
Annotation[] annotations = field.getAnnotations();
```

---

## 4. Spring Framework의 리플렉션 활용

### 4.1 의존성 주입 (DI)

```java
// Spring의 AutowiredAnnotationBeanPostProcessor (단순화)
public Object injectDependencies(Object bean) {
    Class<?> clazz = bean.getClass();

    for (Field field : clazz.getDeclaredFields()) {
        // @Autowired 또는 @Value 애너테이션 확인
        if (field.isAnnotationPresent(Autowired.class)) {
            field.setAccessible(true);
            Object dependency = applicationContext.getBean(field.getType());
            field.set(bean, dependency);  // 리플렉션으로 주입
        }

        if (field.isAnnotationPresent(Value.class)) {
            field.setAccessible(true);
            String placeholder = field.getAnnotation(Value.class).value();
            Object resolvedValue = environment.resolvePlaceholders(placeholder);
            field.set(bean, convertIfNeeded(resolvedValue, field.getType()));
        }
    }
    return bean;
}
```

### 4.2 컴포넌트 스캔

```java
// @ComponentScan 처리 (단순화)
public Set<Class<?>> scanComponents(String basePackage) {
    Set<Class<?>> components = new HashSet<>();

    // 패키지 내 모든 클래스 탐색
    for (Class<?> clazz : findClassesInPackage(basePackage)) {
        // @Component, @Service, @Repository, @Controller 확인
        if (clazz.isAnnotationPresent(Component.class) ||
            clazz.isAnnotationPresent(Service.class) ||
            clazz.isAnnotationPresent(Repository.class) ||
            clazz.isAnnotationPresent(Controller.class)) {
            components.add(clazz);
        }
    }
    return components;
}
```

### 4.3 AOP 프록시 생성

```java
// JDK Dynamic Proxy (인터페이스 기반)
public Object createProxy(Object target) {
    return Proxy.newProxyInstance(
        target.getClass().getClassLoader(),
        target.getClass().getInterfaces(),
        (proxy, method, args) -> {
            // Before advice
            System.out.println("Before: " + method.getName());

            // 실제 메서드 호출 (리플렉션)
            Object result = method.invoke(target, args);

            // After advice
            System.out.println("After: " + method.getName());

            return result;
        }
    );
}
```

### 4.4 @RequestMapping 처리

```java
// HandlerMapping 구성 (단순화)
public Map<String, HandlerMethod> buildHandlerMappings() {
    Map<String, HandlerMethod> mappings = new HashMap<>();

    for (Object controller : controllers) {
        Class<?> clazz = controller.getClass();

        // 클래스 레벨 @RequestMapping
        String basePath = "";
        if (clazz.isAnnotationPresent(RequestMapping.class)) {
            basePath = clazz.getAnnotation(RequestMapping.class).value()[0];
        }

        // 메서드 레벨 매핑
        for (Method method : clazz.getDeclaredMethods()) {
            if (method.isAnnotationPresent(GetMapping.class)) {
                String path = basePath + method.getAnnotation(GetMapping.class).value()[0];
                mappings.put("GET:" + path, new HandlerMethod(controller, method));
            }
            // PostMapping, PutMapping, DeleteMapping 등도 동일하게 처리
        }
    }
    return mappings;
}
```

---

## 5. 리플렉션 성능 고려사항

### 5.1 성능 비교

```java
// 직접 호출 vs 리플렉션 호출 벤치마크
public class ReflectionBenchmark {

    // 직접 호출: ~1ns
    public void directCall() {
        user.getUsername();
    }

    // 리플렉션 호출: ~100-500ns (캐싱 없이)
    public void reflectionCall() throws Exception {
        Method method = User.class.getMethod("getUsername");
        method.invoke(user);
    }

    // 리플렉션 호출 (Method 캐싱): ~10-50ns
    private static final Method cachedMethod = User.class.getMethod("getUsername");

    public void cachedReflectionCall() throws Exception {
        cachedMethod.invoke(user);
    }
}
```

### 5.2 성능 저하 원인

| 원인 | 설명 |
|------|------|
| **타입 검사** | 런타임에 파라미터 타입 검증 필요 |
| **접근 제어 검사** | setAccessible() 호출 비용 |
| **JIT 최적화 제한** | 인라이닝, 상수 폴딩 등 불가 |
| **박싱/언박싱** | primitive 타입 처리 시 Object 변환 |
| **메서드 탐색** | getDeclaredMethod() 호출 시 |

### 5.3 Spring의 최적화 전략

```java
// Spring은 리플렉션 결과를 캐싱
public class CachedIntrospectionResults {
    // 클래스별로 PropertyDescriptor, Method 등 캐싱
    private static final Map<Class<?>, CachedIntrospectionResults> cache
        = new ConcurrentHashMap<>();

    private final PropertyDescriptor[] propertyDescriptors;
    private final Map<String, Method> readMethods;
    private final Map<String, Method> writeMethods;
}
```

---

## 6. 리플렉션 사용 시 주의사항

### 6.1 캡슐화 파괴

```java
// ❌ Bad: 캡슐화 무시하고 private 필드 직접 수정
Field passwordField = User.class.getDeclaredField("password");
passwordField.setAccessible(true);
passwordField.set(user, "hacked");  // 유효성 검사 우회

// ✅ Good: 공개된 API 사용
user.changePassword("newPassword");  // 검증 로직 포함
```

### 6.2 타입 안전성 상실

```java
// 컴파일 타임 타입 체크 불가
Method method = clazz.getMethod("process", Object.class);
method.invoke(target, "wrong-type");  // 런타임에서야 에러 발생
```

### 6.3 Java 모듈 시스템 (Java 9+)

```java
// Java 9+ 에서 강화된 접근 제어
// 다른 모듈의 내부 클래스 접근 시 예외 발생

// 해결: JVM 옵션 추가 (권장하지 않음)
// --add-opens java.base/java.lang=ALL-UNNAMED
```

### 6.4 보안 고려사항

```java
// SecurityManager가 활성화된 환경에서는 리플렉션 제한
// checkPermission(new ReflectPermission("suppressAccessChecks"))
```

---

## 7. 리플렉션 대안

### 7.1 MethodHandle (Java 7+)

```java
// 리플렉션보다 빠른 동적 메서드 호출
MethodHandles.Lookup lookup = MethodHandles.lookup();
MethodType type = MethodType.methodType(String.class);
MethodHandle handle = lookup.findVirtual(User.class, "getUsername", type);

String result = (String) handle.invoke(user);  // 더 빠름
```

### 7.2 컴파일 타임 코드 생성

```java
// Lombok: 컴파일 시점에 getter/setter 생성
@Data
public class User {
    private String username;  // getUsername(), setUsername() 자동 생성
}

// MapStruct: 컴파일 시점에 매퍼 구현체 생성
@Mapper
public interface UserMapper {
    UserDto toDto(User user);  // 구현체 자동 생성
}
```

### 7.3 바이트코드 조작 라이브러리

```java
// ByteBuddy, CGLIB, ASM
// Spring AOP의 CGLIB 프록시도 이 방식
Class<?> dynamicType = new ByteBuddy()
    .subclass(User.class)
    .method(named("getUsername"))
    .intercept(FixedValue.value("intercepted"))
    .make()
    .load(getClass().getClassLoader())
    .getLoaded();
```

---

## 8. 정리: 언제 리플렉션을 사용하는가?

### 적합한 경우

| 사용처 | 예시 |
|--------|------|
| **프레임워크 개발** | Spring DI, Hibernate ORM, Jackson JSON |
| **테스트 코드** | private 메서드 테스트, Mock 라이브러리 |
| **직렬화/역직렬화** | JSON, XML, Protocol Buffers |
| **동적 프록시** | AOP, 로깅, 트랜잭션 처리 |
| **플러그인 시스템** | 런타임에 클래스 동적 로딩 |

### 피해야 하는 경우

| 상황 | 이유 |
|------|------|
| **일반 비즈니스 로직** | 성능 저하, 타입 안전성 상실 |
| **public API로 해결 가능한 경우** | 캡슐화 파괴 |
| **성능 크리티컬한 코드** | 직접 호출 대비 10-100배 느림 |

---

## 9. Spring에서 리플렉션이 final 필드 주입을 막지 못하는 이유

### 왜 필드 @Value에 final을 쓸 수 없는가?

```java
Java 언어 스펙 vs 리플렉션

1. final 필드 = "생성자 완료 전에 초기화 필수" (Java 언어 규칙)
   └─ 컴파일러가 강제함 → 컴파일 에러

2. 리플렉션 = "런타임에 바이트코드 레벨에서 조작"
   └─ 컴파일러 검사 이후 동작
   └─ final 필드도 기술적으로 수정 가능 (Java 8까지)

문제: 리플렉션이 final을 수정할 수 있어도,
      컴파일러가 먼저 "초기화 안 됨" 에러를 발생시킴
```

```java
@Value("${cookie.secure}")
private final boolean cookieSecure;  // ❌ 컴파일 에러
// "variable cookieSecure might not have been initialized"

// 리플렉션이 실행되기도 전에 컴파일이 실패함!
```

---

## References

- [Java Reflection Tutorial - Oracle](https://docs.oracle.com/javase/tutorial/reflect/)
- [Spring Framework - Core Technologies](https://docs.spring.io/spring-framework/reference/core.html)
- [MethodHandles - Java 7+](https://docs.oracle.com/javase/8/docs/api/java/lang/invoke/MethodHandles.html)
- [JEP 193: Variable Handles](https://openjdk.org/jeps/193)