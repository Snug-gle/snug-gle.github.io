---
tags:
  - project
  - rally-point
  - learning
  - msa
  - event-driven
  - distributed-systems
  - kafka
category: learning
status: active
created: 2025-11-16
updated: 2025-11-16
---

# 📚 MSA 및 이벤트 주도 아키텍처 학습 가이드

## 학습 목표

이 가이드는 RallyPoint 프로젝트를 개발하면서 MSA(Microservices Architecture)와 이벤트 주도 아키텍처(Event-Driven Architecture)를 실전에서 적용하고 학습하기 위한 로드맵입니다.

### 최종 학습 목표
1. MSA의 핵심 패턴을 이해하고 실제 프로젝트에 적용
2. 이벤트 주도 아키텍처의 장단점 파악 및 Kafka 활용
3. 분산 시스템의 복잡성 관리 및 문제 해결 능력 향상
4. 대규모 시스템 설계 및 운영 역량 습득

---

## 📖 학습 단계별 가이드

### Phase 1: MSA 기초 (Week 1-2)

#### 핵심 개념
1. **Microservices란?**
   - 단일 책임 원칙 (Single Responsibility)
   - 느슨한 결합 (Loose Coupling)
   - 독립적인 배포 (Independent Deployment)
   - 기술 다양성 (Polyglot)

2. **Monolithic vs MSA**
   - 모놀리식 아키텍처의 한계
   - MSA의 장점과 단점
   - 언제 MSA를 선택해야 하는가?

3. **Domain-Driven Design (DDD)**
   - Bounded Context
   - Aggregate
   - Entity vs Value Object
   - Domain Service vs Application Service

#### 실습 과제
- [ ] User Service를 DDD 관점에서 재설계
- [ ] Bounded Context 다이어그램 작성
- [ ] User, Court, Match 도메인 간 경계 정의

#### 학습 리소스

**필독 서적**:
- 📚 **"Building Microservices" (Sam Newman)** ⭐⭐⭐⭐⭐
  - 1장: Microservices (30분)
  - 2장: The Evolutionary Architect (20분)
  - 3장: How to Model Services (45분)
  - 4장: Integration (60분)

- 📚 **"Domain-Driven Design Distilled" (Vaughn Vernon)**
  - 1장: DDD for Me (15분)
  - 2장: Strategic Design with Bounded Contexts (30분)

**온라인 리소스**:
- 📝 [Martin Fowler - Microservices](https://martinfowler.com/articles/microservices.html)
- 📝 [Microsoft - Microservices Architecture](https://learn.microsoft.com/en-us/azure/architecture/guide/architecture-styles/microservices)
- 🎥 [YouTube: "Microservices Explained in 5 Minutes"](https://www.youtube.com/watch?v=lL_j7ilk7rc)

**실습 예제**:
```java
// DDD: Aggregate Root 예제
@Entity
public class User extends AggregateRoot {
    @EmbeddedId
    private UserId id;

    @Embedded
    private Email email;

    @OneToMany(cascade = CascadeType.ALL)
    private List<UserProfile> profiles;

    // 도메인 로직: 비즈니스 규칙 포함
    public void updateProfile(UserProfile newProfile) {
        validateProfile(newProfile);
        this.profiles.add(newProfile);
        // 도메인 이벤트 발행
        registerEvent(new ProfileUpdatedEvent(this.id, newProfile));
    }
}
```

#### 주차별 체크리스트
- [ ] MSA의 5가지 핵심 특징 설명 가능
- [ ] DDD의 Bounded Context 개념 이해
- [ ] User Service를 도메인 중심으로 재설계
- [ ] 서비스 간 통신 방법 3가지 나열 가능

---

### Phase 2: 분산 시스템 기초 (Week 3-4)

#### 핵심 개념

1. **CAP 정리**
   - Consistency (일관성)
   - Availability (가용성)
   - Partition Tolerance (분할 내성)
   - 실무 적용: AP vs CP 선택

2. **데이터 일관성**
   - Strong Consistency
   - Eventual Consistency
   - 분산 트랜잭션의 문제점

3. **분산 락 (Distributed Lock)**
   - Redis를 이용한 분산 락
   - Redisson 활용
   - 락 타임아웃 및 재시도 전략

4. **캐싱 전략**
   - Cache-Aside Pattern
   - Write-Through / Write-Behind
   - 캐시 무효화 전략

#### 실습 과제
- [ ] Redis 분산 락으로 동시 예약 방지 구현
- [ ] 예약 현황 캐싱 전략 구현
- [ ] 캐시 무효화 시나리오 테스트

#### 학습 리소스

**필독 서적**:
- 📚 **"Designing Data-Intensive Applications" (Martin Kleppmann)** ⭐⭐⭐⭐⭐
  - 5장: Replication (60분)
  - 7장: Transactions (90분)
  - 8장: The Trouble with Distributed Systems (60분)

**온라인 리소스**:
- 📝 [Redis Distributed Locks](https://redis.io/docs/manual/patterns/distributed-locks/)
- 📝 [Redisson Documentation](https://github.com/redisson/redisson/wiki/8.-Distributed-locks-and-synchronizers)
- 🎥 [YouTube: "CAP Theorem Simplified"](https://www.youtube.com/watch?v=k-Yaq8AHlFA)

**실습 예제**:
```kotlin
// Redisson 분산 락 예제
@Service
class ReservationService(
    private val redissonClient: RedissonClient
) {
    fun createReservation(request: ReservationRequest): Reservation {
        val lockKey = "lock:reservation:${request.date}:${request.timeSlot}:${request.courtId}"
        val lock = redissonClient.getLock(lockKey)

        try {
            // 10초 동안 락 획득 시도, 30초 후 자동 해제
            if (lock.tryLock(10, 30, TimeUnit.SECONDS)) {
                // 중복 예약 체크
                checkDuplicateReservation(request)
                // 예약 생성
                return saveReservation(request)
            } else {
                throw ReservationLockException("Unable to acquire lock")
            }
        } finally {
            if (lock.isHeldByCurrentThread) {
                lock.unlock()
            }
        }
    }
}
```

#### 주차별 체크리스트
- [ ] CAP 정리 설명 가능
- [ ] Eventual Consistency 개념 이해
- [ ] 분산 락 구현 및 테스트 완료
- [ ] Redis 캐싱 전략 3가지 이상 적용

---

### Phase 3: 이벤트 주도 아키텍처 (Week 5-6)

#### 핵심 개념

1. **Event-Driven Architecture (EDA)**
   - 이벤트란 무엇인가?
   - Event Notification vs Event-Carried State Transfer
   - Event Sourcing vs Event Streaming
   - CQRS (Command Query Responsibility Segregation)

2. **Apache Kafka 아키텍처**
   - Producer, Consumer, Broker
   - Topic, Partition, Offset
   - Consumer Group
   - Replication Factor

3. **메시지 신뢰성**
   - At-most-once
   - At-least-once
   - Exactly-once
   - Idempotent Producer/Consumer

4. **이벤트 스키마 설계**
   - 이벤트 명명 규칙
   - 버전 관리
   - 스키마 진화 (Schema Evolution)

#### 실습 과제
- [ ] Kafka Producer 구현 (예약 이벤트 발행)
- [ ] Kafka Consumer 구현 (알림 서비스)
- [ ] Idempotent Consumer 구현
- [ ] Dead Letter Queue 설정

#### 학습 리소스

**필독 서적**:
- 📚 **"Kafka: The Definitive Guide"** ⭐⭐⭐⭐⭐
  - 1장: Meet Kafka (20분)
  - 2장: Installing Kafka (30분)
  - 3장: Kafka Producers (60분)
  - 4장: Kafka Consumers (60분)
  - 6장: Reliable Data Delivery (90분)

- 📚 **"Designing Event-Driven Systems" (Ben Stopford)**
  - 1-3장: Event-Driven Basics
  - 4장: Event Collaboration

**온라인 리소스**:
- 📝 [Confluent Kafka Tutorial](https://kafka.apache.org/quickstart)
- 📝 [Martin Fowler - Event-Driven Architecture](https://martinfowler.com/articles/201701-event-driven.html)
- 📝 [AWS - Event-Driven Architecture](https://aws.amazon.com/event-driven-architecture/)
- 🎥 [Udemy: "Apache Kafka Series - Learn Apache Kafka for Beginners"](https://www.udemy.com/course/apache-kafka/)

**실습 예제**:
```kotlin
// Kafka Producer 예제
@Service
class ReservationEventPublisher(
    private val kafkaTemplate: KafkaTemplate<String, ReservationEvent>
) {
    private val logger = LoggerFactory.getLogger(javaClass)

    fun publishReservationCreated(reservation: Reservation) {
        val event = ReservationEvent(
            type = "RESERVATION_CREATED",
            reservationId = reservation.id,
            userId = reservation.userId,
            courtId = reservation.courtId,
            date = reservation.date,
            timeSlot = reservation.timeSlot,
            timestamp = Instant.now()
        )

        kafkaTemplate.send("reservation-events", reservation.id, event)
            .addCallback(
                { logger.info("Event published: $event") },
                { logger.error("Failed to publish event: $event", it) }
            )
    }
}

// Kafka Consumer 예제 (Idempotent)
@Service
class NotificationEventConsumer(
    private val notificationService: NotificationService,
    private val processedEventRepository: ProcessedEventRepository
) {
    @KafkaListener(topics = ["reservation-events"], groupId = "notification-group")
    fun consume(event: ReservationEvent) {
        // Idempotency: 중복 처리 방지
        if (processedEventRepository.exists(event.eventId)) {
            logger.warn("Event already processed: ${event.eventId}")
            return
        }

        try {
            when (event.type) {
                "RESERVATION_CREATED" -> notificationService.sendReservationConfirmation(event)
                "RESERVATION_CANCELLED" -> notificationService.sendCancellationNotice(event)
            }

            // 처리 완료 기록
            processedEventRepository.save(ProcessedEvent(event.eventId, Instant.now()))
        } catch (e: Exception) {
            logger.error("Failed to process event: ${event.eventId}", e)
            throw e // 재시도를 위해 예외 던지기
        }
    }
}
```

#### 주차별 체크리스트
- [ ] Kafka Producer/Consumer 구현 완료
- [ ] At-least-once 처리 보장 구현
- [ ] Idempotent Consumer 패턴 적용
- [ ] 이벤트 스키마 설계 및 버전 관리
- [ ] DLQ 설정 및 테스트

---

### Phase 4: 고급 패턴 (Week 7-10)

#### 핵심 개념

1. **Saga Pattern**
   - Choreography vs Orchestration
   - 보상 트랜잭션 (Compensating Transaction)
   - 실패 처리 전략

2. **Circuit Breaker Pattern**
   - Open, Half-Open, Closed 상태
   - Resilience4j 활용
   - Fallback 전략

3. **API Gateway Pattern**
   - 라우팅 및 필터링
   - 인증/인가 통합
   - Rate Limiting
   - Request Aggregation

4. **Service Mesh**
   - Sidecar Proxy
   - Traffic Management
   - Observability

#### 실습 과제
- [ ] Saga Pattern 구현 (예약 → 결제 → 알림)
- [ ] Circuit Breaker 적용 (Resilience4j)
- [ ] API Gateway 구현 (Spring Cloud Gateway)
- [ ] 분산 추적 설정 (Spring Cloud Sleuth)

#### 학습 리소스

**필독 서적**:
- 📚 **"Microservices Patterns" (Chris Richardson)** ⭐⭐⭐⭐⭐
  - 4장: Managing Transactions with Sagas (90분)
  - 3장: Interprocess Communication (60분)
  - 8장: External API Patterns (45분)

- 📚 **"Release It!" (Michael Nygard)**
  - Circuit Breaker Pattern
  - Bulkhead Pattern
  - Timeout Pattern

**온라인 리소스**:
- 📝 [Microsoft - Saga Pattern](https://learn.microsoft.com/en-us/azure/architecture/reference-architectures/saga/saga)
- 📝 [Resilience4j Documentation](https://resilience4j.readme.io/)
- 📝 [Spring Cloud Gateway](https://spring.io/projects/spring-cloud-gateway)
- 🎥 [YouTube: "Saga Pattern Explained"](https://www.youtube.com/watch?v=xDuwrtwYHu8)

**실습 예제**:
```kotlin
// Circuit Breaker 예제
@Service
class UserServiceClient(
    @Qualifier("userServiceFeignClient") private val feignClient: UserFeignClient
) {
    @CircuitBreaker(name = "userService", fallbackMethod = "getUserFallback")
    @Retry(name = "userService")
    fun getUser(userId: String): User {
        return feignClient.getUser(userId)
    }

    private fun getUserFallback(userId: String, ex: Exception): User {
        logger.warn("Fallback triggered for userId: $userId", ex)
        // 캐시된 데이터 반환 또는 기본값
        return User(id = userId, name = "Unknown")
    }
}

// Saga Orchestrator 예제
@Service
class ReservationSagaOrchestrator(
    private val reservationService: ReservationService,
    private val paymentService: PaymentService,
    private val notificationService: NotificationService
) {
    fun createReservationWithPayment(request: ReservationRequest): ReservationResult {
        var reservation: Reservation? = null
        var payment: Payment? = null

        try {
            // Step 1: 예약 생성
            reservation = reservationService.createReservation(request)

            // Step 2: 결제 처리
            payment = paymentService.processPayment(PaymentRequest(
                reservationId = reservation.id,
                amount = request.amount
            ))

            // Step 3: 알림 전송
            notificationService.sendReservationConfirmation(reservation)

            return ReservationResult.success(reservation, payment)

        } catch (e: Exception) {
            // 보상 트랜잭션 (Compensating Transaction)
            if (payment != null) {
                paymentService.refund(payment.id)
            }
            if (reservation != null) {
                reservationService.cancelReservation(reservation.id)
            }

            throw ReservationSagaException("Saga failed", e)
        }
    }
}
```

#### 주차별 체크리스트
- [ ] Saga Pattern 이해 및 구현
- [ ] Circuit Breaker 패턴 적용
- [ ] API Gateway 구축 완료
- [ ] 분산 추적 설정 및 테스트
- [ ] Fallback 전략 구현

---

### Phase 5: 운영 및 모니터링 (Week 11-12)

#### 핵심 개념

1. **Observability**
   - Metrics (메트릭)
   - Logs (로그)
   - Traces (추적)
   - 3 Pillars of Observability

2. **Logging 전략**
   - 중앙 집중식 로깅
   - 구조화된 로그 (Structured Logging)
   - 로그 레벨 관리
   - ELK Stack (Elasticsearch, Logstash, Kibana)

3. **Metrics & Monitoring**
   - Spring Boot Actuator
   - Prometheus
   - Grafana
   - 주요 메트릭: Latency, Throughput, Error Rate

4. **Distributed Tracing**
   - Spring Cloud Sleuth
   - Zipkin
   - Jaeger
   - Trace Context Propagation

#### 실습 과제
- [ ] ELK Stack 구축 및 중앙 로깅 설정
- [ ] Prometheus + Grafana 대시보드 구성
- [ ] Zipkin 분산 추적 설정
- [ ] 커스텀 메트릭 구현

#### 학습 리소스

**필독 서적**:
- 📚 **"Distributed Systems Observability" (Cindy Sridharan)**
- 📚 **"Site Reliability Engineering" (Google)**
  - 4장: Service Level Objectives

**온라인 리소스**:
- 📝 [Prometheus Documentation](https://prometheus.io/docs/introduction/overview/)
- 📝 [ELK Stack Tutorial](https://www.elastic.co/guide/index.html)
- 📝 [OpenTelemetry](https://opentelemetry.io/docs/)
- 🎥 [YouTube: "Observability in Microservices"](https://www.youtube.com/watch?v=W8ximJjl4Pk)

**실습 예제**:
```yaml
# Prometheus 설정
management:
  endpoints:
    web:
      exposure:
        include: health,info,metrics,prometheus
  metrics:
    export:
      prometheus:
        enabled: true
    tags:
      application: ${spring.application.name}
```

```kotlin
// Custom Metrics 예제
@Service
class ReservationMetricsService(
    private val meterRegistry: MeterRegistry
) {
    private val reservationCounter = meterRegistry.counter("reservations.created")
    private val reservationTimer = meterRegistry.timer("reservations.processing.time")

    fun recordReservationCreated() {
        reservationCounter.increment()
    }

    fun <T> recordProcessingTime(block: () -> T): T {
        return reservationTimer.recordCallable(block)!!
    }
}
```

#### 주차별 체크리스트
- [ ] ELK Stack 구축 완료
- [ ] Prometheus + Grafana 대시보드 생성
- [ ] 분산 추적 동작 확인
- [ ] 주요 메트릭 수집 및 알림 설정

---

## 🎯 실전 시나리오별 학습

### 시나리오 1: 동시 예약 문제 해결
**상황**: 같은 시간대에 여러 사용자가 동시에 예약 시도

**학습 목표**:
- 분산 락의 필요성 이해
- Redis를 이용한 분산 락 구현
- 락 타임아웃 및 재시도 전략

**구현 단계**:
1. 문제 재현 (동시성 테스트)
2. Redis 분산 락 적용
3. 성능 테스트 및 최적화
4. 실패 시나리오 테스트

### 시나리오 2: 예약 → 알림 이벤트 처리
**상황**: 예약이 생성되면 자동으로 이메일/SMS 알림 전송

**학습 목표**:
- 이벤트 주도 아키텍처의 이점
- Kafka Producer/Consumer 구현
- 이벤트 처리 실패 대응

**구현 단계**:
1. 예약 이벤트 스키마 설계
2. Kafka Producer 구현 (Court Service)
3. Kafka Consumer 구현 (Notification Service)
4. Idempotent 처리 및 DLQ 설정

### 시나리오 3: 서비스 장애 대응
**상황**: User Service가 다운되었을 때 Court Service는 어떻게 동작해야 하는가?

**학습 목표**:
- Circuit Breaker 패턴
- Fallback 전략
- Resilience4j 활용

**구현 단계**:
1. User Service 다운 시뮬레이션
2. Circuit Breaker 적용
3. Fallback 로직 구현 (캐시된 데이터 활용)
4. 복구 시나리오 테스트

### 시나리오 4: 대량 예약 취소 배치 작업
**상황**: 만료된 예약을 자동으로 취소하고 대기자에게 알림

**학습 목표**:
- Spring Batch 기본
- 이벤트 기반 배치 처리
- 대용량 데이터 처리

**구현 단계**:
1. Spring Batch Job 설계
2. 만료 예약 조회 및 취소 로직
3. Kafka 이벤트 발행
4. 스케줄링 설정

---

## 📊 학습 평가 체크리스트

### MSA 기초
- [ ] MSA의 장단점을 3가지씩 설명할 수 있다
- [ ] Bounded Context를 식별하고 다이어그램으로 그릴 수 있다
- [ ] 서비스 간 통신 방법 3가지 이상 설명 가능
- [ ] API Gateway의 역할을 이해하고 있다

### 분산 시스템
- [ ] CAP 정리를 이해하고 실무 사례를 설명할 수 있다
- [ ] Eventual Consistency의 개념과 적용 시나리오를 안다
- [ ] 분산 락을 구현하고 테스트할 수 있다
- [ ] 캐싱 전략 3가지 이상 적용할 수 있다

### 이벤트 주도 아키텍처
- [ ] Kafka의 핵심 개념 5가지 설명 가능
- [ ] Producer/Consumer를 직접 구현할 수 있다
- [ ] At-least-once 처리를 보장할 수 있다
- [ ] Idempotent Consumer를 구현할 수 있다
- [ ] 이벤트 스키마를 설계하고 버전 관리할 수 있다

### 고급 패턴
- [ ] Saga Pattern의 2가지 방식을 이해하고 있다
- [ ] Circuit Breaker를 적용하고 Fallback을 구현할 수 있다
- [ ] API Gateway를 구축하고 라우팅/필터를 설정할 수 있다
- [ ] 분산 추적을 설정하고 트레이스를 분석할 수 있다

### 운영 및 모니터링
- [ ] Observability의 3가지 기둥을 설명할 수 있다
- [ ] ELK Stack을 구축하고 중앙 로깅을 설정할 수 있다
- [ ] Prometheus + Grafana 대시보드를 만들 수 있다
- [ ] 커스텀 메트릭을 정의하고 수집할 수 있다

---

## 🚀 추천 학습 순서

### 우선순위 1 (필수)
1. **"Building Microservices" (Sam Newman)** - 1-4장
2. **"Kafka: The Definitive Guide"** - 1-4장
3. **"Designing Data-Intensive Applications" (Martin Kleppmann)** - 5, 7, 8장

### 우선순위 2 (권장)
4. **"Microservices Patterns" (Chris Richardson)** - 3, 4장
5. **"Release It!" (Michael Nygard)** - Circuit Breaker, Bulkhead
6. ELK Stack 및 Prometheus 공식 문서

### 우선순위 3 (심화)
7. **"Site Reliability Engineering" (Google)**
8. **Service Mesh (Istio) 튜토리얼**
9. **Event Sourcing & CQRS 패턴 학습**

---

## 💡 학습 팁

### 1. 이론과 실습의 균형
- 이론 40% : 실습 60%
- 각 개념을 배운 후 반드시 코드로 구현
- 실패 시나리오를 직접 테스트해보기

### 2. 문서화의 중요성
- 학습한 내용을 자신의 언어로 정리
- 실습 코드에 주석으로 설명 추가
- 주차별 회고 작성

### 3. 커뮤니티 활용
- Stack Overflow에서 질문/답변 찾기
- GitHub의 오픈소스 프로젝트 참고
- 기술 블로그 및 컨퍼런스 영상 시청

### 4. 점진적 개선
- 완벽을 추구하지 말고 작은 단위로 완성
- 리팩토링을 두려워하지 않기
- 코드 리뷰를 통한 피드백

---

## 📝 학습 일지 템플릿

```markdown
## Week X 학습 회고

### 학습한 개념
- 개념 1: ...
- 개념 2: ...

### 구현한 기능
- [ ] 기능 1
- [ ] 기능 2

### 어려웠던 점
- 문제: ...
- 해결 방법: ...

### 새롭게 깨달은 점
- ...

### 다음 주 목표
- [ ] ...
```

---

**작성일**: 2025-11-16
**작성자**: Claude Code
**상태**: v1.0
