---
created: 2025-12-03
---
lllll# Iotree LinkWave - 프로젝트 생성 가이드

이 문서는 Iotree LinkWave 프로젝트를 처음부터 생성하는 단계별 가이드입니다.

---

## 📋 목차

1. [프로젝트 구조 결정](#1-프로젝트-구조-결정)
2. [백엔드 프로젝트 생성](#2-백엔드-프로젝트-생성)
3. [프론트엔드 프로젝트 생성](#3-프론트엔드-프로젝트-생성)
4. [데이터베이스 설정](#4-데이터베이스-설정)
5. [Docker 설정](#5-docker-설정)
6. [프로젝트 통합](#6-프로젝트-통합)

---

## 1. 프로젝트 구조 결정

### 권장 구조: 멀티레포 (Multi-Repository)

```
iotree-linkwave/
├── iotree-linkwave-backend/      # Spring Boot 백엔드
├── iotree-linkwave-frontend/     # React 프론트엔드
├── docker-compose.yml             # 통합 배포 설정
├── .env                           # 환경 변수
├── init-db/                       # DB 초기화 스크립트
│   ├── webdb/
│   │   └── schema.sql
│   └── messagedb/
│       └── schema.sql
└── README.md                      # 프로젝트 문서
```

**멀티레포 선택 이유:**
- ✅ 백엔드/프론트엔드 독립적 개발
- ✅ 각각 독립적으로 배포 가능
- ✅ CI/CD 파이프라인 단순화
- ✅ 프로토타입에 적합

---

## 2. 백엔드 프로젝트 생성

### 2.1 Spring Initializr로 프로젝트 생성

1. https://start.spring.io/ 접속

2. 다음 설정 선택:
   - **Project**: Gradle - Kotlin
   - **Language**: Java
   - **Spring Boot**: 4.0.0
   - **Group**: `io.iotree`
   - **Artifact**: `linkwave-backend`
   - **Name**: `linkwave-backend`
   - **Package name**: `io.iotree.linkwave`
   - **Packaging**: Jar
   - **Java**: 21

3. Dependencies 추가:
   - Spring Web
   - Spring Data JPA
   - Spring Security
   - MySQL Driver
   - Lombok
   - Spring Boot Actuator
   - Validation

4. **GENERATE** 클릭하여 다운로드

### 2.2 프로젝트 구조 생성

```bash
cd iotree-linkwave-backend
mkdir -p src/main/java/io/iotree/linkwave/{config,api,dto,entity,repository,service,exception,util}
mkdir -p src/main/java/io/iotree/linkwave/entity/{webdb,messagedb}
mkdir -p src/main/java/io/iotree/linkwave/repository/{webdb,messagedb}
mkdir -p src/main/java/io/iotree/linkwave/dto/{request,response}
```

### 2.3 build.gradle.kts 수정

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

    // SpringDoc OpenAPI (Springfox 대체)
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

### 2.4 application.yml 생성

```yaml
spring:
  application:
    name: linkwave-backend

  # Datasource - Web DB
  datasource:
    webdb:
      jdbc-url: ${WEB_DB_URL:jdbc:mysql://localhost:3306/webdb?useSSL=false&serverTimezone=Asia/Seoul}
      username: ${WEB_DB_USERNAME:root}
      password: ${WEB_DB_PASSWORD:password}
      driver-class-name: com.mysql.cj.jdbc.Driver
      hikari:
        maximum-pool-size: 10
        minimum-idle: 5
        connection-timeout: 30000

    # Datasource - Message DB (same port as Web DB for simplicity)
    messagedb:
      jdbc-url: ${MESSAGE_DB_URL:jdbc:mysql://localhost:3306/messagedb?useSSL=false&serverTimezone=Asia/Seoul}
      username: ${MESSAGE_DB_USERNAME:root}
      password: ${MESSAGE_DB_PASSWORD:password}
      driver-class-name: com.mysql.cj.jdbc.Driver
      hikari:
        maximum-pool-size: 20
        minimum-idle: 10
        connection-timeout: 30000

  # JPA
  jpa:
    hibernate:
      ddl-auto: validate
    show-sql: false
    properties:
      hibernate:
        dialect: org.hibernate.dialect.MySQL8Dialect
        format_sql: true
        use_sql_comments: true

  # File Upload
  servlet:
    multipart:
      max-file-size: 10MB
      max-request-size: 10MB

# JWT
jwt:
  secret: ${JWT_SECRET:your-secret-key-must-be-at-least-256-bits-long-for-hs256}
  expiration: 86400000  # 24 hours

# File Storage
file:
  upload:
    path: ${FILE_UPLOAD_PATH:/var/linkwave/files}
    max-size: 10485760  # 10MB

# Message Settings
message:
  dedup:
    default-window-minutes: 10
  traffic:
    batch-threshold: 100

# Actuator
management:
  endpoints:
    web:
      exposure:
        include: health,info,metrics
  endpoint:
    health:
      show-details: when-authorized

# Logging
logging:
  level:
    io.iotree.linkwave: DEBUG
    org.springframework.web: INFO
    org.hibernate.SQL: DEBUG
```

### 2.5 Dockerfile 생성

```dockerfile
# Backend Dockerfile
FROM eclipse-temurin:17-jre-alpine

WORKDIR /app

# JAR 파일 복사
COPY build/libs/*.jar app.jar

# 포트 노출
EXPOSE 8080

# 헬스체크
HEALTHCHECK --interval=30s --timeout=3s --start-period=40s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://localhost:8080/actuator/health || exit 1

# 실행
ENTRYPOINT ["java", "-jar", "/app/app.jar"]
```

### 2.6 .gitignore 생성

```gitignore
# Gradle
.gradle/
build/
!gradle/wrapper/gradle-wrapper.jar

# IDE
.idea/
*.iml
*.iws
.vscode/

# OS
.DS_Store
Thumbs.db

# Logs
logs/
*.log

# Application
application-local.yml
application-dev.yml
application-prod.yml
```

---

## 3. 프론트엔드 프로젝트 생성

### 3.1 Vite로 React 프로젝트 생성

```bash
# Vite를 사용한 React + JavaScript 프로젝트 생성
npm create vite@latest iotree-linkwave-frontend -- --template react

cd iotree-linkwave-frontend
npm install
```

### 3.2 필수 의존성 설치

```bash
# 상태 관리
npm install zustand @tanstack/react-query

# 라우팅
npm install react-router-dom

# HTTP 클라이언트
npm install axios

# 유틸리티
npm install date-fns clsx

# UI (추천)
npm install -D tailwindcss postcss autoprefixer
npx tailwindcss init -p
```

### 3.3 추천 의존성 설치

```bash
# 폼 관리
npm install react-hook-form @hookform/resolvers zod

# 알림
npm install react-hot-toast

# 차트
npm install recharts

# 파일 업로드
npm install react-dropzone

# 아이콘
npm install lucide-react
```

### 3.4 프로젝트 구조 생성

```bash
mkdir -p src/{api,components,pages,hooks,stores,types,utils}
mkdir -p src/components/{common,message,forms,history,dashboard,addressBook}
```

### 3.5 Tailwind CSS 설정

**tailwind.config.js**

```javascript
/** @type {import('tailwindcss').Config} */
export default {
  content: [
    "./index.html",
    "./src/**/*.{js,ts,jsx,tsx}",
  ],
  theme: {
    extend: {
      colors: {
        primary: {
          50: '#e6f7ff',
          100: '#bae7ff',
          200: '#91d5ff',
          300: '#69c0ff',
          400: '#40a9ff',
          500: '#1890ff',
          600: '#096dd9',
          700: '#0050b3',
          800: '#003a8c',
          900: '#002766',
        },
      },
    },
  },
  plugins: [],
}
```

**src/index.css**

```css
@tailwind base;
@tailwind components;
@tailwind utilities;

@layer base {
  body {
    @apply bg-gray-50 text-gray-900;
  }
}
```

### 3.6 .env.example 생성

```bash
# API
VITE_API_BASE_URL=http://localhost:8080/api/v1

# File Upload
VITE_MAX_FILE_SIZE=10485760
VITE_ALLOWED_FILE_TYPES=image/jpeg,image/png

# Features
VITE_ENABLE_KAKAO=false
VITE_ENABLE_RCS=false
```

### 3.7 vite.config.js 설정

```javascript
import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'
import path from 'path'
import { fileURLToPath } from 'url'

const __dirname = path.dirname(fileURLToPath(import.meta.url))

export default defineConfig({
  plugins: [react()],
  resolve: {
    alias: {
      '@': path.resolve(__dirname, './src'),
    },
  },
  server: {
    port: 3000,
    proxy: {
      '/api': {
        target: 'http://localhost:8080',
        changeOrigin: true,
      },
    },
  },
})
```

### 3.8 jsconfig.json 설정 (JavaScript 프로젝트)

```json
{
  "compilerOptions": {
    "target": "ES2020",
    "lib": ["ES2020", "DOM", "DOM.Iterable"],
    "module": "ESNext",
    "skipLibCheck": true,
    "moduleResolution": "bundler",
    "resolveJsonModule": true,
    "jsx": "react-jsx",

    /* Path mapping */
    "baseUrl": ".",
    "paths": {
      "@/*": ["./src/*"]
    }
  },
  "include": ["src"],
  "exclude": ["node_modules", "dist"]
}
```

### 3.9 Dockerfile 생성

```dockerfile
# Frontend Dockerfile

# Build stage
FROM node:18-alpine AS builder

WORKDIR /app

# 의존성 설치
COPY package*.json ./
RUN npm ci

# 소스 복사 및 빌드
COPY . .
RUN npm run build

# Production stage
FROM nginx:alpine

# 빌드 결과물 복사
COPY --from=builder /app/dist /usr/share/nginx/html

# Nginx 설정 복사
COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
```

### 3.10 nginx.conf 생성

```nginx
server {
    listen 80;
    server_name _;

    root /usr/share/nginx/html;
    index index.html;

    # Gzip compression
    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_types text/css application/javascript application/json application/xml text/plain;

    # SPA routing
    location / {
        try_files $uri $uri/ /index.html;
    }

    # API proxy
    location /api {
        proxy_pass http://backend:8080;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
    }

    # Cache static assets
    location ~* \.(jpg|jpeg|png|gif|ico|css|js)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
}
```

### 3.11 .gitignore 생성

```gitignore
# Dependencies
node_modules/

# Build
dist/
dist-ssr/

# Environment
.env
.env.local
.env.*.local

# Logs
npm-debug.log*
yarn-debug.log*
yarn-error.log*
pnpm-debug.log*

# IDE
.vscode/
.idea/
*.iml

# OS
.DS_Store
Thumbs.db
```

---

## 4. 데이터베이스 설정

### 4.1 디렉토리 구조 생성

```bash
mkdir -p init-db/webdb
mkdir -p init-db/messagedb
```

### 4.2 Web DB 스키마 생성

**init-db/webdb/01-schema.sql**

```sql
-- Companies
CREATE TABLE IF NOT EXISTS companies (
    company_id VARCHAR(50) PRIMARY KEY,
    company_name VARCHAR(100) NOT NULL,
    business_number VARCHAR(20) UNIQUE,
    contact_email VARCHAR(100),
    contact_phone VARCHAR(20),
    status VARCHAR(20) NOT NULL DEFAULT 'ACTIVE',
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_status (status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Users
CREATE TABLE IF NOT EXISTS users (
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
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Sender Numbers
CREATE TABLE IF NOT EXISTS sender_numbers (
    sender_number_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    user_id VARCHAR(50) NOT NULL,
    sender_number VARCHAR(16) NOT NULL,
    is_verified BOOLEAN DEFAULT FALSE,
    is_default BOOLEAN DEFAULT FALSE,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(user_id),
    UNIQUE KEY uk_user_sender (user_id, sender_number),
    INDEX idx_user_id (user_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 나머지 테이블들...
-- (backend-design.md 참고)
```

### 4.3 Message DB 스키마 생성

**init-db/messagedb/01-schema.sql**

```sql
-- UMS Message Table
CREATE TABLE IF NOT EXISTS ums_msg (
    CLIENT_KEY VARCHAR(40) PRIMARY KEY COMMENT '메시지 고유 번호',
    REQ_CH VARCHAR(10) NOT NULL COMMENT '발송 채널',
    TRAFFIC_TYPE VARCHAR(10) DEFAULT 'normal',
    MSG_STATUS VARCHAR(10) NOT NULL,
    REQ_DATE DATETIME NOT NULL,
    CALLBACK_NUMBER VARCHAR(16) NOT NULL,
    PHONE VARCHAR(16),
    MSG VARCHAR(2000),
    TITLE VARCHAR(100),
    DEDUP_HASH VARCHAR(64),
    -- 나머지 필드들...
    INDEX idx_msg_status (MSG_STATUS),
    INDEX idx_traffic_type (TRAFFIC_TYPE),
    INDEX idx_req_date (REQ_DATE),
    INDEX idx_phone (PHONE),
    INDEX idx_dedup_hash (DEDUP_HASH)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

---

## 5. Docker 설정

### 5.1 루트 디렉토리에 docker-compose.yml 생성

```yaml
version: '3.8'

services:
  # MySQL - Web DB
  webdb:
    image: mysql:8.0
    container_name: linkwave-webdb
    environment:
      MYSQL_DATABASE: webdb
      MYSQL_ROOT_PASSWORD: ${WEB_DB_PASSWORD}
      MYSQL_CHARACTER_SET_SERVER: utf8mb4
      MYSQL_COLLATION_SERVER: utf8mb4_unicode_ci
    volumes:
      - webdb_data:/var/lib/mysql
      - ./init-db/webdb:/docker-entrypoint-initdb.d
    ports:
      - "3306:3306"
    networks:
      - linkwave-network
    healthcheck:
      test: ["CMD", "mysqladmin", "ping", "-h", "localhost"]
      interval: 10s
      timeout: 5s
      retries: 5

  # MySQL - Message DB (same port mapping for simplicity)
  messagedb:
    image: mysql:8.0
    container_name: linkwave-messagedb
    environment:
      MYSQL_DATABASE: messagedb
      MYSQL_ROOT_PASSWORD: ${MESSAGE_DB_PASSWORD}
      MYSQL_CHARACTER_SET_SERVER: utf8mb4
      MYSQL_COLLATION_SERVER: utf8mb4_unicode_ci
    volumes:
      - messagedb_data:/var/lib/mysql
      - ./init-db/messagedb:/docker-entrypoint-initdb.d
    ports:
      - "3306:3306"
    networks:
      - linkwave-network
    healthcheck:
      test: ["CMD", "mysqladmin", "ping", "-h", "localhost"]
      interval: 10s
      timeout: 5s
      retries: 5

  # Backend
  backend:
    build:
      context: ./iotree-linkwave-backend
      dockerfile: Dockerfile
    container_name: linkwave-backend
    ports:
      - "8080:8080"
    environment:
      SPRING_PROFILES_ACTIVE: prod
      WEB_DB_URL: jdbc:mysql://webdb:3306/webdb?useSSL=false&serverTimezone=Asia/Seoul
      WEB_DB_USERNAME: root
      WEB_DB_PASSWORD: ${WEB_DB_PASSWORD}
      MESSAGE_DB_URL: jdbc:mysql://messagedb:3306/messagedb?useSSL=false&serverTimezone=Asia/Seoul
      MESSAGE_DB_USERNAME: root
      MESSAGE_DB_PASSWORD: ${MESSAGE_DB_PASSWORD}
      JWT_SECRET: ${JWT_SECRET}
    depends_on:
      webdb:
        condition: service_healthy
      messagedb:
        condition: service_healthy
    networks:
      - linkwave-network
    restart: unless-stopped

  # Frontend
  frontend:
    build:
      context: ./iotree-linkwave-frontend
      dockerfile: Dockerfile
    container_name: linkwave-frontend
    ports:
      - "80:80"
    environment:
      API_BASE_URL: http://backend:8080/api/v1
    depends_on:
      - backend
    networks:
      - linkwave-network
    restart: unless-stopped

volumes:
  webdb_data:
    driver: local
  messagedb_data:
    driver: local

networks:
  linkwave-network:
    driver: bridge
```

### 5.2 .env 파일 생성

```bash
# Database
WEB_DB_PASSWORD=your_secure_webdb_password
MESSAGE_DB_PASSWORD=your_secure_messagedb_password

# JWT (최소 256bit)
JWT_SECRET=your-super-secret-jwt-key-must-be-at-least-256-bits-long-hs256
```

### 5.3 .env.example 생성

```bash
# Database
WEB_DB_PASSWORD=change_me
MESSAGE_DB_PASSWORD=change_me

# JWT
JWT_SECRET=change_me_to_secure_random_string_256_bits
```

---

## 6. 프로젝트 통합

### 6.1 루트 README.md 생성

기존 README.md를 루트 디렉토리에 복사합니다.

### 6.2 Git 초기화

```bash
# 루트 디렉토리
git init
git add .
git commit -m "Initial commit: Iotree LinkWave project setup"
```

### 6.3 .gitignore 생성 (루트)

```gitignore
# Environment
.env

# OS
.DS_Store
Thumbs.db

# Logs
*.log

# IDE
.idea/
.vscode/
*.iml
```

---

## 7. 로컬 개발 환경 실행

### 7.1 데이터베이스만 먼저 시작

```bash
# DB만 시작
docker-compose up -d webdb messagedb

# DB 로그 확인
docker-compose logs -f webdb messagedb
```

### 7.2 백엔드 로컬 실행

```bash
cd iotree-linkwave-backend

# 빌드
./gradlew clean build

# 실행
./gradlew bootRun
```

### 7.3 프론트엔드 로컬 실행

```bash
cd iotree-linkwave-frontend

# 개발 서버 시작
npm run dev
```

### 7.4 전체 스택 Docker로 실행

```bash
# 백엔드 빌드
cd iotree-linkwave-backend
./gradlew clean build
cd ..

# 프론트엔드 빌드는 Dockerfile에서 처리

# 전체 스택 시작
docker-compose up -d

# 로그 확인
docker-compose logs -f
```

---

## 8. 프로젝트 검증

### 8.1 백엔드 헬스체크

```bash
curl http://localhost:8080/actuator/health
```

예상 결과:
```json
{
  "status": "UP"
}
```

### 8.2 프론트엔드 접속

브라우저에서 http://localhost:3000 또는 http://localhost (Docker 실행 시) 접속

---

## 9. 다음 단계

1. **백엔드 구현**
   - Entity 클래스 작성
   - Repository 작성
   - Service 로직 구현
   - Controller 작성
   - Security 설정

2. **프론트엔드 구현**
   - 상태 관리 스토어 설정
   - API 클라이언트 작성
   - 컴포넌트 개발
   - 페이지 구성
   - 라우팅 설정

3. **테스트 작성**
   - 백엔드 단위/통합 테스트
   - 프론트엔드 컴포넌트 테스트

4. **배포 준비**
   - CI/CD 파이프라인 구축
   - 프로덕션 환경 설정
   - 모니터링 설정

---

## 📚 참고 문서

- [Backend Design](./backend-design.md)
- [Frontend Design](./frontend-design.md)
- [README](./README.md)

---

**Iotree LinkWave** - 메시지가 파도처럼 퍼져나가는 문자 발송 시스템 🌊
