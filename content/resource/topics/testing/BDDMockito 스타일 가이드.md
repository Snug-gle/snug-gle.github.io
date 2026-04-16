---
tags: [testing, mockito, bdd, unit-test, backend]
category: resource
created: 2026-04-16
related: [Mockito 테스트 어노테이션, JUnit5 @Nested 구조화, AssertJ 검증 가이드]
---

# 🔍 BDDMockito 스타일 가이드

## 📌 Situation / Symptom

`Mockito.when().thenReturn()` 스타일로도 테스트는 작성할 수 있지만, Given-When-Then 흐름과 섞이면 코드 가독성이 떨어진다. `BDDMockito`는 Mockito 위에 BDD(행위 주도 개발) 어휘를 입힌 래퍼로, 사전 설정과 사후 검증의 의도를 명확히 드러낸다.

---

## 🔍 Technical Analysis

### given / then 대응 구조

```
given(mock.method()).willReturn(value)   ← 사전 프로그래밍 (실제 실행 아님)
        │
  [테스트 대상 실행]
        │
then(mock).should().method()            ← 사후 검증 (호출됐는지 확인)
```

**핵심 원리**: `given()`은 "이 Mock이 이렇게 응답하도록 설정해라"는 선언이다. 실제 메서드 호출이 아니라 프로그래밍이다. Mock은 기본적으로 `null`(참조 타입), `0`(숫자), `false`(boolean)를 반환하므로, `willReturn()` 없이 null을 그대로 사용하면 NPE가 발생한다.

### given / when / then 전체 패턴

```java
import static org.mockito.BDDMockito.*;

@ExtendWith(MockitoExtension.class)
class KeywordServiceTest {

    @Mock
    private KeywordRepository keywordRepository;

    @InjectMocks
    private KeywordService keywordService;

    @Test
    void addKeyword_IfNotPresent_SaveKeyword() {
        // given
        String keyword = "spam";
        given(keywordRepository.findByWord(keyword))
            .willReturn(Optional.empty());                      // 없으면 empty

        // when
        keywordService.addKeyword(keyword);

        // then
        then(keywordRepository).should().save(any(Keyword.class));  // 저장 호출됨
    }

    @Test
    void addKeyword_IfPresent_ThrowsException() {
        // given
        String keyword = "spam";
        given(keywordRepository.findByWord(keyword))
            .willReturn(Optional.of(new Keyword(keyword)));    // 이미 존재

        // when / then
        assertThatThrownBy(() -> keywordService.addKeyword(keyword))
            .isInstanceOf(DuplicateKeywordException.class);

        then(keywordRepository).should(never()).save(any());   // 저장 안 됨
    }
}
```

### shouldHaveNoInteractions() vs should(never())

| 구분 | 의미 | 사용 시점 |
|------|------|----------|
| `then(mock).shouldHaveNoInteractions()` | Mock의 **어떤 메서드도** 호출되지 않았음 | Mock 전체가 건드려지지 않아야 할 때 |
| `then(mock).should(never()).method()` | **특정 메서드만** 호출되지 않았음 | 다른 메서드는 호출됐지만 이 메서드는 금지될 때 |

**왜 구분하나**: `shouldHaveNoInteractions()`은 의도치 않은 부수 호출도 잡아주는 강한 검증이다. 반면 `should(never())`은 특정 메서드에 집중하는 명시적 검증이다. 예외 발생 케이스처럼 "저장이 실행되면 안 된다"를 표현할 때는 `should(never())`가 더 읽기 좋다.

### BDDMockito vs Mockito 스타일 비교

| 항목 | Mockito 스타일 | BDDMockito 스타일 |
|------|--------------|-----------------|
| 사전 설정 | `when(mock.m()).thenReturn(v)` | `given(mock.m()).willReturn(v)` |
| 예외 설정 | `when(mock.m()).thenThrow(e)` | `given(mock.m()).willThrow(e)` |
| 호출 검증 | `verify(mock).m()` | `then(mock).should().m()` |
| 미호출 검증 | `verify(mock, never()).m()` | `then(mock).should(never()).m()` |
| 전체 미호출 | `verifyNoInteractions(mock)` | `then(mock).shouldHaveNoInteractions()` |

> [!tip] Best Practice
> given-when-then 세 블록을 주석으로 구분하라. `given`은 항상 Mock 설정, `when`은 SUT 실행, `then`은 검증만 담당하도록 역할을 분리하면 테스트 의도가 명확해진다.

---

## 🛠 Solution

### 근본 원인: Mock 기본 반환값의 함정

`Optional.of(any())`처럼 실제 서비스 호출 인자에 Mockito 매처를 사용하면 안 된다.  
`any()`는 `given()` 내부 설정에서만 유효하고, 실제 코드 경로에서 호출되면 `null`을 반환한다.

```java
// 잘못된 사용 — NPE 발생
keywordService.addKeyword(any());   // any()가 null 반환 → 실제 메서드에 null 전달

// 올바른 사용 — 실제 객체 전달
keywordService.addKeyword("spam");
```

> [!warning] 매처는 given() 내부에서만
> `any()`, `anyString()`, `eq()` 등 Mockito 매처는 `given()` 또는 `verify()` 내부의 인자 위치에서만 의미가 있다. 실제 서비스 메서드 호출 인자에 쓰면 null로 평가되어 NPE나 논리 오류를 유발한다.

---

## 🔗 Related Concepts

- [[Mockito 테스트 어노테이션]] — @Mock, @InjectMocks, @ExtendWith 기초
- [[JUnit5 @Nested 구조화]] — @Nested로 given 계층화하기
- [[AssertJ 검증 가이드]] — assertThatThrownBy, assertThatCode 조합

---

## 📚 References

- [BDDMockito Javadoc](https://javadoc.io/doc/org.mockito/mockito-core/latest/org/mockito/BDDMockito.html)
- [Mockito BDD Style](https://site.mockito.org/#bdd)
