---
created: 2026-01-22
---
# LinkWave - 멀티채널 메시징 플랫폼

> 개인 개발 프로젝트 | 2025.11 - 현재 진행중 | Full-Stack Developer

## 프로젝트 개요

**LinkWave**는 SMS, LMS, MMS 등 다양한 메시징 채널을 통합 관리하는 엔터프라이즈급 메시징 플랫폼입니다. 멀티테넌트 아키텍처와 역할 기반 접근 제어(RBAC)를 통해 조직별로 격리된 메시징 서비스를 제공합니다.

**프로젝트 저장소**: `/home/sanghoon/project/iotree-linkwave` (WSL)

## 핵심 기술 스택

### Backend
- **Framework**: Spring Boot 4.0, Java 21
- **Database**: MySQL 8.0, Redis
- **ORM**: JPA/Hibernate (User Domain), MyBatis (Message Domain)
- **Security**: Spring Security 6.x, JWT + Refresh Token Rotation (RTR)
- **Build**: Gradle 8.5+ (Kotlin DSL)

### Frontend
- **Core**: React 19, TypeScript 5.x, Vite 7
- **Routing**: TanStack Router 1.140+ (File-based)
- **State**: Zustand 5.x (Global), TanStack Query 5.x (Server)
- **UI**: Tailwind CSS 4, Radix UI, shadcn/ui
- **Forms**: React Hook Form 7.x, Zod 4.x

### Infrastructure
- **Web Server**: Nginx (Port 8890 - Static + Reverse Proxy)
- **Application**: JAR (Port 18080)
- **Database**: Docker Compose MySQL (Port 3309)
- **CI/CD**: GitLab Pipeline

## 아키텍처 설계

### 시스템 아키텍처

```
Client (Browser)
    ↓ HTTPS
Nginx (Port 8890) - Frontend Static + Reverse Proxy
    ↓ /api/v1/*
React 19 + TypeScript + Vite
    ↓ Axios HTTP
Spring Boot 4.0 + Java 21 (Port 18080)
    ├── JPA (User Domain)
    └── MyBatis (Message Domain)
    ↓
MySQL 8.0 (Port 3309) + Redis (Token Store)
```

### CQRS 패턴 적용

**핵심 설계 결정**: 도메인 특성에 따른 하이브리드 영속성 전략

#### JPA/Hibernate (Command Side - User Domain)
- **대상**: User, Organization, SenderNumber, AddressBook
- **이유**:
  - CRUD 중심의 단순한 비즈니스 로직
  - 엔티티 간 관계 매핑이 중요 (1:N, N:M)
  - 트랜잭션 일관성과 무결성 보장 필요

#### MyBatis (Query Side - Message Domain)
- **대상**: UmsMsg (메시지 큐), UmsLog_{YYYYMM} (월별 파티션 로그)
- **이유**:
  - 대용량 데이터 처리 (일 수십만 건 이상)
  - 복잡한 JOIN 및 통계 쿼리 최적화 필요
  - 월별 테이블 파티셔닝으로 수억 건 데이터 관리

### 인증/보안 아키텍처

#### JWT + Refresh Token Rotation (RTR)
```
Login Request
    ↓
AuthService
    ├─ Access Token (15분, localStorage)
    └─ Refresh Token (7일, HttpOnly Cookie + Redis)

Token Refresh (Silent Refresh on 401)
    ↓
Redis Token Validation
    ├─ Valid → New Token Pair
    └─ Invalid → Re-login Required
```

**보안 강화 포인트**:
- Refresh Token 재사용 공격 방지 (Redis에서 일회용 토큰 관리)
- XSS 방지 (Refresh Token을 HttpOnly Cookie에 저장)
- CSRF 방지 (Access Token은 localStorage, API는 동일 도메인)

### 데이터베이스 스키마

#### ERD 핵심 관계
```
organizations (1)
    ↓ contains
users (N)
    ├─ has many ─→ sender_numbers
    ├─ has many ─→ personal_address_book
    └─ has many ─→ ums_msg

ums_msg (메시지 큐)
    └─ logged in ─→ ums_log_{YYYYMM} (월별 파티션)
```

#### 주요 테이블

**User Domain (JPA)**
- `users`: 사용자 계정, 프로필, 상태 관리
- `organizations`: 조직 정보, 사업자 등록 정보
- `sender_numbers`: 발신번호 관리 (본인 인증)
- `personal_address_book` / `shared_address_book`: 개인/공유 주소록

**Message Domain (MyBatis)**
- `ums_msg`: 발송 요청 메시지 큐
  - 필드: msg_id, user_id, phone, content, req_ch, traffic_type, msg_status
- `ums_log_{YYYYMM}`: 월별 파티션 발송 이력
  - 인덱스: DEDUP_HASH (중복 방지), REQ_DATE, MSG_STATUS, TRAFFIC_TYPE

## 구현 기능

### 1. 사용자 관리
- **멀티테넌트 아키텍처**: 조직별 데이터 격리
- **사용자 타입**:
  - INDIVIDUAL (개인 사용자)
  - BUSINESS (사업자 사용자)
- **역할 기반 접근 제어 (RBAC)**:
  - `MEMBER`: 기본 메시징 + 개인 리소스 관리
  - `ORGANIZATION_ADMIN`: 조직 관리 + 공유 리소스 관리
  - `SUPER_ADMIN`: 시스템 전체 관리
- **프로필 관리**: 사용자 정보 수정, 비밀번호 변경

### 2. 메시징 시스템
- **멀티채널 지원**: SMS (90바이트), LMS (2,000자), MMS (이미지 첨부)
  - 향후 확장: RCS, 카카오톡, Push 알림
- **발송 우선순위**: 3단계 트래픽 분류 (실시간/일반/대량)
- **중복 발송 방지**: DEDUP_HASH 메커니즘
  - MD5 해시 (수신번호 + 내용 + 시간 윈도우)
  - 설정 가능한 중복 방지 시간 (예: 5분 이내 동일 메시지 차단)
- **발송 상태 추적**: PENDING → PROCESSING → DELIVERED / FAILED
- **예약 발송**: 지정 시간에 자동 발송
- **대량 발송**: Excel 업로드, 주소록 연동

### 3. 발신번호 관리
- **본인 인증**: 발신번호 소유권 검증
- **번호 등록/삭제**: 개인별 발신번호 관리
- **번호 검증**: 메시지 발송 시 등록된 번호만 사용 가능

### 4. 주소록
- **개인 주소록**: 사용자별 연락처 관리
- **공유 주소록**: 조직 전체 공유 연락처
- **그룹 관리**: 연락처 그룹화 및 태그 기능

### 5. 통계 및 이력
- **대시보드**: 메시지 발송량, 성공률, 채널별 분포
- **발송 이력**: 페이지네이션, 필터링, 검색 기능
- **월별 파티션**: `ums_log_{YYYYMM}` 테이블로 대용량 데이터 관리

## 기술적 구현 하이라이트

### 1. 보안 패턴
```java
// JWT + RTR with Redis
@Service
public class AuthService {
    // Access Token: 15분 (짧은 수명으로 탈취 위험 최소화)
    public String generateAccessToken(User user) {
        return Jwts.builder()
            .setSubject(user.getUsername())
            .setExpiration(new Date(System.currentTimeMillis() + 900000))
            .signWith(secretKey)
            .compact();
    }

    // Refresh Token: Redis에 저장 (일회용 토큰 보장)
    public void storeRefreshToken(String username, String token) {
        redisTemplate.opsForValue().set(
            "RT:" + username,
            token,
            7,
            TimeUnit.DAYS
        );
    }
}
```

### 2. 데이터베이스 최적화
```xml
<!-- MyBatis - 대량 메시지 발송 쿼리 -->
<insert id="bulkInsertMessages" parameterType="list">
    INSERT INTO ums_msg (msg_id, user_id, phone, content, req_ch, traffic_type)
    VALUES
    <foreach collection="list" item="msg" separator=",">
        (#{msg.msgId}, #{msg.userId}, #{msg.phone},
         #{msg.content}, #{msg.reqCh}, #{msg.trafficType})
    </foreach>
</insert>

<!-- 월별 파티션 로그 조회 (인덱스 활용) -->
<select id="findMessageLogs" resultType="UmsLog">
    SELECT * FROM ums_log_${month}
    WHERE user_id = #{userId}
    AND req_date BETWEEN #{startDate} AND #{endDate}
    ORDER BY req_date DESC
    LIMIT #{limit} OFFSET #{offset}
</select>
```

### 3. 프론트엔드 아키텍처

#### 상태 관리 전략
```typescript
// Zustand - 전역 상태 (인증, 설정)
export const useAuthStore = create<AuthState>()(
  persist(
    (set) => ({
      user: null,
      accessToken: null,
      setAuth: (user, token) => set({ user, accessToken: token }),
      clearAuth: () => set({ user: null, accessToken: null }),
    }),
    { name: 'auth-storage' }
  )
);

// TanStack Query - 서버 상태 (API 캐싱)
export const useMessageHistory = (userId: number) => {
  return useQuery({
    queryKey: ['messages', userId],
    queryFn: () => messageApi.fetchHistory(userId),
    staleTime: 5 * 60 * 1000, // 5분간 캐시 유지
  });
};
```

#### 라우팅 구조
```typescript
// TanStack Router - 역할 기반 보호 라우트
export const Route = createFileRoute('/_authenticated')({
  beforeLoad: ({ context }) => {
    if (!context.auth.isAuthenticated) {
      throw redirect({ to: '/login' });
    }
  },
});

export const Route = createFileRoute('/_authenticated/organization-admin')({
  beforeLoad: ({ context }) => {
    if (context.auth.user?.role !== 'ORGANIZATION_ADMIN') {
      throw redirect({ to: '/dashboard' });
    }
  },
});
```

### 4. API 설계

#### RESTful Endpoints
```
POST   /api/v1/auth/signup          # 회원가입
POST   /api/v1/auth/login           # 로그인 (JWT + Refresh Token)
POST   /api/v1/auth/refresh         # 토큰 갱신 (Silent Refresh)
POST   /api/v1/auth/logout          # 로그아웃 (Redis 토큰 삭제)

GET    /api/v1/users/{userId}       # 사용자 조회
PUT    /api/v1/users/{userId}       # 사용자 정보 수정

POST   /api/v1/messages             # 메시지 발송
GET    /api/v1/messages             # 발송 이력 조회 (페이지네이션)
GET    /api/v1/messages/{clientKey} # 특정 메시지 상세 조회

GET    /api/v1/sender-numbers       # 발신번호 목록
POST   /api/v1/sender-numbers       # 발신번호 등록
POST   /api/v1/sender-numbers/{id}/verify  # 번호 인증
DELETE /api/v1/sender-numbers/{id}  # 발신번호 삭제
```

## 프로젝트 디렉토리 구조

### Backend
```
linkwave-backend/
├── src/main/java/io/iotree/linkwave/
│   ├── api/                    # Controllers (4개)
│   │   ├── AuthController.java
│   │   ├── UserController.java
│   │   ├── MessageController.java
│   │   └── SenderNumberController.java
│   ├── application/service/    # Business Logic (4개)
│   │   ├── AuthService.java
│   │   ├── UserService.java
│   │   ├── MessageService.java
│   │   └── SenderNumberService.java
│   ├── domain/                 # JPA Entities
│   │   ├── user/              # User, Organization, SenderNumber
│   │   ├── message/           # UmsMsg, ServiceType
│   │   └── organization/
│   ├── infra/
│   │   ├── jpa/repository/    # JPA Repositories
│   │   └── mybatis/mapper/    # MyBatis Mappers (3개 XML)
│   ├── config/                # Security, JPA, MyBatis, Redis
│   └── common/                # Exception, JWT Provider, Utils
├── src/main/resources/
│   ├── application.yml        # Spring Configuration
│   └── mybatis/mapper/        # MyBatis XML
└── build.gradle.kts           # Gradle (Kotlin DSL)
```

### Frontend
```
linkwave-frontend/
├── src/
│   ├── api/                   # Axios HTTP Client
│   ├── routes/                # TanStack Router (16+ 라우트)
│   │   ├── login.tsx
│   │   ├── signup.tsx
│   │   ├── _authenticated/    # 인증 필요 라우트
│   │   │   ├── dashboard.tsx
│   │   │   ├── sms.tsx
│   │   │   ├── lms.tsx
│   │   │   ├── mms.tsx
│   │   │   └── history.tsx
│   │   ├── organization-admin/ # 조직 관리자 라우트 (5개)
│   │   └── super-admin/       # 슈퍼 관리자 라우트 (5개)
│   ├── components/            # React Components
│   │   ├── ui/               # shadcn/ui Components
│   │   ├── forms/            # Form Components
│   │   ├── dashboard/        # Dashboard Components
│   │   └── history/          # History Components
│   ├── stores/               # Zustand Stores
│   ├── hooks/                # Custom React Hooks
│   └── types/                # TypeScript Types
├── nginx/                    # Nginx Config
└── package.json
```

## 개발 진행 상황

### 완료된 기능 (✅)
- ✅ JWT + RTR 인증 시스템 (Redis 기반)
- ✅ 멀티테넌트 조직 구조
- ✅ 메시지 발송 (SMS/LMS, 내용 길이별 자동 분류)
- ✅ 발신번호 관리 및 검증
- ✅ 사용자 프로필 및 설정 관리
- ✅ 메시지 발송 이력 (페이지네이션)
- ✅ CORS 및 CI/CD 설정
- ✅ UI 리디자인 (shadcn/ui 마이그레이션, Tailwind CSS 4)
- ✅ 폼 검증 (React Hook Form + Zod)

### 진행 중 (🔄)
- 🔄 Phase 3: 고급 메시지 발송 (템플릿, 대량 발송)
- 🔄 대시보드 통계 및 분석
- 🔄 주소록 전체 구현
- 🔄 다크모드 토글

### 예정 (📋)
- 📋 Phase 4-5: RCS, 카카오톡, Push 알림
- 📋 조직 관리 UI
- 📋 관리자 통계 대시보드
- 📋 메시지 일괄 처리
- 📋 데이터베이스 읽기 전용 복제본 (분석용)
- 📋 메시지 큐 통합 (RabbitMQ/Kafka)

## 배포 아키텍처

### 개발 환경
- **서버**: nas.iotree.co.kr:8122
- **Frontend**: Nginx on port 8890 (static + reverse proxy)
- **Backend**: JAR on port 18080
- **Database**: Docker Compose MySQL on port 3309
- **Caching**: Redis (token store)

### 배포 전략
```bash
# Frontend
cd linkwave-frontend
npm run build
scp -r dist/* user@server:/var/www/linkwave/

# Backend
cd linkwave-backend
./gradlew clean build
scp build/libs/linkwave-*.jar user@server:/app/linkwave/
ssh user@server "nohup java -jar /app/linkwave/linkwave-*.jar &"
```

### CI/CD Pipeline (GitLab)
- `develop` 브랜치 → 자동 스테이징 배포
- `main` 브랜치 → 수동 프로덕션 배포

## 학습 및 문서화

프로젝트 진행 중 작성한 29개의 기술 문서 (총 19,800줄, 692KB):

### 주요 문서
- **Backend Implementation Guides**: Auth (JWT, RTR), Message System (CQRS), User Management
- **Frontend Phase Guides**: 9단계 학습 경로 (환경 설정 → 고급 패턴)
- **Architecture Documents**: 시스템 개요, 데이터 플로우, 설계 진화
- **Troubleshooting**: 아키텍처 진화 (v1-v5), JJWT vs OAuth2 비교, CORS/CI-CD
- **Daily Logs**: 일일 개발 진행 사항 및 구현 세부 사항

## 성과 및 배운 점

### 기술적 성과
1. **Full-Stack 통합**: React 19 + Spring Boot 4.0 최신 스택 적용
2. **보안 Best Practice**: JWT+RTR, 멀티테넌트 격리, 소유권 검증
3. **확장성 패턴**: CQRS, 데이터베이스 파티셔닝, 커넥션 풀 최적화
4. **Modern Frontend**: React 19, TanStack 생태계, Utility-first CSS
5. **엔터프라이즈 아키텍처**: 역할 기반 접근 제어, 다중 조직 지원, 감사 로깅

### 주요 학습 내용
1. **하이브리드 ORM 전략**: JPA와 MyBatis의 장점을 조합한 도메인별 영속성 설계
2. **보안 패턴**: Refresh Token Rotation으로 토큰 재사용 공격 방지
3. **대용량 데이터 처리**: 월별 파티션으로 수억 건 데이터 관리
4. **Type-Safe Development**: TypeScript와 Zod를 활용한 컴파일 타임 안전성
5. **CI/CD Automation**: GitLab 파이프라인으로 자동 배포 구축

## 포트폴리오 핵심 요약

**LinkWave**는 개인이 엔터프라이즈급 메시징 플랫폼을 설계하고 구현한 프로젝트로, 다음을 입증합니다:

- ✅ **Full-Stack 역량**: 최신 React + Spring Boot 생태계 숙련도
- ✅ **아키텍처 설계 능력**: CQRS, 멀티테넌트, 역할 기반 접근 제어
- ✅ **보안 구현**: JWT+RTR, Redis 기반 토큰 관리
- ✅ **데이터베이스 최적화**: 하이브리드 ORM, 월별 파티셔닝
- ✅ **DevOps**: Nginx, Docker, GitLab CI/CD
- ✅ **문서화 능력**: 29개의 체계적인 기술 문서

**코드 규모**: 65개 Java 파일 + 110개 TypeScript/TSX 컴포넌트

**개발 기간**: 2025.11 - 현재 (약 2개월, 진행 중)

---

**관련 문서**:
- 상세 아키텍처: `/home/sanghoon/project/iotree-linkwave/daily-dev/`
- 프로젝트 저장소: `/home/sanghoon/project/iotree-linkwave`
- Obsidian 문서: `[[linkwave-project-summary]]`
