---
tags:
  - java
  - record
  - backend
  - modern-java
category: resource
created: 2026-03-31
related:
  - spring-batch-scheduler-chunk-delete
  - java-oop-basics
---

# 🔍 Java Record: compact constructor vs canonical constructor

## 📌 Situation / Symptom

`@ConfigurationProperties`로 설정을 바인딩하는 Java Record에 기본값 보정 로직을 추가해야 했다. `retentionDays <= 0`이면 180으로, `chunkSize <= 0`이면 1000으로 보정하고 싶었는데, Record는 일반 클래스처럼 setter가 없다. 어떤 생성자를 써야 하는가?

---

## 🔍 Technical Analysis

### canonical constructor vs compact constructor

| 구분 | canonical constructor | compact constructor |
|------|----------------------|---------------------|
| 파라미터 선언 | `(int retentionDays, int chunkSize)` 전체 명시 | 파라미터 목록 생략 |
| 필드 할당 | `this.retentionDays = retentionDays` 직접 작성 | 파라미터 재할당 후 컴파일러가 자동 복사 |
| 주 용도 | 모든 초기화 직접 제어 | 검증/보정만 작성, 할당은 위임 |
| 코드량 | 많음 | 적음 |

### compact constructor 동작 원리

```java
public record ArchiveBatchProperties(int retentionDays, int chunkSize) {

    // compact constructor — () 생략
    public ArchiveBatchProperties {
        // 여기서 파라미터 변수(retentionDays, chunkSize)를 직접 재할당 가능
        if (retentionDays <= 0) retentionDays = 180;  // 파라미터 재할당
        if (chunkSize <= 0)     chunkSize = 1000;
        // {} 블록 끝에서 컴파일러가 자동으로
        // this.retentionDays = retentionDays;
        // this.chunkSize = chunkSize; 를 삽입
    }
}
```

컴파일러는 compact constructor 블록 끝에 `this.field = param` 구문을 자동 삽입한다. 따라서 `{}` 안에서는 파라미터 변수를 재할당하는 것으로 충분하다.

### canonical constructor로 동일 효과 구현 시

```java
public record ArchiveBatchProperties(int retentionDays, int chunkSize) {

    // canonical constructor — () 명시 필수
    public ArchiveBatchProperties(int retentionDays, int chunkSize) {
        this.retentionDays = retentionDays <= 0 ? 180 : retentionDays;
        this.chunkSize     = chunkSize <= 0     ? 1000 : chunkSize;
    }
}
```

canonical constructor는 `this.field = ...`를 반드시 직접 작성해야 한다.

### 왜 compact constructor가 더 적합한가

1. **의도 명확**: "보정/검증만" 작성하고 할당은 Record가 처리 — 책임 분리
2. **실수 방지**: `this.chunkSize = retentionDays` 같은 교차 할당 오류 불가
3. **간결함**: 필드가 많을수록 compact가 유리

> [!tip] Best Practice
> 검증(throw)이나 기본값 보정만 필요하다면 compact constructor를 사용하라. 파라미터 값을 변환하거나 다른 파라미터를 조합해야 하는 복잡한 초기화가 있을 때만 canonical constructor를 선택하라.

---

## 🛠 Solution

### @ConfigurationProperties 바인딩 + compact constructor 조합

```java
@ConfigurationProperties(prefix = "app.batch.archive")
public record ArchiveBatchProperties(int retentionDays, int chunkSize) {
    public ArchiveBatchProperties {
        if (retentionDays <= 0) retentionDays = 180;
        if (chunkSize <= 0)     chunkSize = 1000;
    }
}
```

`application.yml`에서 값이 누락되거나 0 이하로 설정된 경우 자동 보정되므로 NPE / 논리 오류 없이 안전하게 동작한다.

> [!warning] 주의
> compact constructor 내에서 `this.retentionDays = ...` 형태로 필드에 직접 접근하려 하면 컴파일 오류가 발생한다. 반드시 파라미터 변수(`retentionDays`)를 재할당하는 방식을 사용해야 한다.

---

## 🔗 Related Concepts

- [[resource/topics/spring/spring-batch-scheduler-chunk-delete|배치 스케줄러 구현 패턴: 청크 삭제 + 분산 락]] — compact constructor를 실제 적용한 컨텍스트
- [[resource/topics/java/java-oop-basics|Java OOP 기초]] — 생성자 기본 개념

---

## 📚 References

- [JEP 395: Records (Java 16)](https://openjdk.org/jeps/395)
- [Java Language Specification — Record Classes](https://docs.oracle.com/javase/specs/jls/se21/html/jls-8.html#jls-8.10)
