---
created: 2025-12-26
---
# Phase 5: 설정 파일

## 📖 개요

이 Phase에서는 프로젝트 실행에 필요한 설정 파일을 완성합니다.

## 🎯 구현 목표

- [ ] build.gradle.kts 의존성 추가
- [ ] application.yml JWT 설정 추가
- [ ] .env 파일 생성 (선택사항)

---

## 📝 1. build.gradle.kts

**위치**: `build.gradle.kts` (프로젝트 루트)

### 추가할 의존성

`dependencies` 블록에 다음 내용 추가:

```kotlin
dependencies {
    // Spring Boot Starters
    implementation("org.springframework.boot:spring-boot-starter-web")
    implementation("org.springframework.boot:spring-boot-starter-data-jpa")
    implementation("org.springframework.boot:spring-boot-starter-security")
    implementation("org.springframework.boot:spring-boot-starter-validation")
    implementation("org.springframework.boot:spring-boot-starter-actuator")

    // Database
    runtimeOnly("com.mysql:mysql-connector-j")
    testRuntimeOnly("com.h2database:h2")  // 테스트용 인메모리 DB

    // JWT ⭐ 추가
    implementation("io.jsonwebtoken:jjwt-api:0.12.3")
    runtimeOnly("io.jsonwebtoken:jjwt-impl:0.12.3")
    runtimeOnly("io.jsonwebtoken:jjwt-jackson:0.12.3")

    // Lombok
    compileOnly("org.projectlombok:lombok")
    annotationProcessor("org.projectlombok:lombok")

    // Environment Variables
    implementation("me.paulschwarz:spring-dotenv:4.0.0")

    // Testing
    testImplementation("org.springframework.boot:spring-boot-starter-test")
    testImplementation("org.springframework.security:spring-security-test")
    testRuntimeOnly("org.junit.platform:junit-platform-launcher")
}
```

### 의존성 설명

#### JWT 관련 (3개 필요)
- `jjwt-api`: JWT API 인터페이스
- `jjwt-impl`: 실제 구현체
- `jjwt-jackson`: JSON 직렬화/역직렬화

#### 주의사항
- 3개 모두 같은 버전 사용 (0.12.3)
- `jjwt-impl`, `jjwt-jackson`은 `runtimeOnly` (컴파일 시 불필요)

### 변경 후 빌드

```bash
./gradlew clean build
```

---

## 📝 2. application.yml

**위치**: `src/main/resources/application.yml`

### JWT 설정 추가

기존 설정에 `linkwave.jwt` 섹션 추가:

```yaml
# LinkWave Backend - 기본 설정 (공통)
spring:
  application:
    name: linkwave-backend

  profiles:
    active: ${SPRING_PROFILES_ACTIVE:local}

  config:
    import: "optional:file:./config/.env[.properties]"

  jpa:
    open-in-view: false
    properties:
      hibernate:
        format_sql: true
        use_sql_comments: true
        jdbc:
          batch_size: 20
        order_inserts: true
        order_updates: true

  servlet:
    multipart:
      enabled: true
      max-file-size: 10MB
      max-request-size: 10MB
      file-size-threshold: 2MB

management:
  endpoints:
    web:
      exposure:
        include: health,info,metrics,prometheus
      base-path: /actuator
  endpoint:
    health:
      show-details: when-authorized
  metrics:
    export:
      prometheus:
        enabled: true

# 애플리케이션 커스텀 설정
linkwave:
  # JWT 설정 ⭐ 추가
  jwt:
    secret: ${JWT_SECRET:YourBase64EncodedSecretKeyMustBeAtLeast256BitsLongForHS256AlgorithmToWorkProperlyAndSecurely}
    access-token-expiration: 3600000      # 1시간 (ms)
    refresh-token-expiration: 604800000   # 7일 (ms)

  file:
    upload:
      path: ${FILE_UPLOAD_PATH:./uploads}
      max-size: 10485760  # 10MB (bytes)
      allowed-extensions: jpg,jpeg,png,gif,bmp

  message:
    dedup:
      enabled: true
      default-window-minutes: 10
    traffic:
      batch-threshold: 100
      real-delay-minutes: 10

logging:
  level:
    root: INFO
    io.iotree.linkwave: INFO
```

### 설정 설명

#### jwt.secret
- **중요**: 최소 256비트 (43자) Base64 문자열
- 환경변수 `JWT_SECRET`으로 오버라이드 가능
- 기본값은 개발용 (운영 환경에서 반드시 변경!)

#### 토큰 만료 시간 (밀리초)
- `access-token-expiration`: 3600000 (1시간)
- `refresh-token-expiration`: 604800000 (7일)

**시간 계산**:
- 1초 = 1000ms
- 1분 = 60000ms
- 1시간 = 3600000ms
- 1일 = 86400000ms

---

## 📝 3. application-local.yml

**위치**: `src/main/resources/application-local.yml`

### JWT secret 오버라이드 (선택사항)

로컬 개발 환경에서는 간단한 secret 사용 가능:

```yaml
# LinkWave Backend - 로컬 개발 환경 설정

server:
  port: 8080

spring:
  datasource:
    url: jdbc:mysql://localhost:3306/linkwave?useSSL=false&allowPublicKeyRetrieval=true&serverTimezone=Asia/Seoul&characterEncoding=UTF-8
    username: root
    password: password
    driver-class-name: com.mysql.cj.jdbc.Driver
    hikari:
      maximum-pool-size: 10
      minimum-idle: 5
      connection-timeout: 30000
      idle-timeout: 600000
      max-lifetime: 1800000

  jpa:
    hibernate:
      ddl-auto: update  # 로컬에서는 자동 스키마 업데이트
    show-sql: true

  devtools:
    restart:
      enabled: true
    livereload:
      enabled: true

  h2:
    console:
      enabled: false

security:
  debug: true

logging:
  level:
    root: INFO
    io.iotree.linkwave: DEBUG
    org.springframework.web: DEBUG
    org.springframework.security: DEBUG
    org.hibernate.SQL: DEBUG
    org.hibernate.type.descriptor.sql.BasicBinder: TRACE
  pattern:
    console: "%d{HH:mm:ss.SSS} [%thread] %-5level %logger{36} - %msg%n"

management:
  endpoints:
    web:
      exposure:
        include: "*"
  endpoint:
    health:
      show-details: always

linkwave:
  file:
    upload:
      path: ./uploads/local
  message:
    dedup:
      enabled: true
  # JWT secret 로컬 개발용 (선택사항)
  # jwt:
  #   secret: local-dev-secret-key-at-least-256-bits-long-base64-encoded-string-for-testing
```

---

## 📝 4. .env 파일 (선택사항)

**위치**: `config/.env` (프로젝트 루트에 config 디렉토리 생성)

### 환경변수 설정

```bash
# JWT Secret (256비트 이상 Base64 문자열)
JWT_SECRET=YourProductionSecretKeyMustBeAtLeast256BitsLongAndBase64EncodedForSecurityPurposes

# Database
DB_URL=jdbc:mysql://localhost:3306/linkwave
DB_USERNAME=root
DB_PASSWORD=your-password

# File Upload
FILE_UPLOAD_PATH=./uploads/production
```

### .env 파일 생성 방법

```bash
mkdir config
touch config/.env
```

### .gitignore에 추가

```bash
echo "config/.env" >> .gitignore
```

**중요**: `.env` 파일은 절대 Git에 커밋하지 마세요!

---

## 📝 5. JWT Secret 생성 방법

### Base64 문자열 생성 (256비트 이상)

#### 방법 1: OpenSSL 사용

```bash
openssl rand -base64 64
```

출력 예시:
```
8kqM3fR7pL9wX2vN6hY4jT5gB1sD8cF0eA9rP3mK7nQ4vH2xW6yJ8tL5uI1oP9zA3bC7eR4fT6gH8jK0mN2sV==
```

#### 방법 2: 온라인 생성기

https://generate-secret.vercel.app/64

#### 방법 3: Java 코드

```java
import java.security.SecureRandom;
import java.util.Base64;

public class SecretGenerator {
  public static void main(String[] args) {
    SecureRandom random = new SecureRandom();
    byte[] bytes = new byte[64]; // 512비트
    random.nextBytes(bytes);
    String secret = Base64.getEncoder().encodeToString(bytes);
    System.out.println(secret);
  }
}
```

---

## 📝 6. 데이터베이스 스키마 생성

### MySQL 접속

```bash
mysql -u root -p
```

### 데이터베이스 생성

```sql
CREATE DATABASE linkwave CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE linkwave;
```

### JPA가 자동으로 테이블 생성

`application-local.yml`에서 `ddl-auto: update` 설정으로 애플리케이션 실행 시 자동 생성됩니다.

수동으로 확인하려면:

```sql
SHOW TABLES;
```

예상 테이블:
- `companies`
- `users`
- `refresh_tokens`

---

## ✅ 완료 체크리스트

- [ ] build.gradle.kts에 JWT 의존성 추가
- [ ] application.yml에 JWT 설정 추가
- [ ] JWT secret 생성 및 설정
- [ ] MySQL 데이터베이스 생성
- [ ] .gitignore에 .env 추가
- [ ] `./gradlew clean build` 성공
- [ ] `./gradlew bootRun` 실행 성공

---

## 🧪 테스트: 애플리케이션 실행

### 1. 빌드

```bash
./gradlew clean build
```

### 2. 실행

```bash
./gradlew bootRun
```

### 3. 로그 확인

정상 실행 시 로그:

```
Started LinkwaveApplication in 3.456 seconds
Tomcat started on port(s): 8080 (http)
```

### 4. Health Check

```bash
curl http://localhost:8080/actuator/health
```

예상 응답:
```json
{
  "status": "UP"
}
```

---

## 🔍 자주하는 실수

### 1. JWT secret이 너무 짧음

**에러**:
```
The specified key byte array is 128 bits which is not secure enough
```

**해결**: 최소 256비트 (43자) 이상 사용

### 2. JWT 의존성 버전 불일치

모든 JJWT 라이브러리는 같은 버전 사용

### 3. MySQL 연결 실패

**에러**:
```
Unable to open JDBC Connection
```

**해결**:
1. MySQL 실행 중인지 확인
2. 데이터베이스 생성 확인
3. username/password 확인

### 4. 포트 충돌

**에러**:
```
Port 8080 is already in use
```

**해결**:
```yaml
# application-local.yml
server:
  port: 8081  # 다른 포트 사용
```

---

## 🎉 최종 테스트

### 전체 플로우 테스트

```bash
# 1. 조직 등록
curl -X POST http://localhost:8080/api/v1/organizations \
  -H "Content-Type: application/json" \
  -d '{
    "organizationName": "주식회사 IoTree",
    "businessNumber": "123-45-67890",
    "address": "서울시 강남구",
    "adminEmail": "admin@iotree.com"
  }'

# 2. 회원가입
curl -X POST http://localhost:8080/api/v1/auth/signup \
  -H "Content-Type: application/json" \
  -d '{
    "username": "admin",
    "password": "Admin123!@#",
    "name": "관리자",
    "phone": "010-1234-5678",
    "userType": "BUSINESS",
    "organizationId": "uuid-here"
  }'

# 3. 로그인
curl -X POST http://localhost:8080/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "username": "admin",
    "password": "Admin123!@#"
  }'

# 4. Access Token으로 조직 조회 (토큰은 3번 응답에서 복사)
curl -X GET http://localhost:8080/api/v1/organizations/{organizationId} \
  -H "Authorization: Bearer {ACCESS_TOKEN}"
```

모든 요청이 성공하면 구현 완료! 🎉

---

**축하합니다! 모든 Phase 완료!** 🎊

전체 가이드 요약: 👉 [00-GETTING-STARTED.md](./00-GETTING-STARTED.md)
