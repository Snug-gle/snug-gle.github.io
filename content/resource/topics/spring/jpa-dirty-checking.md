---
tags:
  - resource
  - spring
  - jpa
  - backend
category: spring
topic: JPA Dirty Checking
status: complete
created: 2024-01-01
modified: 2026-03-26
related: [spring-transactional-deep-dive, spring-cqrs-command-query-path-separation, manytoone-lazy-loading]
---

# 🔍 JPA Dirty Checking (변경 감지)

## 📌 정의

JPA가 엔티티의 변경 여부를 자동으로 감지하여, 트랜잭션 커밋 시점에 자동으로 UPDATE 쿼리를 실행하는 메커니즘.

## 🔍 동작 흐름

1. 트랜잭션 시작 → EntityManager가 엔티티를 영속 상태로 관리
2. 엔티티의 필드를 수정 (setter 등)
3. 트랜잭션 커밋 시점 → JPA가 스냅샷과 현재 상태를 비교하여 변경 감지
4. 변경된 필드가 있으면 UPDATE 쿼리 자동 실행

```java
@Transactional
public void updateUserName(Long id, String newName) {
    User user = userRepository.findById(id).orElseThrow();
    user.setName(newName); // 여기서 변경

    // 별도로 save() 안 해도 JPA가 자동으로 UPDATE 날림
}
// => UPDATE user SET name = 'newName' WHERE id = 1;
```

## ✅ 장점

- 명시적 UPDATE 쿼리 없이 변경 감지만으로 저장 가능
- 트랜잭션 안에서만 작동하므로 안전하고 일관성 있음
- 변경이 없으면 UPDATE도 발생하지 않음 (불필요한 쿼리 없음)

## ❗ 주의할 점

- 트랜잭션 범위를 벗어나면 더티 체킹 작동 안 함
- `flush()` 호출 시점에 쿼리 실행됨 (commit보다 먼저 발생 가능)
- 엔티티가 영속 상태일 때만 작동 (`new`, `detach`, `removed` 상태는 안 됨)

> [!tip] Best Practice
> 엔티티 상태 변경은 반드시 `@Transactional` 범위 안에서 수행하고, 비즈니스 로직은 엔티티 메서드로 캡슐화하는 것이 권장 패턴이다.

## 🔗 Related Concepts

- [[spring-transactional-deep-dive|Spring @Transactional 심화]]
- [[manytoone-lazy-loading|ManyToOne LAZY 로딩과 Jackson 직렬화]]
- [[spring-cqrs-command-query-path-separation|CQRS Command/Query 경로 분리]]

## 📚 References

- [Spring Data JPA Documentation](https://docs.spring.io/spring-data/jpa/docs/current/reference/html/)
- [Hibernate ORM — Flushing](https://docs.jboss.org/hibernate/orm/current/userguide/html_single/Hibernate_User_Guide.html#flushing)
