---
tags:
  - resource
  - spring
  - jpa
  - backend
  - hibernate
category: spring
topic: ManyToOne(fetch = FetchType.LAZY)
status: complete
created: 2024-01-01
modified: 2025-10-29
---
@JsonIgnoreProperties({"hibernateLazyInitializer", "handler"})


@ManyToOne(fetch = FetchType.LAZY) 이 걸 사용했더니 에러가 나서 @JsonIgnoreProperties({"hibernateLazyInitializer", "handler"}) 이것으로 해결했어. 무엇이 문제였고 왜 해결이 되었을까?



정확하게 잘 짚었어.
너가 겪은 문제는 **`@ManyToOne(fetch = FetchType.LAZY)`와 JSON 직렬화(Jackson)`간의 충돌 문제**고, 그걸`@JsonIgnoreProperties({"hibernateLazyInitializer", "handler"})`로 해결했다는 건
바로 **Hibernate 프록시 객체가 JSON 변환 중 오류를 발생시킨 것**이야.

## ✅ 문제 상황 요약

@ManyToOne(fetch = FetchType.LAZY)
private User user;

이렇게 `@ManyToOne(fetch = LAZY)`를 쓰고,
해당 엔티티를 **JSON으로 반환하려고 할 때** (예: API 응답) 아래와 같은 **에러**가 발생했어

com.fasterxml.jackson.databind.JsonMappingException:
  Infinite recursion or no serializer found...


## ✅ 왜 에러가 발생했을까?

Hibernate에서 `LAZY`로 설정하면,
실제 객체(`User`)를 즉시 넣는 게 아니라,
**"프록시 객체(proxy)"**를 만들어서 넣어둬.

예:com.example.User$$HibernateProxy

이 프록시 객체에는 실제 데이터가 없고, 내부적으로 `hibernateLazyInitializer`, `handler` 같은 **지연 로딩용 필드**가 있어.

근데 Jackson은 이걸 **모르는 채로 직렬화(serialize)하려다 실패**함.

---

## ✅ 해결방법: `@JsonIgnoreProperties`

@JsonIgnoreProperties({"hibernateLazyInitializer", "handler"})
@ManyToOne(fetch = FetchType.LAZY)
private User user;

### 어떤 원리?

- `@JsonIgnoreProperties`는 **JSON 변환 시 무시할 필드를 지정**하는 애너테이션이야.
- 즉, `hibernateLazyInitializer`와 `handler`라는 **Hibernate 내부용 필드를 Jackson이 직렬화하지 않도록** 설정해서, 오류를 회피하는 거지.

### 이 방법의 한계

- 근본적 해결책은 아니야.
- 프록시가 초기화되지 않은 상태로 JSON 변환을 시도하면 여전히 문제가 발생할 수 있어.

---

## ✅ 더 근본적인 해결방법들

### 1) DTO 사용 (가장 권장!)

@Data
public class ProductDto {
    private Long id;
    private String name;
    private Long userId;  // User 객체가 아닌 ID만

    public ProductDto(Product product) {
        this.id = product.getId();
        this.name = product.getName();
        this.userId = product.getUser().getId(); // 필요할 때만 가져오기
    }
}

**→ 엔티티 그대로 반환하지 말고, 필요한 정보만 담은 DTO 사용.**
이게 제일 깔끔해.

---

### 2) `@JsonIgnore`로 필드 자체를 숨기기

@JsonIgnore
@ManyToOne(fetch = FetchType.LAZY)
private User user;

**→ user 필드를 JSON 변환에서 완전히 제외.**
만약 안 쓰는 필드라면 이 방법도 괜찮아.

---

### 3) `EAGER` 로딩 (비추천)

@ManyToOne(fetch = FetchType.EAGER)
private User user;

**→ 조인해서 즉시 가져오니까 프록시 문제가 안 생김.**
근데 **성능 저하**를 일으킬 수 있어서 비추.

---

### 4) Hibernate5Module 사용

implementation 'com.fasterxml.jackson.datatype:jackson-datatype-hibernate5'

@Bean
public Module hibernateModule() {
    return new Hibernate5Module();
}

**→ Jackson에서 Hibernate 프록시를 자동으로 처리하게 설정.**
근데 여전히 DTO 쓰는 게 제일 명확하고 안전해.

---

## ✅ 정리

- **문제 원인**: LAZY 설정 → Hibernate 프록시 → Jackson이 못 읽음
- **기존 해결**: `@JsonIgnoreProperties` → 특정 필드 무시
- **더 나은 해결**: **DTO 사용 → 엔티티를 API 응답으로 직접 반환하지 말기**

결론: **가능하면 DTO 패턴을 써라!** 🎯
