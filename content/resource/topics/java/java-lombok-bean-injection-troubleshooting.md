---
tags: [java, troubleshooting, lombok, spring, di, value, requiredargsconstructor]
category: java
created: 2026-01-16
status: complete
description: Lombok의 @RequiredArgsConstructor와 Spring의 @Value 어노테이션을 함께 사용할 때 발생하는 Bean 주입 실패 문제 분석 및 해결 방안
---

# Lombok @RequiredArgsConstructor와 @Value 충돌: Spring Bean 주입 실패 트러블슈팅

> Spring 프로젝트에서 Lombok의 @RequiredArgsConstructor를 사용하여 생성자 주입을 할 때, @Value 어노테이션으로 final 필드에 값을 주입받으려 하면 발생하는 Bean 주입 실패 문제를 분석하고, 명시적 생성자, @ConfigurationProperties 등을 활용한 해결 방안을 제시합니다.

---

## 개요
이 문서는 Spring Framework를 사용하는 프로젝트에서 Lombok의 `@RequiredArgsConstructor` 애너테이션과 Spring의 `@Value` 애너테이션을 함께 사용할 때 발생하는 일반적인 Bean 주입 실패 문제에 대한 분석 및 해결 과정을 다룹니다. `AuthController`와 같은 컴포넌트에서 설정값을 `final` 필드에 주입받으려 할 때 발생하는 `No beans of 'boolean' type found`와 같은 오류의 원인을 심층적으로 분석하고, 명시적 생성자 작성, `@ConfigurationProperties` 분리 등 다양한 해결 방안을 제시합니다.

## 문제 상황

`AuthController`에서 `AuthService`, `JwtTokenProvider`와 같은 다른 Bean들과 함께 `@Value` 애너테이션이 붙은 `cookieSecure`라는 `final boolean` 필드에 설정값을 주입받으려 할 때, IDE에서 `Could not autowire. No beans of 'boolean' type found.`와 같은 경고 또는 런타임 시 Bean 생성 실패 오류가 발생했습니다.

**문제 코드 예시:**

```java
@RestController
@RequiredArgsConstructor // ← Lombok이 모든 final 필드에 대한 생성자를 생성
@RequestMapping("/api/v1/auth")
public class AuthController {

  private final AuthService authService;
  private final JwtTokenProvider jwtTokenProvider;

  @Value("${linkwave.cookie.secure:true}")
  private final boolean cookieSecure; // ← 이 final 필드에 @Value로 값을 주입하려 할 때 충돌 발생

  // ... (다른 메서드들)
}
```

## 원인 분석

문제의 핵심은 **Lombok의 `@RequiredArgsConstructor`가 생성하는 생성자의 동작 방식과 Spring의 `@Value` 애너테이션 처리 방식의 불일치**에 있습니다.

1.  **Lombok `@RequiredArgsConstructor`의 동작 방식**:
    `@RequiredArgsConstructor`는 클래스 내의 모든 `final` 필드 (또는 `NonNull` 필드)를 파라미터로 받는 생성자를 컴파일 시점에 생성합니다. 이때, 필드에 붙어있는 `@Value` 애너테이션은 **생성되는 생성자의 파라미터로 복사되지 않습니다.** Lombok은 `@NonNull`과 같은 특정 애너테이션만 예외적으로 처리할 뿐, `@Value`는 포함하지 않습니다.

    **Lombok이 생성하는 예상 코드:**
    ```java
    public AuthController(AuthService authService,
                          JwtTokenProvider jwtTokenProvider,
                          boolean cookieSecure) { // 파라미터에는 @Value 애너테이션이 없음!
      this.authService = authService;
      this.jwtTokenProvider = jwtTokenProvider;
      this.cookieSecure = cookieSecure;
    }
    ```

2.  **Spring 컨테이너의 Bean 주입 메커니즘**:
    Spring 컨테이너는 `AuthController` Bean을 생성할 때, 해당 클래스의 생성자를 분석하여 필요한 의존성을 주입합니다. Lombok이 생성한 위 생성자를 분석하면 Spring은 `AuthService`, `JwtTokenProvider` 타입의 Bean을 찾고, 마지막으로 `boolean` 타입의 Bean을 찾으려고 시도합니다.

3.  **충돌 발생**:
    `AuthService`와 `JwtTokenProvider`는 Spring 컨테이너에 Bean으로 등록되어 있으므로 정상적으로 주입됩니다. 하지만 `boolean` 타입의 Bean은 존재하지 않으므로, Spring은 `No beans of 'boolean' type found`와 같은 오류를 발생시키며 `AuthController` Bean 생성에 실패하게 됩니다. 이는 `@Value` 애너테이션이 생성자 파라미터에 명시적으로 존재하지 않아 Spring이 해당 파라미터에 설정값을 주입하는 대신 `boolean` 타입의 다른 Bean을 찾으려 하기 때문입니다.

## 해결 과정

이 문제에 대한 몇 가지 해결 방법이 있으며, 각 방법마다 장단점이 있습니다.

### 1. 명시적 생성자 작성 (권장)

가장 명확하고 Spring의 생성자 주입 `Best Practice`를 따르는 방법입니다. Lombok의 `@RequiredArgsConstructor` 대신 개발자가 직접 생성자를 작성하고, `@Value` 애너테이션을 생성자 파라미터에 명시합니다.

```java
@RestController
@RequestMapping("/api/v1/auth")
public class AuthController {

  private final AuthService authService;
  private final JwtTokenProvider jwtTokenProvider;
  private final boolean cookieSecure; // final 필드 유지 가능

  // 개발자가 직접 생성자를 작성하고, @Value를 파라미터에 명시
  public AuthController(
      AuthService authService,
      JwtTokenProvider jwtTokenProvider,
      @Value("${linkwave.cookie.secure:true}") boolean cookieSecure) {
    this.authService = authService;
    this.jwtTokenProvider = jwtTokenProvider;
    this.cookieSecure = cookieSecure;
  }
}
```

### 2. `final` 키워드 제거 + 필드 주입

`@RequiredArgsConstructor`가 생성자에서 제외하도록 `@Value` 필드의 `final` 키워드를 제거합니다. 이 경우 Spring은 리플렉션을 통해 해당 필드에 값을 주입합니다. 하지만 불변성(immutability) 보장이라는 `final`의 장점을 잃게 됩니다.

```java
@RestController
@RequiredArgsConstructor // final 필드만 생성자 파라미터로 포함
@RequestMapping("/api/v1/auth")
public class AuthController {

  private final AuthService authService;
  private final JwtTokenProvider jwtTokenProvider;

  @Value("${linkwave.cookie.secure:true}")
  private boolean cookieSecure; // final 제거 → @RequiredArgsConstructor 생성자에서 제외됨
}
```

### 3. `@ConfigurationProperties` 분리

설정값이 여러 개이거나 복잡한 경우, `@ConfigurationProperties`를 사용하여 설정값을 담는 별도의 클래스(또는 레코드)를 정의하고 이를 Bean으로 주입받는 방법입니다.

```java
// 별도의 설정값 클래스 (record 또는 class)
@ConfigurationProperties(prefix = "linkwave.cookie")
public record CookieProperties(boolean secure) {}

// Controller에서 Bean으로 주입
@RestController
@RequiredArgsConstructor
public class AuthController {
  private final AuthService authService;
  private final JwtTokenProvider jwtTokenProvider;
  private final CookieProperties cookieProperties; // Bean으로 주입받아 사용
}
```

## 설계 결정과 이유 (왜 이 방식을 선택했는가)

위 세 가지 해결 방안 중 **"명시적 생성자 작성" (해결 방법 1)**이 가장 권장됩니다.
*   **불변성(Immutability) 유지**: `final` 필드를 유지할 수 있어 객체의 불변성을 보장하며, 이는 다중 스레드 환경에서 안전하고 유지보수성을 높입니다.
*   **명시적인 의존성**: 생성자 파라미터에 `@Value`를 명시함으로써 어떤 설정값이 주입되는지 코드를 통해 명확히 파악할 수 있습니다.
*   **Spring `Best Practice` 준수**: Spring 공식 문서에서도 생성자 주입을 권장하고 있으며, 이는 테스트 용이성과 순환 의존성 조기 발견 등 여러 장점을 제공합니다.
*   **코드량 관리**: `@Value`로 주입받는 설정값이 1~2개 정도일 경우 코드량 증가가 미미하여 가독성을 해치지 않습니다.

설정값이 많아지거나 계층적인 구조를 가질 경우 `@ConfigurationProperties`를 사용하는 것이 더 효과적일 수 있지만, 단일 설정값 주입에는 명시적 생성자 작성이 가장 적절한 균형점을 제공합니다.

## 배운 점

*   **Lombok `@RequiredArgsConstructor`의 동작 한계**: `@RequiredArgsConstructor`는 `final` 필드에 대한 생성자를 자동으로 생성해주지만, 필드에 붙은 `@Value`와 같은 애너테이션을 생성자 파라미터로 전이시키지 않는다는 것을 명확히 이해했습니다. 이는 Lombok을 사용할 때 애너테이션 처리 방식에 대한 내부 메커니즘을 파악하는 것이 중요함을 시사합니다.
*   **Spring의 `@Value` 주입 방식**: `@Value`는 생성자 파라미터에 직접 사용될 때 Spring이 해당 플레이스홀더를 해석하여 값을 주입한다는 것을 재확인했습니다. 필드 주입은 리플렉션으로 이루어지지만, `final` 필드에는 컴파일 타임에 초기화되어야 한다는 Java 언어 규칙 때문에 필드 주입 방식을 사용할 수 없습니다.
*   **명시적인 코드 작성의 중요성**: 자동화 도구(Lombok)의 편리함도 좋지만, 때로는 명시적으로 코드를 작성하는 것이 프레임워크와의 상호작용 및 디버깅 측면에서 더 명확하고 문제를 예방하는 데 도움이 된다는 것을 배웠습니다.
*   **설정값 관리 전략**: 설정값의 개수와 복잡도에 따라 `@Value` 직접 주입, `@ConfigurationProperties` 분리 등 다양한 전략을 고려해야 함을 인지했습니다.

---

## References
[명시적인 참조가 없어 빈 섹션으로 유지합니다.]