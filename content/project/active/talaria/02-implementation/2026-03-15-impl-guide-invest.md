---
created: 2026-03-15
tags:
  - talaria
  - talaria-invest
  - hexagonal-architecture
  - virtual-threads
  - spring-ai
  - kafka
---

# talaria-invest 구현 가이드

> 원본: `~/Project/talaria/docs/05-impl/talaria-invest.md`

---

## 서비스 역할

배당주 수집 → AI 분석 → Kafka produce. 전체 시스템의 **데이터 흐름 시작점**.

```
Scheduler(08:00) → KIS API 50종목 수집 → Spring AI 분석 → MySQL → Kafka
```

---

## 핵심 설계 결정 (WHY)

### Hexagonal Architecture

| 문제 | 해결 |
|------|------|
| KIS API 직접 의존 → 교체 시 서비스 코드 수정 | `FetchMarketDataPort` 인터페이스 경계 |
| 테스트에서 실제 API 호출 | Mock 어댑터로 대체 |
| LLM 벤더 종속 | `AnalyzeStockPort` 뒤에 Spring AI 어댑터 |

```
Controller → UseCase → Port(interface) ← Adapter(구현체/Mock)
```

### Virtual Threads — 50종목 병렬 수집

- 순차: 50 × 1초(KIS 응답) = **~50초**
- 병렬(Virtual Threads): max(응답) = **~2초**
- `Executors.newVirtualThreadPerTaskExecutor()`로 I/O 대기 시 스레드 반환

**Pitfall**: `@Transactional` 안에서 fork 시 HikariCP 커넥션 고갈
→ API 호출(트랜잭션 밖) + DB 저장(단일 트랜잭션) 분리

### Spring AI — LLM 벤더 종속 제거

`application.yml` 한 줄로 GPT-4o ↔ Claude ↔ Ollama 교체 가능.

**Pitfall**: LLM이 JSON에 마크다운 코드 블록을 감쌀 수 있음
→ `BeanOutputConverter` 또는 블록 제거 전처리 필요

### 부분 실패 허용 (Partial Failure)

LLM 장애 시 해당 종목 skip, 성공 종목만 Kafka publish.

```java
for (Stock stock : stocks) {
    try {
        results.add(analyzeStock(stock.getTicker()));
    } catch (Exception e) {
        log.error("skip | ticker={}", stock.getTicker()); // 계속 진행
    }
}
```

### Kafka produce — `whenComplete()` 필수

```java
kafkaTemplate.send(TOPIC, key, event)
    .whenComplete((result, ex) -> {
        if (ex != null) log.error("publish 실패", ex); // 없으면 실패 모름
    });
```

---

## 구현 단계 체크리스트

- [ ] Step 1: 도메인 모델 (`Stock`, `DividendInfo`, `AnalysisResult`, `Grade`)
- [ ] Step 2: 포트 인터페이스 정의 (`FetchMarketDataPort`, `AnalyzeStockPort` 등)
- [ ] Step 3: JPA 엔티티 & `StockPersistenceAdapter`
- [ ] Step 4: `KisMarketAdapter` — Virtual Threads 병렬 수집
- [ ] Step 5: `SpringAiAnalysisAdapter` — BeanOutputConverter로 JSON 파싱
- [ ] Step 6: `CollectStocksService` — `@Scheduled` + 부분 실패
- [ ] Step 7: `AnalyzeStockService` — 분석 + Kafka publish
- [ ] Step 8: `KafkaStockEventAdapter`
- [ ] Step 9: REST Controller
- [ ] Step 10: 통합 테스트 (EmbeddedKafka)

---

## 포트폴리오 포인트

1. Hexagonal Architecture: 어댑터 1개 교체로 외부 의존성 변경
2. Virtual Threads: WebFlux 없이 고동시성 달성
3. LLM 부분 실패 허용: 배치 안정성 확보
4. Spring AI: 설정 한 줄로 LLM 벤더 교체
