---
created: 2026-03-11
---
---
created: 2026-03-10
updated: 2026-03-10
tags:
  - architecture
  - scheduler
  - spring
  - redis
  - websocket
  - concurrency
---

# 균등 분배 스케줄러 구현기 — @Scheduled + Redis + WebSocket 파이프라인

> SI 프로젝트 구현 경험 기반. 업무 아이템(WorkItem)을 담당자에게 자동 균등 분배하는 스케줄러의 설계와 동시성 처리를 정리합니다.
>
> *익명화: 실제 도메인 명칭을 일반화하여 기술합니다.*

---

## 배경: 수동 배정의 문제

B2B 상담 시스템에서 인바운드 요청(WorkItem)이 들어오면 관리자가 수동으로 담당자에게 배정했습니다. 요청이 몰리는 시간대에는 배정 지연이 발생했고, 담당자 간 부하 불균형도 문제였습니다.

**요구사항**:
1. 5분 주기 자동 분배 (운영자 개입 없음)
2. 균등 분배 (담당자별 처리 수 편차 최소화)
3. 고객 연속성 (같은 고객이 재요청하면 기존 담당자에게)
4. 실시간 알림 (배정 즉시 담당자 화면에 표시)
5. 멀티 서버 환경 지원 (중복 실행 방지)

---

## 전체 아키텍처

```
@Scheduled (5분 주기, Master 서버만)
    │
    ▼
WorkItemService.autoDistribute()
    ├── 미배정 WorkItem 조회
    ├── 대표 그룹별 분류
    └── 담당자별 균등 분배
        │
        ▼
    티켓 생성 & DB 업데이트
        │
        ▼
Redis Pub/Sub publish
    │ (모든 서버 인스턴스가 subscribe)
    ▼
각 서버 → WebSocket → 담당자 브라우저
```

---

## 스케줄러 구현

```java
@RequiredArgsConstructor
@Component
public class WorkItemDistributionScheduler {

    private final WorkItemService workItemService;
    private final RedisProperties redisProperties;
    private final RedisMessagePublisher publisher;
    private final SimpMessagingTemplate messagingTemplate;
    private final NotificationService notificationService;

    @Value("${app.isMasterServer}")
    private Boolean isMasterServer;

    @Scheduled(cron = "0 */5 * * * *")
    @Transactional
    public void distributeWorkItems() {
        // 멀티 인스턴스 중복 실행 방지 — Master 서버만 스케줄러 실행
        if (!isMasterServer) return;

        List<WorkItem> distributed = workItemService.autoDistribute();
        if (distributed == null || distributed.isEmpty()) return;

        ObjectMapper objectMapper = new ObjectMapper();
        try {
            if (redisProperties.getBroadcaster().isEnable() && publisher != null) {
                // 다중 서버: Redis Pub/Sub으로 전체 브로드캐스트
                // → 모든 서버의 WebSocket 핸들러가 수신하여 자신의 클라이언트에 전달
                String json = objectMapper.writeValueAsString(distributed);
                WebSocketMessage msg = WebSocketMessage.builder()
                        .receiverType(ReceiverType.USERS)
                        .sendTime(new Date())
                        .content(json)
                        .build();
                publisher.publish(TOPIC_WORK_ITEM, objectMapper.writeValueAsString(msg));
            } else {
                // 단일 서버: WebSocket 직접 전송
                for (WorkItem item : distributed) {
                    String json = objectMapper.writeValueAsString(item);
                    messagingTemplate.convertAndSend(
                        TOPIC_WORK_ITEM + "/" + item.getAssignedUserId(), json);
                }
            }
            notificationService.saveAll(distributed);  // 알림 이력 저장
        } catch (JsonProcessingException e) {
            log.error("Failed to serialize work items", e);
        }
    }
}
```

**설계 포인트**:
- `isMasterServer` 플래그: 로드밸런서 환경에서 한 서버만 스케줄러를 실행
- Redis 브로드캐스트 분기: 단일/다중 서버 환경 모두 대응
- 스케줄러는 "언제 실행할지"만 담당, 비즈니스 로직은 서비스 계층에 위임

---

## 균등 분배 알고리즘

```java
@Service
public class WorkItemServiceImpl implements WorkItemService {

    // 배정 세션 내 번호 → 담당자 캐시 (동일 번호 연속 배정 보장)
    private Map<String, User> phoneUserCache;

    @Override
    public List<WorkItem> autoDistribute() {
        phoneUserCache = new ConcurrentHashMap<>();

        List<WorkItem> unassigned = findUnassignedItems();
        if (unassigned == null || unassigned.isEmpty()) return unassigned;

        // 1. 대표 번호별로 WorkItem 그룹화
        Map<String, List<WorkItem>> byRepresentNumber = groupByRepresentNumber(unassigned);

        // 2. 각 그룹에 해당하는 배정 그룹 조회
        List<AssignmentGroup> groups = findAssignmentGroups(byRepresentNumber.keySet());
        if (groups == null || groups.isEmpty()) return null;

        // 3. 그룹별 담당자에게 균등 분배
        Map<AssignmentGroup, List<WorkItem>> byGroup = mapToGroups(byRepresentNumber, groups);
        List<WorkItem> result = distributeToUsers(byGroup);

        phoneUserCache.clear();
        return result;
    }

    private List<WorkItem> distributeToUsers(
            Map<AssignmentGroup, List<WorkItem>> byGroup) {
        List<WorkItem> updated = new LinkedList<>();
        Date today = new Date();

        for (Map.Entry<AssignmentGroup, List<WorkItem>> entry : byGroup.entrySet()) {
            AssignmentGroup group = entry.getKey();
            List<WorkItem> items = entry.getValue();

            // 오늘 날짜 기준 담당자별 처리 수 조회
            Map<Long, Integer> userLoadMap = getUserLoadMap(today);

            for (WorkItem item : items) {
                User assignee = selectAssignee(item, userLoadMap, group.getUsers());
                Ticket ticket = createTicket(item, assignee);
                item.setTicket(ticketDao.create(ticket));

                // 분배 중 카운트 실시간 반영 (다음 아이템 배정에 영향)
                userLoadMap.compute(assignee.getId(), (k, v) -> v == null ? 1 : v + 1);
            }

            updated.addAll(workItemDao.updateAll(items));
        }

        return updated;
    }
```

---

## 3단계 우선순위 담당자 선택 로직

```java
    /**
     * 담당자 선택 — 3단계 우선순위
     *
     * 1순위: 이 배정 세션에서 이미 같은 번호를 처리한 담당자 (캐시)
     * 2순위: 오늘 이미 이 번호와 상담한 담당자 (연속성)
     * 3순위: 현재 처리 수가 가장 적은 담당자 (균등 분배)
     */
    private User selectAssignee(WorkItem item,
                                Map<Long, Integer> userLoadMap,
                                List<User> candidates) {
        String phone = item.getContactPhone();

        // 1순위: 같은 세션 내 동일 번호 → 같은 담당자
        if (phoneUserCache.containsKey(phone)) {
            return phoneUserCache.get(phone);
        }

        // 2순위: 오늘 이미 상담한 담당자 (LocalDate 기준)
        List<Ticket> todayTickets = findTodayTicketsByPhone(phone);
        User todayAssignee = todayTickets.isEmpty()
            ? null : todayTickets.get(0).getAssignee();

        User selected = (todayAssignee != null && candidates.contains(todayAssignee))
            ? todayAssignee
            : candidates.stream()
                .min(Comparator.comparingInt(
                    user -> userLoadMap.getOrDefault(user.getId(), 0)))
                .orElseThrow(() -> new IllegalStateException("No candidates"));

        phoneUserCache.put(phone, selected);  // 세션 캐시 저장
        return selected;
    }

    private List<Ticket> findTodayTicketsByPhone(String phone) {
        LocalDateTime startOfDay = LocalDate.now().atStartOfDay();
        LocalDateTime endOfDay = LocalDate.now().atTime(23, 59, 59);
        // DB 조회 (생략)
        return ticketDao.findByPhoneAndDateRange(phone, startOfDay, endOfDay);
    }
```

**알고리즘 해설**:

| 순위 | 조건 | 이유 |
|------|------|------|
| 1순위 | 세션 캐시 | 배치 처리 중 같은 번호 중복 입력 시 일관성 |
| 2순위 | 당일 상담 이력 | 고객이 같은 담당자와 연속 상담 → 컨텍스트 유지 |
| 3순위 | 최소 부하 | 균등 분배, `stream().min()` + Comparator |

---

## 동시성 처리

```java
// ConcurrentHashMap: 배정 세션 내 스레드 안전 캐시
phoneUserCache = new ConcurrentHashMap<>();

// Map.compute(): AtomicInteger 없이 안전한 카운트 업데이트
userLoadMap.compute(assignee.getId(), (k, v) -> v == null ? 1 : v + 1);
```

**ConcurrentHashMap을 선택한 이유**:
- 스케줄러는 단일 스레드에서 실행되지만, `phoneUserCache`가 여러 서비스 메서드에서 공유됨
- HashMap보다 안전하고, 세션 단위(메서드 실행 단위)로 생성·정리되어 메모리 누수 없음

**Map.compute()를 선택한 이유**:
- `map.get(k) + 1; map.put(k, newValue)` 패턴보다 원자적
- 키가 없을 때(`null`)와 있을 때를 람다 하나로 처리

---

## 실시간 알림 파이프라인

```
Redis Pub/Sub → RedisMessageSubscriber → onMessage()
                                              │
                                              ▼
                              SimpMessagingTemplate.convertAndSend()
                                              │
                                              ▼
                              담당자 브라우저 WebSocket 수신
```

Redis를 중간에 둔 이유:
- 스케줄러가 실행된 서버와 담당자가 WebSocket으로 연결된 서버가 다를 수 있음
- Redis Pub/Sub으로 모든 서버에 브로드캐스트 → 각 서버가 자신의 클라이언트에게 전달

---

## 결과

- 수동 배정 시간 제거 (운영자 개입 불필요)
- 담당자별 처리 수 ±1 이내 균등 유지
- 고객 재요청 시 기존 담당자 배정률 향상
- 멀티 서버 환경에서도 중복 배정 없음

---

## 참고

- [[architecture/cqrs-hybrid-orm-linkwave|CQRS 하이브리드 ORM 전략]]
- [[spring/spring-transaction-distributed-lock-redis|Redis 분산락]]
