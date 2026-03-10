---
tags:
  - backend
  - spring
  - message
  - cursor-pagination
  - cqrs
  - mybatis
category: resource
created: 2026-03-10
---

# MessageQueryService 구현 및 커서 페이징 학습

## 상황

MessageQueryService에서 목록 조회 시 커서 기반 페이징(Keyset Pagination)을 구현하면서 여러 개념적 질문과 코드 버그를 발견 및 해결.

---

## 커서 페이징 (Keyset Pagination) 개념

### 오프셋 페이징과의 차이

| 특성 | 오프셋 방식 | 커서 방식 |
| :--- | :--- | :--- |
| 기준점 | 페이지 번호 (0부터 시작) | "어디까지 봤는지" 커서 위치 |
| SQL | LIMIT 10 OFFSET 100 | WHERE id < ? LIMIT 11 |
| 성능 | 뒤로 갈수록 느려짐 (인덱스 스캔) | 항상 일정 (인덱스 범위 스캔) |
| 용도 | 작은 데이터셋, 임의 접근 필요 | 대용량, 스크롤/무한로딩 |

> [!tip] 실무 선택
> 대부분의 최신 모바일 앱은 커서 페이징 사용. API는 스크롤 기반이기 때문.

### 이중 커서 구조 (Composite Cursor)

```
requestedAt, clientKey 두 개를 커서로 사용하는 이유?
→ 동점(tie) 문제 해결
```

**시나리오:**
```
메시지 조회 결과 (requestedAt 기준 정렬)
- Message A: requestedAt=2026-03-10 10:00:00, clientKey=msg-001
- Message B: requestedAt=2026-03-10 10:00:00, clientKey=msg-002  ← 같은 시각!
- Message C: requestedAt=2026-03-10 09:59:00, clientKey=msg-003
```

**오프셋만 사용했을 때의 문제:**
```
커서가 requestedAt=2026-03-10 10:00:00이면?
→ A, B 둘 다 조건을 만족
→ 요청할 때마다 결과가 달라질 수 있음 (비결정적)
```

**해결책: 복합 커서**
```sql
WHERE (requested_at < ?)
   OR (requested_at = ? AND client_key < ?)
```

이 조건으로:
- `requested_at`이 더 작은 데이터는 확실히 걸러짐
- `requested_at`이 같으면 `client_key` 순서로만 필터링
- 결과가 일관성 있음 (deterministic)

> [!warning] 인덱스 전략
> 인덱스는 `(user_id, requested_at DESC, client_key DESC)` 복합 인덱스여야 옵티마이저가 최적 경로를 선택.

---

## SQL 실행 순서와 커서 페이징

```
FROM → WHERE → GROUP BY → HAVING → SELECT → ORDER BY → LIMIT
```

**중요 포인트:**
- **WHERE가 먼저 실행**: 커서 조건(requestedAt, clientKey)이 WHERE 절에 있으므로, 대부분의 데이터가 먼저 걸러짐
- **ORDER BY는 나중**: 따라서 커서 페이징은 매우 빠름 (거의 선택된 범위만 정렬)
- **인덱스 선택은 옵티마이저 결정**: 적절한 복합 인덱스가 있어도 쿼리 통계, 데이터 분포에 따라 옵티마이저가 결정. 항상 인덱스를 타는 게 아님.

---

## 불투명 커서 (Opaque Cursor)

### Base64 인코딩하는 이유

```java
// 커서 구조: requestedAt (ISO 8601) + "|" + clientKey
String cursorStr = requestedAt + "|" + clientKey;
String opaqueCursor = Base64.getEncoder().encodeToString(cursorStr.getBytes());

// 클라이언트에게: "eyIyMDI2LTAzLTEwVDEwOjAwOjAwWn1jbGllbnRLZXktMDAxIg=="
// 클라이언트는 이 값을 다음 요청에 그대로 전달하기만 함
```

**이점:**
1. **캡슐화**: 내부 구조(어떤 필드로 구성됐는지)를 클라이언트에게 노출 안 함
2. **진화 가능성**: 백엔드가 커서 구조를 변경해도 클라이언트 코드 영향 없음
3. **보안**: 커서 값을 보고 순서를 예측할 수 없음

**역방향 디코딩은 백엔드만:**
```java
String cursorStr = new String(Base64.getDecoder().decode(opaqueCursor));
String[] parts = cursorStr.split("\\|");
Instant requestedAt = Instant.parse(parts[0]);
String clientKey = parts[1];
```

> [!tip] API 설계
> 클라이언트는 커서를 "불투명한 토큰"처럼 취급. 파싱하거나 수정하려고 하면 안 됨.

---

## Instant vs LocalDateTime

### 타입 선택 기준

| 특성 | Instant | LocalDateTime |
| :--- | :--- | :--- |
| 타임존 정보 | UTC 절대 시각 | 타임존 정보 없음 |
| 용도 | 시스템이 자동으로 기록 | 사용자가 입력하는 시각 |
| 예시 | requestedAt, createdAt, updatedAt | scheduledAt (예약 발송 시간) |
| DB 저장 | TIMESTAMP WITH TIMEZONE | TIMESTAMP |

### 실무 패턴

```
시스템 자동 시각 → Instant
- Message.requestedAt: Instant (언제 API 요청 받았나?)
- User.createdAt: Instant (언제 가입했나?)

사용자 입력 시각 → LocalDateTime
- Schedule.sendAtTime: LocalDateTime (사용자가 "내일 10:00에" 예약)
- Event.scheduledTime: LocalDateTime (달력 이벤트)
```

### UTC로 저장하는 이유

```
장점:
1. 서버 타임존 설정 변경에 무관 (서비스 이사 등)
2. 코드만 봐도 UTC인지 명확 (타입으로 강제)
3. 국제화 필요할 때 기반이 이미 마련됨

주의:
- DB 서버가 KST(한국 표준시)라고 해도 JPA/JDBC가 자동으로 변환
- JVM은 UTC로 동작하는 게 관례
```

**프로젝트 선택:**
- LinkWave는 UTC 전략 채택
- "시스템이 찍는 시각은 모두 Instant"로 일관성 있음

---

## MessageQueryService 버그 및 개선사항

### 발견된 버그

#### 1. 잘못된 변수명 사용

```java
// Before (버그)
int queryLimit = size + 1;  // 선언했는데...
List<MessageHistory> results = mapper.findWithCursor(
    userId, requestedAt, clientKey,
    size  // ← queryLimit이 아니라 size를 넘김
);

// After (수정)
List<MessageHistoryListDto> results = mapper.findWithCursor(
    userId, requestedAt, clientKey,
    queryLimit  // ← 올바른 변수명
);
```

#### 2. DTO 타입 오류

```java
// Before (버그)
List<MessageHistory> results = ...;  // 엔티티 타입

// After (수정)
List<MessageHistoryListDto> results = ...;  // 인프라 레이어 DTO 타입
```

**이유:**
- `MessageHistory`: JPA 엔티티 (왜 조회 결과에 엔티티가?)
- `MessageHistoryListDto`: MyBatis Mapper가 반환하는 DTO (인프라 레이어)

#### 3. 조건 분기 역순

```java
// Before (버그)
if (statusFilter == null) {
    mapper.findWithCursorAndStatus(userId, ..., statusFilter);  // null을 넘김
} else {
    mapper.findWithCursor(userId, ...);  // status 조건 없음
}

// After (수정)
if (statusFilter != null) {
    mapper.findWithCursorAndStatus(userId, ..., statusFilter);
} else {
    mapper.findWithCursor(userId, ...);
}
```

#### 4. nextCursor 생성 시 clientKey 중복

```java
// Before (버그)
if (results.size() > size) {
    MessageHistoryListDto last = results.get(size - 1);
    nextCursor = encode(last.clientKey(), last.clientKey());  // ← clientKey 2번
}

// After (수정)
MessageHistoryListDto last = results.get(size - 1);
nextCursor = encode(last.requestedAt(), last.clientKey());  // ← requestedAt + clientKey
```

---

## Size+1 트릭 (한 번에 다음 페이지 여부 판단)

### 원리

```
데이터베이스에서 size+1개 요청
    ↓
if (조회된 개수 > size) {
    hasNext = true;  // 다음 페이지 있음
    results = results.subList(0, size);  // size개만 잘라서 반환
} else {
    hasNext = false;  // 마지막 페이지
}
```

**장점:**
- 추가 COUNT 쿼리 불필요
- 다음 페이지 여부를 정확히 판단
- 성능상 효율적

**코드 예시:**
```java
int queryLimit = pageSize + 1;
List<MessageHistoryListDto> results = queryMapper.findWithCursor(
    userId, requestedAt, clientKey, queryLimit
);

PageResponse<MessageHistoryDto> response;
if (results.size() > pageSize) {
    // 한 개 더 조회했는데 size+1개가 왔으면 다음 페이지 있음
    MessageHistoryListDto lastInPage = results.get(pageSize - 1);
    String nextCursor = encodeCursor(
        lastInPage.requestedAt(),
        lastInPage.clientKey()
    );

    response = new PageResponse<>(
        results.subList(0, pageSize).stream()
            .map(MessageHistoryDto::from)
            .toList(),
        nextCursor,
        true  // hasNext
    );
} else {
    // size+1개 미만이면 마지막 페이지
    response = new PageResponse<>(
        results.stream()
            .map(MessageHistoryDto::from)
            .toList(),
        null,  // nextCursor
        false  // hasNext
    );
}
```

---

## CQRS 원칙 적용

### "화면에 보여주기 위한 조회 → MyBatis" 원칙

```
예시: getMessageDetail()
```

#### Before (위반)
```java
@Service
public class MessageQueryService {
    @Autowired
    private MessageHistoryRepository repository;  // JPA

    public MessageHistoryDto getMessageDetail(String clientKey, Long userId) {
        MessageHistory entity = repository.findByClientKey(clientKey);
        // 문제 1: 권한 검증 없음 (클라이언트가 다른 사람의 메시지를 볼 수 있음)
        return MessageHistoryDto.from(entity);
    }
}
```

#### After (CQRS 준수)
```java
@Service
public class MessageQueryService {
    @Autowired
    private MessageHistoryQueryMapper queryMapper;  // MyBatis

    public MessageHistoryDto getMessageDetail(String clientKey, Long userId) {
        // 쿼리에 userId 조건 포함 → SQL 레벨에서 권한 검증
        MessageHistoryDetailDto dto = queryMapper.findByClientKeyAndUserId(
            clientKey, userId
        );
        if (dto == null) {
            throw new MessageNotFoundException();
        }
        return MessageHistoryDto.from(dto);  // DTO 체인
    }
}
```

### DTO 계층 분리

```
DB 조회 결과
    ↓
MessageHistoryListDto (인프라 레이어, MyBatis Mapper)
    ↓
MessageHistoryDto (API 응답, Controller)
```

**각 레이어의 책임:**
1. **MessageHistoryListDto**: "DB에서 조회한 구조" (컬럼 매핑)
2. **MessageHistoryDto**: "클라이언트에게 반환할 구조" (API 계약)

**이유:**
- DB 스키마 변경 시 Mapper만 수정
- API 응답 포맷 변경 시 Controller만 수정
- 관심사 분리 원칙

---

## 다음 검토 사항

### DTO 변환 체인 재검토

현재:
```java
MessageHistoryDto.from(MessageHistoryListDto)
```

CQRS 원칙상 더 명확하게:
```java
// MessageHistoryListDto vs MessageHistoryDetailDto 구분
MessageHistoryDto.fromListDto(MessageHistoryListDto)
MessageHistoryDto.fromDetailDto(MessageHistoryDetailDto)
```

또는:

```java
// 별도 매퍼 활용
@Component
public class MessageHistoryResponseMapper {
    public MessageHistoryDto toResponse(MessageHistoryListDto dto) { ... }
    public MessageHistoryDto toResponse(MessageHistoryDetailDto dto) { ... }
}
```

### Controller 응답 DTO 위치 정리

추천:
```
src/main/java/io/iotree/linkwave/
├── api/
│   ├── dto/
│   │   ├── request/       ← 요청 DTO
│   │   └── response/      ← 응답 DTO (MessageHistoryDto 등)
│   └── controller/
├── application/           ← 비즈니스 로직
└── infrastructure/        ← MyBatis, JPA
    └── dto/               ← 인프라 DTO (MessageHistoryListDto 등)
```

---

## 관련 개념

- [[MessageHistory 설계 패턴|Message History CQRS]]
- [[Cursor Pagination 구현 가이드|Cursor Pagination]]
- [[MyBatis Query Mapper 패턴|MyBatis CQRS]]

## 참고 자료

- SQL 실행 순서 및 쿼리 최적화: [PostgreSQL Query Execution](https://www.postgresql.org/docs/current/query-planning.html)
- Java Instant vs LocalDateTime: [Java Time API Documentation](https://docs.oracle.com/javase/8/docs/api/java/time/package-summary.html)
- RFC 9457 (HyperText Caching): [IETF RFC 9457](https://tools.ietf.org/html/rfc9457)
