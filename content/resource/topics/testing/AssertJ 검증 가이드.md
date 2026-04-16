---
tags: [testing, assertj, unit-test, backend]
category: resource
created: 2026-04-16
related: [BDDMockito 스타일 가이드, JUnit5 @Nested 구조화, Mockito 테스트 어노테이션]
---

# 🔍 AssertJ 검증 가이드

## 📌 Situation / Symptom

JUnit 5 기본 `assertEquals(expected, actual)`은 인자 순서가 헷갈리고, 오류 메시지가 빈약하며, 체이닝이 불가능하다. AssertJ는 유창한(fluent) API로 테스트 검증 코드의 가독성과 오류 메시지 품질을 모두 높인다.

---

## 🔍 Technical Analysis

### 핵심 검증 메서드 정리

#### 예외 검증

```java
// 예외 발생을 검증
assertThatThrownBy(() -> service.doSomething(input))
    .isInstanceOf(IllegalArgumentException.class)
    .hasMessageContaining("invalid");

// 예외가 발생하지 않음을 검증
assertThatCode(() -> service.doSomething(validInput))
    .doesNotThrowAnyException();
```

**왜 ThrowingCallable인가**: `assertThatThrownBy`의 인자 타입은 `ThrowingCallable`이다. 이것은 추상 메서드 1개짜리 `@FunctionalInterface`이므로 람다 `() -> 코드`로 대체할 수 있다. 람다는 "인자 없이 실행할 코드 덩어리"를 넘기는 방법이다.

#### 반환값 검증

```java
// 단순 값 검증
assertThat(result).isEqualTo("expected");
assertThat(result).isNotNull();
assertThat(count).isGreaterThan(0);

// 컬렉션 검증
assertThat(list).hasSize(3);
assertThat(list).contains("a", "b");
assertThat(list).doesNotContain("c");

// Optional 검증
assertThat(optional).isPresent();
assertThat(optional).isEmpty();
assertThat(optional).hasValue("expected");
```

#### 객체 필드 추출 검증 (.extracting)

```java
// 단일 필드 추출
assertThat(user)
    .extracting("name")
    .isEqualTo("홍길동");

// 여러 필드 추출 (tuple)
assertThat(user)
    .extracting("name", "email")
    .containsExactly("홍길동", "hong@example.com");

// 컬렉션에서 필드 추출
assertThat(users)
    .extracting("name")
    .containsExactlyInAnyOrder("홍길동", "김철수");
```

**왜 리플렉션 기반인가**: `.extracting("fieldName")`은 리플렉션으로 필드 값을 꺼낸다. 컴파일 타임 안전성은 없지만, 메서드 레퍼런스 버전 `.extracting(User::getName)`을 쓰면 타입 안전하게 검증할 수 있다.

### JUnit assertEquals vs AssertJ 비교

| 항목 | JUnit assertEquals | AssertJ assertThat |
|------|---------------------|-------------------|
| 인자 순서 | `(expected, actual)` — 혼동 잦음 | `assertThat(actual).isEqualTo(expected)` |
| 체이닝 | 불가 | 가능 (`.isNotNull().isEqualTo(...)`) |
| 오류 메시지 | 기본적 | 상세 diff 제공 |
| 예외 검증 | `assertThrows()` 별도 | `assertThatThrownBy()` 인라인 |
| 커스텀 메시지 | `assertEquals(e, a, "msg")` | `.as("설명").isEqualTo(...)` |

> [!tip] Best Practice
> 예외 검증은 `assertThatThrownBy`를 쓰고, 정상 흐름 검증은 `assertThat(result)`로 시작하라. `.as("설명")`으로 검증 의도를 주석 대신 코드에 담을 수 있다.

---

## 🛠 Solution

### 람다 인자 타입 확인 요령

IDE에서 `assertThatThrownBy(` 입력 후 Ctrl+P(IntelliJ)로 인자 타입을 확인한다. `@FunctionalInterface`가 붙어 있으면 람다로 대체 가능하다.

```java
// ThrowingCallable = @FunctionalInterface → 람다 사용 가능
assertThatThrownBy(() -> service.riskyMethod());

// 익명 클래스로 써도 동일하지만 장황함
assertThatThrownBy(new ThrowingCallable() {
    @Override
    public void call() throws Throwable {
        service.riskyMethod();
    }
});
```

> [!warning] assertThatThrownBy와 doesNotThrowAnyException 혼용 금지
> 같은 시나리오에서 두 가지를 동시에 검증하려 하면 논리적 모순이다. 성공 케이스와 실패 케이스를 별도 테스트 메서드로 분리하라.

---

## 🔗 Related Concepts

- [[BDDMockito 스타일 가이드]] — then/should와 AssertJ 조합 패턴
- [[JUnit5 @Nested 구조화]] — @Nested 내 검증 배치
- [[Mockito 테스트 어노테이션]] — Mock 설정과 검증 연계

---

## 📚 References

- [AssertJ Core Features](https://assertj.github.io/doc/)
- [AssertJ Exception Testing](https://assertj.github.io/doc/#assertions-on-exceptions)
