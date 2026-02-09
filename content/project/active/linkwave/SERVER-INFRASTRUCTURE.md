---
created: 2025-12-03
---
# Iotree LinkWave - 서버 인프라 구성 가이드

> 실제 운영 서버 구축을 위한 완전한 인프라 설정 가이드

---

## 📋 목차

1. [서버 사양 및 요구사항](#1-서버-사양-및-요구사항)
2. [디렉토리 구조 및 권한](#2-디렉토리-구조-및-권한)
3. [필수 소프트웨어 설치](#3-필수-소프트웨어-설치)
4. [데이터베이스 설정](#4-데이터베이스-설정)
5. [백엔드 배포 설정](#5-백엔드-배포-설정)
6. [프론트엔드 배포 설정](#6-프론트엔드-배포-설정)
7. [GitLab CI/CD 구성](#7-gitlab-cicd-구성)
8. [Jenkins 파이프라인 구성](#8-jenkins-파이프라인-구성)
9. [모니터링 및 로깅](#9-모니터링-및-로깅)
10. [보안 설정](#10-보안-설정)

---

## 1. 서버 사양 및 요구사항

### 1.1 권장 서버 스펙

#### 개발/스테이징 환경
```
┌─────────────────────────────────────┐
│  CPU: 4 Core                        │
│  RAM: 8GB                           │
│  Disk: 100GB SSD                    │
│  OS: Ubuntu 22.04 LTS               │
└─────────────────────────────────────┘
```

#### 프로덕션 환경
```
┌─────────────────────────────────────┐
│  CPU: 8 Core                        │
│  RAM: 16GB                          │
│  Disk: 200GB SSD                    │
│  OS: Ubuntu 22.04 LTS               │
└─────────────────────────────────────┘
```

### 1.2 필수 소프트웨어 버전

| 소프트웨어 | 버전 | 용도 |
|-----------|------|------|
| Java | 21 | 백엔드 런타임 |
| Node.js | 20 LTS | 프론트엔드 빌드 |
| npm | 10+ | 패키지 관리 |
| MySQL | 8.0+ | 데이터베이스 |
| Nginx | 1.24+ | 웹 서버 / 리버스 프록시 |
| Docker | 24+ | 컨테이너 (선택) |
| Git | 2.40+ | 버전 관리 |
| Gradle | 8.5+ | 빌드 도구 |

---

## 2. 디렉토리 구조 및 권한

### 2.1 전체 디렉토리 구조

```
/opt/
└── linkwave/                          # 애플리케이션 루트 (root:linkwave)
    ├── backend/                       # 백엔드 디렉토리 (linkwave:linkwave)
    │   ├── current/                   # 현재 실행중인 버전 (심볼릭 링크)
    │   ├── releases/                  # 릴리스 히스토리
    │   │   ├── 20250103-120000/
    │   │   ├── 20250103-130000/
    │   │   └── 20250103-140000/
    │   ├── shared/                    # 공유 설정 파일
    │   │   ├── application.yml
    │   │   ├── application-prod.yml
    │   │   └── logback-spring.xml
    │   └── logs/                      # 애플리케이션 로그
    │       ├── access.log
    │       ├── error.log
    │       └── application.log
    │
    ├── frontend/                      # 프론트엔드 디렉토리 (www-data:www-data)
    │   ├── current/                   # 현재 배포된 버전 (심볼릭 링크)
    │   └── releases/                  # 릴리스 히스토리
    │       ├── 20250103-120000/
    │       ├── 20250103-130000/
    │       └── 20250103-140000/
    │
    ├── data/                          # 데이터 디렉토리 (linkwave:linkwave)
    │   ├── files/                     # 업로드 파일 (MMS, 이미지 등)
    │   │   ├── mms/
    │   │   ├── rcs/
    │   │   └── temp/
    │   └── backups/                   # 백업 파일
    │       ├── db/
    │       └── files/
    │
    └── scripts/                       # 운영 스크립트 (linkwave:linkwave)
        ├── deploy-backend.sh
        ├── deploy-frontend.sh
        ├── backup.sh
        └── health-check.sh

/var/log/
└── linkwave/                          # 시스템 로그 (root:linkwave)
    ├── nginx/
    │   ├── access.log
    │   └── error.log
    └── systemd/
        └── linkwave-backend.log

/etc/
├── nginx/
│   ├── sites-available/
│   │   └── linkwave.conf
│   └── sites-enabled/
│       └── linkwave.conf -> ../sites-available/linkwave.conf
│
└── systemd/system/
    └── linkwave-backend.service
```

### 2.2 사용자 및 그룹 생성

```bash
# linkwave 그룹 생성
sudo groupadd -r linkwave

# linkwave 시스템 사용자 생성 (백엔드 실행용)
sudo useradd -r -g linkwave -s /bin/bash -d /opt/linkwave -m linkwave

# www-data 사용자를 linkwave 그룹에 추가 (프론트엔드용)
sudo usermod -a -G linkwave www-data

# linkwave 사용자를 www-data 그룹에 추가 (파일 공유용)
sudo usermod -a -G www-data linkwave
```

### 2.3 디렉토리 생성 및 권한 설정

```bash
# 루트 디렉토리 생성
sudo mkdir -p /opt/linkwave/{backend,frontend,data,scripts}
sudo mkdir -p /opt/linkwave/backend/{releases,shared,logs}
sudo mkdir -p /opt/linkwave/frontend/releases
sudo mkdir -p /opt/linkwave/data/{files,backups}
sudo mkdir -p /opt/linkwave/data/files/{mms,rcs,temp}
sudo mkdir -p /opt/linkwave/data/backups/{db,files}

# 로그 디렉토리 생성
sudo mkdir -p /var/log/linkwave/{nginx,systemd}

# 소유권 설정
sudo chown -R linkwave:linkwave /opt/linkwave
sudo chown -R www-data:www-data /opt/linkwave/frontend

# 권한 설정
sudo chmod 755 /opt/linkwave
sudo chmod 755 /opt/linkwave/backend
sudo chmod 755 /opt/linkwave/frontend
sudo chmod 775 /opt/linkwave/data
sudo chmod 775 /opt/linkwave/data/files
sudo chmod 700 /opt/linkwave/backend/shared  # 설정 파일 보호
sudo chmod 750 /opt/linkwave/scripts
sudo chmod 755 /var/log/linkwave

# 로그 디렉토리 권한
sudo chown -R linkwave:linkwave /var/log/linkwave
sudo chmod 755 /var/log/linkwave
```

### 2.4 권한 구조 시각화

```
┌─────────────────────────────────────────────────────────────┐
│                   /opt/linkwave                             │
│                 (linkwave:linkwave)                         │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌─────────────────────┐    ┌──────────────────────┐      │
│  │   backend/          │    │   frontend/          │      │
│  │ (linkwave:linkwave) │    │ (www-data:www-data)  │      │
│  │   755               │    │   755                │      │
│  │                     │    │                      │      │
│  │  • JAR 파일 실행    │    │  • Nginx가 파일 서빙 │      │
│  │  • 로그 쓰기        │    │  • 정적 파일만       │      │
│  └─────────────────────┘    └──────────────────────┘      │
│                                                             │
│  ┌─────────────────────────────────────────┐              │
│  │   data/files/                           │              │
│  │ (linkwave:linkwave)                     │              │
│  │   775 (그룹 쓰기 권한)                  │              │
│  │                                         │              │
│  │  • 백엔드: 파일 업로드 쓰기            │              │
│  │  • Nginx: 파일 읽기 (www-data 그룹)   │              │
│  └─────────────────────────────────────────┘              │
└─────────────────────────────────────────────────────────────┘
```

---

## 3. 필수 소프트웨어 설치

### 3.1 시스템 업데이트

```bash
sudo apt update
sudo apt upgrade -y
```

### 3.2 Java 21 설치

```bash
# OpenJDK 21 설치
sudo apt install -y openjdk-21-jdk

# 설치 확인
java -version

# 출력 예시:
# openjdk version "21.0.1" 2023-10-17
# OpenJDK Runtime Environment (build 21.0.1+12-Ubuntu-222.04)
# OpenJDK 64-Bit Server VM (build 21.0.1+12-Ubuntu-222.04, mixed mode, sharing)

# JAVA_HOME 환경변수 설정
echo 'export JAVA_HOME=/usr/lib/jvm/java-21-openjdk-amd64' | sudo tee -a /etc/profile
echo 'export PATH=$PATH:$JAVA_HOME/bin' | sudo tee -a /etc/profile
source /etc/profile
```

### 3.3 Node.js 20 LTS 설치

```bash
# NodeSource 저장소 추가
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -

# Node.js 설치
sudo apt install -y nodejs

# 설치 확인
node -v  # v20.x.x
npm -v   # 10.x.x
```

### 3.4 MySQL 8.0 설치

```bash
# MySQL 서버 설치
sudo apt install -y mysql-server

# MySQL 보안 설정
sudo mysql_secure_installation

# MySQL 서비스 시작 및 자동 시작 설정
sudo systemctl start mysql
sudo systemctl enable mysql

# 설치 확인
mysql --version
```

### 3.5 Nginx 설치

```bash
# Nginx 설치
sudo apt install -y nginx

# Nginx 서비스 시작 및 자동 시작 설정
sudo systemctl start nginx
sudo systemctl enable nginx

# 설치 확인
nginx -v  # nginx version: nginx/1.24.x
```

### 3.6 Git 설치

```bash
# Git 설치
sudo apt install -y git

# 설치 확인
git --version
```

### 3.7 Docker 설치 (선택사항)

```bash
# Docker 공식 GPG 키 추가
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

# Docker 저장소 추가
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Docker 설치
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

# 사용자를 docker 그룹에 추가
sudo usermod -aG docker linkwave

# 설치 확인
docker --version
docker compose version
```

---

## 4. 데이터베이스 설정

### 4.1 MySQL 사용자 및 데이터베이스 생성

```bash
# MySQL 접속
sudo mysql

# 또는 root 비밀번호로 접속
mysql -u root -p
```

```sql
-- Web DB 생성
CREATE DATABASE webdb CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- Message DB 생성
CREATE DATABASE messagedb CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- linkwave 사용자 생성 및 권한 부여
CREATE USER 'linkwave'@'localhost' IDENTIFIED BY 'your_secure_password_here';

-- Web DB 권한
GRANT ALL PRIVILEGES ON webdb.* TO 'linkwave'@'localhost';

-- Message DB 권한
GRANT ALL PRIVILEGES ON messagedb.* TO 'linkwave'@'localhost';

-- 권한 적용
FLUSH PRIVILEGES;

-- 확인
SHOW DATABASES;
SELECT user, host FROM mysql.user WHERE user = 'linkwave';

-- 종료
EXIT;
```

### 4.2 MySQL 설정 튜닝

```bash
# MySQL 설정 파일 편집
sudo nano /etc/mysql/mysql.conf.d/mysqld.cnf
```

```ini
[mysqld]
# 기본 설정
port = 3306
bind-address = 127.0.0.1

# 문자셋
character-set-server = utf8mb4
collation-server = utf8mb4_unicode_ci

# 연결 설정
max_connections = 200
connect_timeout = 10

# 버퍼 설정 (16GB RAM 기준)
innodb_buffer_pool_size = 8G
innodb_log_file_size = 512M
innodb_log_buffer_size = 64M

# 쿼리 캐시 (MySQL 8.0에서는 제거됨)
# query_cache_type = 0
# query_cache_size = 0

# 로그 설정
slow_query_log = 1
slow_query_log_file = /var/log/mysql/slow-query.log
long_query_time = 2

# 일반 로그 (개발 환경에만 활성화)
# general_log = 1
# general_log_file = /var/log/mysql/general.log

# Binary 로그 (복제 및 백업용)
log_bin = /var/log/mysql/mysql-bin.log
expire_logs_days = 7
max_binlog_size = 100M
```

```bash
# MySQL 재시작
sudo systemctl restart mysql

# 설정 확인
mysql -u linkwave -p -e "SHOW VARIABLES LIKE 'character_set%';"
mysql -u linkwave -p -e "SHOW VARIABLES LIKE 'collation%';"
```

### 4.3 데이터베이스 스키마 초기화

```bash
# 스키마 파일 다운로드 (GitLab에서)
cd /tmp
git clone https://gitlab.company.com/iotree/linkwave-db-schema.git

# Web DB 스키마 적용
mysql -u linkwave -p webdb < /tmp/linkwave-db-schema/webdb/schema.sql

# Message DB 스키마 적용
mysql -u linkwave -p messagedb < /tmp/linkwave-db-schema/messagedb/schema.sql

# 초기 데이터 입력 (있는 경우)
mysql -u linkwave -p webdb < /tmp/linkwave-db-schema/webdb/seed.sql
```

---

## 5. 백엔드 배포 설정

### 5.1 systemd 서비스 설정

```bash
# systemd 서비스 파일 생성
sudo nano /etc/systemd/system/linkwave-backend.service
```

```ini
[Unit]
Description=Iotree LinkWave Backend Service
After=syslog.target network.target mysql.service

[Service]
Type=simple
User=linkwave
Group=linkwave
WorkingDirectory=/opt/linkwave/backend/current

# Java 실행 환경
Environment="JAVA_HOME=/usr/lib/jvm/java-21-openjdk-amd64"
Environment="SPRING_PROFILES_ACTIVE=prod"

# 환경 변수 파일
EnvironmentFile=/opt/linkwave/backend/shared/.env

# JAR 실행
ExecStart=/usr/bin/java \
    -Xms2g \
    -Xmx4g \
    -XX:+UseG1GC \
    -XX:MaxGCPauseMillis=200 \
    -XX:+HeapDumpOnOutOfMemoryError \
    -XX:HeapDumpPath=/opt/linkwave/backend/logs/heap-dump.hprof \
    -Dspring.config.additional-location=file:/opt/linkwave/backend/shared/ \
    -Dlogging.config=file:/opt/linkwave/backend/shared/logback-spring.xml \
    -jar /opt/linkwave/backend/current/linkwave-backend.jar

# 프로세스 관리
Restart=always
RestartSec=10
StandardOutput=append:/var/log/linkwave/systemd/linkwave-backend.log
StandardError=append:/var/log/linkwave/systemd/linkwave-backend.log

# 보안 설정
NoNewPrivileges=true
PrivateTmp=true

# 리소스 제한
LimitNOFILE=65536
LimitNPROC=4096

[Install]
WantedBy=multi-user.target
```

### 5.2 환경 변수 파일 생성

```bash
# 환경 변수 파일 생성
sudo nano /opt/linkwave/backend/shared/.env
```

```bash
# Database - Web DB
WEB_DB_URL=jdbc:mysql://localhost:3306/webdb?useSSL=false&serverTimezone=Asia/Seoul&characterEncoding=UTF-8
WEB_DB_USERNAME=linkwave
WEB_DB_PASSWORD=your_secure_password_here

# Database - Message DB (same port as Web DB)
MESSAGE_DB_URL=jdbc:mysql://localhost:3306/messagedb?useSSL=false&serverTimezone=Asia/Seoul&characterEncoding=UTF-8
MESSAGE_DB_USERNAME=linkwave
MESSAGE_DB_PASSWORD=your_secure_password_here

# JWT Secret (최소 256bit)
JWT_SECRET=your-super-secret-jwt-key-must-be-at-least-256-bits-long-change-this-in-production

# File Storage
FILE_UPLOAD_PATH=/opt/linkwave/data/files

# Application
SPRING_PROFILES_ACTIVE=prod
```

```bash
# 권한 설정 (보안 중요!)
sudo chown linkwave:linkwave /opt/linkwave/backend/shared/.env
sudo chmod 600 /opt/linkwave/backend/shared/.env
```

### 5.3 systemd 서비스 활성화

```bash
# systemd 데몬 리로드
sudo systemctl daemon-reload

# 서비스 활성화 (부팅 시 자동 시작)
sudo systemctl enable linkwave-backend

# 서비스 시작
sudo systemctl start linkwave-backend

# 상태 확인
sudo systemctl status linkwave-backend

# 로그 확인
sudo journalctl -u linkwave-backend -f

# 또는
tail -f /var/log/linkwave/systemd/linkwave-backend.log
```

### 5.4 서비스 관리 명령어

```bash
# 서비스 시작
sudo systemctl start linkwave-backend

# 서비스 중지
sudo systemctl stop linkwave-backend

# 서비스 재시작
sudo systemctl restart linkwave-backend

# 서비스 상태 확인
sudo systemctl status linkwave-backend

# 부팅 시 자동 시작 활성화
sudo systemctl enable linkwave-backend

# 부팅 시 자동 시작 비활성화
sudo systemctl disable linkwave-backend
```

---

## 6. 프론트엔드 배포 설정

### 6.1 Nginx 설정

```bash
# Nginx 설정 파일 생성
sudo nano /etc/nginx/sites-available/linkwave.conf
```

```nginx
# Upstream 백엔드 서버
upstream linkwave_backend {
    server localhost:8080 max_fails=3 fail_timeout=30s;
    keepalive 32;
}

# HTTP to HTTPS redirect (SSL 설정 후 활성화)
# server {
#     listen 80;
#     listen [::]:80;
#     server_name linkwave.iotree.com;
#     return 301 https://$server_name$request_uri;
# }

server {
    listen 80;
    listen [::]:80;
    server_name linkwave.iotree.com;

    # SSL 설정 (Let's Encrypt 사용 시)
    # listen 443 ssl http2;
    # listen [::]:443 ssl http2;
    # ssl_certificate /etc/letsencrypt/live/linkwave.iotree.com/fullchain.pem;
    # ssl_certificate_key /etc/letsencrypt/live/linkwave.iotree.com/privkey.pem;
    # ssl_protocols TLSv1.2 TLSv1.3;
    # ssl_ciphers HIGH:!aNULL:!MD5;

    # 로그 설정
    access_log /var/log/linkwave/nginx/access.log combined;
    error_log /var/log/linkwave/nginx/error.log warn;

    # 보안 헤더
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header Referrer-Policy "no-referrer-when-downgrade" always;

    # 최대 업로드 크기
    client_max_body_size 10M;

    # 프론트엔드 정적 파일
    root /opt/linkwave/frontend/current;
    index index.html;

    # Gzip 압축
    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_comp_level 6;
    gzip_types
        text/plain
        text/css
        text/xml
        text/javascript
        application/json
        application/javascript
        application/xml+rss
        application/rss+xml
        font/truetype
        font/opentype
        application/vnd.ms-fontobject
        image/svg+xml;

    # SPA 라우팅 (React Router)
    location / {
        try_files $uri $uri/ /index.html;

        # 정적 파일 캐싱
        location ~* \.(jpg|jpeg|png|gif|ico|css|js|woff|woff2|ttf|svg)$ {
            expires 1y;
            add_header Cache-Control "public, immutable";
            access_log off;
        }
    }

    # API 프록시
    location /api {
        proxy_pass http://linkwave_backend;
        proxy_http_version 1.1;

        # 헤더 설정
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header Connection "";

        # 타임아웃 설정
        proxy_connect_timeout 30s;
        proxy_send_timeout 30s;
        proxy_read_timeout 30s;

        # 버퍼 설정
        proxy_buffering on;
        proxy_buffer_size 4k;
        proxy_buffers 8 4k;
        proxy_busy_buffers_size 8k;

        # 에러 처리
        proxy_next_upstream error timeout invalid_header http_500 http_502 http_503;
    }

    # 업로드된 파일 서빙
    location /files {
        alias /opt/linkwave/data/files;
        autoindex off;

        # 파일 캐싱
        expires 7d;
        add_header Cache-Control "public";

        # 보안: 실행 파일 차단
        location ~ \.(php|jsp|asp|sh|exe)$ {
            deny all;
        }
    }

    # Actuator (헬스체크만 허용)
    location /actuator/health {
        proxy_pass http://linkwave_backend/actuator/health;
        proxy_set_header Host $host;
        access_log off;
    }

    # 다른 Actuator 엔드포인트는 내부망에서만 접근 가능
    location /actuator {
        allow 127.0.0.1;
        allow 10.0.0.0/8;  # 내부 IP 대역
        deny all;
        proxy_pass http://linkwave_backend;
    }

    # .git 등 숨김 파일 차단
    location ~ /\. {
        deny all;
        access_log off;
        log_not_found off;
    }
}
```

### 6.2 Nginx 설정 활성화

```bash
# 심볼릭 링크 생성
sudo ln -s /etc/nginx/sites-available/linkwave.conf /etc/nginx/sites-enabled/

# 기본 사이트 비활성화 (선택사항)
sudo rm /etc/nginx/sites-enabled/default

# 설정 문법 확인
sudo nginx -t

# 출력:
# nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
# nginx: configuration file /etc/nginx/nginx.conf test is successful

# Nginx 재시작
sudo systemctl restart nginx

# 상태 확인
sudo systemctl status nginx
```

### 6.3 Nginx 전역 설정 튜닝

```bash
# Nginx 메인 설정 편집
sudo nano /etc/nginx/nginx.conf
```

```nginx
user www-data;
worker_processes auto;
pid /run/nginx.pid;
include /etc/nginx/modules-enabled/*.conf;

events {
    worker_connections 2048;
    use epoll;
    multi_accept on;
}

http {
    # 기본 설정
    sendfile on;
    tcp_nopush on;
    tcp_nodelay on;
    keepalive_timeout 65;
    types_hash_max_size 2048;
    server_tokens off;

    # MIME 타입
    include /etc/nginx/mime.types;
    default_type application/octet-stream;

    # 로그 포맷
    log_format main '$remote_addr - $remote_user [$time_local] "$request" '
                    '$status $body_bytes_sent "$http_referer" '
                    '"$http_user_agent" "$http_x_forwarded_for" '
                    'rt=$request_time uct="$upstream_connect_time" '
                    'uht="$upstream_header_time" urt="$upstream_response_time"';

    # 로그 설정
    access_log /var/log/nginx/access.log main;
    error_log /var/log/nginx/error.log warn;

    # Gzip 압축
    gzip on;
    gzip_disable "msie6";
    gzip_vary on;
    gzip_proxied any;
    gzip_comp_level 6;
    gzip_types text/plain text/css text/xml text/javascript
               application/json application/javascript application/xml+rss;

    # 가상 호스트 설정 포함
    include /etc/nginx/conf.d/*.conf;
    include /etc/nginx/sites-enabled/*;
}
```

---

## 7. GitLab CI/CD 구성

### 7.1 GitLab Runner 설치

```bash
# GitLab Runner 저장소 추가
curl -L "https://packages.gitlab.com/install/repositories/runner/gitlab-runner/script.deb.sh" | sudo bash

# GitLab Runner 설치
sudo apt install gitlab-runner

# 버전 확인
gitlab-runner --version
```

### 7.2 GitLab Runner 등록

```bash
# Runner 등록 (GitLab UI에서 토큰 확인)
sudo gitlab-runner register

# 입력 정보:
# GitLab URL: https://gitlab.company.com
# Registration token: [GitLab에서 확인]
# Description: linkwave-runner
# Tags: linkwave, deploy
# Executor: shell
```

### 7.3 GitLab Runner 사용자 권한 설정

```bash
# gitlab-runner 사용자를 linkwave 그룹에 추가
sudo usermod -a -G linkwave gitlab-runner

# gitlab-runner가 sudo를 passwordless로 실행하도록 설정
sudo visudo

# 다음 줄 추가:
# gitlab-runner ALL=(ALL) NOPASSWD: /bin/systemctl restart linkwave-backend
# gitlab-runner ALL=(ALL) NOPASSWD: /bin/systemctl restart nginx
```

### 7.4 .gitlab-ci.yml (백엔드)

**iotree-linkwave-backend/.gitlab-ci.yml**

```yaml
stages:
  - build
  - test
  - deploy

variables:
  GRADLE_OPTS: "-Dorg.gradle.daemon=false"
  GRADLE_USER_HOME: "$CI_PROJECT_DIR/.gradle"

# 캐시 설정
cache:
  key: "$CI_COMMIT_REF_NAME"
  paths:
    - .gradle/wrapper
    - .gradle/caches

# 빌드 스테이지
build:
  stage: build
  image: eclipse-temurin:21-jdk
  script:
    - echo "Building LinkWave Backend..."
    - chmod +x ./gradlew
    - ./gradlew clean build -x test
    - echo "Build completed"
  artifacts:
    paths:
      - build/libs/*.jar
    expire_in: 1 hour
  only:
    - develop
    - main
    - tags

# 테스트 스테이지
test:
  stage: test
  image: eclipse-temurin:21-jdk
  services:
    - mysql:8.0
  variables:
    MYSQL_ROOT_PASSWORD: test
    MYSQL_DATABASE: testdb
    SPRING_PROFILES_ACTIVE: test
  script:
    - echo "Running tests..."
    - ./gradlew test
    - echo "Tests completed"
  artifacts:
    when: always
    reports:
      junit: build/test-results/test/**/TEST-*.xml
  only:
    - develop
    - main
    - merge_requests

# 개발 서버 배포
deploy:dev:
  stage: deploy
  script:
    - echo "Deploying to Development Server..."
    - export DEPLOY_DIR="/opt/linkwave/backend"
    - export RELEASE_DIR="$DEPLOY_DIR/releases/$(date +%Y%m%d-%H%M%S)"

    # 릴리스 디렉토리 생성
    - sudo -u linkwave mkdir -p $RELEASE_DIR

    # JAR 파일 복사
    - sudo -u linkwave cp build/libs/*.jar $RELEASE_DIR/linkwave-backend.jar

    # 심볼릭 링크 업데이트
    - sudo -u linkwave ln -sfn $RELEASE_DIR $DEPLOY_DIR/current

    # 서비스 재시작
    - sudo systemctl restart linkwave-backend

    # 헬스체크
    - sleep 10
    - curl -f http://localhost:8080/actuator/health || exit 1

    # 이전 릴리스 정리 (최근 5개만 유지)
    - cd $DEPLOY_DIR/releases && sudo -u linkwave ls -t | tail -n +6 | xargs -r rm -rf

    - echo "Deployment completed successfully!"
  environment:
    name: development
    url: http://dev.linkwave.iotree.com
  only:
    - develop
  tags:
    - linkwave
    - deploy

# 프로덕션 배포 (수동 실행)
deploy:prod:
  stage: deploy
  script:
    - echo "Deploying to Production Server..."
    - export DEPLOY_DIR="/opt/linkwave/backend"
    - export RELEASE_DIR="$DEPLOY_DIR/releases/$(date +%Y%m%d-%H%M%S)"

    # 릴리스 디렉토리 생성
    - sudo -u linkwave mkdir -p $RELEASE_DIR

    # JAR 파일 복사
    - sudo -u linkwave cp build/libs/*.jar $RELEASE_DIR/linkwave-backend.jar

    # 심볼릭 링크 업데이트
    - sudo -u linkwave ln -sfn $RELEASE_DIR $DEPLOY_DIR/current

    # Blue-Green 배포를 위한 헬스체크
    - curl -f http://localhost:8080/actuator/health || echo "Service not running, starting..."

    # 서비스 재시작
    - sudo systemctl restart linkwave-backend

    # 헬스체크 (최대 30초 대기)
    - |
      for i in {1..30}; do
        if curl -f http://localhost:8080/actuator/health; then
          echo "Service is healthy!"
          break
        fi
        echo "Waiting for service to be healthy... ($i/30)"
        sleep 1
      done

    # 이전 릴리스 정리 (최근 10개만 유지)
    - cd $DEPLOY_DIR/releases && sudo -u linkwave ls -t | tail -n +11 | xargs -r rm -rf

    - echo "Production deployment completed!"
  environment:
    name: production
    url: https://linkwave.iotree.com
  when: manual
  only:
    - main
    - tags
  tags:
    - linkwave
    - deploy
```

### 7.5 .gitlab-ci.yml (프론트엔드)

**iotree-linkwave-frontend/.gitlab-ci.yml**

```yaml
stages:
  - build
  - deploy

variables:
  NODE_VERSION: "20"

# 캐시 설정
cache:
  key: "$CI_COMMIT_REF_NAME"
  paths:
    - node_modules/
    - .npm/

# 빌드 스테이지
build:
  stage: build
  image: node:${NODE_VERSION}-alpine
  before_script:
    - npm ci --cache .npm --prefer-offline
  script:
    - echo "Building LinkWave Frontend..."
    - npm run build
    - echo "Build completed"
  artifacts:
    paths:
      - dist/
    expire_in: 1 hour
  only:
    - develop
    - main
    - tags

# 개발 서버 배포
deploy:dev:
  stage: deploy
  script:
    - echo "Deploying Frontend to Development Server..."
    - export DEPLOY_DIR="/opt/linkwave/frontend"
    - export RELEASE_DIR="$DEPLOY_DIR/releases/$(date +%Y%m%d-%H%M%S)"

    # 릴리스 디렉토리 생성
    - sudo -u www-data mkdir -p $RELEASE_DIR

    # 빌드 파일 복사
    - sudo -u www-data cp -r dist/* $RELEASE_DIR/

    # 심볼릭 링크 업데이트
    - sudo -u www-data ln -sfn $RELEASE_DIR $DEPLOY_DIR/current

    # Nginx 리로드
    - sudo systemctl reload nginx

    # 이전 릴리스 정리 (최근 5개만 유지)
    - cd $DEPLOY_DIR/releases && sudo -u www-data ls -t | tail -n +6 | xargs -r rm -rf

    - echo "Frontend deployment completed!"
  environment:
    name: development
    url: http://dev.linkwave.iotree.com
  only:
    - develop
  tags:
    - linkwave
    - deploy

# 프로덕션 배포 (수동 실행)
deploy:prod:
  stage: deploy
  script:
    - echo "Deploying Frontend to Production Server..."
    - export DEPLOY_DIR="/opt/linkwave/frontend"
    - export RELEASE_DIR="$DEPLOY_DIR/releases/$(date +%Y%m%d-%H%M%S)"

    # 릴리스 디렉토리 생성
    - sudo -u www-data mkdir -p $RELEASE_DIR

    # 빌드 파일 복사
    - sudo -u www-data cp -r dist/* $RELEASE_DIR/

    # 심볼릭 링크 업데이트
    - sudo -u www-data ln -sfn $RELEASE_DIR $DEPLOY_DIR/current

    # Nginx 캐시 클리어
    - sudo find /var/cache/nginx -type f -delete 2>/dev/null || true

    # Nginx 리로드
    - sudo systemctl reload nginx

    # 이전 릴리스 정리 (최근 10개만 유지)
    - cd $DEPLOY_DIR/releases && sudo -u www-data ls -t | tail -n +11 | xargs -r rm -rf

    - echo "Production frontend deployment completed!"
  environment:
    name: production
    url: https://linkwave.iotree.com
  when: manual
  only:
    - main
    - tags
  tags:
    - linkwave
    - deploy
```

---

## 8. Jenkins 파이프라인 구성

### 8.1 Jenkins 설치

```bash
# Java 11+ 이미 설치되어 있어야 함 (Java 21 사용 중)

# Jenkins 저장소 키 추가
curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key | sudo tee \
  /usr/share/keyrings/jenkins-keyring.asc > /dev/null

# Jenkins 저장소 추가
echo deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] \
  https://pkg.jenkins.io/debian-stable binary/ | sudo tee \
  /etc/apt/sources.list.d/jenkins.list > /dev/null

# Jenkins 설치
sudo apt update
sudo apt install -y jenkins

# Jenkins 시작 및 자동 시작 설정
sudo systemctl start jenkins
sudo systemctl enable jenkins

# 초기 비밀번호 확인
sudo cat /var/lib/jenkins/secrets/initialAdminPassword
```

### 8.2 Jenkins 사용자 권한 설정

```bash
# jenkins 사용자를 linkwave 그룹에 추가
sudo usermod -a -G linkwave jenkins

# jenkins 사용자 passwordless sudo 설정
sudo visudo

# 다음 줄 추가:
# jenkins ALL=(ALL) NOPASSWD: /bin/systemctl restart linkwave-backend
# jenkins ALL=(ALL) NOPASSWD: /bin/systemctl restart nginx
# jenkins ALL=(ALL) NOPASSWD: /usr/bin/rsync
```

### 8.3 Jenkins 플러그인 설치

Jenkins 웹 UI (http://서버IP:8080)에서 다음 플러그인 설치:

- GitLab Plugin
- Pipeline
- Git Plugin
- Gradle Plugin
- NodeJS Plugin
- SSH Agent Plugin
- Build Timestamp Plugin

### 8.4 Jenkinsfile (백엔드)

**iotree-linkwave-backend/Jenkinsfile**

```groovy
pipeline {
    agent any

    environment {
        JAVA_HOME = '/usr/lib/jvm/java-21-openjdk-amd64'
        GRADLE_OPTS = '-Dorg.gradle.daemon=false'
        DEPLOY_DIR = '/opt/linkwave/backend'
    }

    options {
        buildDiscarder(logRotator(numToKeepStr: '10'))
        timestamps()
        timeout(time: 30, unit: 'MINUTES')
    }

    stages {
        stage('Checkout') {
            steps {
                echo 'Checking out source code...'
                checkout scm
            }
        }

        stage('Build') {
            steps {
                echo 'Building with Gradle...'
                sh '''
                    chmod +x ./gradlew
                    ./gradlew clean build -x test
                '''
            }
        }

        stage('Test') {
            steps {
                echo 'Running tests...'
                sh './gradlew test'
            }
            post {
                always {
                    junit '**/build/test-results/test/*.xml'
                }
            }
        }

        stage('Deploy') {
            when {
                anyOf {
                    branch 'main'
                    branch 'develop'
                }
            }
            steps {
                script {
                    def releaseDir = "${DEPLOY_DIR}/releases/${BUILD_TIMESTAMP}"

                    echo "Deploying to ${releaseDir}..."

                    sh """
                        # 릴리스 디렉토리 생성
                        sudo -u linkwave mkdir -p ${releaseDir}

                        # JAR 파일 복사
                        sudo -u linkwave cp build/libs/*.jar ${releaseDir}/linkwave-backend.jar

                        # 심볼릭 링크 업데이트
                        sudo -u linkwave ln -sfn ${releaseDir} ${DEPLOY_DIR}/current

                        # 서비스 재시작
                        sudo systemctl restart linkwave-backend

                        # 헬스체크
                        sleep 10
                        curl -f http://localhost:8080/actuator/health || exit 1

                        # 이전 릴리스 정리 (최근 5개만 유지)
                        cd ${DEPLOY_DIR}/releases && sudo -u linkwave ls -t | tail -n +6 | xargs -r rm -rf
                    """

                    echo 'Deployment completed successfully!'
                }
            }
        }
    }

    post {
        success {
            echo 'Pipeline succeeded!'
            // Slack, Email 등 알림 설정
        }
        failure {
            echo 'Pipeline failed!'
            // 실패 알림 설정
        }
        always {
            cleanWs()
        }
    }
}
```

### 8.5 Jenkinsfile (프론트엔드)

**iotree-linkwave-frontend/Jenkinsfile**

```groovy
pipeline {
    agent any

    tools {
        nodejs 'NodeJS-20'  // Jenkins Global Tool Configuration에서 설정
    }

    environment {
        DEPLOY_DIR = '/opt/linkwave/frontend'
    }

    options {
        buildDiscarder(logRotator(numToKeepStr: '10'))
        timestamps()
        timeout(time: 20, unit: 'MINUTES')
    }

    stages {
        stage('Checkout') {
            steps {
                echo 'Checking out source code...'
                checkout scm
            }
        }

        stage('Install Dependencies') {
            steps {
                echo 'Installing npm dependencies...'
                sh 'npm ci'
            }
        }

        stage('Build') {
            steps {
                echo 'Building React application...'
                sh 'npm run build'
            }
        }

        stage('Deploy') {
            when {
                anyOf {
                    branch 'main'
                    branch 'develop'
                }
            }
            steps {
                script {
                    def releaseDir = "${DEPLOY_DIR}/releases/${BUILD_TIMESTAMP}"

                    echo "Deploying to ${releaseDir}..."

                    sh """
                        # 릴리스 디렉토리 생성
                        sudo -u www-data mkdir -p ${releaseDir}

                        # 빌드 파일 복사
                        sudo -u www-data cp -r dist/* ${releaseDir}/

                        # 심볼릭 링크 업데이트
                        sudo -u www-data ln -sfn ${releaseDir} ${DEPLOY_DIR}/current

                        # Nginx 리로드
                        sudo systemctl reload nginx

                        # 이전 릴리스 정리 (최근 5개만 유지)
                        cd ${DEPLOY_DIR}/releases && sudo -u www-data ls -t | tail -n +6 | xargs -r rm -rf
                    """

                    echo 'Frontend deployment completed!'
                }
            }
        }
    }

    post {
        success {
            echo 'Pipeline succeeded!'
        }
        failure {
            echo 'Pipeline failed!'
        }
        always {
            cleanWs()
        }
    }
}
```

---

## 9. 모니터링 및 로깅

### 9.1 로그 로테이션 설정

```bash
# logrotate 설정 파일 생성
sudo nano /etc/logrotate.d/linkwave
```

```
/opt/linkwave/backend/logs/*.log {
    daily
    rotate 30
    compress
    delaycompress
    missingok
    notifempty
    create 0640 linkwave linkwave
    sharedscripts
    postrotate
        systemctl reload linkwave-backend > /dev/null 2>&1 || true
    endscript
}

/var/log/linkwave/nginx/*.log {
    daily
    rotate 30
    compress
    delaycompress
    missingok
    notifempty
    create 0640 www-data adm
    sharedscripts
    postrotate
        nginx -s reload > /dev/null 2>&1 || true
    endscript
}
```

### 9.2 헬스체크 스크립트

```bash
# 헬스체크 스크립트 생성
sudo nano /opt/linkwave/scripts/health-check.sh
```

```bash
#!/bin/bash

# Iotree LinkWave 헬스체크 스크립트

BACKEND_URL="http://localhost:8080/actuator/health"
FRONTEND_URL="http://localhost"
LOG_FILE="/opt/linkwave/backend/logs/health-check.log"
ALERT_EMAIL="admin@iotree.com"

# 로그 함수
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

# 백엔드 헬스체크
check_backend() {
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "$BACKEND_URL")

    if [ "$HTTP_CODE" == "200" ]; then
        log "Backend: OK (HTTP $HTTP_CODE)"
        return 0
    else
        log "Backend: FAILED (HTTP $HTTP_CODE)"
        return 1
    fi
}

# 프론트엔드 헬스체크
check_frontend() {
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "$FRONTEND_URL")

    if [ "$HTTP_CODE" == "200" ]; then
        log "Frontend: OK (HTTP $HTTP_CODE)"
        return 0
    else
        log "Frontend: FAILED (HTTP $HTTP_CODE)"
        return 1
    fi
}

# 알림 전송
send_alert() {
    SUBJECT="LinkWave Health Check Alert"
    MESSAGE="$1"

    echo "$MESSAGE" | mail -s "$SUBJECT" "$ALERT_EMAIL"
    log "Alert sent: $MESSAGE"
}

# 메인 헬스체크
main() {
    BACKEND_STATUS=0
    FRONTEND_STATUS=0

    check_backend || BACKEND_STATUS=1
    check_frontend || FRONTEND_STATUS=1

    if [ $BACKEND_STATUS -ne 0 ] || [ $FRONTEND_STATUS -ne 0 ]; then
        send_alert "LinkWave health check failed! Backend: $BACKEND_STATUS, Frontend: $FRONTEND_STATUS"
        exit 1
    fi

    exit 0
}

main
```

```bash
# 실행 권한 부여
sudo chmod +x /opt/linkwave/scripts/health-check.sh
sudo chown linkwave:linkwave /opt/linkwave/scripts/health-check.sh

# crontab에 등록 (5분마다 실행)
sudo crontab -e -u linkwave

# 다음 줄 추가:
# */5 * * * * /opt/linkwave/scripts/health-check.sh
```

---

## 10. 보안 설정

### 10.1 방화벽 설정 (UFW)

```bash
# UFW 설치 (기본 설치되어 있음)
sudo apt install -y ufw

# 기본 정책 설정
sudo ufw default deny incoming
sudo ufw default allow outgoing

# SSH 허용 (포트 변경 시 해당 포트로)
sudo ufw allow 22/tcp

# HTTP/HTTPS 허용
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp

# 특정 IP에서만 Jenkins 접근 허용 (예시)
# sudo ufw allow from 192.168.1.0/24 to any port 8080

# 방화벽 활성화
sudo ufw enable

# 상태 확인
sudo ufw status verbose
```

### 10.2 fail2ban 설정

```bash
# fail2ban 설치
sudo apt install -y fail2ban

# 설정 파일 생성
sudo nano /etc/fail2ban/jail.local
```

```ini
[DEFAULT]
bantime = 3600
findtime = 600
maxretry = 5

[sshd]
enabled = true
port = 22
logpath = /var/log/auth.log

[nginx-http-auth]
enabled = true
port = http,https
logpath = /var/log/linkwave/nginx/error.log
```

```bash
# fail2ban 재시작
sudo systemctl restart fail2ban

# 상태 확인
sudo fail2ban-client status
```

### 10.3 SSL/TLS 설정 (Let's Encrypt)

```bash
# Certbot 설치
sudo apt install -y certbot python3-certbot-nginx

# SSL 인증서 발급
sudo certbot --nginx -d linkwave.iotree.com

# 자동 갱신 확인
sudo certbot renew --dry-run

# crontab에 자동 갱신 등록
sudo crontab -e

# 다음 줄 추가:
# 0 3 * * * certbot renew --quiet && systemctl reload nginx
```

---

## 부록 A: Java 21 & Spring Boot 4.0 주의사항

### A.1 호환성 이슈

#### 1. **javax → jakarta 네임스페이스 변경**
Spring Boot 3.0+부터 Java EE에서 Jakarta EE로 전환되어 모든 패키지가 변경되었습니다.

```java
// 변경 전 (Spring Boot 2.x)
import javax.persistence.Entity;
import javax.servlet.http.HttpServletRequest;

// 변경 후 (Spring Boot 3.x+)
import jakarta.persistence.Entity;
import jakarta.servlet.http.HttpServletRequest;
```

#### 2. **Springfox → SpringDoc 마이그레이션**
Springfox는 Spring Boot 3.0+와 호환되지 않습니다.

```gradle
// build.gradle.kts
dependencies {
    // Springfox 제거
    // implementation("io.springfox:springfox-boot-starter:3.0.0")

    // SpringDoc 사용
    implementation("org.springdoc:springdoc-openapi-starter-webmvc-ui:2.3.0")
}
```

#### 3. **Gradle 버전**
Gradle 8.5+ 사용 권장 (Java 21 완전 지원)

```kotlin
// gradle/wrapper/gradle-wrapper.properties
distributionUrl=https\://services.gradle.org/distributions/gradle-8.5-bin.zip
```

#### 4. **Lombok 버전**
Lombok 1.18.30+ 사용 (Java 21 지원)

```gradle
dependencies {
    compileOnly("org.projectlombok:lombok:1.18.30")
    annotationProcessor("org.projectlombok:lombok:1.18.30")
}
```

#### 5. **Virtual Threads 활용 (Java 21)**
Spring Boot 3.2+에서 Virtual Threads 지원

```yaml
# application.yml
spring:
  threads:
    virtual:
      enabled: true  # Virtual Threads 활성화
```

### A.2 권장 의존성 버전

```kotlin
// build.gradle.kts
plugins {
    kotlin("jvm") version "1.9.21"
    kotlin("plugin.spring") version "1.9.21"
    id("org.springframework.boot") version "3.2.1"
    id("io.spring.dependency-management") version "1.1.4"
}

dependencies {
    // Spring Boot Starters
    implementation("org.springframework.boot:spring-boot-starter-web")
    implementation("org.springframework.boot:spring-boot-starter-data-jpa")
    implementation("org.springframework.boot:spring-boot-starter-security")

    // JWT (Java 21 호환)
    implementation("io.jsonwebtoken:jjwt-api:0.12.3")
    runtimeOnly("io.jsonwebtoken:jjwt-impl:0.12.3")
    runtimeOnly("io.jsonwebtoken:jjwt-jackson:0.12.3")

    // MySQL
    runtimeOnly("com.mysql:mysql-connector-j:8.2.0")

    // Lombok (Java 21 호환)
    compileOnly("org.projectlombok:lombok:1.18.30")
    annotationProcessor("org.projectlombok:lombok:1.18.30")
}
```

---

## 부록 B: 트러블슈팅

### B.1 백엔드 서비스가 시작되지 않을 때

```bash
# 로그 확인
sudo journalctl -u linkwave-backend -n 100 --no-pager

# Java 프로세스 확인
ps aux | grep java

# 포트 사용 확인
sudo netstat -tlnp | grep 8080

# 설정 파일 권한 확인
ls -la /opt/linkwave/backend/shared/
```

### B.2 데이터베이스 연결 실패

```bash
# MySQL 상태 확인
sudo systemctl status mysql

# MySQL 로그 확인
sudo tail -f /var/log/mysql/error.log

# 연결 테스트
mysql -u linkwave -p -h localhost

# 권한 확인
mysql -u root -p
mysql> SELECT user, host FROM mysql.user;
mysql> SHOW GRANTS FOR 'linkwave'@'localhost';
```

### B.3 Nginx 502 Bad Gateway

```bash
# 백엔드 상태 확인
sudo systemctl status linkwave-backend

# Nginx 에러 로그
sudo tail -f /var/log/linkwave/nginx/error.log

# SELinux 확인 (CentOS/RHEL)
# sudo setsebool -P httpd_can_network_connect 1
```

---

## 참고 자료

### Spring Boot 4.0 & Java 21

- [Spring Boot 4.0.0 Release Notes](https://github.com/spring-projects/spring-boot/wiki/Spring-Boot-4.0-Release-Notes)
- [Spring Boot 4.0.0 available now](https://spring.io/blog/2025/11/20/spring-boot-4-0-0-available-now/)
- [Java 21 + Spring Boot 3.x compatibility](https://github.com/sonus21/rqueue/issues/269)
- [Java 21 & Spring Boot 3.2 Migration Guide](https://medium.com/@madampitige90/java-21-spring-boot-3-2-migration-guide-4d2b19e37c7f)
- [Spring Version Compatibility Cheatsheet](https://stevenpg.com/posts/spring-compat-cheatsheet/)

### 서버 관리

- [Ubuntu Server Documentation](https://ubuntu.com/server/docs)
- [Nginx Documentation](https://nginx.org/en/docs/)
- [MySQL 8.0 Reference Manual](https://dev.mysql.com/doc/refman/8.0/en/)

---

**Iotree LinkWave** - 메시지가 파도처럼 퍼져나가는 문자 발송 시스템 🌊
