---
tags: [spring, troubleshooting, redis, transaction, distributed-lock, jpa, mybatis, scheduler]
category: spring
created: 2025-12-26
status: complete
description: 하이브리드 영속성 환경에서의 트랜잭션 관리와 배치 스케줄러 중복 실행 방지를 위한 분산 락, Redis 도입 전략 분석
---

# Spring 트랜잭션과 분산 락: 하이브리드 영속성 및 확장성 고려한 Redis 전략

> JpaTransactionManager의 @Primary 설정 이유, 다중 서버 환경의 배치 스케줄러 중복 실행 문제 해결을 위한 분산 락, 그리고 Redis의 역할 및 적용 방안에 대한 심층 분석

---

## 개요
이 문서는 Spring 기반 애플리케이션에서 하이브리드 영속성(JPA와 MyBatis 혼용) 환경에서의 트랜잭션 관리 문제와 다중 서버 환경에서 발생하는 배치 스케줄러의 중복 실행 문제를 분석하고 해결 방안을 제시합니다. 특히 JpaTransactionManager를 @Primary로 설정해야 하는 이유와 Redis를 활용한 분산 락 메커니즘을 상세히 설명합니다. 또한 Redis의 다양한 역할과 MySQL 보호 원리를 이해하고, LinkWave 프로젝트의 확장 가능한 시스템 설계를 위한 Redis 도입 전략 및 프로토타입 단계에서의 실용적인 접근 방안을 모색합니다.

## 문제 상황

### 하이브리드 영속성 환경의 트랜잭션 관리 문제

LinkWave 프로젝트는 사용자(User), 조직(Organization) 도메인에 JPA를, 메시지(Message) 도메인에 MyBatis를, 통계(Statistics) 도메인에 다시 JPA를 사용하는 **하이브리드 영속성 전략**을 채택하고 있습니다. 이로 인해 `JpaTransactionManager`와 `DataSourceTransactionManager`라는 두 가지 트랜잭션 매니저가 필요하며, @Transactional 어노테이션 사용 시 특정 트랜잭션 매니저가 우선적으로 선택되지 않으면 예기치 않은 문제가 발생할 수 있습니다.

### 배치 스케줄러 중복 실행 문제

단일 서버 환경에서는 문제가 없던 배치 스케줄러(`@Scheduled`)가 서버가 2대 이상으로 확장될 경우, 각 서버의 JVM에서 독립적으로 실행되어 동일한 작업이 동시에 여러 번 수행되는 **중복 실행 문제**가 발생합니다. 특히 통계 집계와 같이 데이터의 정합성이 중요한 작업에서 이러한 중복 실행은 심각한 데이터 불일치를 야기합니다.

## 원인 분석

### JpaTransactionManager @Primary의 필요성

하이브리드 영속성 환경에서 `JpaTransactionManager`가 @Primary로 지정되지 않으면, Spring은 `DataSourceTransactionManager`를 기본으로 선택할 가능성이 있습니다.
`DataSourceTransactionManager`는 JDBC 기반의 트랜잭션만 관리하므로 JPA의 핵심 기능인 **Dirty Checking을 통한 자동 변경 감지 및 `EntityManager.flush()` 호출 시점 제어**를 알지 못합니다. 이로 인해 JPA로 변경된 데이터가 트랜잭션 도중 MyBatis 쿼리에 반영되지 않거나, 예외 발생 시 JPA 작업이 제대로 롤백되지 않아 데이터 정합성이 깨질 위험이 있습니다. 반면 `JpaTransactionManager`는 내부적으로 DataSource를 관리할 수 있으므로, @Primary로 설정될 경우 JPA와 MyBatis 작업을 모두 통합하여 관리할 수 있게 됩니다.

### 배치 스케줄러 중복 실행의 메커니즘

`@Scheduled` 어노테이션은 Spring Boot 애플리케이션이 실행되는 **각 JVM 인스턴스에서 독립적으로 동작**합니다. 즉, 2대의 서버에 동일한 애플리케이션이 배포되어 있다면, 두 서버 모두에서 지정된 시간에 스케줄링된 메서드가 실행됩니다. 서버들은 서로의 존재를 인지하지 못하며, 이는 분산 환경에서 동일한 배치 작업이 여러 번 실행되어 데이터 중복 처리, 리소스 경합, 데이터 불일치 등의 문제를 일으키는 직접적인 원인이 됩니다.

## 해결 과정

### JpaTransactionManager를 @Primary로 설정

두 트랜잭션 매니저 중 `JpaTransactionManager`를 `@Primary` 어노테이션을 사용하여 우선적으로 선택되도록 설정합니다.
이를 통해 JPA의 Dirty Checking과 flush 메커니즘이 보장되며, MyBatis 작업 또한 같은 DataSource를 공유하므로 `JpaTransactionManager`의 관리 하에 통합적인 트랜잭션 처리가 가능해집니다.

```java
@Configuration
public class DataSourceConfig {

    @Bean
    @Primary  // ⭐ 핵심!
    public JpaTransactionManager jpaTransactionManager(
            EntityManagerFactory entityManagerFactory) {
        return new JpaTransactionManager(entityManagerFactory);
    }
}
```

### Redis 기반 분산 락 도입

배치 스케줄러의 중복 실행 문제를 해결하기 위해 **분산 락(Distributed Lock)** 메커니즘을 도입합니다. Redis를 분산 락 저장소로 활용하며, `ShedLock`과 같은 라이브러리를 사용하면 `@Scheduled` 메서드에 간단한 어노테이션 추가만으로 분산 락을 적용할 수 있습니다.

**동작 방식:**
1.  스케줄링된 메서드가 실행될 때, 먼저 Redis에 특정 키(락)를 획득하려고 시도합니다.
2.  가장 먼저 락을 획득한 서버만이 실제 배치 작업을 수행합니다.
3.  락 획득에 실패한 다른 서버들은 현재 스케줄러 실행을 건너뛰거나 대기합니다.
4.  작업이 완료되면 락을 해제합니다.
이 과정을 통해 다중 서버 환경에서도 특정 배치 작업이 **정확히 한 번만** 실행되도록 보장합니다.

```java
// build.gradle (의존성 추가)
implementation 'net.javacrumbs.shedlock:shedlock-spring:5.10.0'
implementation 'net.javacrumbs.shedlock:shedlock-provider-redis-spring:5.10.0'

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
    // ShedLock이 자동으로 락 관리 → 10대 서버 중 1대만 실행!
    // ... 실제 배치 작업 로직 ...
}
```

## 설계 결정과 이유 (왜 이 방식을 선택했는가)

### JpaTransactionManager를 @Primary로 선정한 이유

JpaTransactionManager를 @Primary로 설정한 주된 이유는 **JPA의 Dirty Checking과 EntityManager의 flush 메커니즘을 통해 데이터 정합성을 일관되게 유지**하고, 하이브리드 영속성 환경에서 **트랜잭션 롤백 시 모든 영속성 컨텍스트의 변경 사항이 예측 가능하게 처리**되도록 하기 위함입니다. DataSourceTransactionManager는 이러한 JPA의 특수 기능을 알지 못해 부분적인 롤백이나 데이터 불일치를 야기할 수 있기 때문입니다. JpaTransactionManager는 DataSource 기반의 트랜잭션도 관리할 수 있으므로, MyBatis 작업까지 통합 관리하는 것이 더 안전하고 효율적입니다.

### Redis를 분산 락 및 캐시로 활용하는 이유

Redis는 인메모리(In-Memory) 데이터 저장소로서 초고속 읽기/쓰기 성능을 제공합니다. 이는 MySQL과 같은 디스크 기반 데이터베이스의 부하를 줄이고 애플리케이션의 응답 속도를 향상시키는 데 매우 효과적입니다.
**MySQL 보호 (Cache Shield)**: 대량의 동일한 조회 요청이 발생할 경우, Redis 캐싱을 통해 MySQL로 가는 부하를 대폭 줄여 MySQL 서버의 안정성을 확보합니다.
**분산 락**: Redis의 `SET NX EX` 명령어는 분산 환경에서 원자적인 락 획득 및 만료 처리를 가능하게 하여, 다중 서버 환경에서 배치 스케줄러의 중복 실행과 같은 동시성 문제를 안전하게 해결할 수 있는 강력한 수단이 됩니다. 이는 확장 가능한 시스템의 필수 요소입니다.

### 확장 가능한 시스템 설계 원칙 고려

1.  **무상태성(Stateless)**: 서버 인스턴스 자체에 상태를 저장하지 않고, 모든 상태 관리를 DB나 Redis와 같은 외부 저장소로 위임하여 서버 확장을 용이하게 합니다.
2.  **멱등성(Idempotency)**: 동일한 요청이 여러 번 발생하더라도 시스템의 상태가 최종적으로 동일하게 유지되도록 설계하여, 분산 시스템의 재시도 로직이나 중복 메시지 처리 시 데이터 정합성을 보장합니다.
3.  **관찰 가능성(Observability)**: 시스템의 상태, 성능, 오류 등을 실시간으로 모니터링하고 분석할 수 있도록 상세한 로그, 메트릭, 알람 시스템을 구축하여 문제 발생 시 신속한 탐지 및 대응이 가능하도록 합니다.

## 배운 점

### 트랜잭션 관리의 미묘한 차이

`JpaTransactionManager`와 `DataSourceTransactionManager`가 단순히 DB 작업을 관리하는 것을 넘어, 사용하는 영속성 기술의 특수 기능(예: JPA의 Dirty Checking)까지 영향을 미친다는 것을 이해했습니다. 특히 하이브리드 영속성 환경에서는 주도권을 가진 트랜잭션 매니저 선정이 시스템 전체의 정합성과 안정성에 지대한 영향을 미친다는 점을 깨달았습니다.

### 분산 시스템에서 동시성 제어의 중요성

`@Scheduled`와 같은 간단한 어노테이션이 분산 환경에서 얼마나 큰 문제를 야기할 수 있는지 직접 경험했습니다. 서버 확장이 빈번한 현대 시스템에서는 단순히 단일 서버 환경에서의 동작만 고려할 것이 아니라, `ShedLock`과 같은 분산 락 메커니즘을 통해 동시성 문제를 선제적으로 해결해야 함을 배웠습니다.

### Redis의 전략적 활용 가치

Redis는 단순한 캐시 서버를 넘어 분산 시스템의 다양한 문제를 해결하는 만능 도구임을 확인했습니다. 특히 MySQL의 부하를 경감시키는 캐시 쉴드 역할, 배치 스케줄러의 중복 실행을 막는 분산 락, 그리고 세션 저장소, 메시지 큐 등 다양한 활용 사례를 통해 확장 가능한 아키텍처 구축의 핵심 구성 요소임을 이해했습니다.

### 프로토타입 개발의 실용적 결정

모든 최신 기술이나 완벽한 아키텍처를 초기 단계부터 도입할 필요는 없다는 실용적인 접근법을 배웠습니다. 현재 시스템 규모(서버 1대)와 프로토타입 목표를 고려하여 Redis 도입을 보류하고 MySQL 기반의 중복 방지 로직으로 대체하는 결정은, 개발 시간과 리소스 효율성을 극대화하면서도 핵심 기능을 안정적으로 구현할 수 있는 합리적인 선택이었습니다. 추후 시스템이 확장될 때 Redis를 점진적으로 도입하는 마이그레이션 전략을 수립함으로써 불필요한 초기 복잡성을 피할 수 있습니다.

## References

- [Spring Data Redis 공식 문서](https://spring.io/projects/spring-data-redis)
- [ShedLock GitHub](https://github.com/lukas-krecan/ShedLock)
- [Redis 공식 문서](https://redis.io/documentation)
- LinkWave CLAUDE.md - 하이브리드 영속성 전략
- LinkWave 06-UMS-MESSAGE-FLOW.md - 메시지 발송 구현
- LinkWave 07-STATISTICS-ANALYTICS.md - 통계 시스템