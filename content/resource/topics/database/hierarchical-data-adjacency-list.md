---
tags:
  - database
  - mysql
  - data-modeling
  - tree-structure
  - jpa
  - linkwave
category: resource
created: 2026-04-21
related:
  - cursor-pagination-linkwave
  - innodb-batch-delete-pattern
---

# 🔍 계층형 데이터 모델링 — 4가지 패턴과 Adjacency List 실전 적용

> 조직도, 카테고리 트리, 댓글 스레드처럼 "부모-자식" 관계를 RDB에 저장할 때 선택 가능한 4가지 패턴을 비교하고, LinkWave Group 도메인에 Adjacency List를 적용한 경험을 정리합니다.

---

## 📌 계층형 데이터란?

노드(Node)와 간선(Edge)으로 이루어진 트리 구조를 관계형 데이터베이스에 저장하는 문제입니다. 대표적인 사례:

- **조직도**: 회사 → 사업부 → 팀 → 개인
- **카테고리**: 전자제품 → 노트북 → 게이밍 노트북
- **댓글 스레드**: 원댓글 → 대댓글 → 대대댓글
- **파일 시스템**: 디렉토리 트리

RDB는 본질적으로 집합(set) 기반이라 계층 구조를 자연스럽게 표현하지 못합니다. 어떤 패턴을 선택하느냐에 따라 쓰기 복잡도, 읽기 복잡도, 스키마 복잡성이 크게 달라집니다.

---

## 🔍 4가지 패턴 비교

| 패턴 | 핵심 아이디어 | 쓰기 복잡도 | 전체 트리 조회 | 직접 부모/자식 조회 | 스키마 복잡성 | 적합한 케이스 |
|------|------------|------------|-------------|------------------|-------------|-------------|
| **Adjacency List** | `parent_id` FK 하나 | O(1) | WITH RECURSIVE 필요 | O(1) | 낮음 | 깊이 예측 불가, 쓰기 빈번 |
| **Path Enumeration** | 경로 문자열 저장 (`/1/3/7/`) | O(1) | LIKE `/1/%` | 파싱 필요 | 낮음 | 읽기 위주, 깊이 제한 있음 |
| **Closure Table** | 조상-자손 쌍을 별도 테이블에 전부 기록 | O(깊이) | 단순 JOIN | O(1) | 높음 | 읽기 빈번, 다양한 집계 |
| **Nested Set** | left/right 값으로 범위 인코딩 | O(n) | 단순 범위 쿼리 | O(1) | 중간 | 읽기 전용에 가까운 정적 트리 |

### 패턴별 상세

#### Adjacency List
```sql
CREATE TABLE groups (
    id          BIGINT PRIMARY KEY AUTO_INCREMENT,
    name        VARCHAR(100) NOT NULL,
    parent_id   BIGINT NULL,
    FOREIGN KEY (parent_id) REFERENCES groups(id)
);
```
- 장점: 스키마 단순, INSERT/UPDATE O(1), 직접 부모/자식 조회 직관적
- 단점: 트리 전체 조회 시 `WITH RECURSIVE` 필요 (MySQL 8.0+), 애플리케이션 레벨 재귀 조회 유혹

#### Path Enumeration
```sql
ALTER TABLE groups ADD COLUMN path VARCHAR(500);  -- '/1/3/7/'
```
- 장점: 하위 트리 조회가 `LIKE '/1/%'`로 단순
- 단점: 경로 파싱 로직 필요, 노드 이동 시 모든 하위 경로 업데이트

#### Closure Table
```sql
CREATE TABLE group_paths (
    ancestor    BIGINT NOT NULL,
    descendant  BIGINT NOT NULL,
    depth       INT NOT NULL,
    PRIMARY KEY (ancestor, descendant)
);
```
- 장점: 모든 조상/자손 조회가 단순 JOIN
- 단점: 삽입 시 조상 수만큼 행 추가, 삭제 시 관련 행 전부 제거

#### Nested Set
```sql
ALTER TABLE groups ADD COLUMN lft INT, ADD COLUMN rgt INT;
```
- 장점: 하위 트리 조회가 `WHERE lft BETWEEN ? AND ?`
- 단점: 노드 삽입/삭제 시 절반 이상의 노드 left/right 재계산 → O(n)

---

## 🛠 Adjacency List 실전 구현

### MySQL DDL

```sql
CREATE TABLE groups (
    id               BIGINT NOT NULL AUTO_INCREMENT,
    group_code       VARCHAR(50)  NOT NULL UNIQUE,
    group_name       VARCHAR(100) NOT NULL,
    parent_group_id  BIGINT NULL,
    status           VARCHAR(20)  NOT NULL DEFAULT 'ACTIVE',
    created_at       DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at       DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    CONSTRAINT fk_group_parent FOREIGN KEY (parent_group_id) REFERENCES groups (id)
);
```

### JPA Entity (Self-Referential)

```java
@Entity
@Table(name = "groups")
public class Group {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "group_code", nullable = false, unique = true)
    private String groupCode;

    @Column(name = "group_name", nullable = false)
    private String groupName;

    // Adjacency List: 직접 부모 참조
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "parent_group_id")
    private Group parent;

    // 직접 자식 목록 (필요시 로딩)
    @OneToMany(mappedBy = "parent", fetch = FetchType.LAZY)
    private List<Group> children = new ArrayList<>();

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private GroupStatus status;

    // 루트 그룹 여부
    public boolean isRoot() {
        return this.parent == null;
    }
}
```

> [!tip] Best Practice
> `children` 컬렉션을 `EAGER`로 로딩하면 트리 전체를 N+1로 불러올 수 있습니다. `LAZY`로 선언하고 필요한 경우에만 명시적으로 로딩하세요. 트리 전체 탐색이 필요하면 아래의 `WITH RECURSIVE`를 SQL 레벨에서 처리하는 것이 훨씬 효율적입니다.

---

## 🔍 MySQL 8.0 WITH RECURSIVE — 트리 전체 조회

### 특정 노드의 모든 하위 그룹 조회 (하향 탐색)

```sql
WITH RECURSIVE group_tree AS (
    -- 기준 노드 (anchor)
    SELECT id, group_name, parent_group_id, 0 AS depth
    FROM groups
    WHERE id = :rootGroupId

    UNION ALL

    -- 재귀 부분: 자식 노드를 계속 JOIN
    SELECT g.id, g.group_name, g.parent_group_id, gt.depth + 1
    FROM groups g
    INNER JOIN group_tree gt ON g.parent_group_id = gt.id
)
SELECT * FROM group_tree ORDER BY depth, id;
```

### 특정 노드의 모든 조상 조회 (상향 탐색)

```sql
WITH RECURSIVE ancestors AS (
    SELECT id, group_name, parent_group_id, 0 AS level
    FROM groups
    WHERE id = :targetGroupId

    UNION ALL

    SELECT g.id, g.group_name, g.parent_group_id, a.level + 1
    FROM groups g
    INNER JOIN ancestors a ON g.id = a.parent_group_id
)
SELECT * FROM ancestors WHERE id != :targetGroupId
ORDER BY level DESC;
```

> [!warning] 주의 사항
> MySQL의 `WITH RECURSIVE`는 기본적으로 재귀 깊이를 1000으로 제한합니다 (`cte_max_recursion_depth`). 순환 참조(Cycle)가 데이터에 존재하면 무한 루프가 발생하므로, 삽입 시점에 사이클 방지 검증이 필요합니다.

---

## 🚀 LinkWave Group 도메인 적용 사례

### 배경

LinkWave는 고객사에 구축하여 운영하는 메시지 발송 플랫폼입니다. 초기에는 `Team` 이라는 고정된 단일 계층 구조를 사용했으나, 다음 문제가 발생했습니다.

- 고객사 A: "팀" 단위 관리 (1단계)
- 고객사 B: "본부 → 팀 → 파트" 3단계 계층
- 고객사 C: 프로젝트 기반 동적 조직 (깊이 불확정)

**결론**: `Team`이라는 추상화는 고정 계층을 전제했고, 유연한 조직 계층을 지원하려면 `Group` + Adjacency List가 더 적합한 모델이었습니다.

### 변경 요약

```
Before: User → Team (1:1, 단일 계층)
After:  User → Group (1:1, Group은 self-referential로 n단계 계층 가능)
```

데이터 모델에 `parent_group_id` FK를 추가하고, 초기 구현에서는 직접 부모/자식 조회만 지원합니다. 트리 전체 조회 API는 실제 고객사 요구사항 확인 후 `WITH RECURSIVE`로 구현할 예정입니다.

---

## 🎯 언제 Closure Table로 마이그레이션할까?

Adjacency List가 불충분해지는 시점은 다음과 같습니다.

| 시나리오 | Adjacency List 한계 | Closure Table 이점 |
|---------|-------------------|------------------|
| 특정 그룹의 모든 멤버 수 집계 | 재귀 쿼리 반복 필요 | 단순 COUNT + JOIN |
| "A가 B의 조상인가?" 검사 | 재귀 탐색 | `SELECT 1 FROM paths WHERE ancestor=A AND descendant=B` |
| 트리 조회가 초당 수천 건 | WITH RECURSIVE 비용 누적 | 단순 인덱스 스캔 |
| 다단계 권한 상속 | 복잡한 재귀 로직 | 조상 목록 테이블에서 IN 조회 |

마이그레이션 전략: Adjacency List를 유지한 채 Closure Table을 **추가**하고, 트리 탐색 쿼리만 Closure Table을 참조하도록 전환합니다.

---

## 🔗 Related Concepts

- [[cursor-pagination-linkwave|커서 기반 페이징 구현기]] — 대용량 조회 최적화
- [[innodb-batch-delete-pattern|InnoDB 배치 삭제 패턴]] — 계층 삭제 시 배치 처리
- [[resource/topics/spring/_Spring MOC|🍃 Spring MOC]] — JPA Entity 설계 패턴

---

## 📚 References

- [MySQL 8.0 Recursive CTE 공식 문서](https://dev.mysql.com/doc/refman/8.0/en/with.html)
- *SQL Antipatterns* — Bill Karwin, Chapter 3: Naive Trees
- [Adjacency List vs Closure Table — Use The Index, Luke](https://use-the-index-luke.com/)
