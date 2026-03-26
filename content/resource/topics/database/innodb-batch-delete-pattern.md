---
tags:
  - database
  - mysql
  - innodb
  - transaction
  - batch
  - pagination
  - backend
  - performance
category: resource
created: 2026-03-25
related:
  - cursor-pagination-linkwave
  - 잠금
  - 교착 상태
---

# 🔍 InnoDB 배치 삭제 패턴: 락 경합과 페이징 버그 해결

## 📌 Situation / Symptom

대량 레코드를 배치로 삭제할 때 두 가지 문제가 발생했다.

1. **락 경합**: 전체 루프를 하나의 `@Transactional`로 감싸면 InnoDB 레코드 락이 루프 완료까지 유지되어, 동시에 실행 중인 발송 API와 락 경합이 발생한다.
2. **OFFSET 페이징 버그**: 삭제 후 데이터가 앞으로 당겨지면서 일부 레코드를 건너뛰는 문제가 발생한다.

---

## 🔍 Technical Analysis

### 1. InnoDB 트랜잭션 락 보유 시간

InnoDB는 트랜잭션이 활성화된 동안 수정/삭제된 레코드에 대해 **레코드 락**을 유지한다. 트랜잭션이 길수록 락 보유 시간이 길어진다.

```
단일 @Transactional로 10,000건 삭제
├── 1,000번째 삭제: 락 유지 중...
├── 5,000번째 삭제: 락 유지 중...
└── 10,000번째 삭제 완료 → 커밋 → 락 해제
    ↑ 이 시간 동안 발송 API가 같은 테이블 접근 시 락 대기
```

**청크 단위 커밋으로 락 보유 시간 단축:**

```java
// 문제 패턴: 전체를 하나의 트랜잭션으로
@Transactional
public void archiveAll(List<Long> ids) {
    for (Long id : ids) {
        repository.deleteById(id);  // 락이 루프 내내 누적
    }
}

// 권장 패턴: 청크 단위 커밋
public void archiveInChunks(List<Long> ids, int chunkSize) {
    Lists.partition(ids, chunkSize).forEach(chunk -> {
        archiveChunk(chunk);  // 각 청크마다 트랜잭션 분리
    });
}

@Transactional
public void archiveChunk(List<Long> chunk) {
    repository.deleteAllByIdInBatch(chunk);
    // 메서드 종료 시 커밋 → 락 즉시 해제
}
```

| 방식 | 락 보유 시간 | 발송 API 영향 |
|------|-------------|--------------|
| 단일 @Transactional (전체) | 전체 처리 시간 | 높음 |
| 청크 단위 커밋 | 청크 처리 시간만 | 낮음 |

### 2. OFFSET 페이징의 배치 삭제 버그

OFFSET 페이징은 삭제 작업과 함께 사용하면 레코드를 건너뛰는 버그가 발생한다.

```
초기 상태: [A, B, C, D, E, F]
1페이지 (offset=0, size=3) 조회: [A, B, C]
→ A, B, C 삭제
→ 남은 데이터: [D, E, F]

2페이지 (offset=3, size=3) 조회: [] (빈 결과)
→ D, E, F가 앞으로 당겨졌으나 offset=3부터 조회하여 건너뜀
```

**해결: 항상 첫 페이지(offset=0) 재조회**

```java
// 문제 패턴: offset을 증가시키면서 조회
int page = 0;
while (true) {
    List<Entity> batch = repository.findAll(
        PageRequest.of(page++, CHUNK_SIZE)  // offset 증가 → 버그
    );
    if (batch.isEmpty()) break;
    repository.deleteAllInBatch(batch);
}

// 권장 패턴: 삭제 후 항상 첫 페이지 재조회
while (true) {
    List<Entity> batch = repository.findAll(
        PageRequest.of(0, CHUNK_SIZE)  // 항상 offset=0
    );
    if (batch.isEmpty()) break;
    repository.deleteAllInBatch(batch);
}
```

> [!tip] Best Practice
> 배치 삭제 루프에서는 항상 `PageRequest.of(0, chunkSize)`로 첫 페이지를 재조회하라. 삭제 후 남은 데이터가 앞으로 당겨지기 때문에 offset을 증가시키면 반드시 일부 레코드를 건너뛴다.

### 3. deleteAllByIdInBatch vs deleteAll

| 메서드 | 동작 | SQL |
|--------|------|-----|
| `deleteAll(list)` | 각 엔티티마다 SELECT → DELETE | N번의 DELETE |
| `deleteAllByIdInBatch(ids)` | 단일 DELETE IN | 1번의 `DELETE WHERE id IN (...)` |

배치 삭제에는 `deleteAllByIdInBatch()`를 사용해야 DB 왕복 횟수를 줄일 수 있다.

---

## 🛠 Solution

**루트 원인 요약:**

1. 단일 트랜잭션 → InnoDB 레코드 락이 전체 배치 처리 시간만큼 유지
2. OFFSET 페이징 + 삭제 조합 → 삭제 후 데이터 이동으로 레코드 건너뜀

**권장 패턴 (청크 단위 + 첫 페이지 재조회):**

```java
public void batchArchive(int chunkSize) {
    while (true) {
        // 항상 offset=0 재조회
        List<Long> ids = repository.findOldRecordIds(
            PageRequest.of(0, chunkSize)
        );
        if (ids.isEmpty()) break;

        archiveChunk(ids);  // 청크 단위 트랜잭션 → 커밋 후 락 해제
    }
}

@Transactional
public void archiveChunk(List<Long> ids) {
    repository.deleteAllByIdInBatch(ids);
}
```

> [!warning] 주의: @Transactional 전파
> 청크 메서드를 같은 클래스에서 호출하면 self-invocation 문제로 `@Transactional`이 동작하지 않는다. 반드시 별도 Bean으로 분리하거나 `self` 주입 방식을 사용해야 한다. Spring AOP 프록시 원리는 [[spring-cache-aop-proxy-pattern|Spring Cache AOP 프록시 패턴]] 참고.

---

## 🔗 Related Concepts

- [[잠금|InnoDB Lock 메커니즘]] — 레코드 락, 갭 락, 넥스트 키 락
- [[교착 상태|Deadlock 이해와 해결]] — 락 경합이 심화되면 교착 상태로 이어짐
- [[cursor-pagination-linkwave|커서 기반 페이징 구현기]] — 배치 처리에서도 커서 방식으로 전환하면 OFFSET 버그 원천 차단
- [[spring-cache-aop-proxy-pattern|Spring Cache AOP 프록시 패턴]] — self-invocation 문제 (배치 청크 분리와 동일한 프록시 원리)

---

## 📚 References

- [Spring Data JPA - deleteAllByIdInBatch](https://docs.spring.io/spring-data/jpa/docs/current/api/org/springframework/data/jpa/repository/JpaRepository.html)
- [MySQL InnoDB Locking](https://dev.mysql.com/doc/refman/8.0/en/innodb-locking.html)
