---
created: 2025-12-26
---
# LinkWave Backend 배포 가이드

이 문서는 LinkWave Backend 애플리케이션의 배포 절차, CI/CD 설정, 운영 및 문제 해결 방법을 설명합니다.

## 목차

1. [배포 개요](#1-배포-개요)
2. [로컬 개발 환경](#2-로컬-개발-환경)
3. [운영 서버 배포 (JAR)](#3-운영-서버-배포-jar)
4. [CI/CD 자동 배포 (GitLab)](#4-cicd-자동-배포-gitlab)
5. [운영 및 모니터링](#5-운영-및-모니터링)
6. [문제 해결](#6-문제-해결)

---

## 1. 배포 개요

### 1.1 배포 방식

LinkWave Backend는 **JAR 직접 배포** 방식을 사용합니다 (Docker Compose 아님).

- **애플리케이션**: JAR 파일을 nohup으로 직접 실행
- **MySQL**: 별도 Docker Compose로 관리
- **프로세스 관리**: Shell scripts (start-jar.sh, stop-jar.sh)

### 1.2 서버 정보

**개발 서버**:
- **Host**: `nas.iotree.co.kr`
- **SSH Port**: `8122`
- **User**: `sanghpark`
- **App Directory**: `/home/sanghpark/app/link-wave`
- **MySQL Directory**: `/home/sanghpark/mysql`

**디렉토리 구조**:
```
/home/sanghpark/app/link-wave/
├── release/
│   └── linkwave-backend.jar
├── scripts/
│   ├── start-jar.sh
│   └── stop-jar.sh
├── config/
│   └── .env
├── logs/
│   ├── linkwave.log
│   └── application-startup.log
└── pids/
    └── linkwave.pid

/home/sanghpark/mysql/
├── docker-compose.yml
├── data/                   # MySQL 데이터 (HDD 심볼릭 링크)
└── logs/                   # MySQL 로그
```

---

## 2. 로컬 개발 환경

### 2.1 사전 준비

- **Java 21** - OpenJDK 또는 Oracle JDK
- **MySQL 8.0** - Docker 또는 직접 설치
- **Gradle 8.5+** - Wrapper 사용 가능
- **Git** - 버전 관리

### 2.2 설정 파일 준비

#### config/.env 파일 생성

프로젝트 루트의 `config` 디렉토리에 `.env` 파일을 생성합니다.

```bash
mkdir -p config
cat > config/.env <<'EOF'
# Spring Profile
SPRING_PROFILE=local

# Database
DB_NAME=linkwave
DB_USER=linkwave
DB_PASSWORD=your_local_password
DB_ROOT_PASSWORD=your_local_root_password

# JWT
JWT_SECRET=your-256-bit-secret-key-minimum-32-characters-long-for-hs256
JWT_EXPIRATION=86400000  # 24 hours in ms

# File Upload
FILE_MAX_SIZE=10485760   # 10MB

# Message Settings
MESSAGE_DEDUP_ENABLED=true
MESSAGE_DEDUP_WINDOW=10  # minutes
MESSAGE_BATCH_THRESHOLD=100  # recipients
EOF
```

#### config/application-local.yml 파일 (선택 사항)

필요한 경우 로컬 환경 오버라이드 설정을 추가할 수 있습니다.

```yaml
spring:
  datasource:
    url: jdbc:mysql://localhost:3307/linkwave?useSSL=false&allowPublicKeyRetrieval=true
    username: ${DB_USER}
    password: ${DB_PASSWORD}

logging:
  level:
    io.iotree.linkwave: DEBUG
```

### 2.3 MySQL 시작 (Docker)

```bash
cd deployment/mysql
docker-compose up -d
cd ../..
```

**확인**:
```bash
docker ps | grep linkwave-mysql
docker logs linkwave-mysql
```

### 2.4 애플리케이션 실행

```bash
# 빌드
./gradlew clean build

# 실행
./gradlew bootRun
```

### 2.5 서비스 확인

```bash
# 헬스 체크
curl http://localhost:8080/actuator/health

# 응답 예시
{"status":"UP"}
```

---

## 3. 운영 서버 배포 (JAR)

### 3.1 MySQL 설정

서버에서 MySQL을 Docker Compose로 실행합니다.

```bash
# 서버 접속
ssh -p 8122 sanghpark@nas.iotree.co.kr

# MySQL 시작
cd /home/sanghpark/mysql
docker-compose up -d

# 확인
docker ps | grep mysql
docker logs mysql
```

**MySQL 데이터 위치**:
- 기본: `/home/sanghpark/mysql/data`
- HDD 마운트: `/mnt/hdd/mysql-data` (심볼릭 링크)

### 3.2 빌드 및 업로드

로컬 환경에서 빌드 후 서버로 업로드합니다.

```bash
# 1. 빌드 (테스트 제외)
./gradlew clean build -x test

# 2. JAR 파일 업로드
scp -P 8122 build/libs/linkwave-backend.jar sanghpark@nas.iotree.co.kr:/home/sanghpark/app/link-wave/release/

# 3. 스크립트 업로드 (변경 시)
scp -P 8122 scripts/start-jar.sh scripts/stop-jar.sh sanghpark@nas.iotree.co.kr:/home/sanghpark/app/link-wave/scripts/
```

### 3.3 실행

서버에서 애플리케이션을 시작합니다.

```bash
# 서버 접속
ssh -p 8122 sanghpark@nas.iotree.co.kr

# 앱 디렉토리로 이동
cd /home/sanghpark/app/link-wave

# 스크립트 실행 권한 확인
chmod +x scripts/*.sh

# 기존 프로세스 종료
./scripts/stop-jar.sh

# 새 버전 시작
./scripts/start-jar.sh
```

### 3.4 확인

```bash
# 프로세스 확인
ps -ef | grep linkwave-backend.jar

# PID 파일 확인
cat pids/linkwave.pid

# 로그 확인
tail -f logs/application-startup.log
tail -f logs/linkwave.log

# 헬스 체크
curl http://localhost:8080/actuator/health
```

---

## 4. CI/CD 자동 배포 (GitLab)

### 4.1 GitLab CI/CD 파이프라인

`.gitlab-ci.yml` 파일에 정의된 파이프라인:

**Stages**:
1. **build**: 코드 빌드, 테스트, JAR 생성
2. **deploy**: 서버 배포 (수동 트리거)

**Branches**:
- **develop**: 개발 서버 자동 배포 (수동 트리거)
- **main**: 운영 서버 배포 (수동 트리거)

### 4.2 파이프라인 동작

```yaml
deploy:
  stage: deploy
  script:
    # 1. JAR 파일 복사
    - scp -P 8122 build/libs/*.jar sanghpark@nas.iotree.co.kr:/home/sanghpark/app/link-wave/release/linkwave-backend.jar

    # 2. 스크립트 복사
    - scp -P 8122 scripts/*.sh sanghpark@nas.iotree.co.kr:/home/sanghpark/app/link-wave/scripts/

    # 3. 원격 재시작
    - |
      ssh -p 8122 sanghpark@nas.iotree.co.kr << 'ENDSSH'
        cd /home/sanghpark/app/link-wave || exit 1
        chmod +x scripts/*.sh
        ./scripts/stop-jar.sh || true
        ./scripts/start-jar.sh
      ENDSSH
  when: manual
  only:
    - develop
```

### 4.3 배포 실행 방법

1. GitLab 프로젝트 페이지 → **CI/CD** → **Pipelines** 이동
2. `develop` 브랜치의 최신 파이프라인 선택
3. **deploy** stage에서 **수동 실행 버튼** 클릭
4. 배포 로그 확인

### 4.4 GitLab Runner 설정

**Runner 위치**: `nas.iotree.co.kr` 서버에 설치

**Executor**: Shell

**SSH Key 설정**:
- GitLab CI/CD Variables에 `SSH_PRIVATE_KEY` 등록
- 서버에 공개키 등록 (`~/.ssh/authorized_keys`)

---

## 5. 운영 및 모니터링

### 5.1 로그 확인

```bash
# 애플리케이션 시작 로그
tail -f /home/sanghpark/app/link-wave/logs/application-startup.log

# 애플리케이션 실행 로그
tail -f /home/sanghpark/app/link-wave/logs/linkwave.log

# MySQL 로그
docker logs mysql
```

### 5.2 애플리케이션 재시작

```bash
cd /home/sanghpark/app/link-wave

# 종료
./scripts/stop-jar.sh

# 시작
./scripts/start-jar.sh

# 한 번에 재시작 (stop 후 start)
./scripts/stop-jar.sh && ./scripts/start-jar.sh
```

### 5.3 프로세스 상태 확인

```bash
# 프로세스 확인
ps -ef | grep linkwave-backend.jar

# PID 파일 확인
cat /home/sanghpark/app/link-wave/pids/linkwave.pid

# 포트 확인
netstat -tuln | grep 8080
lsof -i:8080
```

### 5.4 데이터베이스 백업

```bash
# MySQL 백업 (Docker 컨테이너 내부)
docker exec mysql mysqldump -u root -p linkwave > backup_$(date +%Y%m%d).sql

# 또는 호스트에서 직접
mysqldump -h localhost -P 3307 -u root -p linkwave > backup.sql

# 백업 복원
mysql -h localhost -P 3307 -u root -p linkwave < backup.sql
```

### 5.5 디스크 사용량 확인

```bash
# 전체 디스크 사용량
df -h

# 앱 디렉토리 사용량
du -sh /home/sanghpark/app/link-wave/*

# MySQL 데이터 디렉토리 사용량
du -sh /mnt/hdd/mysql-data
```

---

## 6. 문제 해결

### 6.1 MySQL 연결 실패

**증상**: 애플리케이션이 MySQL에 연결할 수 없음

**확인 사항**:
```bash
# Docker 컨테이너 상태
docker ps | grep mysql

# MySQL 로그
docker logs mysql

# 포트 확인
netstat -tuln | grep 3307
lsof -i:3307

# MySQL 접속 테스트
mysql -h localhost -P 3307 -u linkwave -p
```

**해결 방법**:
```bash
# MySQL 재시작
cd /home/sanghpark/mysql
docker-compose restart

# MySQL 완전 재시작
docker-compose down
docker-compose up -d
```

### 6.2 포트 충돌

**증상**: 8080 포트가 이미 사용 중

**확인**:
```bash
# 포트 사용 프로세스 확인
lsof -i:8080
netstat -tuln | grep 8080
```

**해결 방법**:
```bash
# 기존 프로세스 종료
./scripts/stop-jar.sh

# 강제 종료 (필요 시)
kill -9 $(lsof -t -i:8080)

# 또는 포트 변경 (application.yml)
server:
  port: 8081
```

### 6.3 Out of Memory

**증상**: `java.lang.OutOfMemoryError`

**해결 방법**: `start-jar.sh` 스크립트에서 JVM 옵션 조정

```bash
# start-jar.sh 수정
nohup "$JAVA_HOME/bin/java" \
    -Xms512m \
    -Xmx2048m \
    -XX:+UseG1GC \
    -jar "$JAR_FILE" \
    > "$STARTUP_LOG" 2>&1 &
```

**권장 설정**:
- 개발 서버: `-Xms512m -Xmx1024m`
- 운영 서버: `-Xms1024m -Xmx2048m`

### 6.4 프로세스가 종료되지 않음

**증상**: `stop-jar.sh` 실행 후에도 프로세스가 살아있음

**해결 방법**:
```bash
# PID 확인
cat pids/linkwave.pid

# 강제 종료
kill -9 $(cat pids/linkwave.pid)

# 또는 프로세스명으로 찾아서 종료
pkill -9 -f linkwave-backend.jar

# PID 파일 삭제
rm pids/linkwave.pid
```

### 6.5 Permission Denied (스크립트 실행 오류)

**증상**: `./scripts/start-jar.sh: Permission denied`

**해결 방법**:
```bash
# 스크립트 실행 권한 부여
chmod +x /home/sanghpark/app/link-wave/scripts/*.sh

# 확인
ls -la scripts/
```

### 6.6 Java 버전 불일치

**증상**: `Unsupported class file major version`

**확인**:
```bash
# 서버 Java 버전 확인
java -version

# JAVA_HOME 확인
echo $JAVA_HOME
```

**해결 방법**:
```bash
# start-jar.sh에서 Java 21 경로 지정
JAVA_HOME=/usr/lib/jvm/java-21-openjdk-amd64
```

### 6.7 환경 변수 로드 실패

**증상**: `config/.env` 파일을 찾을 수 없음

**확인**:
```bash
# .env 파일 존재 확인
ls -la /home/sanghpark/app/link-wave/config/.env

# 파일 권한 확인
chmod 600 config/.env
```

### 6.8 로그 파일이 너무 큼

**증상**: 디스크 공간 부족

**해결 방법**:
```bash
# 로그 파일 크기 확인
du -sh logs/*

# 오래된 로그 삭제 (7일 이상)
find logs/ -name "*.log" -mtime +7 -delete

# 또는 압축
gzip logs/linkwave.log.2024-12-01

# logrotate 설정 (권장)
cat > /etc/logrotate.d/linkwave <<'EOF'
/home/sanghpark/app/link-wave/logs/*.log {
    daily
    rotate 7
    compress
    missingok
    notifempty
}
EOF
```

### 6.9 GitLab CI/CD 배포 실패

**증상**: GitLab 파이프라인 deploy stage 실패

**확인 사항**:
1. SSH 키 설정 확인
2. 서버 접근 권한 확인
3. 스크립트 실행 권한 확인

**해결 방법**:
```bash
# GitLab CI/CD Variables 확인
# - SSH_PRIVATE_KEY
# - SSH_KNOWN_HOSTS

# 서버에서 SSH 키 등록 확인
cat ~/.ssh/authorized_keys | grep gitlab

# 수동으로 배포 테스트
ssh -p 8122 sanghpark@nas.iotree.co.kr "cd /home/sanghpark/app/link-wave && ./scripts/start-jar.sh"
```

---

## 7. 추가 참고 사항

### 7.1 Spring Profile 관리

- **local**: 로컬 개발 환경
- **dev**: 개발 서버
- **prod**: 운영 서버 (예정)

Profile 변경:
```bash
# config/.env 파일에서
SPRING_PROFILE=dev
```

### 7.2 Blue-Green 배포 (향후 계획)

현재는 단일 인스턴스 배포이지만, 향후 무중단 배포를 위해 Blue-Green 방식 고려:

1. 2개 인스턴스 실행 (8080, 8081)
2. Nginx 리버스 프록시로 트래픽 전환
3. 한쪽씩 순차적으로 업데이트

### 7.3 모니터링 도구 (향후 계획)

- **Spring Boot Actuator**: 헬스 체크, 메트릭스
- **Prometheus + Grafana**: 메트릭 수집 및 시각화
- **ELK Stack**: 로그 수집 및 분석
- **Sentry**: 에러 추적

---

## 8. 체크리스트

### 배포 전 체크리스트

- [ ] 코드 리뷰 완료
- [ ] 테스트 통과 확인 (`./gradlew test`)
- [ ] 코드 포맷 적용 (`./gradlew spotlessApply`)
- [ ] config/.env 설정 확인
- [ ] MySQL 서버 실행 중
- [ ] 서버 디스크 공간 확인 (`df -h`)

### 배포 후 체크리스트

- [ ] 애플리케이션 프로세스 확인 (`ps -ef | grep linkwave`)
- [ ] 헬스 체크 성공 (`curl http://localhost:8080/actuator/health`)
- [ ] 로그 에러 없음 (`tail -f logs/linkwave.log`)
- [ ] API 엔드포인트 정상 동작 확인
- [ ] 데이터베이스 연결 확인

---

## 참고 문서

- [README.md](../README.md) - 프로젝트 개요 및 빠른 시작
- [DEVELOPER-HANDBOOK.md](DEVELOPER-HANDBOOK.md) - 개발자 핸드북
- [ARCHITECTURE.md](ARCHITECTURE.md) - JPA/MyBatis 전략
- [Implementation Guides](implementation-guides/) - 단계별 구현 가이드
