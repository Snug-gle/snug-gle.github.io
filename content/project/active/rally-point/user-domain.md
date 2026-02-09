---
tags:
  - project
  - rally-point
  - spring
  - jwt
  - authentication
  - user-service
category: project
status: in-progress
created: 2025-06-25
updated: 2025-10-29
---

# 회원 관리 도메인 (Rally-Point User)

## 프로젝트 구조

```
rallypoint-plus-user/
├── src/main/java/com/rallypointplus/user/
│   ├── domain/              # 도메인 계층
│   │   ├── vo/             # Value Objects (User, UserRole, UserStatus)
│   │   ├── table/          # JPA Entities (UserJpaEntity, UserProfileJpaEntity, UserCredentialJpaEntity)
│   │   └── service/        # 도메인 서비스
│   ├── application/        # 애플리케이션 계층
│   │   ├── dto/           # Data Transfer Objects
│   │   ├── service/       # 애플리케이션 서비스 (UserApplicationService, AuthService)
│   │   └── rest/          # REST Controllers
│   ├── infra/             # 인프라 계층
│   │   └── jpa/          # JPA Repository
│   └── common/            # 공통 계층
│       ├── config/        # 설정 (CustomSecurityConfig)
│       ├── security/      # 보안 (JWT, OAuth2)
│       ├── handler/       # 핸들러
│       ├── mapper/        # MapStruct 매퍼
│       ├── exception/     # 예외 처리
│       └── constant/      # 상수
└── src/main/resources/
    ├── application.yml
    └── logback-spring.xml
```

## 기술 스택

- **언어**: Java 21
- **프레임워크**: Spring Boot 3.3.3
- **빌드 도구**: Gradle (Kotlin DSL)
- **데이터베이스**: MySQL
- **ORM**: Spring Data JPA
- **보안**: Spring Security, JWT, OAuth2
- **매퍼**: MapStruct
- **유틸리티**: Lombok

## 현재 구현 상태

### ✅ 완료된 기능

#### 1. CRUD
- [x] 회원 생성 (create)
- [x] 회원 조회 (read)
- [ ] 회원 수정 (update)
- [ ] 회원 삭제 (delete)

#### 2. 인증
- [x] JWT 토큰 발급
- [x] JWT 토큰 검증
- [x] CustomUserDetails 구현
- [x] CustomAuthenticationProvider

#### 3. 로그인 API
- [x] Form 기반 로그인
- [x] OAuth2 로그인 (Kakao)
- [ ] Google OAuth2
- [ ] Naver OAuth2

#### 4. MSA API
- [ ] 회원 verify API
- [ ] 벌크 조회 API
- [ ] 상태 확인 API

### 🚧 진행 중

- JWT Refresh Token 구현
- 이메일 인증 프로세스
- 프로필 확장 (경력, 레벨, 프로필 사진)

### 📋 계획된 기능

자세한 요구사항은 [[business-requirements]] 문서를 참고하세요.

#### Phase 1 (1-2개월)
- 이메일 인증 프로세스
- 프로필 확장 (경력, 레벨, 프로필 사진)
- MSA 사용자 검증 API
- 친구 시스템 기본 기능

#### Phase 2 (3-4개월)
- 추가 소셜 로그인 (Google, Naver)
- 평가 시스템
- 알림 설정 관리
- 회원 등급 시스템
- 2단계 인증

#### Phase 3 (5-6개월)
- 플레이 통계 및 분석
- 리워드 시스템
- 배지 시스템
- 관리자 대시보드

## 개발 가이드

### 개발 원칙
- [[development-principles]] 문서 참고
- 레이어드 아키텍처 준수
- DDD 패턴 적용 (VO vs Entity 분리)
- MapStruct를 통한 명시적 변환
- 테스트 커버리지 80% 이상 유지

### Git Workflow
- [[git-workflow-guide]] 문서 참고
- Git Flow 전략 사용
- 모든 작업은 Issue 기반
- 커밋 메시지 컨벤션 준수

### CI/CD
- [[github-actions-guide]] 문서 참고
- PR 생성 시 자동 테스트 및 빌드
- main 브랜치 머지 시 자동 배포
- 코드 품질 검사 자동화

### Issue 및 Tag 관리
- [[issue-and-tag-management]] 문서 참고
- Semantic Versioning 준수
- Release Notes 작성
- CHANGELOG 관리

## API 엔드포인트

### 인증 API
```
POST   /api/v1/auth/login          # 로그인
POST   /api/v1/auth/logout         # 로그아웃
POST   /api/v1/auth/refresh        # 토큰 갱신
GET    /api/v1/auth/me             # 현재 사용자 정보
```

### 사용자 API
```
POST   /api/v1/users               # 회원가입
GET    /api/v1/users/{userId}      # 사용자 조회
PUT    /api/v1/users/{userId}      # 사용자 수정
DELETE /api/v1/users/{userId}      # 사용자 삭제
PATCH  /api/v1/users/{userId}/profile  # 프로필 수정
```

### MSA 내부 API
```
GET    /internal/users/{userId}/verify     # 사용자 검증
POST   /internal/users/bulk                # 벌크 조회
GET    /internal/users/{userId}/status     # 상태 확인
```

## 데이터 모델

### 핵심 엔티티

#### UserJpaEntity
- id (PK)
- email (Unique)
- status (ACTIVE, INACTIVE, SUSPENDED)
- role (USER, ADMIN, VIP)
- createdAt, updatedAt

#### UserCredentialJpaEntity
- id (PK)
- userId (FK)
- password (BCrypt)
- provider (LOCAL, KAKAO, GOOGLE, NAVER)
- providerId

#### UserProfileJpaEntity
- id (PK)
- userId (FK)
- name
- profileImageUrl
- phoneNumber
- birthday

## 로컬 개발 환경 설정

### 필수 요구사항
- Java 21
- MySQL 8.0
- Redis (선택)

### 실행 방법

```bash
# 1. 데이터베이스 준비
mysql -u root -p
CREATE DATABASE rallypoint;
CREATE USER 'sanghoon'@'localhost' IDENTIFIED BY 'sanghoon1234';
GRANT ALL PRIVILEGES ON rallypoint.* TO 'sanghoon'@'localhost';

# 2. 프로젝트 클론
cd /Users/sanghoon/Project/IdeaProjects/rallypoint-plus-user

# 3. 빌드
./gradlew clean build

# 4. 실행
./gradlew bootRun

# 또는 JAR 실행
java -jar build/libs/rallypoint-plus-user-0.0.1-SNAPSHOT.jar
```

### 환경변수 설정

`.env` 파일 생성 (`.env.example` 참고):

```bash
DB_URL=jdbc:mysql://localhost:3304/rallypoint
DB_USERNAME=sanghoon
DB_PASSWORD=sanghoon1234
JWT_SECRET_KEY=your-secret-key-here
KAKAO_CLIENT_ID=your-kakao-client-id
KAKAO_CLIENT_SECRET=your-kakao-client-secret
```

## 테스트

```bash
# 전체 테스트 실행
./gradlew test

# 특정 테스트 실행
./gradlew test --tests UserApplicationServiceTest

# 테스트 커버리지 확인
./gradlew jacocoTestReport
open build/reports/jacoco/test/html/index.html
```

## 관련 문서

- [[architecture]] - 전체 MSA 아키텍처
- [[business-requirements]] - 비즈니스 요구사항
- [[development-principles]] - 개발 원칙
- [[git-workflow-guide]] - Git 워크플로우
- [[github-actions-guide]] - CI/CD 가이드
- [[issue-and-tag-management]] - Issue & Tag 관리

## 문제 해결

### 자주 발생하는 이슈

1. **JWT 토큰 만료 오류**
   - `application.yml`의 `security.jwt.expireTime` 확인
   - Refresh Token 구현 필요

2. **OAuth2 로그인 실패**
   - Kakao Developer Console에서 Redirect URI 확인
   - 클라이언트 ID/Secret 확인

3. **데이터베이스 연결 오류**
   - MySQL 서버 실행 확인
   - 포트 번호 확인 (기본: 3304)

## 다음 단계

1. [ ] JWT Refresh Token 구현
2. [ ] 이메일 인증 프로세스 개발
3. [ ] 프로필 확장 기능 추가
4. [ ] MSA 내부 API 개발
5. [ ] 통합 테스트 강화
6. [ ] API 문서화 (Swagger/OpenAPI)