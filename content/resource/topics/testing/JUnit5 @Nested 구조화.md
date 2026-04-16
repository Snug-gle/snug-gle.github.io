---
tags: [testing, junit5, unit-test, backend]
category: resource
created: 2026-04-16
related: [BDDMockito 스타일 가이드, Mockito 테스트 어노테이션, AssertJ 검증 가이드]
---

# 🔍 JUnit5 @Nested 구조화

## 📌 Situation / Symptom

테스트 케이스가 많아지면 메서드명만으로는 맥락 파악이 어렵다. `testAddKeyword_success`, `testAddKeyword_duplicate` 같은 평면 구조는 어떤 메서드의 어떤 시나리오인지 한눈에 파악하기 힘들다.

---

## 🔍 Technical Analysis

### @Nested 동작 원리

JUnit 5의 `@Nested`는 외부 테스트 클래스 내에 **중첩 내부 클래스**를 정의해 계층형 트리로 테스트를 구성한다.

```
ContentFilterServiceTest
├── CheckContentTest
│   ├── checkContent_NoViolation_PassThrough
│   └── checkContent_Violation_ThrowsException
└── AddKeywordTest
    ├── addKeyword_IfNotPresent_SaveKeyword
    └── addKeyword_IfPresent_ThrowsException
```

**왜 내부 클래스여야 하나**: Java 문법상 `@Nested`는 반드시 외부 클래스의 멤버 클래스(비static)에 붙여야 한다. 별도 파일로 분리된 클래스에는 사용 불가다. 이 제약 덕분에 외부 클래스의 픽스처(`@Mock`, `@InjectMocks` 필드)를 자연스럽게 공유할 수 있다.

### 구조 예시

```java
@ExtendWith(MockitoExtension.class)
class ContentFilterServiceTest {

    @Mock
    private KeywordRepository keywordRepository;

    @InjectMocks
    private ContentFilterService contentFilterService;

    // 공유 픽스처 — 모든 @Nested에서 사용
    @BeforeEach
    void setUp() {
        // 공통 설정
    }

    @Nested
    class CheckContentTest {

        @Test
        void checkContent_NoViolation_PassThrough() {
            given(keywordRepository.findAll()).willReturn(List.of());
            assertThatCode(() -> contentFilterService.checkContent("hello"))
                .doesNotThrowAnyException();
        }

        @Test
        void checkContent_Violation_ThrowsException() {
            given(keywordRepository.findAll())
                .willReturn(List.of(new Keyword("spam")));
            assertThatThrownBy(() -> contentFilterService.checkContent("buy spam now"))
                .isInstanceOf(ContentViolationException.class);
        }
    }

    @Nested
    class AddKeywordTest {

        @Test
        void addKeyword_IfNotPresent_SaveKeyword() {
            given(keywordRepository.findByWord("spam")).willReturn(Optional.empty());
            contentFilterService.addKeyword("spam");
            then(keywordRepository).should().save(any(Keyword.class));
        }

        @Test
        void addKeyword_IfPresent_ThrowsException() {
            given(keywordRepository.findByWord("spam"))
                .willReturn(Optional.of(new Keyword("spam")));
            assertThatThrownBy(() -> contentFilterService.addKeyword("spam"))
                .isInstanceOf(DuplicateKeywordException.class);
        }
    }
}
```

### @BeforeEach 픽스처 배치 원칙

| 픽스처 범위 | 배치 위치 | 이유 |
|-----------|----------|------|
| 모든 `@Nested` 공통 | 외부 클래스 `@BeforeEach` | 중복 제거, 한 곳에서 관리 |
| 특정 `@Nested`에서만 사용 | 해당 `@Nested` 내 로컬 변수 | 범위를 좁혀 의도 명확화 |
| 단일 테스트 전용 | 테스트 메서드 내 지역변수 | 의존 최소화 |

**왜 이렇게 나누나**: 외부 `@BeforeEach`는 `@Nested` 실행 전에도 호출된다. 특정 `@Nested`에만 필요한 설정을 외부에 두면 불필요한 Mock 설정이 다른 테스트에도 영향을 준다. 의도하지 않은 `given()` 설정은 `UnnecessaryStubbingException`을 유발할 수 있다.

### 언제 @Nested를 쓸까

| 상황 | 권장 |
|------|------|
| 메서드당 테스트 2개 이상 | @Nested 도입 |
| 메서드당 테스트 1개 | 평면 구조로 충분 |
| 상태(성공/실패/경계) 시나리오 구분 | @Nested로 그룹화 |
| 사전 조건이 다른 시나리오 묶기 | @Nested + @BeforeEach 조합 |

> [!tip] Best Practice
> `@Nested` 클래스명은 "무엇을 테스트하는가"를 표현하라. `AddKeywordTest`, `WhenKeywordExists`, `GivenEmptyKeywordList` 모두 유효하다. 팀이 일관된 규칙을 선택하면 된다.

---

## 🛠 Solution

### 단위 테스트에서 PK 처리

`@GeneratedValue`는 DB 실행 시에만 ID를 발급한다. 순수 단위 테스트에서 엔티티 ID가 필요한 경우:

```java
// 방법 1: willReturn으로 픽스처 반환 (권장)
Keyword savedKeyword = new Keyword("spam");
given(keywordRepository.save(any())).willReturn(savedKeyword);

// 방법 2: 리플렉션으로 ID 주입 (ID 검증이 필요한 경우)
Keyword keyword = new Keyword("spam");
ReflectionTestUtils.setField(keyword, "id", 1L);
```

> [!warning] log.warn 테스트 불필요
> 로그 호출은 부작용이 없으므로 테스트하지 않는다. 구현 세부사항에 결합되면 내부 로그 수준이나 메시지 변경만으로 테스트가 깨진다. 비즈니스 결과(예외 발생, DB 저장, 이벤트 발행)만 검증하라.

---

## 🔗 Related Concepts

- [[BDDMockito 스타일 가이드]] — given-when-then 패턴
- [[AssertJ 검증 가이드]] — @Nested 내 검증 표현식
- [[Mockito 테스트 어노테이션]] — @Mock, @InjectMocks 기초

---

## 📚 References

- [JUnit 5 @Nested](https://junit.org/junit5/docs/current/user-guide/#writing-tests-nested)
- [Mockito UnnecessaryStubbingException](https://javadoc.io/doc/org.mockito/mockito-core/latest/org/mockito/exceptions/misusing/UnnecessaryStubbingException.html)
