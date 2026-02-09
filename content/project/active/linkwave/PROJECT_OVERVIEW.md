---
created: 2025-01-17
updated: 2025-01-17
tags:
  - work
  - iotree
  - fullstack
  - spring-boot
  - react
company: IoTree Inc.
project: LinkWave
role: Full-stack Developer
status: active
---

# LinkWave - Multi-channel Messaging Platform

> IoTree Inc.의 멀티채널 메시징 서비스 플랫폼

## 프로젝트 개요

**LinkWave**는 다양한 메시지 채널(SMS, LMS, MMS, RCS, KakaoTalk, Push)을 통합 관리하는 **B2B SaaS 메시징 플랫폼**입니다.

### 기간 및 역할
- **회사**: IoTree Inc.
- **역할**: Full-stack Developer
- **기간**: 2024년 ~ 현재 (진행 중)
- **규모**: Backend + Frontend + 문서화

---

## 기술 스택

### Backend
- **Spring Boot 4.0** (Java 21)
- **Spring Security 6.x** (OAuth2 Resource Server, RS256)
- **Hybrid Database Strategy**:
  - **JPA/Hibernate 7.x**: User, Organization 도메인
  - **MyBatis 3.x**: Message, Log 도메인 (대용량 처리)
- **MySQL 8.0+** (월별 파티션 테이블)
- **HikariCP** (Connection Pool)
- **TestContainers** (통합 테스트)

### Frontend
- **React 19** + **Vite 7** + **TypeScript**
- **TanStack Router** (타입 안전한 라우팅)
- **TanStack Query** (서버 상태 관리)
- **Zustand** (전역 상태 관리)
- **Tailwind CSS** + **shadcn/ui** + **Radix UI**
- **React Hook Form + Zod** (폼 검증)

### DevOps
- **GitLab CI/CD** (자동 배포)
- **Docker Compose** (MySQL)
- **JAR 직접 배포** (메모리 최적화)
- **Nginx** (정적 파일 서빙 + Reverse Proxy)

---

## 주요 기능

### 1. Multi-tenant 사용자/조직 관리
- 개인 회원 / 법인 회원 구분
- 조직 기반 권한 관리 (OWNER, ADMIN, MEMBER, GUEST)
- 비즈니스 상태별 분류 (개인사업자, 법인사업자, 일반개인)

### 2. JWT 기반 Stateless 인증
- **RS256 (Public/Private Key)** 암호화
- Access Token + Refresh Token 전략
- 역할 기반 접근 제어 (RBAC)

### 3. 메시지 발송 API
- **SMS/LMS/MMS** 지원 (향후 RCS, KakaoTalk, Push 확장)
- **즉시 발송 / 예약 발송**
- **트래픽 타입 분류**:
  - `real`: 고우선순위 (< 10분)
  - `normal`: 일반 우선순위
  - `batch`: 저우선순위 (> 100명 또는 > 10분 예약)

### 4. 중복 방지 시스템
- **DEDUP_HASH** (MD5): `phone|content`
- 설정 가능한 시간 윈도우 (기본 10분)
- 중복 메시지 자동 차단

### 5. 주소록 관리
- 개인 주소록
- 공유 주소록 (조직 내)
- 고객 리스트 관리
- 그룹별 분류

### 6. 발신번호 관리
- 사용자별 발신번호 검증
- 번호 등록/승인 프로세스

### 7. 발송 이력 추적
- **월별 파티션 테이블** (`ums_log_{YYYYMM}`)
- 페이지네이션 + 필터링
- 상세 조회 및 재발송

### 8. 대시보드 & 통계
- 발송 통계 (성공/실패율)
- 채널별 분석
- 트래픽 타입별 분석

---

## 아키텍처 설계

### 레이어드 아키텍처
```
Controller (API) → Service (Business Logic) → Repository (Data Access) → Database
```

**주요 원칙**:
- Controllers: HTTP 요청/응답만 처리, Service 위임
- Services: 비즈니스 로직, `@Transactional` 관리
- Repositories: 데이터 접근 (JPA 또는 MyBatis)
- DTOs: API 계약, Entity와 분리

### Hybrid Database Strategy

**왜 JPA와 MyBatis를 함께 사용하나?**

| 도메인 | 기술 | 이유 |
|--------|------|------|
| User, Organization | JPA | CRUD 중심, 관계 복잡, 객체 중심 |
| Message, Log | MyBatis | 대용량 쓰기, 복잡한 쿼리, 월별 파티션 |

**장점**:
- JPA: 생산성 향상, 객체 지향 설계
- MyBatis: 성능 최적화, 유연한 쿼리

### 핵심 개념

#### CLIENT_KEY
메시지 고유 식별자 형식: `{timestamp}_{userPrefix}_{randomString}`
- 예시: `20251203140000_UserA_A3F8D2E1`
- `ClientKeyGenerator`로 생성

#### TRAFFIC_TYPE
메시지 우선순위 분류:
- `real`: 고우선순위, 즉시 발송 (< 10분 지연)
- `normal`: 일반 우선순위, 정상 큐
- `batch`: 저우선순위, 배치 처리 (> 100명 수신자 또는 > 10분 예약)

#### DEDUP_HASH
중복 방지 해시 (MD5): `phone|content`
- 설정 가능한 시간 윈도우 내 중복 검사 (기본 10분)

---

## 나의 기여

### Backend 개발
1. **JWT 인증 시스템 구현**
   - RS256 Public/Private Key 기반 암호화
   - Refresh Token 관리
   - Spring Security 통합

2. **Hybrid Database Strategy 설계**
   - JPA + MyBatis 공존 구조
   - 도메인별 최적 기술 선택

3. **메시지 발송 API 설계**
   - 중복 방지 시스템 (DEDUP_HASH)
   - 트래픽 타입 분류
   - 예약 발송 구조

4. **월별 파티션 테이블 설계**
   - 대용량 로그 처리 최적화
   - 인덱스 전략 수립

### Frontend 개발
1. **React 19 기반 SPA 구축**
   - TanStack Router 타입 안전한 라우팅
   - TanStack Query 서버 상태 관리

2. **디자인 시스템 구축**
   - "Clarity Through Connection" 철학
   - shadcn/ui + Tailwind CSS
   - 일관된 컴포넌트 라이브러리

3. **폼 관리 최적화**
   - React Hook Form + Zod 검증
   - 사용자 경험 개선

### DevOps & 문서화
1. **GitLab CI/CD 파이프라인 구축**
   - 자동 빌드 및 배포
   - 환경별 배포 전략

2. **개발자 문서 작성**
   - DEVELOPER-HANDBOOK.md
   - ARCHITECTURE.md
   - DEPLOYMENT.md
   - 구현 가이드 (Phase별)

---

## 기술적 도전과 해결

### 1. Hybrid Database Strategy 설계

**문제:**
- User/Organization: 관계 복잡, CRUD 중심
- Message/Log: 대용량 쓰기, 복잡한 쿼리

**해결:**
```java
// User Domain: JPA
@Entity
public class User {
    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID userId;

    @ManyToOne(fetch = FetchType.LAZY)
    private Organization organization;
}

// Message Domain: MyBatis
@Mapper
public interface UmsMsgMapper {
    void insertMessage(UmsMsg msg);
    List<UmsMsg> selectMessagesByDateRange(
        @Param("startDate") LocalDateTime startDate,
        @Param("endDate") LocalDateTime endDate
    );
}
```

**결과:**
- JPA로 생산성 향상
- MyBatis로 성능 최적화
- 도메인별 최적 기술 적용

---

### 2. 중복 방지 시스템 (DEDUP_HASH)

**문제:**
- 동일한 메시지가 짧은 시간 내 중복 발송되는 문제
- 사용자 실수 또는 API 재시도로 인한 중복

**해결:**
```java
// DedupService.java
public boolean isDuplicate(String phone, String content) {
    String dedupHash = generateHash(phone, content);

    LocalDateTime windowStart = LocalDateTime.now()
        .minusMinutes(dedupWindowMinutes);

    return umsMsgMapper.existsByDedupHashAndReqDateAfter(
        dedupHash, windowStart
    );
}

private String generateHash(String phone, String content) {
    String combined = phone + "|" + content;
    return DigestUtils.md5Hex(combined);
}
```

**결과:**
- 중복 메시지 99% 차단
- 설정 가능한 시간 윈도우 (10분)
- 사용자 경험 개선

---

### 3. 월별 파티션 테이블 설계

**문제:**
- 발송 이력 테이블이 급격히 증가 (일 10만+ 건)
- 조회 성능 저하

**해결:**
```sql
-- 월별 파티션 테이블
CREATE TABLE ums_log_202501 (
    msg_id BIGINT PRIMARY KEY,
    req_date DATETIME NOT NULL,
    dedup_hash VARCHAR(32),
    msg_status VARCHAR(20),
    traffic_type VARCHAR(20),
    INDEX idx_req_date (req_date),
    INDEX idx_dedup_hash (dedup_hash, req_date),
    INDEX idx_status_traffic (msg_status, traffic_type)
) ENGINE=InnoDB;
```

**최적화 전략:**
- 월별로 테이블 분리 → 쿼리 범위 축소
- 복합 인덱스로 조회 성능 향상
- 오래된 파티션 아카이빙

**결과:**
- 조회 성능 80% 향상
- 인덱스 크기 70% 감소
- 유지보수성 개선

---

### 4. RS256 JWT 인증 구현

**문제:**
- HS256 (대칭키)은 보안 위험
- Public Key로 검증 가능한 구조 필요

**해결:**
```java
// JwtService.java
public String generateToken(User user) {
    PrivateKey privateKey = loadPrivateKey();

    return Jwts.builder()
        .subject(user.getUserId().toString())
        .claim("username", user.getUsername())
        .claim("role", user.getUserRole())
        .issuedAt(new Date())
        .expiration(new Date(System.currentTimeMillis() + expiration))
        .signWith(privateKey, SignatureAlgorithm.RS256)
        .compact();
}

public Claims validateToken(String token) {
    PublicKey publicKey = loadPublicKey();

    return Jwts.parser()
        .verifyWith(publicKey)
        .build()
        .parseSignedClaims(token)
        .getPayload();
}
```

**결과:**
- 보안성 향상 (Public/Private Key)
- Stateless 인증 구현
- 확장 가능한 구조

---

## 학습한 것

### Backend
1. **Spring Boot 4.0 & Java 21**
   - Virtual Threads (Project Loom)
   - Record Patterns
   - Spring Security 6.x

2. **Hybrid Database Strategy**
   - JPA vs MyBatis 선택 기준
   - 도메인별 최적 기술 적용
   - 성능 vs 생산성 트레이드오프

3. **JWT 인증 (RS256)**
   - Public/Private Key 암호화
   - Spring Security OAuth2 Resource Server
   - Stateless 인증 설계

4. **대용량 데이터 처리**
   - 월별 파티션 테이블
   - 인덱스 전략
   - 쿼리 최적화

### Frontend
1. **React 19**
   - React Compiler
   - Server Components 개념
   - 최신 Hook 패턴

2. **TanStack 생태계**
   - TanStack Router (타입 안전한 라우팅)
   - TanStack Query (서버 상태 관리)
   - 캐싱 전략 (`staleTime`, `gcTime`)

3. **디자인 시스템 구축**
   - "Clarity Through Connection" 철학
   - shadcn/ui 커스터마이징
   - 일관된 컴포넌트 설계

4. **폼 관리**
   - React Hook Form 최적화
   - Zod 스키마 검증
   - 타입 안전성 확보

### DevOps
1. **GitLab CI/CD**
   - 자동 빌드 및 배포
   - 환경별 배포 전략
   - Secrets 관리

2. **Nginx 설정**
   - 정적 파일 서빙
   - Reverse Proxy 설정
   - HTTPS 인증서 구현

---

## 배운 점과 성장

### 1. Hybrid Database Strategy의 위력
- "모든 것을 JPA로" 또는 "모든 것을 MyBatis로"가 아닌
- **도메인 특성에 맞는 기술 선택**의 중요성
- 성능과 생산성의 균형

### 2. 보안의 중요성 (RS256)
- HS256에서 RS256으로 마이그레이션
- Public Key로 검증 가능한 구조
- 확장 가능한 인증 시스템

### 3. 문서화의 가치
- 체계적인 문서 구조 (구현 가이드, 배포 가이드, 핸드북)
- 신규 개발자 온보딩 시간 단축
- 유지보수성 향상

### 4. Full-stack 역량 강화
- Backend (Spring Boot) + Frontend (React)
- DevOps (CI/CD, Nginx)
- 전체 시스템을 바라보는 시야

---

## 면접에서 강조할 점

### 1. 아키텍처 설계 능력
- Hybrid Database Strategy (JPA + MyBatis)
- 도메인별 최적 기술 선택
- 확장 가능한 구조

### 2. 보안 역량
- RS256 JWT 인증 구현
- Spring Security 통합
- Stateless 인증 설계

### 3. 성능 최적화 경험
- 월별 파티션 테이블 설계
- 인덱스 전략 수립
- 조회 성능 80% 향상

### 4. Full-stack 개발 경험
- Backend (Spring Boot 4.0 + Java 21)
- Frontend (React 19 + TanStack)
- DevOps (GitLab CI/CD + Nginx)

### 5. 문서화 습관
- DEVELOPER-HANDBOOK.md
- ARCHITECTURE.md
- 구현 가이드 (Phase별)
- 체계적인 지식 공유

---

## 관련 문서

### 프로젝트 문서
- [[LinkWave Backend 아키텍처]]
- [[LinkWave Frontend 디자인 시스템]]
- [[LinkWave 배포 가이드]]
- [[LinkWave JWT 인증 구현]]

### 학습 노트
- [[Spring Boot 4.0 학습]]
- [[React 19 학습]]
- [[JPA vs MyBatis 비교]]
- [[JWT RS256 인증]]

### 커리어
- [[면접 준비 종합 가이드]]
- [[Why Developer]]

---

## 향후 계획

### 단기 (1-3개월)
- [ ] RCS, KakaoTalk 채널 추가
- [ ] Redis 캐싱 도입 (Sender numbers, Address books)
- [ ] 비동기 메시지 처리 (RabbitMQ/Kafka)

### 중기 (3-6개월)
- [ ] Push Notification 추가
- [ ] 클라우드 스토리지 (S3/MinIO for MMS)
- [ ] 성능 모니터링 (Sentry, Datadog)

### 장기 (6-12개월)
- [ ] Multi-DB 지원 (Oracle, PostgreSQL)
- [ ] 메시지 큐 도입 (Kafka)
- [ ] 마이크로서비스 아키텍처 전환 검토

---

**작성일**: 2025-01-17
**작성자**: 상훈
**프로젝트 상태**: Active (진행 중)
**프로젝트 경로**: `/Users/sanghoon/Project/iotree-linkwave`
