---
created: 2026-02-10
tags:
  - linkwave
  - backend
  - deployment
---

> 이 문서는 linkwave-docs의 backend/DEPLOYMENT.md를 요약한 것입니다.

# LinkWave Backend 배포 가이드

## 1. 배포 개요

### 배포 방식
**JAR 직접 배포** (Docker Compose 아님)
- 애플리케이션: JAR → nohup 실행
- MySQL: 별도 Docker Compose
- 프로세스 관리: Shell scripts

### 서버 정보 (개발 서버)
- Host: `nas.iotree.co.kr` (SSH Port: 8122)
- App Directory: `/home/sanghpark/app/link-wave`

### 디렉토리 구조
```
/home/sanghpark/app/link-wave/
├── release/linkwave-backend.jar
├── scripts/ (start-jar.sh, stop-jar.sh)
├── config/.env
├── logs/ (linkwave.log)
└── pids/linkwave.pid
```

---

## 2. 로컬 개발 환경

```bash
# MySQL + Redis 실행
docker compose up -d

# 빌드
./gradlew clean build

# 실행
./gradlew bootRun --args='--spring.profiles.active=local'
```

---

## 3. 운영 서버 배포 (JAR)

### 빌드
```bash
./gradlew clean build -x test
# → build/libs/linkwave-backend-0.0.1-SNAPSHOT.jar
```

### 배포 순서
```bash
# 1. JAR 파일 전송
scp -P 8122 build/libs/linkwave-backend-*.jar \
  sanghpark@nas.iotree.co.kr:/home/sanghpark/app/link-wave/release/

# 2. SSH 접속
ssh -p 8122 sanghpark@nas.iotree.co.kr

# 3. 기존 프로세스 중지
cd /home/sanghpark/app/link-wave
./scripts/stop-jar.sh

# 4. 새 버전 실행
./scripts/start-jar.sh
```

### start-jar.sh
```bash
nohup java -jar release/linkwave-backend.jar \
  --spring.profiles.active=dev \
  > logs/linkwave.log 2>&1 &
echo $! > pids/linkwave.pid
```

### 환경 변수 (.env)
```
SPRING_DATASOURCE_URL=jdbc:mysql://localhost:3306/linkwave
SPRING_DATASOURCE_USERNAME=linkwave
SPRING_DATASOURCE_PASSWORD=****
JWT_SECRET=****
```

---

## 4. CI/CD (GitLab)

### 파이프라인
```
build → test → deploy
```

- **build**: `./gradlew clean build -x test`
- **test**: `./gradlew test`
- **deploy**: SCP + SSH로 자동 배포 (develop 브랜치 merge 시)

---

## 5. 운영 및 모니터링

### 로그 확인
```bash
# 실시간 로그
tail -f logs/linkwave.log

# 에러만 필터
grep ERROR logs/linkwave.log
```

### 프로세스 관리
```bash
# 상태 확인
cat pids/linkwave.pid | xargs ps -p

# 중지
./scripts/stop-jar.sh

# 재시작
./scripts/stop-jar.sh && ./scripts/start-jar.sh
```

### Health Check
- Spring Actuator: `GET /actuator/health`

---

## 6. 트러블슈팅

| 문제 | 원인 | 해결 |
|------|------|------|
| 서버 시작 실패 | 포트 충돌 | `lsof -i :8080`으로 확인 |
| DB 연결 실패 | Docker 미실행 | `docker compose up -d` |
| OOM | 힙 부족 | `-Xmx512m` 옵션 추가 |
| 로그 없음 | 경로 오류 | logs/ 디렉토리 확인 |

---

## Related Documents

- [[developer-handbook|Developer Handbook]]
- [[frontend-deployment|Frontend Deployment]]
