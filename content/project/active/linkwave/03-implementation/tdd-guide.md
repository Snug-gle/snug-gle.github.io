---
created: 2026-02-10
tags:
  - linkwave
  - backend
  - tdd
  - testing
---

> 이 문서는 linkwave-docs의 backend/TDD_GUIDE.md를 요약한 것입니다.

# Backend TDD Development Guide

## 1. TDD Workflow

```
RED (Fail) → GREEN (Pass) → REFACTOR → (반복)
```

1. **RED**: 실패하는 테스트 먼저 작성
2. **GREEN**: 테스트 통과하는 최소 코드 작성
3. **REFACTOR**: 테스트 통과 유지하며 코드 개선

---

## 2. Test Structure

### Test Pyramid
- **Unit** (많이, 빠르게): 단일 클래스/메서드 — JUnit 5 + Mockito
- **Integration** (적당히): 컴포넌트 상호작용 — TestContainers + @SpringBootTest
- **E2E** (적게): 전체 API 플로우 — RestAssured + MockMvc

### 테스트 위치
| 타입 | 디렉토리 |
|------|----------|
| Unit | `src/test/java/.../unit/` |
| Integration | `src/test/java/.../integration/` |
| E2E | `src/test/java/.../e2e/` |

---

## 3. 네이밍 컨벤션

```java
// 패턴: {methodName}_{scenario}_{expectedResult}
void signUp_withValidRequest_returnsCreated()
void signUp_withDuplicateUsername_throwsConflict()

// 한국어도 허용
void 회원가입_성공()
void 중복_아이디로_회원가입시_예외발생()
```

---

## 4. 테스트 패턴

### Given-When-Then
```java
@Test
void signUp_withValidRequest_returnsCreated() {
    // Given: 테스트 데이터 준비
    var request = new SignUpRequest("user", "pass", "name", ...);

    // When: 테스트 대상 실행
    var result = authService.signUp(request);

    // Then: 결과 검증
    assertThat(result.getAccessToken()).isNotNull();
}
```

### Mocking 전략
- **Unit Test**: `@ExtendWith(MockitoExtension.class)` + `@Mock`
- **Integration Test**: `@SpringBootTest` + 실제 DB (TestContainers)
- Service 테스트 시 Repository/Mapper를 Mock

---

## 5. 레이어별 테스트 가이드

### Controller (API Layer)
- MockMvc 사용, Service Mock
- 요청/응답 형식, 상태 코드, 인증 검증

### Service (Application Layer)
- Repository/Mapper Mock
- 비즈니스 로직, 예외 케이스 검증

### Repository (Infrastructure)
- @DataJpaTest 또는 TestContainers
- CRUD 동작, 쿼리 결과 검증

---

## 6. 테스트 실행

```bash
# 전체 테스트
./gradlew test

# 특정 클래스
./gradlew test --tests "*.AuthServiceTest"

# Unit만
./gradlew test -Ptest.type=unit

# 커버리지 리포트
./gradlew jacocoTestReport
```

---

## Related Documents

- [[developer-handbook|Developer Handbook]]
- [[backend-architecture|Backend Architecture]]
