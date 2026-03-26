---
tags: [spring, cqrs, architecture, rest-api, linkwave, backend, jpa, mybatis]
category: resource
created: 2026-03-16
modified: 2026-03-26
related: [spring-event-cqrs-sync-pattern, cursor-pagination-linkwave, spring-transactional-deep-dive]
---

# 🔍 CQRS Command/Query 경로 분리 — 컨트롤러 레벨

## 📌 Situation / Symptom

Spring Boot 프로젝트에서 메시지 발송(Command)과 메시지 조회(Query) 기능을 모두 `MessageController` 하나에 구현하려 했다. 그러나 `/api/v1/messages` 경로는 이미 발송 Command 전용으로 사용 중이어서 조회 엔드포인트를 추가할 위치가 모호해졌다.

```
// 충돌 상황
POST /api/v1/messages          ← MessageController (발송, Command)
GET  /api/v1/messages?cursor=  ← 어디에 넣어야 하는가?
```

---

## 🔍 Technical Analysis

### CQRS 경로 분리 원칙

CQRS(Command Query Responsibility Segregation)는 서비스·레포지토리 계층에만 적용하는 개념이 아니다. **컨트롤러(URL 경로) 레벨까지 분리하면** 인가 정책, 캐싱, 모니터링을 독립적으로 관리할 수 있다.

```
Command Side                   Query Side
────────────────               ────────────────────────
POST /api/v1/messages          GET /api/v1/message-history/sent
PUT  /api/v1/messages/{id}     GET /api/v1/message-history/scheduled
DELETE /api/v1/messages/{id}   GET /api/v1/message-history/{clientKey}

MessageController              MessageHistoryController
  └─ MessageService              └─ MessageQueryService
       └─ JPA Repository               └─ MyBatis QueryMapper
          (쓰기)                           (읽기)
```

### Command vs Query 컨트롤러 비교

| 항목 | Command Controller | Query Controller |
|------|-------------------|-----------------|
| HTTP 메서드 | POST, PUT, DELETE | GET |
| 응답 | 201 Created / 204 No Content | 200 OK + 데이터 |
| 인가 | 쓰기 권한 필요 | 읽기 전용 권한 가능 |
| 캐싱 | 불가 (상태 변경) | 가능 (`Cache-Control`) |
| 기술 스택 | JPA (영속성 컨텍스트) | MyBatis (읽기 최적화 쿼리) |

> [!tip] Best Practice
> URL 경로에 `-history`, `-query`, `-summary` 같은 접미사를 붙이면 Command/Query 의도가 드러난다. REST 순수주의 관점에서 벗어나지만, 팀 내 명확성과 CQRS 의도 전달 측면에서 유리하다.

---

## 🛠 Solution

### 루트 원인

`MessageController`가 `/api/v1/messages` 경로를 Command 전용으로 점유 → 조회 기능을 같은 컨트롤러에 넣으면 Command/Query 경계가 흐려짐.

### 수정: Query 전용 컨트롤러 분리

```java
// Command 전용 — 기존 유지
@RestController
@RequestMapping("/api/v1/messages")
public class MessageController {
    // POST, PUT, DELETE 엔드포인트만
}

// Query 전용 — 신규 생성
@RestController
@RequestMapping("/api/v1/message-history")
public class MessageHistoryController {

    private final MessageQueryService messageQueryService;

    @GetMapping("/sent")
    public ResponseEntity<CursorPageResponse<MessageHistoryResponse>> getSentMessages(
            @RequestParam(required = false) String cursor,
            @RequestParam(required = false) String status,
            @RequestParam(defaultValue = "20") int size) {
        return ResponseEntity.ok(messageQueryService.getSentMessages(cursor, status, size));
    }

    @GetMapping("/scheduled")
    public ResponseEntity<CursorPageResponse<MessageHistoryResponse>> getScheduledMessages(
            @RequestParam(required = false) String cursor,
            @RequestParam(defaultValue = "20") int size) {
        return ResponseEntity.ok(messageQueryService.getScheduledMessages(cursor, size));
    }

    @GetMapping("/{clientKey}")
    public ResponseEntity<MessageHistoryResponse> getMessageDetail(
            @PathVariable String clientKey) {
        return ResponseEntity.ok(messageQueryService.getMessageDetail(clientKey));
    }
}
```

> [!warning] 주의 사항
> Query Controller에서 상태 변경 작업(`@Transactional` 쓰기)을 수행하지 말 것. Query 서비스는 읽기 전용 트랜잭션(`@Transactional(readOnly = true)`)으로 제한하는 것이 안전하다.

---

## 🔗 Related Concepts

- [[역할 기반 분리 CQRS|역할 기반 분리 CQRS]] — Service/Repository 계층의 Command/Query 분리 원칙
- [[spring-event-cqrs-sync-pattern|Spring Event 기반 CQRS 동기화 패턴]] — 이벤트 기반 CQRS 심화
- [[resource/topics/database/cursor-pagination-linkwave|커서 기반 페이징 구현기]] — Query 컨트롤러에서 사용하는 cursor 페이징 방식
- [[spring-dto-naming-conventions|DTO 레이어별 네이밍 컨벤션]] — Response/Result suffix 구분

---

## 📚 References

- [Martin Fowler — CQRS Pattern](https://martinfowler.com/bliki/CQRS.html)
- [Spring MVC — @RestController](https://docs.spring.io/spring-framework/docs/current/reference/html/web.html#mvc-controller)

---

## 📚 Service/Repository 레벨 CQRS — 역할 기반 분리

컨트롤러 경로 분리와 함께, 서비스·레포지토리 계층에서도 Command/Query 역할을 기술 스택으로 분리한다.

### 핵심 원칙: 조회의 목적에 따른 기술 스택 분리

```
조회 결과의 사용 목적
├── 상태 변경을 위한 조회 → Command Layer (JPA)
│   ├── findById()   - 엔티티 수정 목적
│   ├── existsBy()   - 유효성 검증 목적
│   └── findOneBy()  - 비즈니스 로직 실행 목적
│
└── 사용자에게 보여주기 위한 조회 → Query Layer (MyBatis)
    ├── 목록 조회 (페이징, 정렬)
    ├── 검색 (복잡한 조건)
    ├── 상세 보기 (Join 필요)
    └── 통계/집계
```

### 네이밍 컨벤션

| 계층 | 역할 | 네이밍 | 기술 스택 |
|------|------|--------|-----------|
| Command | 상태 변경 | `{Entity}Repository` | JPA |
| Query | 데이터 제공 | `{Entity}QueryMapper` | MyBatis |

```java
UserRepository    // JPA - Command
UserQueryMapper   // MyBatis - Query
```

### 의사결정 플로우

```
조회 쿼리를 작성해야 할 때
        ↓
"이 조회 결과로 무엇을 하는가?"
        ↓
    ┌───┴───┐
    │       │
엔티티 수정?   화면 표시?
영속성 필요?   DTO 반환?
    │           │
    ↓           ↓
JPA Repository  MyBatis Mapper
(Command)       (Query)
```

#### JPA를 사용해야 하는 경우

- 조회 후 엔티티 상태 변경 필요
- 영속성 컨텍스트 관리 필요
- 비즈니스 로직을 엔티티 메서드로 실행
- 트랜잭션 내 Dirty Checking 활용

#### MyBatis를 사용해야 하는 경우

- 조회 결과를 화면에 바로 표시
- 복잡한 Join이 필요한 상세 조회
- 동적 검색 조건이 많은 목록 조회
- 통계/집계 쿼리
- 성능 최적화가 필요한 대량 조회

### QueryDSL 대신 MyBatis를 선택한 이유

| 관점 | MyBatis | QueryDSL |
|------|---------|----------|
| 학습 곡선 | SQL 지식만으로 즉시 사용 | Q클래스 생성, 복잡한 API 학습 필요 |
| 유지보수 | XML SQL 직관적 | Java DSL 코드 복잡 |
| 성능 튜닝 | SQL 직접 작성, 실행 계획 확인 용이 | ORM 추상화로 제어 범위 제한 |
| 팀 협업 | DBA와 SQL 공유 가능 | Java 개발자 전용 |

### 실무 예시

```java
// ❌ MyBatis로 엔티티 수정 — 잘못된 접근
userQueryMapper.updateUserName(userId, newName); // 엔티티 생명주기 무시

// ✅ JPA로 엔티티 수정 — 올바른 접근
User user = userRepository.findById(userId).orElseThrow();
user.changeName(newName); // 엔티티 메서드 + Dirty Checking 자동 반영

// ❌ JPA로 목록 조회 — N+1 유발
users.stream().map(u -> new UserListDto(u.getId(), u.getPosts().size())).toList();

// ✅ MyBatis로 목록 조회 — 단일 쿼리
userQueryMapper.findUserList(); // 필요한 데이터만 Join
```

> [!warning] 경계를 명확히
> Command와 Query를 섞어 사용하지 말 것. Service 계층에서 역할에 맞는 레이어를 호출한다.
