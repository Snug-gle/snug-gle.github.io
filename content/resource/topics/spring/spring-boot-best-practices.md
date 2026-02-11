---
created: 2026-02-04
up: "[[resource/topics/spring/_Spring MOC]]"
tags: [spring, spring-boot, best-practices, testing]
---
# Spring Boot 실무 패턴 학습 노트

> kuke-board 프로젝트를 진행하며 학습한 내용 정리

---

## 1. 팩토리 메서드 네이밍 컨벤션

### 일반적인 컨벤션

| 메서드명 | 용도 | 예시 |
|---------|------|------|
| `of` | 파라미터를 조합해 객체 생성 | `Article.of(id, title, ...)` |
| `from` | 다른 객체로부터 변환 | `ArticleResponse.from(article)` |
| `create` | 비즈니스 의미를 강조한 생성 | `Article.create(...)` |

### Entity에서의 사용

```java
// 도메인 의미가 명확한 create
public static Article create(Long articleId, String title, String content,
                              Long boardId, Long writerId) {
    Article article = new Article();
    article.articleId = articleId;
    article.title = title;
    article.content = content;
    article.boardId = boardId;
    article.writerId = writerId;
    return article;
}
```

### DTO/Response에서의 사용

```java
// Entity -> DTO 변환에는 from이 적합
public record ArticleResponse(
    Long articleId,
    String title,
    String content,
    Long boardId,
    Long writerId,
    LocalDateTime createAt,
    LocalDateTime modifiedAt
) {
    public static ArticleResponse from(Article article) {
        return new ArticleResponse(
            article.getArticleId(),
            article.getTitle(),
            article.getContent(),
            article.getBoardId(),
            article.getWriterId(),
            article.getCreateAt(),
            article.getModifiedAt()
        );
    }
}
```

### 정리

- **Entity**: `create` 또는 `of` (도메인 행위 강조 시 `create` 권장)
- **DTO → Entity**: `toEntity()` 인스턴스 메서드
- **Entity → DTO**: `from(Entity)` 정적 메서드
- **Value Object**: `of`가 자연스러움 (예: `Money.of(1000)`)

---

## 2. JPA Auditing - 생성/수정 시간 자동화

### 수동 설정의 문제점

```java
// 매번 수동으로 시간 설정 - 실수 가능성
article.createAt = LocalDateTime.now();
article.modifiedAt = article.createAt;
```

### Auditing으로 자동화

**1. Entity 설정:**

```java
@Entity
@Table(name = "article")
@Getter
@NoArgsConstructor(access = AccessLevel.PROTECTED)
@EntityListeners(AuditingEntityListener.class)  // 추가
public class Article {

    @Id
    private Long articleId;
    private String title;
    private String content;
    private Long boardId;
    private Long writerId;

    @CreatedDate
    @Column(updatable = false)
    private LocalDateTime createAt;

    @LastModifiedDate
    private LocalDateTime modifiedAt;
}
```

**2. Auditing 활성화:**

```java
@SpringBootApplication
@EnableJpaAuditing
public class ArticleApplication {
    public static void main(String[] args) {
        SpringApplication.run(ArticleApplication.class, args);
    }
}
```

### 필요한 import

```java
import org.springframework.data.annotation.CreatedDate;
import org.springframework.data.annotation.LastModifiedDate;
import org.springframework.data.jpa.domain.support.AuditingEntityListener;
import jakarta.persistence.EntityListeners;
import jakarta.persistence.Column;
```

---

## 3. Snowflake ID - 분산 환경에서의 고유 ID 생성

### 문제점: 직접 인스턴스 생성

```java
// 문제가 있는 코드
private final Snowflake snowflake = new Snowflake();
```

**문제:**
- Snowflake는 `timestamp + workerId + sequence`로 구성
- 분산 환경에서 각 인스턴스가 **고유한 workerId**를 가져야 함
- `new Snowflake()`로 하면 workerId 충돌 가능

### 권장 방식: Spring Bean으로 관리

**1. Config 클래스 (common 모듈):**

```java
@Configuration
public class SnowflakeConfig {

    @Bean
    public Snowflake snowflake(
            @Value("${snowflake.worker-id:0}") long workerId,
            @Value("${snowflake.datacenter-id:0}") long datacenterId) {
        return new Snowflake(workerId, datacenterId);
    }
}
```

**2. application.yml:**

```yaml
snowflake:
  worker-id: ${SNOWFLAKE_WORKER_ID:1}
  datacenter-id: ${SNOWFLAKE_DATACENTER_ID:1}
```

**3. Service에서 주입받아 사용:**

```java
@Service
@RequiredArgsConstructor
public class ArticleService {

    private final Snowflake snowflake;  // Bean 주입
    private final ArticleRepository articleRepository;
}
```

### 배포 환경별 설정

| 환경 | 설정 방법 |
|------|----------|
| 개발 | application.yml에 고정값 |
| 운영 | 환경변수로 인스턴스별 고유값 주입 |

```bash
# 컨테이너/인스턴스별로 다른 값
SNOWFLAKE_WORKER_ID=1 java -jar article.jar
SNOWFLAKE_WORKER_ID=2 java -jar article.jar
```

---

## 4. 멀티 모듈 설정 관리

### 프로젝트 구조

```
kuke-board/
├── common/                    # 공통 유틸리티
└── service/
    ├── article/              # 각각 독립적인 Spring Boot 앱
    ├── comment/
    ├── like/
    └── view/
```

### 설정 관리 옵션

**옵션 1: 각 서비스별 개별 설정**

```yaml
# service/article/src/main/resources/application.yml
snowflake:
  worker-id: 1

# service/comment/src/main/resources/application.yml
snowflake:
  worker-id: 2
```

**옵션 2: 환경변수 주입 (권장)**

```yaml
# 모든 서비스 공통
snowflake:
  worker-id: ${SNOWFLAKE_WORKER_ID:0}
  datacenter-id: ${SNOWFLAKE_DATACENTER_ID:0}
```

**옵션 3: common 모듈에 기본 설정 + import**

```yaml
# service/article/application.yml
spring:
  config:
    import: classpath:application-common.yml
```

---

## 5. 테스트 전략

### 테스트 피라미드

```
        /\
       /  \     E2E (소수)
      /----\
     /      \   Integration (중간)
    /--------\
   /          \ Unit (다수)
  --------------
```

### 테스트 종류별 비교

| 종류 | 애너테이션 | 속도 | 용도 |
|------|-----------|------|------|
| Unit | `@ExtendWith(MockitoExtension.class)` | 매우 빠름 | Service 로직 |
| Slice | `@WebMvcTest`, `@DataJpaTest` | 빠름 | Controller, Repository |
| Integration | `@SpringBootTest` | 느림 | 전체 흐름 |

### Controller 슬라이스 테스트 (권장)

```java
@WebMvcTest(ArticleController.class)
class ArticleControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @MockitoBean
    private ArticleService articleService;

    @Test
    void createArticle() throws Exception {
        // given
        given(articleService.create(any())).willReturn(
            new ArticleResponse(1L, "title", "content", 1L, 1L,
                LocalDateTime.now(), LocalDateTime.now())
        );

        // when & then
        mockMvc.perform(post("/v1/articles")
                .contentType(MediaType.APPLICATION_JSON)
                .content("""
                    {"title":"title","content":"content","boardId":1,"writerId":1}
                    """))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.title").value("title"));
    }
}
```

### Service 단위 테스트

```java
@ExtendWith(MockitoExtension.class)
class ArticleServiceTest {

    @Mock
    private ArticleRepository articleRepository;

    @InjectMocks
    private ArticleService articleService;

    @Test
    void create_shouldReturnArticleResponse() {
        // given
        Article article = Article.create(1L, "title", "content", 1L, 1L);
        given(articleRepository.save(any())).willReturn(article);

        // when
        ArticleResponse response = articleService.create(
            new ArticleCreateRequest("title", "content", 1L, 1L)
        );

        // then
        assertThat(response.title()).isEqualTo("title");
        verify(articleRepository).save(any());
    }
}
```

### 통합 테스트 (WebTestClient 사용)

```java
@SpringBootTest(webEnvironment = WebEnvironment.RANDOM_PORT)
class ArticleIntegrationTest {

    @Autowired
    private WebTestClient webTestClient;

    @Test
    void createArticle() {
        webTestClient.post()
            .uri("/v1/articles")
            .contentType(MediaType.APPLICATION_JSON)
            .bodyValue(new ArticleCreateRequest("title", "content", 1L, 1L))
            .exchange()
            .expectStatus().isOk()
            .expectBody()
            .jsonPath("$.title").isEqualTo("title");
    }
}
```

**WebTestClient 사용 시 필요한 의존성:**

```kotlin
// build.gradle.kts
testImplementation("org.springframework.boot:spring-boot-starter-webflux")
```

---

## 6. Mockito 애너테이션 비교

### `@Mock` vs `@InjectMocks` vs `@MockitoBean`

| | `@Mock` | `@InjectMocks` | `@MockitoBean` |
|---|---|---|---|
| **출처** | Mockito | Mockito | Spring Boot |
| **Spring 필요** | X | X | O |
| **용도** | Mock 객체 생성 | Mock 주입받을 대상 | Spring Bean을 Mock으로 교체 |

### 사용 예시

**순수 Mockito (Spring 컨텍스트 없음):**

```java
@ExtendWith(MockitoExtension.class)
class ArticleServiceTest {

    @Mock
    private ArticleRepository articleRepository;

    @InjectMocks
    private ArticleService articleService;
}
```

**Spring 컨텍스트 내에서:**

```java
@WebMvcTest(ArticleController.class)
class ArticleControllerTest {

    @MockitoBean  // Spring Bean을 Mock으로 교체
    private ArticleService articleService;
}
```

### 참고: @MockBean → @MockitoBean

Spring Boot 3.4부터 `@MockBean`이 deprecated되고 `@MockitoBean`으로 변경됨.

```java
// 이전 (deprecated)
@MockBean
private ArticleService articleService;

// 현재 (Spring Boot 3.4+)
@MockitoBean
private ArticleService articleService;
```

---

## 7. 테스트 선택 가이드

| 테스트 대상 | 권장 방식 | 이유 |
|------------|----------|------|
| Service 로직 | `@Mock` + `@InjectMocks` | 빠름, DB 불필요 |
| Controller 엔드포인트 | `@WebMvcTest` + `MockMvc` | 빠름, Service Mock |
| Repository 쿼리 | `@DataJpaTest` | H2로 빠르게 검증 |
| 전체 통합 | `@SpringBootTest` | 필요할 때만 (느림) |

---

## 참고 자료

- [Spring Data JPA Auditing](https://docs.spring.io/spring-data/jpa/docs/current/reference/html/#auditing)
- [Spring Boot Testing](https://docs.spring.io/spring-boot/docs/current/reference/html/features.html#features.testing)
- [Mockito Documentation](https://javadoc.io/doc/org.mockito/mockito-core/latest/org/mockito/Mockito.html)
