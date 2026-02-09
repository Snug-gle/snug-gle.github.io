---
created: 2025-12-03
---
# Iotree LinkWave - 백엔드 설계

## 1. 개요

### 1.1 목적
문자 발송 요청을 접수하고 데이터베이스에 저장하는 백엔드 API 서버

**LinkWave**는 다양한 메시지 채널(SMS → LMS → MMS → RCS → 카카오톡 → 푸시)의 확장성을 표현하며,
메시지가 파도처럼 연결되어 전파되는 의미를 담고 있습니다.

### 1.2 기술 스택

**Core Framework**
- Spring Boot 4.0.0 (GA: 2025년 11월)
- Java 21 (LTS)
- Gradle 8.5+ (Kotlin DSL)

**Database**
- MySQL 8.0+ (기본)
- JPA/Hibernate
- 향후 확장: Oracle, PostgreSQL

**Security**
- Spring Security
- JWT 인증

**Additional Libraries**
- Lombok
- MapStruct (DTO 매핑)
- Apache Commons (유틸리티)

**Testing**
- JUnit 5
- Mockito
- TestContainers
- RestAssured

**Monitoring & Logging**
- SLF4J + Logback
- Spring Actuator
- (추천) Micrometer (메트릭 수집)
- (추천) Spring AOP (로깅/감사)

---

## 2. 시스템 아키텍처

### 2.1 레이어 구조

```
┌─────────────────────────────────────┐
│      Presentation Layer             │
│    (REST API Controllers)           │
└─────────────────────────────────────┘
              ↓
┌─────────────────────────────────────┐
│      Service Layer                  │
│    (Business Logic)                 │
└─────────────────────────────────────┘
              ↓
┌─────────────────────────────────────┐
│      Repository Layer               │
│    (Data Access)                    │
└─────────────────────────────────────┘
              ↓
┌─────────────────────────────────────┐
│      Database Layer                 │
│    (Web DB / Message DB)            │
└─────────────────────────────────────┘
```

### 2.2 데이터베이스 분리 전략

**Web DB (웹 서비스용)**
- 사용자 인터페이스 및 부가 기능 지원
- 빈번한 읽기/쓰기, 사용자 경험 최적화
- 테이블: 주소록, 발신번호, 보관함, 공유 주소록, 고객 리스트

**Message DB (발송용)**
- 메시지 발송 처리 및 이력 관리
- 대용량 처리, 발송 성능 최적화
- 테이블: ums_msg, ums_log_{YYYYMM}

**데이터 동기화 모듈**
- Web DB → Message DB 데이터 전송
- TRAFFIC_TYPE에 따른 우선순위 처리

---

## 3. 프로젝트 구조

```
src/main/java/io/iotree/linkwave/
├── config/
│   ├── DatabaseConfig.java
│   ├── SecurityConfig.java
│   ├── WebConfig.java
│   └── AsyncConfig.java
├── api/
│   ├── MessageController.java
│   ├── StatisticsController.java
│   ├── SenderNumberController.java
│   ├── AddressBookController.java
│   └── UserController.java
├── dto/
│   ├── request/
│   │   ├── MessageRequestDto.java
│   │   ├── SmsRequestDto.java
│   │   ├── LmsRequestDto.java
│   │   ├── MmsRequestDto.java
│   │   └── RecipientDto.java
│   └── response/
│       ├── MessageResponseDto.java
│       ├── MessageStatusDto.java
│       └── StatisticsDto.java
├── entity/
│   ├── webdb/
│   │   ├── User.java
│   │   ├── Company.java
│   │   ├── SenderNumber.java
│   │   ├── PersonalAddressBook.java
│   │   ├── SharedAddressBook.java
│   │   ├── MessageStorage.java
│   │   └── MessageFile.java
│   └── messagedb/
│       ├── UmsMsg.java
│       └── UmsLog.java
├── repository/
│   ├── webdb/
│   │   ├── UserRepository.java
│   │   ├── CompanyRepository.java
│   │   ├── SenderNumberRepository.java
│   │   └── AddressBookRepository.java
│   └── messagedb/
│       ├── UmsMsgRepository.java
│       └── UmsLogRepository.java
├── service/
│   ├── MessageService.java
│   ├── MessageSyncService.java
│   ├── DedupService.java
│   ├── StatisticsService.java
│   ├── FileStorageService.java
│   ├── AddressBookService.java
│   └── UserService.java
├── exception/
│   ├── MessageException.java
│   ├── DuplicateMessageException.java
│   └── GlobalExceptionHandler.java
└── util/
    ├── ClientKeyGenerator.java
    ├── HashUtil.java
    └── DateTimeUtil.java
```

---

## 4. REST API 설계

### 4.1 인증

**Base URL**: `/api/v1`

**인증 방식**: JWT Token
```
Authorization: Bearer {token}
```

### 4.2 메시지 발송 API

#### 4.2.1 메시지 발송 요청

```
POST /api/v1/messages

Request Body:
{
  "messageType": "SMS|LMS|MMS",
  "senderNumber": "0212345678",
  "recipients": [
    {
      "phone": "01012345678",
      "name": "홍길동",
      "variables": {
        "이름": "홍길동",
        "회사명": "ABC회사"
      }
    }
  ],
  "content": "메시지 내용",
  "title": "메시지 제목",  // LMS, MMS only
  "scheduledAt": "2025-12-03T10:00:00",  // optional
  "trafficType": "normal|real|batch",    // optional
  "dedupEnabled": true,                   // optional
  "dedupWindowMinutes": 10,               // optional
  "files": [  // MMS only
    {
      "fileName": "image.jpg",
      "fileSize": 123456,
      "fileData": "base64_encoded_data"
    }
  ]
}

Response:
{
  "clientKey": "20251202143000_CompanyA_A3F8D2",
  "status": "ACCEPTED",
  "trafficType": "normal",
  "requestedAt": "2025-12-02T14:30:00",
  "recipientCount": 2,
  "estimatedCost": 40.0
}
```

#### 4.2.2 메시지 상세 조회

```
GET /api/v1/messages/{clientKey}

Response:
{
  "clientKey": "20251202143000_CompanyA_A3F8D2",
  "messageType": "SMS",
  "content": "메시지 내용",
  "status": "ready|request|complete",
  "requestedAt": "2025-12-02T14:30:00",
  "sentAt": "2025-12-02T14:30:15",
  "recipients": [
    {
      "phone": "01012345678",
      "name": "홍길동",
      "status": "ready",
      "sentAt": null
    }
  ]
}
```

#### 4.2.3 메시지 목록 조회

```
GET /api/v1/messages?page=0&size=20&status=ready&startDate=2025-12-01&endDate=2025-12-02

Response:
{
  "content": [
    {
      "clientKey": "20251202143000_CompanyA_A3F8D2",
      "messageType": "SMS",
      "recipientCount": 2,
      "status": "ready",
      "requestedAt": "2025-12-02T14:30:00"
    }
  ],
  "totalElements": 100,
  "totalPages": 5,
  "currentPage": 0,
  "size": 20
}
```

#### 4.2.4 예약 발송 취소

```
DELETE /api/v1/messages/{clientKey}/schedule

Response: 204 No Content
```

### 4.3 통계 API

#### 4.3.1 발송 통계 조회

```
GET /api/v1/statistics/summary?startDate=2025-12-01&endDate=2025-12-02

Response:
{
  "period": {
    "startDate": "2025-12-01",
    "endDate": "2025-12-02"
  },
  "totalCount": 1234,
  "byStatus": {
    "ready": 100,
    "request": 50,
    "complete": 1084
  },
  "byType": {
    "SMS": 800,
    "LMS": 300,
    "MMS": 134
  },
  "totalCost": 246800.0
}
```

### 4.4 주소록 API

#### 4.4.1 개인 주소록 조회

```
GET /api/v1/address-book?page=0&size=20&groupName=친구

Response:
{
  "content": [
    {
      "addressId": 1,
      "groupName": "친구",
      "name": "홍길동",
      "phone": "01012345678",
      "email": "hong@example.com",
      "memo": "동기"
    }
  ],
  "totalElements": 50,
  "totalPages": 3
}
```

#### 4.4.2 주소록 등록

```
POST /api/v1/address-book

Request:
{
  "groupName": "친구",
  "name": "홍길동",
  "phone": "01012345678",
  "email": "hong@example.com",
  "memo": "동기"
}

Response: 201 Created
{
  "addressId": 1,
  "groupName": "친구",
  "name": "홍길동",
  "phone": "01012345678"
}
```

### 4.5 발신번호 API

#### 4.5.1 발신번호 목록 조회

```
GET /api/v1/sender-numbers

Response:
{
  "senderNumbers": [
    {
      "senderNumberId": 1,
      "senderNumber": "0212345678",
      "isVerified": true,
      "isDefault": true,
      "createdAt": "2025-12-01T10:00:00"
    }
  ]
}
```

---

## 5. 데이터베이스 설계

### 5.1 Web DB 테이블

#### 5.1.1 companies (회사)

```sql
CREATE TABLE companies (
    company_id VARCHAR(50) PRIMARY KEY,
    company_name VARCHAR(100) NOT NULL,
    business_number VARCHAR(20) UNIQUE,
    contact_email VARCHAR(100),
    contact_phone VARCHAR(20),
    status VARCHAR(20) NOT NULL DEFAULT 'ACTIVE',
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_status (status)
);
```

#### 5.1.2 users (사용자)

```sql
CREATE TABLE users (
    user_id VARCHAR(50) PRIMARY KEY,
    company_id VARCHAR(50) NOT NULL,
    username VARCHAR(50) NOT NULL UNIQUE,
    password VARCHAR(255) NOT NULL,
    email VARCHAR(100),
    phone VARCHAR(20),
    role VARCHAR(20) NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'ACTIVE',
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (company_id) REFERENCES companies(company_id),
    INDEX idx_company_id (company_id),
    INDEX idx_username (username)
);
```

#### 5.1.3 sender_numbers (발신번호)

```sql
CREATE TABLE sender_numbers (
    sender_number_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    user_id VARCHAR(50) NOT NULL,
    sender_number VARCHAR(16) NOT NULL,
    is_verified BOOLEAN DEFAULT FALSE,
    is_default BOOLEAN DEFAULT FALSE,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(user_id),
    UNIQUE KEY uk_user_sender (user_id, sender_number),
    INDEX idx_user_id (user_id)
);
```

#### 5.1.4 personal_address_book (개인 주소록)

```sql
CREATE TABLE personal_address_book (
    address_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    user_id VARCHAR(50) NOT NULL,
    group_name VARCHAR(100),
    name VARCHAR(100) NOT NULL,
    phone VARCHAR(20) NOT NULL,
    email VARCHAR(100),
    memo TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(user_id),
    INDEX idx_user_id (user_id),
    INDEX idx_group_name (group_name)
);
```

#### 5.1.5 shared_address_book (공유 주소록)

```sql
CREATE TABLE shared_address_book (
    shared_address_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    company_id VARCHAR(50) NOT NULL,
    group_name VARCHAR(100),
    name VARCHAR(100) NOT NULL,
    phone VARCHAR(20) NOT NULL,
    email VARCHAR(100),
    department VARCHAR(100),
    memo TEXT,
    created_by VARCHAR(50) NOT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (company_id) REFERENCES companies(company_id),
    FOREIGN KEY (created_by) REFERENCES users(user_id),
    INDEX idx_company_id (company_id),
    INDEX idx_group_name (group_name)
);
```

#### 5.1.6 message_storage (문자 보관함)

```sql
CREATE TABLE message_storage (
    storage_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    user_id VARCHAR(50) NOT NULL,
    folder_name VARCHAR(50) DEFAULT 'default',
    message_type VARCHAR(10) NOT NULL,
    title VARCHAR(100),
    content TEXT NOT NULL,
    is_template BOOLEAN DEFAULT FALSE,
    template_name VARCHAR(100),
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(user_id),
    INDEX idx_user_id (user_id),
    INDEX idx_folder_name (folder_name),
    INDEX idx_is_template (is_template)
);
```

#### 5.1.7 message_files (첨부파일)

```sql
CREATE TABLE message_files (
    file_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    client_key VARCHAR(40),
    user_id VARCHAR(50) NOT NULL,
    file_name VARCHAR(255) NOT NULL,
    file_path VARCHAR(500) NOT NULL,
    file_url VARCHAR(500),
    file_size BIGINT NOT NULL,
    file_type VARCHAR(50) NOT NULL,
    file_category VARCHAR(20),
    storage_type VARCHAR(20) DEFAULT 'LOCAL',
    is_deleted BOOLEAN DEFAULT FALSE,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    deleted_at DATETIME NULL,
    FOREIGN KEY (user_id) REFERENCES users(user_id),
    INDEX idx_client_key (client_key),
    INDEX idx_user_id (user_id)
);
```

#### 5.1.8 audit_logs (감사 로그)

```sql
CREATE TABLE audit_logs (
    log_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    user_id VARCHAR(50) NOT NULL,
    company_id VARCHAR(50) NOT NULL,
    action_type VARCHAR(50) NOT NULL,
    action_detail TEXT,
    ip_address VARCHAR(45),
    user_agent VARCHAR(255),
    request_url VARCHAR(500),
    request_method VARCHAR(10),
    response_status INT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(user_id),
    FOREIGN KEY (company_id) REFERENCES companies(company_id),
    INDEX idx_user_id (user_id),
    INDEX idx_action_type (action_type),
    INDEX idx_created_at (created_at)
);
```

#### 5.1.9 sync_queue (동기화 큐)

```sql
CREATE TABLE sync_queue (
    queue_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    client_key VARCHAR(40) NOT NULL,
    sync_status VARCHAR(20) NOT NULL DEFAULT 'PENDING',
    sync_type VARCHAR(20) NOT NULL,
    payload TEXT NOT NULL,
    retry_count INT DEFAULT 0,
    max_retry INT DEFAULT 3,
    error_message TEXT,
    next_retry_at DATETIME,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    synced_at DATETIME NULL,
    INDEX idx_sync_status (sync_status),
    INDEX idx_next_retry_at (next_retry_at)
);
```

### 5.2 Message DB 테이블

#### 5.2.1 ums_msg (발송 요청)

```sql
CREATE TABLE ums_msg (
    -- 기본 정보
    CLIENT_KEY VARCHAR(40) PRIMARY KEY COMMENT '메시지 고유 번호',
    REQ_CH VARCHAR(10) NOT NULL COMMENT '발송 채널: SMS, LMS, MMS',
    TRAFFIC_TYPE VARCHAR(10) DEFAULT 'normal' COMMENT 'real/normal/batch',
    MSG_STATUS VARCHAR(10) NOT NULL COMMENT 'ready/request/complete',
    REQ_DATE DATETIME NOT NULL COMMENT '발송 요청 시간',

    -- 발신 정보
    CALLBACK_NUMBER VARCHAR(16) NOT NULL COMMENT '발신번호',
    KISA_ORIGCODE VARCHAR(20) COMMENT 'KISA 최초 발신사업자 구분 코드',
    CAMPAIGN_ID VARCHAR(20) COMMENT '캠페인 ID',
    DEPT_CODE VARCHAR(20) COMMENT '부서코드',

    -- 수신 정보
    PHONE VARCHAR(16) COMMENT '수신번호',

    -- 메시지 내용
    MSG VARCHAR(2000) COMMENT '메시지 내용',
    TITLE VARCHAR(100) COMMENT '제목 (LMS/MMS)',
    TEMPLATE_CODE VARCHAR(20) COMMENT '템플릿 키',
    MERGE_DATA VARCHAR(2000) COMMENT '가변 데이터 (JSON)',
    MMS_FILE_LIST VARCHAR(600) COMMENT 'MMS 파일 (최대 3개)',

    -- 중복 발송 방지
    DEDUP_HASH VARCHAR(64) COMMENT '중복 체크용 해시',

    -- 예비 필드
    ETC1 VARCHAR(50),
    ETC2 VARCHAR(50),
    ETC3 VARCHAR(50),
    ETC4 VARCHAR(50),
    ETC5 VARCHAR(50),
    ETC6 VARCHAR(50),

    -- 인덱스
    INDEX idx_msg_status (MSG_STATUS),
    INDEX idx_traffic_type (TRAFFIC_TYPE),
    INDEX idx_req_date (REQ_DATE),
    INDEX idx_phone (PHONE),
    INDEX idx_dedup_hash (DEDUP_HASH),
    INDEX idx_campaign_id (CAMPAIGN_ID)
) COMMENT='메시지 발송 요청 테이블';
```

#### 5.2.2 ums_log_{YYYYMM} (월별 발송 이력)

```sql
CREATE TABLE ums_log_202512 (
    log_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    CLIENT_KEY VARCHAR(40) NOT NULL,
    REQ_CH VARCHAR(10) NOT NULL,
    PHONE VARCHAR(16) NOT NULL,
    MSG_STATUS VARCHAR(10) NOT NULL,
    DONE_DATE DATETIME,
    DONE_CODE VARCHAR(10),
    DONE_CODE_DESC VARCHAR(200),
    SUCCESS_YN VARCHAR(1),
    FAIL_REASON VARCHAR(100),
    COST DECIMAL(10, 2),
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,

    INDEX idx_client_key (CLIENT_KEY),
    INDEX idx_phone (PHONE),
    INDEX idx_done_date (DONE_DATE),
    INDEX idx_success_yn (SUCCESS_YN)
) COMMENT='메시지 발송 이력';
```

---

## 6. 핵심 비즈니스 로직

### 6.1 메시지 발송 플로우

```java
@Service
@RequiredArgsConstructor
public class MessageService {

    private final MessageSyncService messageSyncService;
    private final DedupService dedupService;
    private final SenderNumberRepository senderNumberRepository;

    @Transactional
    public MessageResponseDto sendMessage(MessageRequestDto request, String userId) {
        // 1. 발신번호 검증
        validateSenderNumber(request.getSenderNumber(), userId);

        // 2. 내용 검증
        validateMessageContent(request);

        // 3. 중복 발송 체크
        if (request.isDedupEnabled()) {
            checkDuplicates(request);
        }

        // 4. TRAFFIC_TYPE 결정
        String trafficType = determineTrafficType(request);

        // 5. 파일 업로드 (MMS)
        List<String> fileUrls = uploadFiles(request.getFiles(), userId);

        // 6. Message DB 동기화
        SyncResult syncResult = messageSyncService.syncToMessageDb(
            request, userId, trafficType, fileUrls);

        // 7. Response 생성
        return MessageResponseDto.builder()
            .clientKey(syncResult.getClientKey())
            .status("ACCEPTED")
            .trafficType(trafficType)
            .requestedAt(LocalDateTime.now())
            .recipientCount(request.getRecipients().size())
            .build();
    }

    private String determineTrafficType(MessageRequestDto request) {
        if (request.getTrafficType() != null) {
            return request.getTrafficType();
        }

        if (request.getScheduledAt() != null &&
            request.getScheduledAt().isAfter(LocalDateTime.now().plusMinutes(10))) {
            return "batch";
        }

        if (request.getRecipients().size() > 100) {
            return "batch";
        }

        return "normal";
    }
}
```

### 6.2 데이터 동기화 모듈

```java
@Service
@RequiredArgsConstructor
public class MessageSyncService {

    private final UmsMsgRepository umsMsgRepository;
    private final SyncQueueRepository syncQueueRepository;
    private final ClientKeyGenerator clientKeyGenerator;

    @Transactional
    public SyncResult syncToMessageDb(MessageRequestDto request,
                                      String userId,
                                      String trafficType,
                                      List<String> fileUrls) {
        try {
            // CLIENT_KEY 생성
            String clientKey = clientKeyGenerator.generate(userId);

            // DEDUP_HASH 생성
            String dedupHash = generateDedupHash(request);

            // UmsMsg 엔티티 생성
            for (RecipientDto recipient : request.getRecipients()) {
                UmsMsg umsMsg = UmsMsg.builder()
                    .clientKey(clientKey)
                    .reqCh(request.getMessageType())
                    .trafficType(trafficType)
                    .msgStatus("ready")
                    .reqDate(request.getScheduledAt() != null ?
                             request.getScheduledAt() : LocalDateTime.now())
                    .callbackNumber(request.getSenderNumber())
                    .phone(recipient.getPhone())
                    .msg(replaceVariables(request.getContent(), recipient.getVariables()))
                    .title(request.getTitle())
                    .dedupHash(dedupHash)
                    .mmsFileList(String.join(",", fileUrls))
                    .build();

                umsMsgRepository.save(umsMsg);
            }

            return SyncResult.success(clientKey);

        } catch (Exception e) {
            // 실패 시 sync_queue에 등록
            registerToSyncQueue(request, userId, e.getMessage());
            throw new SyncFailedException("동기화 실패", e);
        }
    }

    private String replaceVariables(String content, Map<String, String> variables) {
        if (variables == null || variables.isEmpty()) {
            return content;
        }

        String result = content;
        for (Map.Entry<String, String> entry : variables.entrySet()) {
            result = result.replace("#{" + entry.getKey() + "}", entry.getValue());
        }
        return result;
    }
}
```

### 6.3 중복 발송 방지

```java
@Service
@RequiredArgsConstructor
public class DedupService {

    private final UmsMsgRepository umsMsgRepository;

    public String generateHash(String phone, String content) {
        String combined = phone + "|" + content;
        return DigestUtils.md5Hex(combined);
    }

    public boolean isDuplicate(String dedupHash, int windowMinutes) {
        LocalDateTime threshold = LocalDateTime.now().minusMinutes(windowMinutes);
        return umsMsgRepository.existsByDedupHashAndReqDateAfter(dedupHash, threshold);
    }
}
```

### 6.4 CLIENT_KEY 생성

```java
@Component
public class ClientKeyGenerator {

    public String generate(String userId) {
        String datetime = LocalDateTime.now()
            .format(DateTimeFormatter.ofPattern("yyyyMMddHHmmss"));
        String userPrefix = userId.replaceAll("[^a-zA-Z0-9]", "")
            .substring(0, Math.min(10, userId.length()));
        String randomString = RandomStringUtils.randomAlphanumeric(8).toUpperCase();

        return String.format("%s_%s_%s", datetime, userPrefix, randomString);
    }
}
```

---

## 7. 보안

### 7.1 인증/인가

```java
@Configuration
@EnableWebSecurity
public class SecurityConfig {

    @Bean
    public SecurityFilterChain filterChain(HttpSecurity http) throws Exception {
        http
            .csrf(csrf -> csrf.disable())
            .cors(cors -> cors.configurationSource(corsConfigurationSource()))
            .sessionManagement(session ->
                session.sessionCreationPolicy(SessionCreationPolicy.STATELESS))
            .authorizeHttpRequests(auth -> auth
                .requestMatchers("/api/v1/auth/**").permitAll()
                .requestMatchers("/api/v1/admin/**").hasRole("ADMIN")
                .anyRequest().authenticated())
            .addFilterBefore(jwtAuthenticationFilter(),
                UsernamePasswordAuthenticationFilter.class);

        return http.build();
    }
}
```

### 7.2 Rate Limiting

```java
@Component
public class RateLimitInterceptor implements HandlerInterceptor {

    private final LoadingCache<String, AtomicInteger> requestCountsPerUser;

    public RateLimitInterceptor() {
        this.requestCountsPerUser = CacheBuilder.newBuilder()
            .expireAfterWrite(1, TimeUnit.MINUTES)
            .build(new CacheLoader<>() {
                @Override
                public AtomicInteger load(String key) {
                    return new AtomicInteger(0);
                }
            });
    }

    @Override
    public boolean preHandle(HttpServletRequest request,
                            HttpServletResponse response,
                            Object handler) throws Exception {
        String userId = extractUserId(request);
        AtomicInteger count = requestCountsPerUser.get(userId);

        if (count.incrementAndGet() > 100) {
            response.setStatus(HttpStatus.TOO_MANY_REQUESTS.value());
            return false;
        }

        return true;
    }
}
```

---

## 8. 모니터링 및 로깅

### 8.1 로깅 설정

```xml
<!-- logback-spring.xml -->
<configuration>
    <appender name="STDOUT" class="ch.qos.logback.core.ConsoleAppender">
        <encoder>
            <pattern>%d{yyyy-MM-dd HH:mm:ss} [%thread] %-5level %logger{36} - %msg%n</pattern>
        </encoder>
    </appender>

    <appender name="FILE" class="ch.qos.logback.core.rolling.RollingFileAppender">
        <file>logs/quicksend-proto.log</file>
        <rollingPolicy class="ch.qos.logback.core.rolling.TimeBasedRollingPolicy">
            <fileNamePattern>logs/quicksend-proto.%d{yyyy-MM-dd}.log</fileNamePattern>
            <maxHistory>30</maxHistory>
        </rollingPolicy>
        <encoder>
            <pattern>%d{yyyy-MM-dd HH:mm:ss} [%thread] %-5level %logger{36} - %msg%n</pattern>
        </encoder>
    </appender>

    <root level="INFO">
        <appender-ref ref="STDOUT"/>
        <appender-ref ref="FILE"/>
    </root>
</configuration>
```

### 8.2 Actuator 설정

```yaml
management:
  endpoints:
    web:
      exposure:
        include: health,info,metrics,prometheus
  endpoint:
    health:
      show-details: always
  metrics:
    export:
      prometheus:
        enabled: true
```

---

## 9. 테스트 전략

### 9.1 단위 테스트

```java
@ExtendWith(MockitoExtension.class)
class MessageServiceTest {

    @Mock
    private MessageSyncService messageSyncService;

    @Mock
    private DedupService dedupService;

    @InjectMocks
    private MessageService messageService;

    @Test
    @DisplayName("메시지 발송 성공")
    void sendMessage_Success() {
        // given
        MessageRequestDto request = createMessageRequest();
        String userId = "user123";

        when(messageSyncService.syncToMessageDb(any(), any(), any(), any()))
            .thenReturn(SyncResult.success("CLIENT_KEY_123"));

        // when
        MessageResponseDto response = messageService.sendMessage(request, userId);

        // then
        assertThat(response.getClientKey()).isEqualTo("CLIENT_KEY_123");
        assertThat(response.getStatus()).isEqualTo("ACCEPTED");
    }
}
```

### 9.2 통합 테스트

```java
@SpringBootTest
@AutoConfigureMockMvc
@Testcontainers
class MessageControllerIntegrationTest {

    @Container
    static MySQLContainer<?> mysql = new MySQLContainer<>("mysql:8.0");

    @Autowired
    private MockMvc mockMvc;

    @Test
    @DisplayName("메시지 발송 API 통합 테스트")
    void sendMessage_Integration() throws Exception {
        String requestBody = """
            {
              "messageType": "SMS",
              "senderNumber": "0212345678",
              "recipients": [{"phone": "01012345678"}],
              "content": "테스트 메시지"
            }
            """;

        mockMvc.perform(post("/api/v1/messages")
                .contentType(MediaType.APPLICATION_JSON)
                .content(requestBody)
                .header("Authorization", "Bearer test-token"))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.clientKey").exists())
            .andExpect(jsonPath("$.status").value("ACCEPTED"));
    }
}
```

---

## 10. 배포 설정

### 10.1 application.yml

```yaml
spring:
  application:
    name: quicksend-proto

  datasource:
    webdb:
      jdbc-url: ${WEB_DB_URL:jdbc:mysql://localhost:3306/webdb}
      username: ${WEB_DB_USERNAME:root}
      password: ${WEB_DB_PASSWORD:password}
      driver-class-name: com.mysql.cj.jdbc.Driver
    messagedb:
      jdbc-url: ${MESSAGE_DB_URL:jdbc:mysql://localhost:3306/messagedb}
      username: ${MESSAGE_DB_USERNAME:root}
      password: ${MESSAGE_DB_PASSWORD:password}
      driver-class-name: com.mysql.cj.jdbc.Driver

  jpa:
    hibernate:
      ddl-auto: validate
    show-sql: false
    properties:
      hibernate:
        dialect: org.hibernate.dialect.MySQL8Dialect
        format_sql: true

  servlet:
    multipart:
      max-file-size: 10MB
      max-request-size: 10MB

jwt:
  secret: ${JWT_SECRET:your-secret-key-change-in-production}
  expiration: 86400000  # 24 hours

file:
  upload:
    path: ${FILE_UPLOAD_PATH:/var/quicksend/files}
    max-size: 10485760  # 10MB

message:
  dedup:
    default-window-minutes: 10
  traffic:
    batch-threshold: 100
```

### 10.2 build.gradle.kts

```kotlin
plugins {
    java
    id("org.springframework.boot") version "4.0.0"
    id("io.spring.dependency-management") version "1.1.7"
}

group = "io.iotree.linkwave"
version = "0.1.0-SNAPSHOT"

java {
    toolchain {
        languageVersion = JavaLanguageVersion.of(21)
    }
}

configurations {
    compileOnly {
        extendsFrom(configurations.annotationProcessor.get())
    }
}

repositories {
    mavenCentral()
}

dependencies {
    // Spring Boot Starters
    implementation("org.springframework.boot:spring-boot-starter-web")
    implementation("org.springframework.boot:spring-boot-starter-data-jpa")
    implementation("org.springframework.boot:spring-boot-starter-security")
    implementation("org.springframework.boot:spring-boot-starter-validation")
    implementation("org.springframework.boot:spring-boot-starter-actuator")

    // Database
    runtimeOnly("com.mysql:mysql-connector-j:8.2.0")

    // JWT (Java 21 호환)
    implementation("io.jsonwebtoken:jjwt-api:0.12.3")
    runtimeOnly("io.jsonwebtoken:jjwt-impl:0.12.3")
    runtimeOnly("io.jsonwebtoken:jjwt-jackson:0.12.3")

    // Utilities
    compileOnly("org.projectlombok:lombok:1.18.30")  // Java 21 호환
    annotationProcessor("org.projectlombok:lombok:1.18.30")
    implementation("org.apache.commons:commons-lang3")
    implementation("commons-codec:commons-codec:1.16.0")

    // Monitoring
    runtimeOnly("io.micrometer:micrometer-registry-prometheus")

    // SpringDoc (Springfox 대체)
    implementation("org.springdoc:springdoc-openapi-starter-webmvc-ui:2.3.0")

    // Testing
    testImplementation("org.springframework.boot:spring-boot-starter-test")
    testImplementation("org.springframework.security:spring-security-test")
    testImplementation("org.testcontainers:mysql:1.19.3")
    testImplementation("io.rest-assured:rest-assured:5.4.0")

    // JUnit Platform (Java 21 호환)
    testRuntimeOnly("org.junit.platform:junit-platform-launcher")
}

tasks.withType<Test> {
    useJUnitPlatform()
}

// Virtual Threads 지원 (Java 21)
tasks.withType<JavaCompile> {
    options.compilerArgs.add("-parameters")
}
```

---

## 11. 향후 확장 고려사항

### 11.1 캐싱 전략

**Redis 도입 (추천)**
- 발신번호 목록 캐싱
- 주소록 그룹 캐싱
- 통계 데이터 캐싱
- Rate Limiting

### 11.2 비동기 처리

**Spring Async (추천)**
- 대량 발송 비동기 처리
- 파일 업로드 비동기 처리
- 통계 생성 비동기 처리

### 11.3 파일 저장소

**S3/MinIO (추천)**
- 첨부파일 클라우드 저장
- CDN 연동

### 11.4 데이터베이스 확장

**읽기 복제본 (추천)**
- Master/Slave 구성
- 통계 조회 성능 향상

**Connection Pool 최적화 (추천)**
- HikariCP 설정 튜닝

---

## 부록: 기술 의사결정

### A.1 Spring Boot 4.0 선택 이유
- 최신 Spring 생태계 지원
- Java 17+ 지원
- 향상된 성능 및 보안

### A.2 JPA/Hibernate 선택 이유
- 다중 데이터베이스 지원 용이
- 객체 지향적 개발
- Spring Boot와의 강력한 통합

### A.3 JWT 인증 선택 이유
- Stateless 아키텍처
- 확장성 (수평 확장 용이)
- 모바일 앱 지원 고려

### A.4 DB 분리 전략
- 성능 최적화
- 부하 분산
- 장애 격리
- 확장성
