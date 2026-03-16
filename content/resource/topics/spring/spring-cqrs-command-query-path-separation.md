---
tags: [spring, cqrs, architecture, rest-api, linkwave, backend]
category: resource
created: 2026-03-16
related: [역할 기반 분리 CQRS, spring-event-cqrs-sync-pattern, cursor-pagination-linkwave]
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
