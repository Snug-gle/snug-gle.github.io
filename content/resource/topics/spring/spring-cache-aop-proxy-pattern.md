---
tags:
  - spring
  - cache
  - aop
  - proxy
  - caffeine
  - backend
  - performance
category: resource
created: 2026-03-25
related:
  - spring-internals-bean-lifecycle-event
  - spring-event-design-domain-vs-infra
  - spring-transactional-deep-dive
  - spring-event-cqrs-sync-pattern
---

# 🔍 Spring Cache AOP 프록시 패턴과 로컬 캐시 전략

## 📌 Situation / Symptom

메시지 발송의 핵심 경로(hot path)에서 금지 키워드 검사를 수행할 때, 매 호출마다 Redis에 TCP 소켓 통신이 발생했다. 문제는 단순한 Set 포함 여부 확인임에도 네트워크 I/O를 감수해야 한다는 점이었다.

추가로, 같은 서비스 클래스 안에서 `@Cacheable` 메서드를 호출할 경우 캐시가 전혀 동작하지 않는 함정이 있었다.

---

## 🔍 Technical Analysis

### 1. Spring Cache AOP 프록시 자기 호출 문제

Spring의 `@Cacheable`, `@CacheEvict`는 AOP 프록시를 통해 동작한다. 스프링 컨테이너가 Bean을 주입할 때 실제 클래스 인스턴스 대신 프록시 객체를 주입하고, 이 프록시가 메서드 호출 전후로 캐시 인터셉터를 실행한다.

```
외부 호출자 → [AOP 프록시] → 인터셉터 실행 → 실제 메서드
같은 클래스 내 this.method() → 프록시 우회 → 인터셉터 미실행
```

**self-invocation 시나리오**:
```java
// 문제: 같은 클래스 내부에서 호출 → @Cacheable 미동작
@Service
public class ContentFilterService {

    @Cacheable("keywords")
    public Set<String> loadKeywords() { ... }  // 프록시 대상

    public boolean checkContent(String text) {
        return this.loadKeywords()  // this = 실제 인스턴스 (프록시 아님)
                   .stream().anyMatch(text::contains);
    }
}
```

**해결: 책임 분리로 클래스 경계 만들기**

```java
// KeywordCacheRepository: @Cacheable/@CacheEvict만 담당
@Repository
public class KeywordCacheRepository {

    private final KeywordMapper keywordMapper;

    @Cacheable(value = "keywords", key = "'all'")
    public Set<String> loadAll() {
        return new HashSet<>(keywordMapper.findAllKeywords());
    }

    @CacheEvict(value = "keywords", allEntries = true)
    public void evict() {}
}

// ContentFilterKeywordStore: 비교 로직만 담당, 외부에서 Repository 주입
@Component
public class ContentFilterKeywordStore {

    private final KeywordCacheRepository cacheRepository;

    public Optional<String> findViolatingKeyword(String content) {
        return cacheRepository.loadAll()   // 외부 Bean 호출 → 프록시 경유
                              .stream()
                              .filter(content::contains)
                              .findFirst();
    }
}
```

외부 Bean을 통한 호출이므로 프록시가 개입해 `@Cacheable`이 정상 동작한다.

### 2. Redis vs JVM 로컬 캐시 비교

| 항목 | Redis | Caffeine (JVM 로컬) |
|------|-------|---------------------|
| 접근 방식 | TCP 소켓 (네트워크) | JVM 힙 메모리 |
| 레이턴시 | ~1ms (왕복) | ~100ns |
| 멀티 인스턴스 일관성 | 모든 인스턴스 공유 | 인스턴스 간 불일치 가능 |
| 재시작 시 캐시 상태 | 유지 (persistent 설정 시) | 자동 초기화 (항상 DB 기준) |
| 적합한 상황 | 공유 상태, 세션, 분산 환경 | hot path, 읽기 전용, 단일 인스턴스 |

**로컬 캐시가 유리한 조건:**
- 캐시 데이터가 단일 JVM 내에서 완결될 때
- 발송 hot path처럼 레이턴시가 매우 중요할 때
- 데이터 변경 빈도가 낮고 무효화 신호를 명시적으로 줄 수 있을 때

### 3. Caffeine 캐시 특성

```java
@Configuration
@EnableCaching
public class CacheConfig {

    @Bean
    public CacheManager cacheManager() {
        CaffeineCache keywordCache = new CaffeineCache("keywords",
            Caffeine.newBuilder()
                .maximumSize(1)          // 전체 Set을 단일 항목으로 관리
                // expireAfterWrite 설정 없음: 수동 무효화 전용
                // TTL 설정 시 만료 시점에 필터 우회 가능성 존재
                .recordStats()
                .build()
        );
        return new SimpleCacheManager(List.of(keywordCache));
    }
}
```

- **thundering herd 방지**: 캐시 미스 시 단 1개 스레드만 DB 조회, 나머지는 대기 후 결과 공유
- **maximumSize=1**: 금지 키워드 전체를 `Set<String>` 한 항목으로 저장
- **TTL 없음**: 수동 무효화 전용 설계. TTL을 두면 만료 순간 필터가 잠시 우회되는 위험 존재

### 4. @TransactionalEventListener(AFTER_COMMIT)으로 캐시 무효화

캐시 무효화 타이밍이 잘못되면 "유령 키워드" 또는 "삭제된 키워드 잔존" 문제가 생긴다.

```
DB 저장 성공 → 트랜잭션 커밋 → KeywordChangedEvent 발행
                                        ↓ (AFTER_COMMIT)
                              KeywordCacheRefreshHandler.onEvent()
                                        ↓
                              cacheRepository.evict() → 다음 요청 시 DB 재조회
```

```java
@Component
public class KeywordCacheRefreshHandler {

    private final KeywordCacheRepository cacheRepository;

    @TransactionalEventListener(phase = TransactionPhase.AFTER_COMMIT)
    public void onKeywordChanged(KeywordChangedEvent event) {
        cacheRepository.evict();
    }
}
```

| 이벤트 리스너 | 실행 시점 | 롤백 시 |
|--------------|-----------|---------|
| `@EventListener` | 이벤트 발행 즉시 (트랜잭션 내) | 핸들러 실행됨 → 유령 키워드 발생 가능 |
| `@TransactionalEventListener(AFTER_COMMIT)` | 커밋 완료 후 | 핸들러 미실행 → 캐시 오염 없음 |

> [!tip] Best Practice
> 캐시 무효화는 항상 `AFTER_COMMIT`으로 묶어라. DB 롤백 시에도 캐시가 오염되지 않는다. `KeywordChangedEvent`는 빈 record 신호 이벤트로 충분하다 — 키워드 값 자체를 담을 필요가 없다.

---

## 🛠 Solution

**루트 원인**: `@Cacheable` 자기 호출 문제 + Redis의 네트워크 I/O + Redis SADD 버그 (삭제된 키워드 잔존)

**Redis SADD 버그의 구조적 원인:**
```
addKeyword() → Redis SADD ✓
removeKeyword() → Redis SREM ✓ (정상 흐름)
서버 재시작 → Redis 캐시 유지 (DB와 불일치 가능)
DB 롤백 → Redis에 유령 키워드 잔존
```

Caffeine으로 전환하면 재시작 시 JVM 캐시가 자동 초기화되어 구조적으로 해결된다.

**최종 구조:**
```
ContentFilterService
  └─ ContentFilterKeywordStore (비교 로직)
       └─ KeywordCacheRepository (@Cacheable/@CacheEvict)
            └─ KeywordMapper (DB 조회)

KeywordCacheRefreshHandler (@TransactionalEventListener AFTER_COMMIT)
  └─ KeywordCacheRepository.evict()
```

> [!warning] 멀티 인스턴스 주의
> Caffeine은 JVM 로컬 캐시이므로 인스턴스가 2개 이상일 때 한 인스턴스에서 키워드를 추가/삭제해도 다른 인스턴스의 캐시는 즉시 무효화되지 않는다. 향후 인스턴스 확장 시 Redis Pub/Sub로 무효화 신호를 브로드캐스트하는 방식으로 보완할 수 있다.

---

### 5. ApplicationRunner로 캐시 사전 적재 (Cache Warm-Up)

애플리케이션 기동 직후 첫 요청 전에 캐시를 채워두면 cold start로 인한 Cache Miss를 없앨 수 있다.

```java
// ApplicationRunner: ApplicationContext refresh 완료 후 실행 → DB 접근 안전
@Component
@Slf4j
public class KeywordCacheWarmUp implements ApplicationRunner {

    private final KeywordCacheRepository keywordCacheRepository;

    @Override
    public void run(ApplicationArguments args) {
        try {
            Set<String> keywords = keywordCacheRepository.loadAll();
            log.info("캐시 워밍업 완료 — {}개 로드", keywords.size());
        } catch (Exception e) {
            log.error("캐시 워밍업 실패 — 앱 기동 중단", e);
            throw e;  // 필터 없는 서버 운영 방지
        }
    }
}
```

**@PostConstruct 대신 ApplicationRunner를 쓰는 이유**: `@PostConstruct`는 Bean 초기화 단계에서 실행되어 트랜잭션 컨텍스트가 완전히 준비되지 않을 수 있다. `ApplicationRunner`는 컨텍스트 refresh 완료 후 실행되므로 DB 조회가 안전하다.

| | @PostConstruct | ApplicationRunner |
|-|----------------|-------------------|
| 실행 시점 | Bean 초기화 직후 | ApplicationContext refresh 완료 후 |
| 트랜잭션 컨텍스트 | 미보장 | 보장 |
| 적합한 용도 | 간단한 필드 초기화 | DB 조회, 캐시 워밍업 |

**ApplicationRunner vs @Scheduled 실행 순서**: Spring Boot는 두 가지를 컨텍스트 refresh 후 거의 동시에 시작한다. 워밍업 완료 전 스케줄러가 먼저 실행될 수 있으나, Caffeine의 lazy load(캐시 미스 시 자동 DB 조회)로 기능상 문제는 없다. 엄격한 순서가 필요하면 스케줄러에 `initialDelay`를 추가한다.

### 6. TTL 없는 캐시 — 수동 무효화 전용 설계

금지 키워드처럼 "즉시 반영이 중요하고 변경 빈도가 낮은" 데이터에는 TTL을 두지 않는다.

**TTL 설정 시 발생하는 문제:**
```
TTL 만료 → 캐시 비워짐 → 재적재 전 요청 → 필터 동작 안 함 → 정책 위반 메시지 발송 가능
```

**수동 무효화 전용 설계가 올바른 이유:**
- 키워드 변경이 즉시 적용되어야 하는 보안 요구사항
- `@TransactionalEventListener(AFTER_COMMIT)` + `@CacheEvict` 조합으로 커밋 즉시 정확한 무효화 가능
- TTL 만료 창 동안 필터 우회 가능성이 없음

> [!tip] maximumSize(1) 의미
> `maximumSize`는 캐시 엔트리(항목) 수 제한이다. 금지 키워드 전체를 `Set<String>` 하나로 관리하므로 항목이 1개 → `maximumSize(1)`이 올바른 설정이다. `maximumSize(100)`으로 설정하면 100개의 독립 항목을 허용하는 것으로 과도한 설정이다.

---

## 🔗 Related Concepts

- [[spring-transactional-deep-dive|Spring @Transactional 심층 분석]] — self-invocation 함정이 @Transactional에서도 동일하게 적용
- [[spring-event-design-domain-vs-infra|Spring 이벤트 설계: 도메인 이벤트 vs 인프라 이벤트]] — @EventListener vs @TransactionalEventListener 선택 기준
- [[spring-internals-bean-lifecycle-event|Spring Bean 라이프사이클과 이벤트]] — AOP 프록시 생성 원리
- [[spring-transaction-distributed-lock-redis|Spring 트랜잭션, 분산 락, Redis 전략]] — Redis 사용 패턴과 한계

---

## 📚 References

- [Spring Cache Abstraction 공식 문서](https://docs.spring.io/spring-framework/docs/current/reference/html/integration.html#cache)
- [Caffeine Cache GitHub](https://github.com/ben-manes/caffeine)
- [Spring @TransactionalEventListener 공식 문서](https://docs.spring.io/spring-framework/docs/current/javadoc-api/org/springframework/transaction/event/TransactionalEventListener.html)
