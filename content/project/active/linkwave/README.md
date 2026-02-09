---
created: 2025-12-03
---
# Iotree LinkWave

> 메시지가 파도처럼 퍼져나가는 문자 발송 시스템 프로토타입

**LinkWave**는 다양한 메시지 채널(SMS → LMS → MMS → RCS → 카카오톡 → 푸시)의 확장성을 표현하며,
연결된 메시지가 파도처럼 전파되는 의미를 담고 있습니다.

## 📋 프로젝트 개요

Iotree LinkWave는 SMS, LMS, MMS 문자 발송 기능을 제공하는 웹 기반 메시징 플랫폼의 프로토타입입니다.
사용자가 메시지를 작성하고 발송 요청하면, 시스템이 이를 데이터베이스에 저장하여 발송 준비를 완료합니다.

### 핵심 기능

- ✉️ **다중 메시지 타입**: SMS, LMS, MMS 지원
- 👥 **수신자 관리**: 직접 입력, 주소록 선택, 엑셀 업로드
- ⏰ **예약 발송**: 원하는 시간에 자동 발송
- 🔒 **중복 방지**: 동일 번호/내용 중복 발송 차단
- 📊 **발송 이력**: 발송 현황 및 통계 조회
- 📱 **반응형 UI**: 모바일/태블릿/데스크톱 대응

---

## 🏗️ 시스템 아키텍처

```
┌─────────────────────────────────────────────┐
│               Frontend (React)              │
│  - Zustand (전역 상태)                      │
│  - TanStack Query (서버 상태)              │
└─────────────────────────────────────────────┘
                    ↓ REST API
┌─────────────────────────────────────────────┐
│            Backend (Spring Boot)            │
│  - REST API                                 │
│  - Business Logic                           │
│  - Data Sync Module                         │
└─────────────────────────────────────────────┘
                    ↓
┌──────────────────────┐  ┌──────────────────┐
│   Web DB (MySQL)     │  │ Message DB       │
│  - 사용자 관리       │  │  - 발송 요청     │
│  - 주소록            │  │  - 발송 이력     │
│  - 보관함            │  │                  │
└──────────────────────┘  └──────────────────┘
```

### 데이터베이스 분리 전략

**Web DB**
- 목적: 사용자 인터페이스 및 부가 기능 지원
- 특징: 빈번한 읽기/쓰기, 사용자 경험 최적화
- 테이블: 회사, 사용자, 주소록, 보관함, 발신번호

**Message DB**
- 목적: 메시지 발송 처리 및 이력 관리
- 특징: 대용량 처리, 발송 성능 최적화
- 테이블: ums_msg (발송 요청), ums_log_{YYYYMM} (월별 이력)

---

## 🛠️ 기술 스택

### 백엔드

| 카테고리 | 기술 | 버전 | 용도 |
|---------|------|------|------|
| **Framework** | Spring Boot | 4.0+ | 백엔드 프레임워크 |
| **Language** | Java | 17+ | 프로그래밍 언어 |
| **Build Tool** | Gradle | 8.x | 빌드 도구 |
| **Database** | MySQL | 8.0+ | 관계형 데이터베이스 |
| **ORM** | JPA/Hibernate | 6.x | 객체 관계 매핑 |
| **Security** | Spring Security | 6.x | 인증/인가 |
| **Auth** | JWT | - | 토큰 기반 인증 |
| **Logging** | SLF4J + Logback | - | 로깅 |
| **Monitoring** | Spring Actuator | - | 헬스체크/메트릭 |
| **Test** | JUnit 5 | 5.x | 단위 테스트 |
| | Mockito | - | 모킹 프레임워크 |
| | TestContainers | - | 통합 테스트 |
| | RestAssured | - | API 테스트 |

**추천 기술 (선택사항)**
- Micrometer: 메트릭 수집 및 모니터링
- Spring AOP: 관점 지향 프로그래밍 (로깅/감사)
- Redis: 캐싱 및 Rate Limiting
- MinIO/S3: 파일 저장소

### 프론트엔드

| 카테고리 | 기술 | 버전 | 용도 |
|---------|------|------|------|
| **Framework** | React | 18+ | UI 프레임워크 |
| **Language** | JavaScript | ES6+ | 프로그래밍 언어 |
| **Build Tool** | Vite | 5.x | 빌드 도구 |
| **State (Global)** | Zustand | 4.x | 전역 상태 관리 |
| **State (Server)** | TanStack Query | 5.x | 서버 상태 관리 |
| **Routing** | React Router | 6.x | 라우팅 |
| **HTTP Client** | Axios | 1.x | API 통신 |
| **Date** | date-fns | 3.x | 날짜 처리 |

**추천 기술 (선택사항)**
- Tailwind CSS: 유틸리티 기반 스타일링
- shadcn/ui: 컴포넌트 라이브러리
- React Hook Form: 폼 상태 관리
- Zod: 스키마 검증
- react-hot-toast: 알림 메시지
- Recharts: 통계 차트
- react-dropzone: 파일 업로드

---

## 📦 프로젝트 구조

### 백엔드 구조

```
quicksend-proto-backend/
├── src/main/java/com/quicksend/proto/
│   ├── config/              # 설정 클래스
│   ├── api/                 # REST 컨트롤러
│   ├── dto/                 # 데이터 전송 객체
│   ├── entity/              # JPA 엔티티
│   │   ├── webdb/          # Web DB 엔티티
│   │   └── messagedb/      # Message DB 엔티티
│   ├── repository/          # 데이터 접근 계층
│   │   ├── webdb/
│   │   └── messagedb/
│   ├── service/             # 비즈니스 로직
│   ├── exception/           # 예외 처리
│   └── util/                # 유틸리티
├── src/main/resources/
│   ├── application.yml      # 설정 파일
│   └── logback-spring.xml   # 로깅 설정
└── src/test/                # 테스트 코드
```

### 프론트엔드 구조

```
quicksend-proto-frontend/
├── src/
│   ├── api/                 # API 클라이언트
│   ├── components/          # React 컴포넌트
│   │   ├── common/         # 공통 컴포넌트
│   │   ├── message/        # 메시지 관련
│   │   ├── forms/          # 폼 컴포넌트
│   │   ├── history/        # 이력 조회
│   │   ├── dashboard/      # 대시보드
│   │   └── addressBook/    # 주소록
│   ├── pages/              # 페이지 컴포넌트
│   ├── hooks/              # Custom Hooks
│   ├── stores/             # Zustand 스토어
│   ├── types/              # TypeScript 타입
│   ├── utils/              # 유틸리티 함수
│   ├── App.tsx
│   └── main.tsx
└── package.json
```

---

## 🚀 시작하기

### 사전 요구사항

- Java 17 이상
- Node.js 18 이상
- MySQL 8.0 이상
- Git

### 백엔드 설정

#### 1. 저장소 클론

```bash
git clone https://github.com/your-org/iotree-linkwave-backend.git
cd iotree-linkwave-backend
```

#### 2. 데이터베이스 생성

```sql
-- Web DB
CREATE DATABASE webdb CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- Message DB
CREATE DATABASE messagedb CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
```

#### 3. 환경 변수 설정

```bash
# application-dev.yml 생성
cp src/main/resources/application.yml src/main/resources/application-dev.yml
```

```yaml
# application-dev.yml
spring:
  datasource:
    webdb:
      jdbc-url: jdbc:mysql://localhost:3306/webdb
      username: your_username
      password: your_password
    messagedb:
      jdbc-url: jdbc:mysql://localhost:3306/messagedb
      username: your_username
      password: your_password
```

#### 4. 빌드 및 실행

```bash
# 빌드
./gradlew build

# 실행
./gradlew bootRun --args='--spring.profiles.active=dev'
```

서버가 `http://localhost:8080`에서 실행됩니다.

### 프론트엔드 설정

#### 1. 저장소 클론

```bash
git clone https://github.com/your-org/iotree-linkwave-frontend.git
cd iotree-linkwave-frontend
```

#### 2. 의존성 설치

```bash
npm install
```

#### 3. 환경 변수 설정

```bash
# .env 생성
cp .env.example .env
```

```bash
# .env
VITE_API_BASE_URL=http://localhost:8080/api/v1
VITE_MAX_FILE_SIZE=10485760
```

#### 4. 개발 서버 실행

```bash
npm run dev
```

앱이 `http://localhost:3000`에서 실행됩니다.

---

## 📖 주요 기능 가이드

### 1. SMS 발송

1. 상단 네비게이션에서 **[SMS]** 클릭
2. 수신자 전화번호 입력 또는 주소록 선택
3. 발신번호 선택
4. 메시지 내용 입력 (최대 90byte)
5. 즉시 발송 또는 예약 발송 선택
6. **[발송]** 버튼 클릭

### 2. LMS 발송

1. 상단 네비게이션에서 **[LMS]** 클릭
2. 수신자 입력
3. 발신번호 선택
4. 제목 입력 (선택)
5. 메시지 내용 입력 (최대 2000byte)
6. **[발송]** 버튼 클릭

### 3. MMS 발송

1. 상단 네비게이션에서 **[MMS]** 클릭
2. 수신자 입력
3. 발신번호 선택
4. 제목 입력
5. 메시지 내용 입력
6. 이미지 파일 업로드 (JPG/PNG, 최대 300KB)
7. **[발송]** 버튼 클릭

### 4. 발송 이력 조회

1. 상단 네비게이션에서 **[발송이력]** 클릭
2. 조회 기간 및 필터 설정
3. 목록에서 항목 클릭하여 상세 조회
4. 예약 발송 건은 취소 가능

### 5. 주소록 관리

1. 상단 네비게이션에서 **[주소록]** 클릭
2. **[새 연락처]** 버튼으로 추가
3. 그룹별 분류 가능
4. 엑셀 파일로 대량 등록 가능

---

## 🔧 설정 및 커스터마이징

### 백엔드 설정

#### TRAFFIC_TYPE 결정 로직

메시지의 우선순위를 결정하는 로직을 커스터마이징할 수 있습니다.

```java
// MessageSyncService.java
private String determineTrafficType(MessageRequest request) {
    // 사용자 지정 우선
    if (request.getTrafficType() != null) {
        return request.getTrafficType();
    }

    // 예약 발송은 batch
    if (request.getScheduledAt() != null &&
        request.getScheduledAt().isAfter(LocalDateTime.now().plusMinutes(10))) {
        return "batch";
    }

    // 대량 발송은 batch (임계값 변경 가능)
    if (request.getRecipientCount() > 100) {
        return "batch";
    }

    // 기본은 normal
    return "normal";
}
```

#### 중복 발송 방지 시간 윈도우

```yaml
# application.yml
message:
  dedup:
    default-window-minutes: 10  # 기본 10분, 필요시 변경
```

#### Rate Limiting 설정

```java
// RateLimitInterceptor.java
if (count.incrementAndGet() > 100) {  // 분당 100회 제한, 필요시 변경
    response.setStatus(HttpStatus.TOO_MANY_REQUESTS.value());
    return false;
}
```

### 프론트엔드 설정

#### 바이트 계산 로직

```typescript
// utils/formatting.ts
export const calculateByteSize = (text: string): number => {
  let byteSize = 0;
  for (let i = 0; i < text.length; i++) {
    const char = text.charAt(i);
    if (escape(char).length > 4) {
      byteSize += 2; // 한글 등 멀티바이트 문자
    } else {
      byteSize += 1; // 영문, 숫자 등
    }
  }
  return byteSize;
};
```

#### API 재시도 로직

```typescript
// api/client.ts
client.interceptors.response.use(
  (response) => response.data,
  async (error) => {
    const config = error.config;

    // 재시도 로직 추가 가능
    if (!config._retry && error.response?.status >= 500) {
      config._retry = true;
      return client.request(config);
    }

    return Promise.reject(error);
  }
);
```

---

## 🧪 테스트

### 백엔드 테스트

```bash
# 전체 테스트 실행
./gradlew test

# 특정 테스트 클래스 실행
./gradlew test --tests MessageServiceTest

# 통합 테스트 실행
./gradlew integrationTest
```

### 프론트엔드 테스트

```bash
# 단위 테스트
npm run test

# 커버리지 포함
npm run test:coverage
```

---

## 📊 API 문서

### Swagger UI (추후 추가 예정)

백엔드 서버 실행 후 다음 URL에서 API 문서 확인:

```
http://localhost:8080/swagger-ui.html
```

### 주요 엔드포인트

| Method | Endpoint | 설명 |
|--------|----------|------|
| POST | `/api/v1/auth/login` | 로그인 |
| POST | `/api/v1/messages` | 메시지 발송 요청 |
| GET | `/api/v1/messages` | 메시지 목록 조회 |
| GET | `/api/v1/messages/{clientKey}` | 메시지 상세 조회 |
| DELETE | `/api/v1/messages/{clientKey}/schedule` | 예약 발송 취소 |
| GET | `/api/v1/statistics/summary` | 발송 통계 조회 |
| GET | `/api/v1/address-book` | 주소록 조회 |
| POST | `/api/v1/address-book` | 주소록 추가 |
| GET | `/api/v1/sender-numbers` | 발신번호 목록 조회 |

---

## 🔐 보안

### 인증/인가

- JWT 토큰 기반 인증
- Spring Security를 통한 엔드포인트 보호
- Role 기반 접근 제어 (USER, ADMIN)

### 데이터 보호

- HTTPS 통신 권장
- 비밀번호는 BCrypt로 암호화 저장
- SQL Injection 방지 (Prepared Statement)
- XSS 방지 (입력 검증 및 이스케이프)

### Rate Limiting

- API 호출 제한 (사용자별/IP별)
- 대량 발송 시 Throttling

---

## 📈 모니터링

### Spring Actuator 엔드포인트

```
http://localhost:8080/actuator/health
http://localhost:8080/actuator/metrics
http://localhost:8080/actuator/prometheus
```

### 주요 메트릭

- API 응답 시간
- 데이터베이스 커넥션 풀 상태
- 메시지 등록 성공률
- DB에 저장된 대기 메시지 수

---

## 🚢 배포

### 백엔드 배포

#### JAR 빌드

```bash
./gradlew clean build
```

#### 실행

```bash
java -jar build/libs/iotree-linkwave-backend-0.1.0.jar \
  --spring.profiles.active=prod
```

#### Docker

```dockerfile
FROM openjdk:17-slim
WORKDIR /app
COPY build/libs/*.jar app.jar
EXPOSE 8080
ENTRYPOINT ["java","-jar","/app.jar"]
```

```bash
# 이미지 빌드
docker build -t iotree-linkwave-backend:0.1.0 .

# 컨테이너 실행
docker run -p 8080:8080 \
  -e SPRING_PROFILES_ACTIVE=prod \
  iotree-linkwave-backend:0.1.0
```

### 프론트엔드 배포

#### 빌드

```bash
npm run build
```

빌드 결과물은 `dist/` 디렉토리에 생성됩니다.

#### Nginx 설정

```nginx
server {
    listen 80;
    server_name linkwave.iotree.com;

    root /var/www/iotree-linkwave/dist;
    index index.html;

    location / {
        try_files $uri $uri/ /index.html;
    }

    location /api {
        proxy_pass http://backend:8080;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

### Docker Compose 배포 (권장)

전체 스택을 한 번에 배포하는 방법입니다.

#### docker-compose.yml

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

  # MySQL - Message DB (separate container, same port mapping for simplicity)
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

  # Frontend (Nginx)
  frontend:
    build:
      context: ./iotree-linkwave-frontend
      dockerfile: Dockerfile
    container_name: linkwave-frontend
    ports:
      - "80:80"
      - "443:443"
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

#### .env 파일

```bash
# Database
WEB_DB_PASSWORD=your_secure_password_here
MESSAGE_DB_PASSWORD=your_secure_password_here

# JWT
JWT_SECRET=your_jwt_secret_key_min_256_bits
```

#### 배포 실행

```bash
# 전체 스택 시작
docker-compose up -d

# 로그 확인
docker-compose logs -f

# 특정 서비스 로그
docker-compose logs -f backend

# 전체 스택 중지
docker-compose down

# 볼륨까지 삭제 (데이터 초기화)
docker-compose down -v
```

#### Frontend Dockerfile

```dockerfile
# Build stage
FROM node:18-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run build

# Production stage
FROM nginx:alpine
COPY --from=builder /app/dist /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
```

#### nginx.conf (Frontend)

```nginx
server {
    listen 80;
    server_name _;

    root /usr/share/nginx/html;
    index index.html;

    # Gzip compression
    gzip on;
    gzip_types text/css application/javascript application/json;

    location / {
        try_files $uri $uri/ /index.html;
    }

    location /api {
        proxy_pass http://backend:8080;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;

        # CORS headers (if needed)
        add_header Access-Control-Allow-Origin *;
    }
}
```

---

## 🛣️ 로드맵

### Phase 1 - MVP (현재)

- [x] SMS, LMS, MMS 발송
- [x] 수신자 관리
- [x] 발송 이력 조회
- [x] 기본 주소록 기능
- [x] 예약 발송
- [x] 중복 발송 방지

### Phase 2 - 확장 (계획)

- [ ] 카카오톡 알림톡/친구톡
- [ ] RCS 메시지
- [ ] 템플릿 관리
- [ ] 대량 발송 최적화
- [ ] 파일 저장소 (S3/MinIO)
- [ ] 통계 대시보드 강화

### Phase 3 - 고도화 (계획)

- [ ] Webhook 콜백
- [ ] API 키 관리
- [ ] 멀티 테넌시 강화
- [ ] 발송 결과 실시간 업데이트 (WebSocket)
- [ ] 모바일 앱 (React Native)

---

## 🤝 기여

프로젝트에 기여하고 싶으시다면:

1. Fork the Project
2. Create your Feature Branch (`git checkout -b feature/AmazingFeature`)
3. Commit your Changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the Branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

---

## 📝 라이선스

이 프로젝트는 MIT 라이선스 하에 배포됩니다. 자세한 내용은 `LICENSE` 파일을 참조하세요.

---

## 💬 문의 및 지원

- **이슈 트래커**: [GitHub Issues](https://github.com/your-org/iotree-linkwave/issues)
- **이메일**: support@iotree.com
- **문서**: [Wiki](https://github.com/your-org/iotree-linkwave/wiki)

---

## 🙏 감사의 말

이 프로젝트는 다음 오픈소스 프로젝트들의 도움을 받았습니다:

- Spring Boot
- React
- TanStack Query
- Zustand
- 그 외 많은 오픈소스 기여자들

---

## 📚 참고 자료

### 백엔드

- [Spring Boot Documentation](https://docs.spring.io/spring-boot/docs/current/reference/html/)
- [Spring Security Reference](https://docs.spring.io/spring-security/reference/)
- [JPA/Hibernate Guide](https://docs.jboss.org/hibernate/orm/current/userguide/html_single/)

### 프론트엔드

- [React Documentation](https://react.dev/)
- [TanStack Query Docs](https://tanstack.com/query/latest)
- [Zustand Documentation](https://docs.pmnd.rs/zustand)
- [TypeScript Handbook](https://www.typescriptlang.org/docs/)

### 데이터베이스

- [MySQL 8.0 Reference Manual](https://dev.mysql.com/doc/refman/8.0/en/)
- [Database Design Best Practices](https://www.databasestar.com/database-design-best-practices/)

---

## ⚖️ 기술 의사결정

### 왜 DB를 Web DB와 Message DB로 분리했나요?

- **성능 최적화**: 웹 서비스와 발송 처리를 독립적으로 최적화
- **부하 분산**: 사용자 트래픽과 발송 부하를 분리
- **확장성**: 각 DB를 독립적으로 스케일 업/아웃 가능
- **장애 격리**: Web DB 장애 시에도 발송 시스템은 정상 동작

### 왜 Zustand와 TanStack Query를 함께 사용하나요?

- **Zustand**: 클라이언트 상태 (UI 상태, 사용자 입력 등)
- **TanStack Query**: 서버 상태 (API 데이터, 캐싱, 동기화)
- 각 라이브러리가 담당하는 영역을 명확히 분리하여 코드 복잡도 감소

### 프로토타입인데 왜 TypeScript를 사용하나요?

- 빠른 개발 과정에서도 타입 안정성으로 버그 감소
- IDE 자동완성으로 생산성 향상
- 프로토타입에서 실제 제품으로 전환 시 리팩토링 용이

---

---

**Iotree LinkWave** - 메시지가 파도처럼 퍼져나가는 문자 발송 시스템 🌊
