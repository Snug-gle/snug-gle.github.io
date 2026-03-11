---
created: 2026-03-11
---
---
created: 2026-03-10
updated: 2026-03-10
tags:
  - database
  - pagination
  - cursor
  - mybatis
  - linkwave
---

# 커서 기반 페이징 구현기 — LinkWave 메시지 이력 조회

> LinkWave(멀티채널 메시징 플랫폼) 백엔드에서 대용량 메시지 이력 조회에 커서 페이징을 직접 구현한 경험을 정리합니다.

---

## 배경: OFFSET 방식의 한계

LinkWave의 메시지 발송 이력 테이블(`message_history`)은 일 10만+ 건이 쌓이는 구조입니다. 초기에는 OFFSET 방식으로 페이징을 구현했는데, 문제가 발생했습니다.

```sql
-- 문제가 된 쿼리
SELECT * FROM message_history
WHERE user_id = ?
ORDER BY requested_at DESC
LIMIT 20 OFFSET 10000;  -- 10,000개를 건너뛰어야 함
```

EXPLAIN으로 확인했더니 `OFFSET 10000`은 10,020개를 읽어 앞의 10,000개를 버리는 방식이라 **후반 페이지로 갈수록 성능이 O(n)으로 저하**됩니다. 특히 월별 파티션 테이블에서도 각 파티션 내 OFFSET 탐색 비용은 동일하게 발생합니다.

---

## 커서 페이징(Keyset Pagination) 개념

커서 방식은 "마지막으로 읽은 행의 정렬 기준값"을 WHERE 조건으로 전달합니다.

```sql
-- 커서 방식: 항상 O(1) 성능
SELECT * FROM message_history
WHERE user_id = ?
  AND requested_at < '2024-01-15 10:30:00'  -- ← 커서
ORDER BY requested_at DESC
LIMIT 20;
```

인덱스 스캔이 커서 위치부터 시작하므로 후반 페이지도 동일한 성능을 유지합니다.

---

## 이중 커서 구조 — 동점 문제 해결

단일 커서(`requested_at`)만 사용하면 **동점 문제**가 발생합니다. 같은 시각에 여러 메시지가 발송된 경우, 동일한 `requested_at` 값을 가진 행이 여러 개 존재하여 페이지 경계에서 중복이나 누락이 생깁니다.

해결 방법: `(requested_at, client_key)` 이중 커서

```sql
AND (
    requested_at < #{cursorRequestedAt}
    OR (requested_at = #{cursorRequestedAt} AND client_key < #{cursorClientKey})
)
ORDER BY requested_at DESC, client_key DESC
```

`(A < cursor_A) OR (A = cursor_A AND B < cursor_B)` 패턴은 정렬 기준이 2개일 때 안전하게 "이 지점 이후"를 표현합니다.

---

## 전체 구현: MyBatis XML + Java

### MessageHistoryQueryMapper.xml

```xml
<?xml version="1.0" encoding="UTF-8"?>
<mapper namespace="io.iotree.linkwave.infra.mybatis.mapper.MessageHistoryQueryMapper">

    <select id="findSentMessages"
            resultType="...MessageHistoryQueryMapper$MessageHistoryListDto">
        SELECT
            client_key AS clientKey,
            batch_key AS batchKey,
            sender_number AS senderNumber,
            recipient_phone AS recipientPhone,
            message_type AS messageType,
            content, title, status,
            result_code AS resultCode,
            result_channel AS resultChannel,
            requested_at AS requestedAt,
            scheduled_at AS scheduledAt,
            completed_at AS completedAt,
            is_scheduled AS isScheduled
        FROM message_history
        <where>
            user_id = #{userId}
            <if test="status != null and status != ''">
                AND status = #{status}
            </if>
            <if test="cursorRequestedAt != null and cursorClientKey != null">
                AND (
                    requested_at &lt; #{cursorRequestedAt}
                    OR (requested_at = #{cursorRequestedAt} AND client_key &lt; #{cursorClientKey})
                )
            </if>
        </where>
        ORDER BY requested_at DESC, client_key DESC
        LIMIT #{limit}
    </select>

</mapper>
```

**포인트**:
- `<if test="...">` 동적 쿼리로 첫 페이지(커서 없음)와 이후 페이지 통합 처리
- XML에서 `<`는 `&lt;`로 이스케이프
- `LIMIT #{limit}`은 `size + 1`이 전달됨 (hasNext 판단용)

---

### CursorUtils.java — Base64 불투명 커서

```java
public class CursorUtils {

  private static final String DELIMITER = "|";

  /** 커서 인코딩 (날짜 + ID) */
  public static String encode(LocalDateTime dataValue, String id) {
    if (dataValue == null || id == null) return null;
    String combined = dataValue.toString() + DELIMITER + id;
    return Base64.getUrlEncoder().encodeToString(
        combined.getBytes(StandardCharsets.UTF_8));
  }

  /** 커서 디코딩 */
  public static CursorData decode(String cursor) {
    if (cursor == null || cursor.isBlank()) return CursorData.empty();

    String decoded = new String(
        Base64.getUrlDecoder().decode(cursor), StandardCharsets.UTF_8);
    String[] parts = decoded.split("\\|", 2);
    if (parts.length != 2) return CursorData.empty();

    return new CursorData(parts[0], parts[1]);
  }

  public record CursorData(String sortValue, String id) {
    public static CursorData empty() { return new CursorData(null, null); }
    public boolean isEmpty() { return sortValue == null && id == null; }

    public LocalDateTime sortValueAsDateTime() {
      return sortValue != null ? LocalDateTime.parse(sortValue) : null;
    }
  }
}
```

**왜 Base64로 인코딩하는가?**

"불투명 커서(opaque cursor)"를 만들기 위해서입니다. 클라이언트가 `?cursor=2024-01-15T10:30:00|msg-123`을 직접 조작하면 보안 문제가 생길 수 있습니다. Base64 URL-safe 인코딩으로 내부 구조를 숨기고, 서버만 디코딩할 수 있도록 합니다.

---

### MessageQueryService.java — size+1 트릭

```java
@Transactional(readOnly = true)
public CursorPageResponse<MessageHistoryDto> getSentMessages(
    UUID userId, String status, String cursor, int size) {

  CursorData cursorData = CursorUtils.decode(cursor);
  int queryLimit = size + 1;  // ← 하나 더 조회

  List<MessageHistory> results =
      messageHistoryRepository
          .findByUserIdOrderByRequestedAtDesc(
              userId.toString(), PageRequest.of(0, queryLimit))
          .getContent();

  boolean hasNext = results.size() > size;  // 더 조회됐으면 다음 페이지 있음
  List<MessageHistory> items = hasNext ? results.subList(0, size) : results;

  String nextCursor = null;
  if (hasNext && !items.isEmpty()) {
    MessageHistory lastItem = items.get(items.size() - 1);
    nextCursor = CursorUtils.encode(
        lastItem.getRequestedAt(), lastItem.getClientKey());
  }

  return CursorPageResponse.of(
      items.stream().map(MessageHistoryDto::from).toList(),
      nextCursor,
      hasNext);
}
```

**size+1 트릭의 의미**:
- 요청한 것보다 1개 더 조회
- 결과가 `size`를 초과 → 다음 페이지 있음 → `hasNext = true`
- 실제 반환은 `subList(0, size)`로 잘라냄
- 별도 `COUNT(*)` 쿼리 없이 다음 페이지 존재 여부 판단

---

## 커서 응답 구조

```json
{
  "items": [...],
  "nextCursor": "MjAyNC0wMS0xNVQxMDozMDowMHxtc2ctMTIz",
  "hasNext": true
}
```

클라이언트는 `nextCursor`를 그대로 다음 요청 파라미터로 전달합니다. Base64이므로 URL-safe하고, 내용을 파싱하지 않습니다.

---

## OFFSET vs 커서 비교

| 항목 | OFFSET | 커서(Keyset) |
|------|--------|-------------|
| 성능 | O(n) — 페이지가 깊을수록 느림 | O(1) — 항상 일정 |
| 임의 페이지 이동 | 가능 | 불가 (순차 탐색만) |
| 데이터 일관성 | 새 데이터 삽입 시 중복/누락 가능 | 커서 기준으로 안정적 |
| 복잡도 | 단순 | 이중 커서 시 쿼리 복잡 |
| 적합한 사례 | 소규모, 임의 페이지 | 대용량, 무한 스크롤 |

메시지 이력처럼 **순차 탐색이 자연스럽고 데이터가 많이 쌓이는** 경우 커서 방식이 적합합니다.

---

## 성능 결과

월별 파티션 + 복합 인덱스 `(user_id, requested_at DESC, client_key DESC)` 조합으로:
- 조회 범위 86% 감소 (파티션 pruning 효과)
- 쿼리 응답 시간 80% 단축
- 후반 페이지도 초반 페이지와 동일한 응답 시간 유지

---

## 참고

- [[spring/역할 기반 분리 CQRS|CQRS 하이브리드 ORM 전략]]
- [[spring/spring-event-cqrs-sync-pattern|Event-Driven 읽기 모델 동기화]]
