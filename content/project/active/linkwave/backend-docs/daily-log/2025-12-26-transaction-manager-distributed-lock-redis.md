---
created: 2025-12-26
---
# 2025-12-26: 트랜잭션 관리와 분산 락, Redis 아키텍처

## 학습 목표

이 세션에서 다음 주제를 학습했습니다:

1. ✅ **JpaTransactionManager를 @Primary로 설정하는 이유**
2. ✅ **배치 스케줄러 중복 실행 문제와 분산 락**
3. ✅ **Redis의 역할과 MySQL 보호 원리**
4. ✅ **확장 가능한 시스템 설계 원칙**

---

## 1. JpaTransactionManager가 @Primary여야 하는 이유

### 문제 상황

LinkWave는 **하이브리드 영속성 전략**을 사용합니다:

```
User Domain (users, organizations)      → JPA
Message Domain (ums_msg, ums_log)       → MyBatis
Statistics Domain (ums_stats_daily)     → JPA
```

두 가지 트랜잭션 매니저가 필요:
- `JpaTransactionManager` - JPA 엔티티 관리
- `DataSourceTransactionManager` - MyBatis 쿼리 실행

### @Primary가 필요한 이유

#### 이유 1: JPA Dirty Checking 지원

```java
@Transactional  // 어떤 트랜잭션 매니저?
public void updateUserAndQueryStatistics(String userId) {
    // 1. JPA로 User 수정
    User user = userRepository.findById(userId).orElseThrow();
    user.setName("홍길동");  // 아직 DB에 반영 안됨!

    // 2. MyBatis로 통계 조회 (users 테이블 JOIN)
    StatisticsDto stats = umsMsgMapper.getUserStatistics(userId);
    //                    ↑
    //                    문제: MyBatis가 업데이트 전 데이터를 봄!
}
```

**JpaTransactionManager가 @Primary일 때:**

```java
@Transactional  // JpaTransactionManager가 관리
public void updateUserAndQueryStatistics(String userId) {
    User user = userRepository.findById(userId).orElseThrow();
    user.setName("홍길동");

    // JPA에게 "지금 DB에 반영해!" 명령
    entityManager.flush();  // ✅ JpaTransactionManager만 지원

    // 이제 MyBatis가 최신 데이터를 봄
    StatisticsDto stats = umsMsgMapper.getUserStatistics(userId);
}
```

**DataSourceTransactionManager는 flush()를 모릅니다!**

#### 이유 2: 롤백 범위 보장

```java
@Transactional
public SendResponse sendMessage(...) {
    // 1. MyBatis - 메시지 INSERT
    umsMsgMapper.batchInsert(messages);  // ✅ 성공

    // 2. JPA - 통계 업데이트
    statisticsService.incrementPending(...);  // ✅ 성공

    // 3. JPA - 사용자 업데이트
    user.incrementMessageSentCount();  // ✅ 성공

    // 4. 외부 API 호출
    externalApi.sendNotification();  // ❌ 예외 발생!
}
```

**JpaTransactionManager가 @Primary일 때:**
```
예외 발생!
→ JpaTransactionManager가 롤백 시작
→ 1. JPA 작업 롤백 (user, statistics)
→ 2. MyBatis 작업도 롤백 (같은 DataSource 공유)
→ ✅ 모두 롤백됨!
```

**DataSourceTransactionManager가 @Primary일 때:**
```
예외 발생!
→ DataSourceTransactionManager가 롤백 시작
→ 1. MyBatis 작업 롤백
→ 2. JPA 작업은...? 🤔
→ ❌ JPA의 flush 타이밍 제어 실패 가능
→ ❌ Dirty Checking이 제대로 작동 안할 수 있음
```

### 설정 방법

```java
@Configuration
public class DataSourceConfig {

    @Bean
    @Primary  // ⭐ 핵심!
    public JpaTransactionManager jpaTransactionManager(
            EntityManagerFactory entityManagerFactory) {
        return new JpaTransactionManager(entityManagerFactory);
    }

    // MyBatis도 같은 DataSource를 사용하므로
    // JpaTransactionManager가 전체를 관리할 수 있음
}
```

### 핵심 원리

> **JpaTransactionManager는 DataSource도 관리할 수 있습니다!**
>
> JpaTransactionManager가 @Primary면 MyBatis도 같이 관리합니다.
> 하지만 DataSourceTransactionManager는 JPA의 특수 기능(flush, clear)을 모릅니다.

---

## 2. 배치 스케줄러 중복 실행과 분산 락

### 문제 상황: 서버 확장 시 중복 실행

#### 서버 1대일 때 (문제 없음)

```
[서버 1]
  └─ @Scheduled(cron = "0 5 * * * *")
     └─ aggregateHourlyResults()
        └─ UPDATE ums_stats_daily
           SET success_count = success_count + 100

매 시간 5분마다 1번만 실행 → ✅ 정상
```

#### 서버 2대로 확장 시 (문제 발생!)

```
         [로드 밸런서]
              |
        ┌─────┴─────┐
        |           |
    [서버 1]     [서버 2]
        |           |
        └─────┬─────┘
              |
           [MySQL]
```

**10시 5분이 되면:**

```
10:05:00.000 - [서버 1] @Scheduled 트리거 발동!
10:05:00.000 - [서버 2] @Scheduled 트리거 발동!
                        ↑ 동시 실행!

[서버 1] SELECT ... FROM ums_log (결과: 100건)
[서버 2] SELECT ... FROM ums_log (결과: 100건)

[서버 1] UPDATE ums_stats_daily SET success_count += 100
        → success_count = 100

[서버 2] UPDATE ums_stats_daily SET success_count += 100
        → success_count = 200 (중복!)
```

**결과:**
- 실제 발송: 100건
- 통계: 200건
- ❌ 데이터 정합성 깨짐!

### 원인

> **@Scheduled는 각 서버의 JVM에서 독립적으로 실행됩니다!**

```java
// 서버 1의 JVM
@Scheduled(cron = "0 5 * * * *")  // 10:05에 실행
public void aggregateHourlyResults() { ... }

// 서버 2의 JVM
@Scheduled(cron = "0 5 * * * *")  // 10:05에 실행 (동시!)
public void aggregateHourlyResults() { ... }
```

서버들은 서로를 모릅니다:
- 서버 1: "내가 지금 집계 중이야!" ← 서버 2가 모름
- 서버 2: "나도 집계할게!" ← 동시 실행!

### 해결책: 분산 락 (Distributed Lock)

**개념:**
> "먼저 자물쇠를 잠근 놈만 일할 수 있다!"

#### Redis를 이용한 분산 락

```java
@Scheduled(cron = "0 5 * * * *")
public void aggregateHourlyResults() {

    // 1. Redis에 자물쇠 잠그기 시도
    String lockKey = "stats-aggregation-lock";
    boolean locked = redisLock.tryLock(lockKey, 10, TimeUnit.MINUTES);

    if (!locked) {
        log.info("다른 서버가 이미 집계 중입니다. 건너뜁니다.");
        return;  // 포기
    }

    try {
        // 2. 자물쇠를 잠갔다! 집계 실행
        var results = umsLogQueryMapper.aggregateByHour(...);
        statsDailyRepository.updateResults(...);

    } finally {
        // 3. 일 끝나면 자물쇠 풀기
        redisLock.unlock(lockKey);
    }
}
```

#### 동작 과정

```
10:05:00.000 - [서버 1] tryLock("stats-lock")
10:05:00.001 - [Redis] "stats-lock" = "server-1" (SET NX EX 600)
10:05:00.002 - [서버 1] locked = true ✅ "내가 일한다!"

10:05:00.010 - [서버 2] tryLock("stats-lock")
10:05:00.011 - [Redis] "stats-lock" 이미 있음!
10:05:00.012 - [서버 2] locked = false ❌ "포기!"
10:05:00.013 - [서버 2] return; (종료)

10:05:00.100 - [서버 1] 집계 실행 중...
10:05:10.000 - [서버 1] 집계 완료!
10:05:10.001 - [서버 1] unlock("stats-lock")
10:05:10.002 - [Redis] "stats-lock" 삭제
```

**결과:**
- 서버 1만 집계 실행
- 서버 2는 건너뜀
- ✅ 중복 없음!

#### ShedLock 라이브러리 사용 (권장)

```gradle
// build.gradle
implementation 'net.javacrumbs.shedlock:shedlock-spring:5.10.0'
implementation 'net.javacrumbs.shedlock:shedlock-provider-redis-spring:5.10.0'
```

```java
// 설정
@Configuration
@EnableScheduling
@EnableSchedulerLock(defaultLockAtMostFor = "10m")
public class SchedulerConfig {

    @Bean
    public LockProvider lockProvider(RedisConnectionFactory factory) {
        return new RedisLockProvider(factory, "linkwave");
    }
}

// 사용
@Scheduled(cron = "0 5 * * * *")
@SchedulerLock(
    name = "statsAggregation",
    lockAtMostFor = "10m",   // 최대 10분간 락 유지
    lockAtLeastFor = "1m"    // 최소 1분간 락 유지
)
public void aggregateHourlyResults() {
    // ShedLock이 자동으로 락 관리
    log.info("집계 시작!");
    // ...
}
```

---

## 3. Redis의 역할과 필요성

### Redis란?

**Redis = Remote Dictionary Server**

```
Redis는 "메모리에 데이터를 저장하는 초고속 저장소"
```

### 비유: 편의점 vs 창고

```
[MySQL = 대형 창고]
- 엄청난 양의 물건 보관 (수백만~수억 건)
- 찾는데 시간 걸림 (디스크 읽기)
- 안전하게 보관 (영구 저장)
- 느리지만 확실함

[Redis = 편의점]
- 자주 쓰는 것만 보관 (메모리)
- 초고속으로 찾음 (RAM 속도)
- 전기 나가면 날아감 (휘발성)
- 빠르지만 용량 제한
```

### Redis vs MySQL 비교

| 항목 | Redis | MySQL |
|------|-------|-------|
| **저장 위치** | 메모리 (RAM) | 디스크 (SSD/HDD) |
| **속도** | 초고속 (0.001초) | 보통 (0.01~1초) |
| **데이터 크기** | 작음 (GB 단위) | 큼 (TB 단위) |
| **영구성** | 휘발성 (옵션으로 저장 가능) | 영구 저장 |
| **용도** | 캐시, 락, 세션, 큐 | 메인 데이터 저장 |
| **가격** | 메모리 비쌈 | 디스크 저렴 |

### MySQL을 보호하는 원리: 캐시 쉴드

#### 시나리오: 대시보드 조회 폭주

```
트래픽 급증! 1초에 1000명이 대시보드 조회

❌ Redis 없을 때:
[1000명] → [MySQL]
    ↓
MySQL: "SELECT 복잡한 집계 쿼리" × 1000번
    ↓
CPU 100%, 응답 느려짐
    ↓
다른 기능도 느려짐 (메시지 발송도 영향)
    ↓
MySQL 다운! 💥

✅ Redis 있을 때:
[1000명] → [Redis 캐시]
    ↓
첫 1명만 MySQL 조회 (1번)
나머지 999명은 Redis에서 반환 (0.001초)
    ↓
MySQL은 여유롭게 메시지 발송 처리
    ↓
시스템 안정! ✅
```

### Redis의 4가지 주요 역할

#### 1. 캐시 (Cache) - 가장 많이 사용

```java
@Cacheable(value = "dashboard", key = "#userId", ttl = 60)
public DashboardResponse getDashboard(String userId) {
    // 1번 호출: Redis에 없음 → MySQL 조회 → Redis에 저장
    // 2번 호출: Redis에 있음 → 바로 반환 (MySQL 안 감)
    return statsDailyRepository.findByUserId(userId);
}
```

**효과:**
- 조회 속도: 5초 → 0.001초
- MySQL 부하: 1000 req/s → 16 req/s (1분당 1번)

#### 2. 분산 락 (Distributed Lock)

```java
// 서버가 여러 대일 때 "자물쇠" 역할
@SchedulerLock(name = "statsAggregation")
public void aggregateHourlyResults() {
    // 여러 서버 중 1대만 실행
}
```

#### 3. 세션 저장소

```
서버가 여러 대일 때, 로그인 상태 공유

서버 1에 로그인 → Redis에 세션 저장
다음 요청이 서버 2로 감 → Redis에서 세션 조회 → 로그인 유지!
```

#### 4. 메시지 큐

```
[발송 요청] → [Redis Queue] → [Worker] → [SNAP Agent]

대량 발송 시:
1. 10만 건 요청 → Redis Queue에 넣기
2. Worker들이 하나씩 꺼내서 처리
3. 서버 재시작해도 Queue에 남아있음
```

---

## 4. LinkWave 프로젝트 적용 방안

### 적용처 1: 통계 캐싱

```java
@Service
public class StatisticsService {

    @Cacheable(
        value = "dashboard",
        key = "#userId + ':' + #startDate + ':' + #endDate",
        ttl = 60  // 1분
    )
    public DashboardResponse getDashboard(
            String userId,
            LocalDate startDate,
            LocalDate endDate) {

        return statsDailyRepository
            .findByUserIdAndStatDateBetween(userId, startDate, endDate);
    }
}
```

### 적용처 2: 분산 락 (스케줄러)

```java
@Configuration
@EnableSchedulerLock(defaultLockAtMostFor = "10m")
public class SchedulerConfig {

    @Bean
    public LockProvider lockProvider(RedisConnectionFactory factory) {
        return new RedisLockProvider(factory, "linkwave");
    }
}

@Scheduled(cron = "0 5 * * * *")
@SchedulerLock(name = "statsAggregation")
public void aggregateHourlyResults() {
    // 서버 10대여도 1대만 실행
}
```

### 적용처 3: 발신번호 캐싱

```java
// 발신번호는 자주 안 바뀜 → 캐시 적합
@Cacheable(value = "senderNumbers", key = "#userId", ttl = 3600)
public List<SenderNumber> getSenderNumbers(String userId) {
    return senderNumberRepository.findByUserId(userId);
}

// 발신번호 등록 시 캐시 삭제
@CacheEvict(value = "senderNumbers", key = "#userId")
public void registerSenderNumber(String userId, SenderNumber sn) {
    senderNumberRepository.save(sn);
}
```

### 적용처 4: 중복 발송 방지

```java
public boolean isDuplicate(String phone, String message) {
    String key = "dedup:" + phone + ":" + MD5(message);

    // Redis에 있으면 중복
    if (redisTemplate.hasKey(key)) {
        return true;
    }

    // 없으면 저장 (TTL 10분)
    redisTemplate.opsForValue().set(key, "1", 10, TimeUnit.MINUTES);
    return false;
}
```

---

## 5. 확장 가능한 시스템 설계 원칙

### 원칙 1: 무상태성 (Stateless)

```java
// ❌ 나쁜 예: 서버 메모리에 상태 저장
private static int processedCount = 0;

@Scheduled(cron = "0 5 * * * *")
public void aggregate() {
    processedCount++;  // 서버마다 다른 값!
}

// ✅ 좋은 예: DB/Redis에 상태 저장
@Scheduled(cron = "0 5 * * * *")
public void aggregate() {
    var checkpoint = checkpointRepository.findLastProcessed();
    // 처리
    checkpointRepository.save(newCheckpoint);
}
```

### 원칙 2: 멱등성 (Idempotency)

"같은 작업을 여러 번 실행해도 결과가 같다"

```sql
-- ❌ 나쁜 예: 중복 실행 시 문제
UPDATE ums_stats_daily
SET success_count = success_count + 100;  -- 매번 증가!

-- ✅ 좋은 예: 처리한 것 기록
INSERT INTO ums_stats_processed (client_key, processed_at)
SELECT CLIENT_KEY, NOW()
FROM ums_log
WHERE ...
ON DUPLICATE KEY UPDATE client_key = client_key;  -- 중복 무시

-- 아직 집계 안된 것만 집계
UPDATE ums_stats_daily s
SET success_count = success_count + (
    SELECT COUNT(*)
    FROM ums_log l
    WHERE l.CLIENT_KEY NOT IN (
        SELECT client_key FROM ums_stats_processed
    )
);
```

### 원칙 3: 관찰 가능성 (Observability)

```java
@Scheduled(cron = "0 5 * * * *")
@SchedulerLock(name = "statsAggregation")
public void aggregateHourlyResults() {

    long startTime = System.currentTimeMillis();
    log.info("📊 통계 집계 시작: server={}", serverName);

    try {
        var results = umsLogQueryMapper.aggregateByHour(...);
        int updatedCount = statsDailyRepository.updateResults(...);

        long duration = System.currentTimeMillis() - startTime;

        // 메트릭 기록
        meterRegistry.counter("stats.aggregation.success").increment();
        meterRegistry.timer("stats.aggregation.duration")
            .record(duration, TimeUnit.MILLISECONDS);

        log.info("✅ 통계 집계 완료: count={}, duration={}ms",
                 updatedCount, duration);

    } catch (Exception e) {
        log.error("❌ 통계 집계 실패: {}", e.getMessage(), e);
        alertService.send("통계 집계 실패: " + e.getMessage());
        throw e;
    }
}
```

---

## 6. 서버 확장 시나리오

### 서버 1대 → 10대 확장

```
            [로드 밸런서]
                 |
    ┌────────────┼────────────┐
    |    |    |  |  |    |    |
 [서버1][2][3][4][5][6][7]...[10]
    |    |    |  |  |    |    |
    └────────────┼────────────┘
                 |
              [Redis] ← 분산 락
                 |
              [MySQL]
```

**10:05분 되면:**
```
[서버 1~10] 모두 @Scheduled 트리거!
    ↓
[서버 3] Redis 락 획득 성공! ✅
[서버 1,2,4~10] Redis 락 실패, return ❌
    ↓
[서버 3]만 집계 실행
    ↓
완료 후 락 해제
```

**장점:**
- 서버가 100대가 되어도 똑같이 작동
- Redis만 있으면 OK
- 추가 설정 불필요

### DB도 확장 (Master-Slave)

```
     [서버들]
        |
   [Redis 분산 락]
        |
    [Master DB] ← 쓰기 전용
        |
    Replication
        |
    ┌───┴───┐
 [Slave1][Slave2] ← 읽기 전용
```

---

## 7. 구현 체크리스트

### 필수 구현 (우선순위 높음)

- [ ] **Redis 설치 및 설정**
  - [ ] Docker Compose에 Redis 추가
  - [ ] Spring Boot Redis 의존성 추가
  - [ ] RedisConfig.java 작성

- [ ] **트랜잭션 관리**
  - [ ] JpaTransactionManager @Primary 설정 확인
  - [ ] 하이브리드 트랜잭션 통합 테스트

- [ ] **분산 락 구현**
  - [ ] ShedLock 의존성 추가
  - [ ] SchedulerConfig 설정
  - [ ] StatsAggregationService에 @SchedulerLock 적용

### 권장 구현 (우선순위 중간)

- [ ] **캐싱 전략**
  - [ ] 대시보드 조회 캐싱
  - [ ] 발신번호 캐싱
  - [ ] CacheManager 설정

- [ ] **중복 방지**
  - [ ] 중복 발송 방지 로직 (Redis)
  - [ ] 중복 집계 방지 테이블 (ums_stats_processed)

### 향후 고려 (우선순위 낮음)

- [ ] **모니터링**
  - [ ] Redis 메트릭 수집
  - [ ] 집계 성공/실패 알람
  - [ ] 캐시 히트율 모니터링

- [ ] **고급 기능**
  - [ ] Redis Cluster 설정
  - [ ] 메시지 큐 (대량 발송용)
  - [ ] 세션 저장소 (JWT 대신)

---

## 8. 서버 규모별 권장 사항

| 서버 대수 | 필수 사항 | 권장 사항 |
|----------|----------|----------|
| **1대** | - | - |
| **2~5대** | ✅ 분산 락 (Redis) | 모니터링 |
| **5~20대** | ✅ 분산 락<br>✅ DB Read Replica | ✅ 메트릭 수집<br>✅ 알람 설정 |
| **20대+** | ✅ 분산 락<br>✅ DB 클러스터<br>✅ Redis 클러스터 | ✅ APM 도구<br>✅ 자동 복구<br>✅ 카오스 테스트 |

---

## 9. 핵심 인사이트

### 트랜잭션 관리
- JpaTransactionManager는 DataSource도 관리 가능
- Dirty Checking과 flush는 JPA만의 특수 기능
- 하이브리드 아키텍처에서는 JPA가 주도권을 가져야 함

### 분산 락
- @Scheduled는 각 서버에서 독립적으로 실행
- Redis는 서버 간 조율자 역할
- ShedLock으로 간단히 해결 가능

### Redis
- MySQL의 "방탄복" 역할
- 속도는 Redis, 영구성은 MySQL
- 캐시, 락, 세션, 큐 등 다양한 역할

### 확장성
- 무상태성: 상태는 DB/Redis에 저장
- 멱등성: 중복 실행해도 안전하게
- 관찰 가능성: 로그, 메트릭, 알람

---

## 10. 프로토타입 단계 결정사항 ⭐

### 현재 상황 분석

```
✅ 확정된 환경:
- 개발 서버 존재
- 프로토타입 제작 목표
- 서버 1대 (필요 시 확장 가능)
- Redis 미경험

❌ 불확정 요소:
- 예상 트래픽 미정
- 서버 확장 시점 미정
- 운영 환경 미정
```

### 최종 결정: **Redis 도입 보류** ⏸️

```
이유:
1. 서버 1대 → 분산 락 불필요
2. 프로토타입 단계 → 성능 최적화 우선순위 낮음
3. Redis 미경험 → 학습 및 운영 부담

대안:
✅ 중복 방지: MySQL (DEDUP_HASH + SELECT)
✅ 통계 집계: @Scheduled (서버 1대면 문제없음)
✅ 트랜잭션: JpaTransactionManager @Primary
```

### Redis 도입 시점 기준

| 상황 | Redis 필요성 | 우선 적용 기능 |
|------|-------------|--------------|
| **서버 2대 이상 확장** | ✅ 필수 | 분산 락 (ShedLock) |
| **대시보드 조회 > 1초** | ✅ 권장 | 캐싱 |
| **일 발송 > 10만건** | ✅ 권장 | 중복 방지, 캐싱 |
| **실시간 중복 체크 요구** | ✅ 권장 | Redis TTL |
| **서버 1대, 낮은 트래픽** | ❌ 불필요 | - |

### 프로토타입 단계 구현 계획

#### Phase 1: 핵심 기능 (MySQL만 사용)

```
1. 중복 발송 방지
   - MySQL DEDUP_HASH 기반
   - SELECT + INSERT 패턴
   - 10분 윈도우

2. 메시지 발송
   - ums_msg 직접 활용
   - 즉시/예약/대량 발송

3. 통계 집계
   - ums_stats_daily 테이블
   - @Scheduled 배치 (서버 1대용)

4. 트랜잭션 관리
   - JpaTransactionManager @Primary
   - 하이브리드 영속성 안정화
```

#### Phase 2: Redis 도입 (서버 확장 시)

```
트리거: 서버 2대 이상 확장 결정

작업:
1. Redis 설치 (Docker)
2. ShedLock 적용 (분산 락)
3. 기존 코드 최소 변경
   - @SchedulerLock 어노테이션만 추가
```

#### Phase 3: 성능 최적화 (트래픽 증가 시)

```
트리거: 성능 문제 발생

작업:
1. 대시보드 캐싱
   - @Cacheable 어노테이션
2. 발신번호 캐싱
   - TTL 1시간
3. 중복 체크 Redis 전환
   - TTL 10분
```

---

## 11. MySQL 기반 중복 방지 구현 (프로토타입용)

### 설계 원칙

```
✅ 장점:
- Redis 불필요
- DB 제약조건으로 보장
- 간단한 구현

⚠️ 주의사항:
- SELECT + INSERT 두 번 쿼리
- 트랜잭션 내에서 실행 필수
- 만료 레코드 정리 배치 필요
```

### 구현 방법

#### 1. UmsMsg에 DEDUP_HASH 필드 추가

```java
@Entity
@Table(name = "ums_msg")
public class UmsMsg {

    @Id
    @Column(name = "CLIENT_KEY", length = 40)
    private String clientKey;

    // ... 기존 필드들 ...

    @Column(name = "DEDUP_HASH", length = 32)
    private String dedupHash;  // MD5(phone|message)

    // 인덱스: CREATE INDEX idx_dedup_hash ON ums_msg(DEDUP_HASH, REQ_DATE)
}
```

#### 2. MyBatis Mapper 중복 체크 쿼리

```java
@Mapper
public interface UmsMsgMapper {

    // 중복 체크 (10분 윈도우)
    boolean existsByDedupHashWithinMinutes(
        @Param("dedupHash") String dedupHash,
        @Param("minutes") int minutes
    );

    void batchInsert(@Param("list") List<UmsMsg> messages);
}
```

```xml
<!-- UmsMsgMapper.xml -->
<select id="existsByDedupHashWithinMinutes" resultType="boolean">
    SELECT COUNT(*) > 0
    FROM ums_msg
    WHERE DEDUP_HASH = #{dedupHash}
      AND REQ_DATE >= DATE_SUB(NOW(), INTERVAL #{minutes} MINUTE)
    LIMIT 1
</select>
```

#### 3. MessageService 중복 방지 로직

```java
@Service
@RequiredArgsConstructor
public class MessageService {

    private final UmsMsgMapper umsMsgMapper;
    private final StatisticsService statisticsService;

    @Transactional  // JpaTransactionManager가 관리
    public SendResponse sendMessage(SendRequest request, String userId, String orgId) {

        List<UmsMsg> messages = new ArrayList<>();
        int duplicateCount = 0;

        for (String phone : request.getPhones()) {

            // 중복 해시 생성
            String dedupHash = generateDedupHash(phone, request.getMessage());

            // 중복 체크 (옵션)
            if (request.isCheckDuplicate()) {
                boolean isDuplicate = umsMsgMapper.existsByDedupHashWithinMinutes(
                    dedupHash,
                    request.getDedupWindowMinutes()  // 기본 10분
                );

                if (isDuplicate) {
                    log.warn("중복 발송 차단: phone={}, hash={}", phone, dedupHash);
                    duplicateCount++;
                    continue;  // 건너뛰기
                }
            }

            // 메시지 생성
            UmsMsg msg = UmsMsg.builder()
                .clientKey(generateClientKey(userId))
                .reqCh(request.getChannel())
                .phone(phone)
                .msg(request.getMessage())
                .dedupHash(dedupHash)
                .reqDate(request.isScheduled()
                    ? request.getScheduledAt()
                    : LocalDateTime.now())
                .etc1(userId)
                .etc2(orgId)
                .etc3(generateGroupId())
                .etc4(request.getSendType())
                .build();

            messages.add(msg);
        }

        // 배치 INSERT
        if (!messages.isEmpty()) {
            umsMsgMapper.batchInsert(messages);

            // 통계 업데이트 (같은 트랜잭션)
            statisticsService.incrementPending(
                messages.get(0).getReqDate().toLocalDate(),
                userId,
                orgId,
                request.getChannel(),
                messages.size()
            );
        }

        return SendResponse.builder()
            .totalCount(request.getPhones().size())
            .successCount(messages.size())
            .duplicateCount(duplicateCount)
            .build();
    }

    private String generateDedupHash(String phone, String message) {
        String raw = phone + "|" + message;
        return DigestUtils.md5Hex(raw);  // Apache Commons Codec
    }

    private String generateClientKey(String userId) {
        String timestamp = LocalDateTime.now()
            .format(DateTimeFormatter.ofPattern("yyyyMMddHHmmss"));
        String random = RandomStringUtils.randomAlphanumeric(6).toUpperCase();
        String userPrefix = userId.length() > 5
            ? userId.substring(0, 5)
            : userId;
        return String.format("LW_%s_%s_%s", timestamp, userPrefix, random);
    }

    private String generateGroupId() {
        String date = LocalDateTime.now()
            .format(DateTimeFormatter.ofPattern("yyyyMMdd"));
        String random = UUID.randomUUID().toString().substring(0, 8).toUpperCase();
        return String.format("GRP_%s_%s", date, random);
    }
}
```

#### 4. SendRequest 중복 체크 옵션 추가

```java
@Getter
@Builder
public class SendRequest {

    private String channel;
    private List<String> phones;
    private String message;

    @Builder.Default
    private boolean checkDuplicate = true;  // 중복 체크 ON/OFF

    @Builder.Default
    private int dedupWindowMinutes = 10;    // 중복 윈도우 (기본 10분)

    // ... 기타 필드
}
```

### 성능 비교: MySQL vs Redis

| 항목 | MySQL | Redis |
|------|-------|-------|
| **조회 속도** | 0.01~0.05초 | 0.001초 |
| **적합 트래픽** | < 10만건/일 | > 10만건/일 |
| **운영 복잡도** | 낮음 | 중간 |
| **정합성** | 높음 (영구 저장) | 중간 (휘발성) |
| **비용** | 낮음 (기존 DB) | 중간 (메모리) |

### 프로토타입에서 충분한 이유

```
일 발송량 < 10만건:
- 중복 체크 빈도: 낮음
- MySQL SELECT 속도: 0.01초 (충분히 빠름)
- 추가 인프라 불필요

서버 1대:
- 동시 요청 처리량: 낮음
- 경쟁 조건 발생 확률: 매우 낮음
- 트랜잭션만으로 충분히 안전
```

---

## 12. Redis 도입 시 마이그레이션 가이드

### 중복 방지 Redis 전환 (나중에)

```java
@Service
public class MessageService {

    private final RedisTemplate<String, String> redisTemplate;

    @Transactional
    public SendResponse sendMessage(SendRequest request, ...) {

        for (String phone : request.getPhones()) {

            if (request.isCheckDuplicate()) {

                // ✅ Redis 방식 (변경 후)
                String dedupKey = "dedup:" + phone + ":" + MD5(request.getMessage());
                Boolean isNew = redisTemplate.opsForValue()
                    .setIfAbsent(dedupKey, "1", 10, TimeUnit.MINUTES);

                if (!isNew) {
                    log.warn("중복 발송 차단 (Redis): phone={}", phone);
                    continue;
                }

                // ❌ MySQL 방식 (변경 전)
                // boolean isDuplicate = umsMsgMapper.existsByDedupHash(...);
            }

            // 메시지 생성 및 INSERT (변경 없음)
            // ...
        }
    }
}
```

### 변경 사항 최소화

```
변경 필요:
✅ build.gradle: Redis 의존성 추가
✅ RedisConfig.java: 설정 추가
✅ MessageService: 중복 체크 로직만 변경

변경 불필요:
✅ UmsMsg 엔티티
✅ MyBatis Mapper
✅ 통계 로직
✅ API 인터페이스
```

---

## 13. 다음 단계

### 즉시 작업 (프로토타입용)

1. **트랜잭션 설정 확인**
   - [ ] JpaTransactionManager @Primary 확인
   - [ ] 통합 테스트 작성 (롤백 검증)

2. **중복 방지 구현 (MySQL)**
   - [ ] UmsMsg에 dedupHash 필드 추가
   - [ ] UmsMsgMapper 중복 체크 쿼리 추가
   - [ ] MessageService 로직 구현
   - [ ] 테스트 작성

3. **통계 시스템 구현**
   - [ ] ums_stats_daily 테이블 생성
   - [ ] StatsAggregationService 작성
   - [ ] @Scheduled 배치 구현 (서버 1대용)

### 보류 (서버 확장 시)

- ⏸️ Redis 설치
- ⏸️ ShedLock 분산 락
- ⏸️ 캐싱 시스템

---

## 14. 참고 자료

### 프로토타입 단계
- LinkWave CLAUDE.md - 하이브리드 영속성 전략
- LinkWave 06-UMS-MESSAGE-FLOW.md - 메시지 발송 구현
- LinkWave 07-STATISTICS-ANALYTICS.md - 통계 시스템

### Redis 도입 시 (나중에)
- [Spring Data Redis 공식 문서](https://spring.io/projects/spring-data-redis)
- [ShedLock GitHub](https://github.com/lukas-krecan/ShedLock)
- [Redis 공식 문서](https://redis.io/documentation)
