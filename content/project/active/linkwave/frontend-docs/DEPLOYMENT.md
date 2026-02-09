---
created: 2025-12-26
---
# LinkWave Frontend - 배포 가이드

프론트엔드 배포 프로세스 및 운영 가이드

## 목차

1. [배포 개요](#배포-개요)
2. [서버 환경](#서버-환경)
3. [초기 서버 설정](#초기-서버-설정)
4. [GitLab CI/CD 설정](#gitlab-cicd-설정)
5. [배포 실행](#배포-실행)
6. [운영 및 모니터링](#운영-및-모니터링)
7. [트러블슈팅](#트러블슈팅)

---

## 배포 개요

### 배포 방식

**정적 파일 직접 배포 (Docker 미사용)**

- **장점**: 메모리 소비 최소화, 간단한 구조, 빠른 배포
- **방식**: Vite 빌드 → SCP 전송 → Nginx 서빙
- **메모리 사용**: 추가 메모리 사용 거의 없음 (기존 Nginx 활용)

### 배포 아키텍처

```
개발자 PC
  ↓ git push
GitLab
  ↓ CI/CD Pipeline
빌드 (Node.js)
  ↓ npm run build
dist/ 생성
  ↓ SCP
배포 서버 (nas.iotree.co.kr)
  ↓ deploy.sh
Nginx (8890)
  ├─ 정적 파일 서빙 (HTML, JS, CSS)
  └─ /api/* → Spring Boot (18081) 프록시
       ↓
사용자: http://nas.iotree.co.kr:8890
```

---

## 서버 환경

### 서버 정보

```
호스트: nas.iotree.co.kr
SSH 포트: 8122
사용자: sanghpark
앱 경로: /home/sanghpark/app/link-wave/frontend
```

### 포트 구성

```
8890: 프론트엔드 Nginx (HTTPS, dev/staging)
      ↓ /api/* 요청을 프록시
18080: 백엔드 Spring Boot (staging)
```

### 환경별 설정

- **dev/staging**: develop 브랜치 → 포트 8890 (HTTPS)
- **API 호출**: 프론트엔드 Nginx(8890)가 백엔드(18080)로 프록시
- **사용자 접근**: http://nas.iotree.co.kr:8890

### 필수 소프트웨어

- Nginx (시스템 서비스)
- Node.js 20+ (빌드용, CI/CD에서만 사용)

---

## 초기 서버 설정

### 1. SSH 접속 및 디렉토리 생성

```bash
# 서버 접속
ssh -p 8122 sanghpark@nas.iotree.co.kr

# 앱 디렉토리 생성
mkdir -p /home/sanghpark/app/link-wave/frontend
mkdir -p /home/sanghpark/app/link-wave/frontend/scripts
cd /home/sanghpark/app/link-wave
```

### 2. Nginx 설정

Nginx 설정 파일은 CI/CD에서 자동으로 전송되지만, 수동으로 설정할 수도 있습니다:

```bash
# Nginx 설정 파일 복사 (처음 1회)
sudo cp /home/sanghpark/app/link-wave/nginx-frontend.conf \
        /etc/nginx/conf.d/linkwave-frontend.conf

# Nginx 설정 테스트
sudo nginx -t

# Nginx 재시작
sudo systemctl reload nginx
```

### 3. Nginx 상태 확인

```bash
# Nginx 상태 확인
sudo systemctl status nginx

# 포트 확인
sudo netstat -tulpn | grep 8890

# 헬스 체크
curl http://localhost:8890/health
```

---

## GitLab CI/CD 설정

### 1. GitLab CI/CD 변수 설정

GitLab 프로젝트 → Settings → CI/CD → Variables

```
SSH_PRIVATE_KEY: 서버 SSH 개인키 (Type: File)
```

### 2. SSH 키 생성 및 등록

**개발 PC에서**:

```bash
# SSH 키 생성 (백엔드와 동일한 키 사용 가능)
ssh-keygen -t ed25519 -C "gitlab-ci-deploy" -f ~/.ssh/gitlab_deploy

# 공개키를 서버에 등록
ssh-copy-id -i ~/.ssh/gitlab_deploy.pub -p 8122 sanghpark@nas.iotree.co.kr

# 개인키를 GitLab CI/CD 변수에 등록
# GitLab UI에서 SSH_PRIVATE_KEY 변수에 ~/.ssh/gitlab_deploy 파일 내용 복사
```

### 3. 파이프라인 단계

```
1. build        - Node.js 빌드, PandaCSS 코드 생성, Lint 체크
2. deploy       - 정적 파일 전송 및 배포 스크립트 실행
```

---

## 배포 실행

### 자동 배포 (GitLab CI/CD)

#### Staging 배포

```bash
# develop 브랜치에 push
git checkout develop
git add .
git commit -m "feat: 새로운 기능 추가"
git push origin develop

# GitLab UI에서 수동으로 deploy-staging Job 실행
# Pipelines → develop 브랜치 → deploy-staging (수동 실행)
```

### 수동 배포

서버에 직접 접속하여 배포하는 방법:

```bash
# 1. 로컬에서 빌드
npm ci
npm run prepare
cp .env.dev .env
npm run build

# 2. 서버로 파일 전송
scp -P 8122 -r dist sanghpark@nas.iotree.co.kr:/home/sanghpark/app/link-wave/
scp -P 8122 nginx/conf.d/linkwave-frontend.conf sanghpark@nas.iotree.co.kr:/home/sanghpark/app/link-wave/nginx-frontend.conf
scp -P 8122 scripts/*.sh sanghpark@nas.iotree.co.kr:/home/sanghpark/app/link-wave/frontend/scripts/

# 3. 서버에서 배포
ssh -p 8122 sanghpark@nas.iotree.co.kr
cd /home/sanghpark/app/link-wave
chmod +x frontend/scripts/deploy.sh
./frontend/scripts/deploy.sh
```

### 배포 후 확인

```bash
# 1. Nginx 상태 확인
sudo systemctl status nginx

# 2. 헬스 체크
curl http://localhost:8890/health

# 3. 브라우저에서 접속
# http://nas.iotree.co.kr:8890

# 4. Nginx 로그 확인
sudo tail -f /var/log/nginx/linkwave-frontend-access.log
sudo tail -f /var/log/nginx/linkwave-frontend-error.log
```

---

## 운영 및 모니터링

### 일상 운영 명령어

```bash
# Nginx 재시작
sudo systemctl reload nginx

# Nginx 설정 테스트
sudo nginx -t

# 로그 실시간 모니터링
sudo tail -f /var/log/nginx/linkwave-frontend-access.log
sudo tail -f /var/log/nginx/linkwave-frontend-error.log

# 디스크 사용량 확인
du -sh /home/sanghpark/app/link-wave/frontend
```

### 헬스 체크

```bash
# 프론트엔드 헬스 체크
curl http://localhost:8890/health

# API 헬스 체크 (백엔드)
curl http://localhost:8890/api/v1/health
```

### 파일 구조

```
/home/sanghpark/app/link-wave/
├── frontend/                   # 현재 배포된 파일
│   ├── index.html
│   ├── assets/
│   ├── scripts/
│   │   ├── deploy.sh          # 배포 스크립트
│   │   └── rollback.sh        # 롤백 스크립트
│   └── ...
├── frontend-backup/            # 이전 버전 백업
└── nginx-frontend.conf         # Nginx 설정 파일
```

---

## 트러블슈팅

### Nginx 502 Bad Gateway

**증상**: API 호출 시 502 에러 (프론트에서 /api/* 호출 실패)

```bash
# 1. 백엔드 Spring Boot 상태 확인
curl http://localhost:18080/actuator/health

# 2. 백엔드가 응답하지 않으면 프로세스 확인
ps aux | grep java
# 또는
cd /home/sanghpark/app/link-wave
tail -f logs/linkwave.log

# 3. 백엔드 재시작 (staging)
cd /home/sanghpark/app/link-wave
export SERVER_PORT=18080
./scripts/start-jar.sh

# 4. Nginx 재시작
sudo systemctl reload nginx
```

### Nginx 404 Not Found

**증상**: 정적 파일을 찾을 수 없음

```bash
# 1. 파일 경로 확인
ls -la /home/sanghpark/app/link-wave/frontend/

# 2. Nginx 설정 확인
cat /etc/nginx/conf.d/linkwave-frontend.conf | grep root

# 3. 권한 확인
chmod -R 755 /home/sanghpark/app/link-wave/frontend/
```

### Nginx 설정 오류

**증상**: "nginx: configuration file test failed"

```bash
# 1. 설정 테스트로 오류 확인
sudo nginx -t

# 2. 설정 파일 문법 확인
cat /etc/nginx/conf.d/linkwave-frontend.conf

# 3. 오류 수정 후 재테스트
sudo nginx -t
sudo systemctl reload nginx
```

### 빌드 실패

**증상**: GitLab CI/CD에서 빌드 실패

```bash
# 로컬에서 빌드 테스트
npm ci
npm run prepare
npm run lint
npm run build

# 빌드 로그 확인
# GitLab UI → Pipelines → 실패한 Job → 로그 확인
```

### 롤백

**증상**: 배포 후 문제 발생, 이전 버전으로 복구 필요

```bash
# 방법 1: 서버에서 직접 롤백
ssh -p 8122 sanghpark@nas.iotree.co.kr
cd /home/sanghpark/app/link-wave
./frontend/scripts/rollback.sh

# 방법 2: GitLab CI/CD에서 롤백
# GitLab UI → Pipelines → rollback-staging (수동 실행)
```

### API 연결 실패

**증상**: 프론트엔드에서 API 호출 실패

```bash
# 1. 브라우저 개발자 도구 → Network 탭 확인
# http://nas.iotree.co.kr:8890/api/v1/... 요청 확인

# 2. .env.dev 파일 확인
cat .env.dev
# VITE_API_BASE_URL=/api/v1 인지 확인

# 3. 백엔드 서버 확인 (직접 18080 포트)
curl http://localhost:18080/actuator/health

# 4. Nginx 프록시 설정 확인
cat /etc/nginx/conf.d/linkwave.conf | grep proxy_pass
# http://localhost:18080 로 프록시되는지 확인

# 5. 백엔드 Spring Boot 프로세스 확인
ps aux | grep java
```

---

## 성능 최적화

### Gzip 압축

Nginx 설정에 이미 포함되어 있습니다:

```nginx
gzip on;
gzip_vary on;
gzip_min_length 1024;
gzip_types text/plain text/css text/xml text/javascript
           application/x-javascript application/xml+rss
           application/javascript application/json;
```

### 정적 리소스 캐싱

```nginx
location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
    expires 1y;
    add_header Cache-Control "public, immutable";
}
```

### Vite 빌드 최적화

```javascript
// vite.config.js
export default defineConfig({
  build: {
    rollupOptions: {
      output: {
        manualChunks: {
          vendor: ['react', 'react-dom'],
          router: ['@tanstack/react-router'],
        },
      },
    },
  },
});
```

---

## 보안 체크리스트

- [x] Nginx 보안 헤더 설정
  - X-Frame-Options
  - X-Content-Type-Options
  - X-XSS-Protection
- [ ] HTTPS/SSL 인증서 설정 (향후 적용)
- [ ] 방화벽 설정 (필요한 포트만 오픈)
- [ ] robots.txt 설정 (dev 환경)
- [ ] 정기적인 보안 업데이트

---

## 참고 자료

- [Vite 공식 문서](https://vitejs.dev/)
- [Nginx 공식 문서](https://nginx.org/en/docs/)
- [GitLab CI/CD 문서](https://docs.gitlab.com/ee/ci/)

---

## 지원

문제가 발생하거나 도움이 필요한 경우:

- 프로젝트 이슈: http://gitlab.iotree.co.kr/iotree/linkwave-frontend/issues
- 담당자: sanghpark@iotree.co.kr
