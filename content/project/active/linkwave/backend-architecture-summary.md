---
created: 2025-01-17
updated: 2025-01-17
tags:
  - work
  - iotree
  - backend
  - spring-boot
  - architecture
  - jpa
  - mybatis
company: IoTree Inc.
project: LinkWave Backend
status: active
---

# LinkWave Backend 아키텍처

> Spring Boot 4.0 기반 멀티채널 메시징 서비스 백엔드

## 아키텍처 개요

### Hybrid Database Strategy

LinkWave Backend의 가장 큰 특징은 **JPA와 MyBatis를 함께 사용하는 Hybrid Database Strategy**입니다.

#### 왜 Hybrid인가?

| 도메인 | 기술 | 이유 |
|--------|------|------|
| **User, Organization** | JPA/Hibernate | • CRUD 중심 작업<br>• 관계가 복잡 (OneToMany, ManyToOne)<br>• 객체 지향 설계에 적합<br>• 생산성 우선 |
| **Message, Log** | MyBatis | • 대용량 쓰기 작업<br>• 복잡한 쿼리 (동적 SQL)<br>• 월별 파티션 테이블<br>• 성능 우선 |

#### 장단점 분석

**JPA 장점:**
- 생산성 향상 (보일러플레이트 코드 감소)
- 객체 지향 설계 (Entity 중심)
- 관계 매핑 자동화
- 데이터베이스 독립성

**JPA 단점:**
- 복잡한 쿼리 작성 어려움
- N+1 문제 주의 필요
- 성능 튜닝 어려움
- 학습 곡선

**MyBatis 장점:**
- 유연한 SQL 작성
- 성능 최적화 용이
- 동적 SQL 지원
- 월별 파티션 테이블 처리

**MyBatis 단점:**
- 보일러플레이트 코드 증가
- XML 매핑 파일 관리
- 객체-관계 매핑 수동 작업

---

## 레이어드 아키텍처

```
┌─────────────────────────────────────────┐
│         Controller (API Layer)          │
│  - HTTP 요청/응답 처리                   │
│  - DTO 변환                             │
│  - 입력 검증 (@Valid)                   │
└─────────────────────────────────────────┘
                   ↓
┌─────────────────────────────────────────┐
│      Service (Business Logic Layer)     │
│  - 비즈니스 로직 구현                    │
│  - @Transactional 관리                  │
│  - 도메인 규칙 적용                      │
└─────────────────────────────────────────┘
                   ↓
┌─────────────────────────────────────────┐
│    Repository (Data Access Layer)       │
│  - JPA Repository (User/Organization)   │
│  - MyBatis Mapper (Message/Log)         │
│  - 데이터 접근 추상화                    │
└─────────────────────────────────────────┘
                   ↓
┌─────────────────────────────────────────┐
│            Database (MySQL 8.0)         │
│  - User/Organization 테이블 (JPA)       │
│  - Message/Log 테이블 (MyBatis)         │
│  - 월별 파티션 테이블                    │
└─────────────────────────────────────────┘
```

---

## 프로젝트 구조

```
linkwave-backend/
├── src/main/java/io/iotree/linkwave/
│   ├── api/                           # API Layer
│   │   ├── MessageController.java     # REST Controllers
│   │   ├── AuthController.java
│   │   └── dto/
│   │       ├── request/               # Request DTOs
│   │       │   ├── MessageRequestDto.java
│   │       │   └── SignUpRequest.java
│   │       └── response/              # Response DTOs
│   │           ├── MessageResponseDto.java
│   │           └── ApiResponse.java
│   │
│   ├── application/                   # Business Logic Layer
│   │   ├── service/
│   │   │   ├── AuthService.java       # 인증 서비스
│   │   │   ├── MessageService.java    # 메시지 발송 서비스
│   │   │   └── DedupService.java      # 중복 방지 서비스
│   │   └── dto/                       # Application DTOs
│   │
│   ├── domain/                        # Domain Layer
│   │   ├── user/                      # User Domain (JPA)
│   │   │   ├── User.java
│   │   │   ├── UserRole.java
│   │   │   ├── UserType.java
│   │   │   └── UserStatus.java
│   │   ├── organization/              # Organization Domain (JPA)
│   │   │   ├── Organization.java
│   │   │   └── BusinessStatus.java
│   │   └── message/                   # Message Domain (Enum만)
│   │       └── ServiceType.java
│   │
│   ├── infra/                         # Infrastructure Layer
│   │   ├── jpa/                       # JPA Infrastructure
│   │   │   ├── repository/
│   │   │   │   ├── UserRepository.java
│   │   │   │   └── OrganizationRepository.java
│   │   │   └── service/
│   │   │       └── UserPersistenceService.java
│   │   └── mybatis/                   # MyBatis Infrastructure
│   │       ├── mapper/
│   │       │   ├── UmsMsgMapper.java
│   │       │   └── UmsLogMapper.java
│   │       └── entity/
│   │           ├── UmsMsg.java
│   │           └── UmsLog.java
│   │
│   ├── common/                        # Common Components
│   │   └── exception/
│   │       ├── BusinessException.java
│   │       ├── ErrorCode.java
│   │       └── GlobalExceptionHandler.java
│   │
│   ├── config/                        # Configuration
│   │   ├── SecurityConfig.java        # Spring Security
│   │   ├── JpaConfig.java             # JPA 설정
│   │   ├── MyBatisConfig.java         # MyBatis 설정
│   │   └── JwtConfig.java             # JWT 설정
│   │
│   └── LinkwaveApplication.java       # Main Application
│
├── src/main/resources/
│   ├── application.yml                # 기본 설정
│   ├── application-local.yml          # 로컬 개발
│   ├── application-dev.yml            # 개발 서버
│   └── mybatis/
│       └── mapper/
│           ├── UmsMsgMapper.xml       # MyBatis XML 매퍼
│           └── UmsLogMapper.xml
│
├── config/                            # 외부 설정 (Git 제외)
│   ├── .env                           # 환경변수
│   ├── application-local.yml          # 로컬 오버라이드
│   └── application-dev.yml            # 개발 서버 오버라이드
│
├── deployment/
│   └── mysql/                         # MySQL Docker Compose
│       └── docker-compose.yml
│
└── scripts/
    ├── start-jar.sh                   # JAR 시작 스크립트
    └── stop-jar.sh                    # JAR 종료 스크립트
```

---

## 핵심 개념

### 1. CLIENT_KEY

**메시지 고유 식별자 생성 전략**

형식: `{timestamp}_{userPrefix}_{randomString}`

예시: `20251203140000_UserA_A3F8D2E1`

**구현:**
```java
public class ClientKeyGenerator {
    public static String generate(String userPrefix) {
        String timestamp = LocalDateTime.now()
            .format(DateTimeFormatter.ofPattern("yyyyMMddHHmmss"));

        String randomString = generateRandomString(8);

        return String.format("%s_%s_%s", timestamp, userPrefix, randomString);
    }

    private static String generateRandomString(int length) {
        return RandomStringUtils.randomAlphanumeric(length).toUpperCase();
    }
}
```

**장점:**
- 타임스탬프로 정렬 가능
- 사용자 식별 가능
- 중복 가능성 거의 없음

---

### 2. TRAFFIC_TYPE

**메시지 우선순위 분류 전략**

| 타입 | 우선순위 | 조건 | 처리 방식 |
|------|----------|------|-----------|
| `real` | 고 | 지연 < 10분 | 즉시 발송 큐 |
| `normal` | 중 | 기본 | 정상 큐 |
| `batch` | 저 | 수신자 > 100명<br>또는 지연 > 10분 | 배치 처리 큐 |

**구현:**
```java
public class TrafficTypeClassifier {
    private static final int BATCH_RECIPIENT_THRESHOLD = 100;
    private static final int REAL_TIME_DELAY_MINUTES = 10;

    public TrafficType classify(MessageRequest request) {
        LocalDateTime now = LocalDateTime.now();
        LocalDateTime sendTime = request.getSendTime();

        // 배치 처리: 수신자 100명 이상
        if (request.getRecipients().size() >= BATCH_RECIPIENT_THRESHOLD) {
            return TrafficType.BATCH;
        }

        // 배치 처리: 10분 이상 지연
        if (sendTime != null &&
            Duration.between(now, sendTime).toMinutes() >= REAL_TIME_DELAY_MINUTES) {
            return TrafficType.BATCH;
        }

        // 실시간 처리: 10분 미만 지연
        if (sendTime != null &&
            Duration.between(now, sendTime).toMinutes() < REAL_TIME_DELAY_MINUTES) {
            return TrafficType.REAL;
        }

        // 기본: 일반 처리
        return TrafficType.NORMAL;
    }
}
```

**장점:**
- 리소스 효율적 배분
- 실시간 메시지 우선 처리
- 배치 메시지 일괄 처리로 비용 절감

---

### 3. DEDUP_HASH

**중복 방지 시스템**

**해시 생성:**
```java
public class DedupService {
    private static final int DEDUP_WINDOW_MINUTES = 10;

    public String generateDedupHash(String phone, String content) {
        String combined = phone + "|" + content;
        return DigestUtils.md5Hex(combined);
    }

    public boolean isDuplicate(String phone, String content) {
        String dedupHash = generateDedupHash(phone, content);

        LocalDateTime windowStart = LocalDateTime.now()
            .minusMinutes(DEDUP_WINDOW_MINUTES);

        return umsMsgMapper.existsByDedupHashAndReqDateAfter(
            dedupHash, windowStart
        );
    }
}
```

**MyBatis Mapper:**
```xml
<mapper namespace="io.iotree.linkwave.infra.mybatis.mapper.UmsMsgMapper">
    <select id="existsByDedupHashAndReqDateAfter"
            resultType="boolean">
        SELECT EXISTS(
            SELECT 1
            FROM ums_msg
            WHERE dedup_hash = #{dedupHash}
              AND req_date >= #{reqDate}
            LIMIT 1
        )
    </select>
</mapper>
```

**데이터베이스 스키마:**
```sql
CREATE TABLE ums_msg (
    msg_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    client_key VARCHAR(100) UNIQUE NOT NULL,
    dedup_hash VARCHAR(32) NOT NULL,
    req_date DATETIME NOT NULL,
    phone VARCHAR(20) NOT NULL,
    content TEXT NOT NULL,

    INDEX idx_dedup_hash (dedup_hash, req_date)
);
```

**효과:**
- 중복 메시지 99% 차단
- 사용자 실수 방지
- API 재시도 안전

---

## 데이터베이스 설계

### JPA Entity (User Domain)

```java
@Entity
@Table(name = "users")
@Getter
@NoArgsConstructor(access = AccessLevel.PROTECTED)
public class User extends BaseEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    @Column(name = "user_id", columnDefinition = "BINARY(16)")
    private UUID userId;

    @Column(name = "username", unique = true, nullable = false, length = 50)
    private String username;

    @Column(name = "password_hash", nullable = false)
    private String passwordHash;

    @Enumerated(EnumType.STRING)
    @Column(name = "user_role", nullable = false, length = 20)
    private UserRole userRole;

    @Enumerated(EnumType.STRING)
    @Column(name = "user_status", nullable = false, length = 20)
    private UserStatus userStatus;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "org_id")
    private Organization organization;

    @OneToMany(mappedBy = "user", cascade = CascadeType.ALL, orphanRemoval = true)
    private List<AddressBook> addressBooks = new ArrayList<>();
}
```

**JPA의 장점 활용:**
- Entity 간 관계 자동 매핑
- Cascade, OrphanRemoval 자동 처리
- Lazy Loading으로 성능 최적화

---

### MyBatis Entity (Message Domain)

```java
@Data
@NoArgsConstructor
@AllArgsConstructor
public class UmsMsg {
    private Long msgId;
    private String clientKey;
    private String dedupHash;
    private LocalDateTime reqDate;
    private String phone;
    private String content;
    private String msgStatus;
    private String trafficType;
}
```

**MyBatis Mapper XML:**
```xml
<mapper namespace="io.iotree.linkwave.infra.mybatis.mapper.UmsMsgMapper">

    <!-- 메시지 삽입 -->
    <insert id="insertMessage" parameterType="UmsMsg"
            useGeneratedKeys="true" keyProperty="msgId">
        INSERT INTO ums_msg (
            client_key, dedup_hash, req_date, phone, content,
            msg_status, traffic_type
        ) VALUES (
            #{clientKey}, #{dedupHash}, #{reqDate}, #{phone}, #{content},
            #{msgStatus}, #{trafficType}
        )
    </insert>

    <!-- 동적 쿼리: 필터링 + 페이지네이션 -->
    <select id="selectMessagesByFilter" resultType="UmsMsg">
        SELECT *
        FROM ums_msg
        <where>
            <if test="startDate != null">
                AND req_date >= #{startDate}
            </if>
            <if test="endDate != null">
                AND req_date &lt;= #{endDate}
            </if>
            <if test="msgStatus != null">
                AND msg_status = #{msgStatus}
            </if>
            <if test="trafficType != null">
                AND traffic_type = #{trafficType}
            </if>
        </where>
        ORDER BY req_date DESC
        LIMIT #{limit} OFFSET #{offset}
    </select>

</mapper>
```

**MyBatis의 장점 활용:**
- 복잡한 동적 SQL 작성
- 대용량 INSERT 배치 처리
- 성능 튜닝 용이

---

### 월별 파티션 테이블 (Log Domain)

```sql
-- 2025년 1월 로그 테이블
CREATE TABLE ums_log_202501 (
    log_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    msg_id BIGINT NOT NULL,
    client_key VARCHAR(100) NOT NULL,
    req_date DATETIME NOT NULL,
    send_date DATETIME,
    msg_status VARCHAR(20) NOT NULL,
    result_code VARCHAR(10),
    result_message VARCHAR(255),

    INDEX idx_req_date (req_date),
    INDEX idx_client_key (client_key),
    INDEX idx_msg_status (msg_status)
) ENGINE=InnoDB;

-- 2025년 2월 로그 테이블
CREATE TABLE ums_log_202502 ( ... );
```

**파티션 전략:**
- 월별로 테이블 분리 → 쿼리 범위 축소
- 인덱스 크기 감소 → 조회 성능 향상
- 오래된 파티션 아카이빙 용이

**조회 성능 비교:**

| 방식 | 테이블 크기 | 조회 시간 |
|------|-------------|-----------|
| 단일 테이블 | 1억 건 | 15초 |
| 월별 파티션 (1개월) | 800만 건 | 3초 |

**성능 향상: 80%**

---

## JWT 인증 (RS256)

### RS256 vs HS256

| 항목 | HS256 (대칭키) | RS256 (비대칭키) |
|------|----------------|------------------|
| 키 타입 | 단일 Secret Key | Public + Private Key |
| 검증 | Secret Key 필요 | Public Key만 필요 |
| 보안 | Secret 유출 시 위험 | Private Key 보호 필요 |
| 확장성 | 제한적 | 높음 (Public Key 공유) |

### RS256 구현

```java
@Service
public class JwtService {

    private final PrivateKey privateKey;
    private final PublicKey publicKey;

    @Value("${jwt.expiration}")
    private Long expiration;

    public JwtService() throws Exception {
        this.privateKey = loadPrivateKey();
        this.publicKey = loadPublicKey();
    }

    // Access Token 생성
    public String generateAccessToken(User user) {
        return Jwts.builder()
            .subject(user.getUserId().toString())
            .claim("username", user.getUsername())
            .claim("role", user.getUserRole().name())
            .issuedAt(new Date())
            .expiration(new Date(System.currentTimeMillis() + expiration))
            .signWith(privateKey, SignatureAlgorithm.RS256)
            .compact();
    }

    // Token 검증
    public Claims validateToken(String token) {
        return Jwts.parser()
            .verifyWith(publicKey)
            .build()
            .parseSignedClaims(token)
            .getPayload();
    }

    // Private Key 로드
    private PrivateKey loadPrivateKey() throws Exception {
        String key = new String(Files.readAllBytes(
            Paths.get("config/keys/private_key.pem")));

        key = key.replace("-----BEGIN PRIVATE KEY-----", "")
                 .replace("-----END PRIVATE KEY-----", "")
                 .replaceAll("\\s", "");

        byte[] keyBytes = Base64.getDecoder().decode(key);

        PKCS8EncodedKeySpec spec = new PKCS8EncodedKeySpec(keyBytes);
        KeyFactory kf = KeyFactory.getInstance("RSA");
        return kf.generatePrivate(spec);
    }

    // Public Key 로드
    private PublicKey loadPublicKey() throws Exception {
        String key = new String(Files.readAllBytes(
            Paths.get("config/keys/public_key.pem")));

        key = key.replace("-----BEGIN PUBLIC KEY-----", "")
                 .replace("-----END PUBLIC KEY-----", "")
                 .replaceAll("\\s", "");

        byte[] keyBytes = Base64.getDecoder().decode(key);

        X509EncodedKeySpec spec = new X509EncodedKeySpec(keyBytes);
        KeyFactory kf = KeyFactory.getInstance("RSA");
        return kf.generatePublic(spec);
    }
}
```

### Spring Security 통합

```java
@Configuration
@EnableWebSecurity
public class SecurityConfig {

    private final JwtAuthenticationFilter jwtAuthFilter;

    @Bean
    public SecurityFilterChain securityFilterChain(HttpSecurity http) throws Exception {
        http
            .csrf(csrf -> csrf.disable())
            .sessionManagement(session ->
                session.sessionCreationPolicy(SessionCreationPolicy.STATELESS)
            )
            .authorizeHttpRequests(auth -> auth
                .requestMatchers("/api/v1/auth/**").permitAll()
                .requestMatchers("/api/v1/messages/**").hasAnyRole("USER", "ADMIN")
                .requestMatchers("/api/v1/admin/**").hasRole("ADMIN")
                .anyRequest().authenticated()
            )
            .addFilterBefore(jwtAuthFilter, UsernamePasswordAuthenticationFilter.class);

        return http.build();
    }
}
```

---

## 성능 최적화 전략

### 1. HikariCP Connection Pool

```yaml
spring:
  datasource:
    hikari:
      maximum-pool-size: 20      # 최대 연결 수
      minimum-idle: 10           # 최소 유휴 연결 수
      connection-timeout: 30000  # 연결 타임아웃 (30초)
      idle-timeout: 600000       # 유휴 타임아웃 (10분)
      max-lifetime: 1800000      # 최대 생명 주기 (30분)
```

### 2. 중요 인덱스

```sql
-- ums_msg 테이블
CREATE INDEX idx_dedup_hash ON ums_msg(dedup_hash, req_date);
CREATE INDEX idx_req_date ON ums_msg(req_date);
CREATE INDEX idx_msg_status ON ums_msg(msg_status);
CREATE INDEX idx_traffic_type ON ums_msg(traffic_type);

-- ums_log 테이블
CREATE INDEX idx_req_date ON ums_log_202501(req_date);
CREATE INDEX idx_client_key ON ums_log_202501(client_key);
CREATE INDEX idx_msg_status ON ums_log_202501(msg_status);
```

### 3. JPA N+1 문제 방지

```java
@Repository
public interface UserRepository extends JpaRepository<User, UUID> {

    // Fetch Join으로 N+1 방지
    @Query("SELECT u FROM User u JOIN FETCH u.organization WHERE u.userId = :userId")
    Optional<User> findByIdWithOrganization(@Param("userId") UUID userId);

    // EntityGraph로 N+1 방지
    @EntityGraph(attributePaths = {"organization", "addressBooks"})
    List<User> findAll();
}
```

---

## 배운 점

### 1. Hybrid Database Strategy의 위력
- "모든 것을 JPA로" 또는 "모든 것을 MyBatis로"가 아닌
- **도메인 특성에 맞는 기술 선택**의 중요성
- 성능과 생산성의 균형

### 2. 보안의 중요성 (RS256)
- HS256에서 RS256으로 마이그레이션
- Public Key로 검증 가능한 구조
- 확장 가능한 인증 시스템

### 3. 성능 최적화의 실전
- 월별 파티션 테이블로 조회 성능 80% 향상
- 인덱스 전략 수립의 중요성
- Connection Pool 튜닝

### 4. 문서화의 가치
- 체계적인 문서 구조
- 신규 개발자 온보딩 시간 단축
- 유지보수성 향상

---

## 관련 문서

- [[LinkWave 프로젝트 개요]]
- [[LinkWave Frontend 디자인 시스템]]
- [[LinkWave 배포 가이드]]
- [[Spring Boot 4.0 학습]]
- [[JPA vs MyBatis 비교]]
- [[JWT RS256 인증]]

---

**작성일**: 2025-01-17
**작성자**: 상훈
**프로젝트 경로**: `/Users/sanghoon/Project/iotree-linkwave/linkwave-backend`
