---
tags:
  - spring
  - aop
  - proxy
  - self-invocation
  - backend
category: resource
created: 2026-03-26
related:
  - spring-cache-aop-proxy-pattern
  - spring-transactional-deep-dive
  - spring-bean-lifecycle-ioc-di
---

# 🔍 Spring AOP 프록시와 Self-Invocation 함정

> AOP가 어노테이션 하나로 동작하는 원리, 그리고 같은 클래스 내부 호출에서 조용히 실패하는 이유

---

## 📌 Situation / Symptom

같은 서비스 클래스 안에서 `@Cacheable` 메서드를 `this.method()`로 호출했는데 캐시가 전혀 동작하지 않았다. 에러 메시지도 없고, 단순히 매번 DB를 조회했다. 처음에는 캐시 설정 문제라고 생각했지만, 원인은 AOP 프록시 동작 원리에 있었다.

`@Transactional`을 붙인 내부 메서드에서도 같은 현상이 발생한다 — 독립 트랜잭션(`REQUIRES_NEW`)이 기대했는데 부모 트랜잭션에 합류해버리는 경우.

---

## 🔍 Technical Analysis

### 1. AOP가 동작하는 원리 — 횡단 관심사와 프록시

**횡단 관심사(Cross-Cutting Concern)**: 트랜잭션, 캐시, 로깅, 보안처럼 비즈니스 로직과 무관하지만 여러 곳에 반복되는 코드.

AOP 이전의 방식:
```java
public void saveUser(User user) {
    // 1. 트랜잭션 시작 (반복 코드)
    TransactionManager.begin();
    try {
        // 2. 실제 비즈니스 로직
        userRepository.save(user);
        TransactionManager.commit();
    } catch (Exception e) {
        TransactionManager.rollback();
        throw e;
    }
}
```

AOP 방식:
```java
@Transactional  // "트랜잭션이 필요하다"는 선언만
public void saveUser(User user) {
    userRepository.save(user);  // 비즈니스 로직만
}
```

Spring이 `@Transactional`이나 `@Cacheable`이 붙은 Bean을 등록할 때, **실제 객체 대신 프록시 객체를 컨테이너에 등록**한다. 다른 Bean이 이 Bean을 주입받으면 프록시를 받게 된다.

```
일반 호출 흐름:
호출자 → [AOP 프록시] → 인터셉터 실행 → 실제 객체 메서드

self-invocation 흐름:
호출자 → [AOP 프록시] → 실제 객체 메서드 A → this.메서드 B()
                                               ↑
                                    this = 실제 객체 (프록시 아님)
                                    프록시 우회 → 인터셉터 미실행
```

### 2. this가 항상 실제 객체인 이유

`this`는 Java 언어 수준의 참조로, **현재 실행 중인 객체 자신**을 가리킨다. Spring이 프록시를 만들더라도 실제 객체 안의 `this`를 프록시로 바꿀 수 없다. Java 언어 명세 자체가 허용하지 않는다.

```java
// Spring이 내부적으로 하는 일 (단순화)
class KeywordServiceProxy extends KeywordService {

    private final CacheInterceptor cacheInterceptor;
    private final KeywordService realObject;  // 진짜 객체 참조

    @Override
    public Set<String> loadKeywords() {
        // 프록시가 가로채서 캐시 처리
        return cacheInterceptor.invoke(() -> realObject.loadKeywords());
    }
}
```

진짜 `KeywordService` 객체 안에서 `this.loadKeywords()`를 호출하면, 그 `this`는 `realObject`이지 `KeywordServiceProxy`가 아니다.

### 3. Self-Invocation의 핵심 위험 — 조용한 실패

이것이 self-invocation을 특히 위험하게 만드는 이유다.

| 어노테이션 | self-invocation 시 증상 |
|-----------|------------------------|
| `@Cacheable` | 에러 없이 매번 DB 조회 (캐시 완전 무시) |
| `@CacheEvict` | 에러 없이 무효화 미실행 (Stale Cache 유지) |
| `@Transactional` | 에러 없이 트랜잭션 없이 실행 (또는 기존 트랜잭션 합류) |
| `@Transactional(REQUIRES_NEW)` | 에러 없이 독립 트랜잭션 분리 실패 |
| `@Async` | 에러 없이 동기 실행 |

로그에도 남지 않고, 예외도 발생하지 않는다. 기능 테스트에서도 "DB 조회가 좀 많네?"로 지나치기 쉽다.

### 4. 해결 방법 — 별도 Bean으로 분리

유일한 근본적 해결책은 **호출 경계를 Bean 경계로 만드는 것**이다. 즉, AOP 어노테이션이 붙은 메서드를 별도 Bean에 두고, 외부 Bean 호출로 만든다.

**Before — self-invocation 발생:**
```java
@Service
public class ContentFilterService {

    @Cacheable("keywords")
    public Set<String> loadKeywords() {
        return keywordMapper.findAll();
    }

    public boolean check(String text) {
        return this.loadKeywords()  // 프록시 우회
                   .stream().anyMatch(text::contains);
    }
}
```

**After — Bean 분리로 해결:**
```java
// AOP 어노테이션 전담 Bean
@Repository
public class KeywordCacheRepository {

    @Cacheable("keywords")
    public Set<String> loadAll() {
        return keywordMapper.findAll();
    }

    @CacheEvict(value = "keywords", allEntries = true)
    public void evict() {}
}

// 비즈니스 로직 Bean — 외부 Bean 주입
@Component
public class ContentFilterKeywordStore {

    private final KeywordCacheRepository cacheRepo;  // 주입받음

    public Optional<String> findViolating(String content) {
        return cacheRepo.loadAll()  // 외부 Bean 호출 → 프록시 경유 → 캐시 동작
                        .stream()
                        .filter(content::contains)
                        .findFirst();
    }
}
```

> [!tip] Best Practice
> AOP 어노테이션(`@Cacheable`, `@CacheEvict`, `@Transactional`)이 붙은 메서드는 그 어노테이션 처리만 담당하는 전용 Bean에 두는 것이 원칙이다. 비즈니스 로직 Bean은 이 전용 Bean을 주입받아 외부 호출로 사용한다. 책임 분리이자 AOP 동작 보장이다.

### 5. AOP가 적용되는 원리 한 줄 요약

| 질문 | 답변 |
|------|------|
| 언제 프록시가 생성되나? | ApplicationContext 초기화 시 `BeanPostProcessor`가 처리 |
| 어떤 방식으로 프록시 생성? | CGLIB (클래스 상속 기반) 또는 JDK 다이나믹 프록시 (인터페이스 기반) |
| 프록시가 개입하는 조건 | Spring 컨테이너를 통해 주입받은 Bean의 메서드 호출 |
| 프록시가 개입하지 않는 조건 | `this.method()`, `new MyService()`, static 메서드 |

---

## 🛠 Solution

**루트 원인**: `this.method()` 호출은 항상 실제 객체를 통하므로 AOP 프록시를 우회한다.

**공통 해결 패턴**:
1. AOP 어노테이션 담당 클래스 분리
2. 외부에서 해당 클래스를 Bean으로 주입받아 호출
3. Spring 컨테이너를 통한 Bean 호출 → 프록시 경유 보장

> [!warning] 흔한 실수
> "같은 클래스니까 더 효율적으로 직접 호출하자"는 생각이 self-invocation 버그를 만든다. AOP 어노테이션이 붙은 메서드는 항상 외부 Bean을 통해 호출해야 한다. 팀원이 리팩토링하면서 클래스를 합칠 때도 이 원칙을 주의해야 한다.

---

## 🔗 Related Concepts

- [[spring-cache-aop-proxy-pattern|Spring Cache AOP 프록시 패턴과 로컬 캐시 전략]] — Caffeine 캐시에서 self-invocation 문제를 해결한 실제 구현 예시
- [[spring-transactional-deep-dive|Spring @Transactional 심층 분석]] — @Transactional의 self-invocation 함정과 Propagation 전략
- [[spring-bean-lifecycle-ioc-di|Spring IoC/DI와 Bean 생명주기]] — Bean이 프록시로 등록되는 시점과 ApplicationContext 초기화 흐름
- [[spring-internals-bean-lifecycle-event|Spring Bean 라이프사이클과 이벤트]] — BeanPostProcessor가 AOP 프록시를 생성하는 내부 동작

---

## 📚 References

- [Spring AOP 공식 문서 — Understanding AOP Proxies](https://docs.spring.io/spring-framework/reference/core/aop/proxying.html)
- [Spring @Transactional self-invocation limitation](https://docs.spring.io/spring-framework/reference/data-access/transaction/declarative/annotations.html)
