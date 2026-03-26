---
tags:
  - resource
  - spring
  - jpa
  - backend
  - entity
category: spring
topic: JPA Entity Relationships
status: complete
created: 2024-01-01
modified: 2026-03-26
related: [manytoone-lazy-loading, jpa-dirty-checking, spring-transactional-deep-dive]
---

# 🔍 JPA 엔티티 관계 어노테이션

## 📌 @OneToMany 주요 속성

### `mappedBy`

```java
@OneToMany(mappedBy = "user")
private List<Order> orders;
```

- 연관관계의 주인을 설정하는 속성
- `mappedBy = "user"` → `user` 필드가 있는 클래스(Order)가 연관관계 주인
- 연관관계 주인 쪽 클래스에 FK가 존재함

### `fetch = FetchType.LAZY`

```java
@OneToMany(mappedBy = "user", fetch = FetchType.LAZY)
private List<Order> orders;
```

- 연관된 데이터를 언제 로드할지 결정하는 옵션
- `LAZY`: 해당 필드를 실제로 호출할 때(`orders.get()`) 쿼리 실행
- 기본값은 컬렉션(`@OneToMany`)이면 `LAZY`, 단일 연관(`@ManyToOne`)이면 `EAGER`

### `cascade = CascadeType.ALL`

```java
@OneToMany(mappedBy = "user", cascade = CascadeType.ALL)
private List<Order> orders;
```

- 부모 엔티티의 저장/삭제 작업을 자식 엔티티에도 전파하는 옵션
- `CascadeType.ALL`: persist, merge, remove 등 모든 작업 전파
- 주로 부모-자식 생명주기가 동일한 경우에 사용

### `orphanRemoval = true`

```java
@OneToMany(mappedBy = "user", cascade = CascadeType.ALL, orphanRemoval = true)
private List<Order> orders;
```

- 부모 엔티티의 컬렉션에서 자식 엔티티가 제거되면 DB에서도 DELETE
- `cascade = REMOVE`와 차이: 컬렉션에서 제거(`list.remove()`)만으로도 삭제 트리거

## ✅ 자주 쓰는 조합

```java
// 라이프사이클을 완전히 부모에게 위임하는 패턴
@OneToMany(mappedBy = "parent",
           fetch = FetchType.LAZY,
           cascade = CascadeType.ALL,
           orphanRemoval = true)
private List<Child> children = new ArrayList<>();
```

> [!warning] orphanRemoval 주의
> `orphanRemoval = true`는 다른 엔티티에서 같은 자식을 참조하지 않을 때만 사용해야 한다. 공유 엔티티에 적용하면 의도치 않은 DELETE가 발생할 수 있다.

## 🔗 Related Concepts

- [[manytoone-lazy-loading|ManyToOne LAZY 로딩과 Jackson 직렬화]]
- [[jpa-dirty-checking|JPA Dirty Checking (변경 감지)]]
- [[spring-transactional-deep-dive|Spring @Transactional 심화]]

## 📚 References

- [Hibernate ORM — Associations](https://docs.jboss.org/hibernate/orm/current/userguide/html_single/Hibernate_User_Guide.html#associations)
- [Spring Data JPA Documentation](https://docs.spring.io/spring-data/jpa/docs/current/reference/html/)
