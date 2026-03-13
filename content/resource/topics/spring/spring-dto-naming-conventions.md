---
tags: [backend, spring, java, architecture, naming-convention]
category: resource
created: 2026-03-13
related: [development-principles, spring-boot-best-practices, 역할 기반 분리 CQRS]
---

# 🔍 Spring Boot DTO 레이어별 네이밍 컨벤션

## 📌 Situation / Symptom

Spring Boot 멀티레이어 애플리케이션에서 DTO 클래스가 늘어날수록 `UserDto`, `MessageDto`, `MessageHistoryDto` 같은 단순 `*Dto` suffix만으로는 클래스의 **역할과 위치**를 즉시 파악하기 어렵다. 다음과 같은 문제가 반복적으로 발생한다.

- HTTP 응답 DTO인지 DB 조회 결과 DTO인지 이름만으로 알 수 없음
- 동일 도메인에 `MessageDto`, `MessageResponseDto`, `MessageQueryDto`가 공존해 혼란 발생
- 인프라 레이어(MyBatis) DTO가 컨트롤러까지 그대로 노출되는 레이어 오염

## 🔍 Technical Analysis

### 레이어 구조와 DTO 흐름

```
Controller  →  Application  →  Infrastructure(MyBatis/JPA)
    ↑               ↑                   ↑
*Request       *Response            *Result
(바인딩)      (클라이언트 응답)    (DB 조회 결과)
```

DTO는 **레이어 경계를 넘을 때마다 변환**된다. 각 레이어의 DTO는 서로 다른 라이프사이클과 관심사를 가진다.

### 레이어별 Suffix 규칙

| Suffix | 역할 | 위치 | 소비자 |
|--------|------|------|--------|
| `*Request` | HTTP 요청 바인딩 | `application/dto/request/` | Controller → Application |
| `*Response` | HTTP 응답 직렬화 | `application/dto/response/` | Application → Controller → Client |
| `*Result` | 인프라 레이어 조회 결과 | `infra/mybatis/dto/` or `infra/jpa/dto/` | Infrastructure → Application |
| (없음) | JPA 엔티티 | `domain/` | JPA managed, 직접 반환 지양 |

> [!tip] Best Practice
> `*Dto` 단독 suffix는 역할이 모호하므로 지양한다. 신규 클래스는 반드시 위 네 가지 중 하나의 suffix를 선택한다. JPA Projection 인터페이스도 `*Result` suffix를 권장한다.

### 왜 `*Result`인가? (`*Dto` 대비)

1. **레이어 경계 명시**: `Result`는 인프라 레이어의 "조회 결과물"이라는 의도를 전달
2. **변환 의무 신호**: Application 레이어는 `*Result`를 받으면 `*Response`로 변환해야 한다는 것을 이름으로 인지
3. **인프라 기술 독립성**: `MyBatisResult`, `JpaResult`처럼 기술명 없이도 인프라 출력임을 표현

### Mapper CQRS suffix: `*QueryMapper` vs `*CommandMapper`

읽기/쓰기 책임을 Mapper 이름으로 분리한다.

| Suffix | 역할 | 허용 작업 |
|--------|------|----------|
| `*QueryMapper` | 읽기 전용 Mapper | `SELECT` only |
| `*CommandMapper` | 쓰기 전용 Mapper | `INSERT`, `UPDATE`, `DELETE` |

```java
// 읽기 전용 — 이름에서 역할이 드러남
public interface MessageHistoryQueryMapper {
    List<MessageHistoryListResult> findAllByUserId(Long userId);
    MessageHistoryDetailResult findDetailById(Long id);
}

// 쓰기 전용
public interface UmsLogCommandMapper {
    int insert(UmsLog umsLog);
    int updateStatus(Long id, String status);
}
```

## 🛠 Solution

### 실제 리팩토링 예시 (Linkwave 적용)

**Before** — suffix 혼재 상태:
```
infra/mybatis/dto/
  MessageHistoryListDto.java    // 역할 불명확
  StatusCountDto.java
  UserLoginQueryDto.java
application/dto/response/
  MessageHistoryDto.java        // *Dto가 response 폴더에 존재
```

**After** — suffix 규칙 적용:
```
infra/mybatis/dto/
  MessageHistoryListResult.java
  MessageHistoryDetailResult.java
  StatusCountResult.java
  UserLoginResult.java
application/dto/response/
  MessageHistoryResponse.java
```

**rename 후 영향 파일 업데이트 체크리스트**:
1. `import` 문
2. 메서드 반환 타입 / 파라미터 타입
3. MyBatis XML `resultType` 또는 `resultMap`의 `type` 속성
4. 테스트 코드 (`assertInstanceOf`, mock 타입 등)

> [!warning] XML namespace 업데이트 누락 주의
> MyBatis Mapper를 rename할 때 XML 파일의 `namespace` 속성도 반드시 함께 변경해야 한다. 컴파일은 통과하지만 런타임에 `BindingException`이 발생한다.
> ```xml
> <!-- Before -->
> <mapper namespace="com.example.infra.mybatis.mapper.UmsLogMapper">
> <!-- After -->
> <mapper namespace="com.example.infra.mybatis.mapper.UmsLogQueryMapper">
> ```

### 대규모 Rename 리팩토링 순서

```
1. 새 이름으로 파일 생성 (내용 복사)
2. 모든 참조 업데이트 (import, 주입, XML)
3. 구 파일 삭제
4. 컴파일 검증: ./gradlew compileJava
5. grep 검증: grep -r "OldClassName" src/
```

IDE 자동 rename을 사용할 경우에도 5번 grep 검증은 필수 (XML, 문자열 리터럴은 자동 변환 누락 빈번).

## 🔗 Related Concepts

- [[resource/topics/spring/development-principles|개발 원칙 가이드]] — DDD 레이어 아키텍처, DTO 변환 원칙
- [[resource/topics/spring/spring-boot-best-practices|Spring Boot 실무 패턴]] — 팩토리 메서드, Auditing, 전반적인 베스트 프랙티스
- [[resource/topics/spring/역할 기반 분리 CQRS|역할 기반 분리 CQRS]] — Command/Query 분리 패턴, Mapper CQRS
- [[resource/topics/spring/spring-rfc9457-error-handling|RFC 9457 에러 처리]] — 응답 DTO 설계 연관 (에러 응답 표준화)

## 📚 References

- [Spring Boot Reference — Data Access](https://docs.spring.io/spring-boot/docs/current/reference/html/data.html)
- [MyBatis 3 — Mapper XML Files](https://mybatis.org/mybatis-3/sqlmap-xml.html)
- [Martin Fowler — Data Transfer Object](https://martinfowler.com/eaaCatalog/dataTransferObject.html)
