---
created: 2025-12-26
---
# HTTPS 인증서 구현 계획 (8890 포트)

## 📋 개요

**목표**: 8890 포트 (LinkWave 프로젝트)에 HTTPS 인증서 적용

**현재 상태 발견**:
- ✅ **5000 포트**: 이미 HTTPS 작동 중 (`https://nas.도메인.co.kr:5000`)
- ❌ **8890 포트**: HTTP만 작동 (`http://nas.도메인.co.kr:8890`) - **적용 필요**
- ⏸️ **10000 포트**: 나중에 처리

**전략**:
- 기존 5000 포트 HTTPS 설정을 참고하여 8890 포트에 동일하게 적용
- **포트 번호 유지** (8890 → 8890 HTTPS)
- 기존 SSL 인증서 재사용 또는 확인

**예상 소요 시간**: 1-2시간 (기존 설정 복사/수정)

---

## 🎯 아키텍처 설계

### Before (현재)
```
✅ https://nas.도메인.co.kr:5000 (다른 서비스 - 이미 HTTPS)
❌ http://nas.도메인.co.kr:8890 (LinkWave - HTTP만 작동)
```

### After (목표)
```
✅ https://nas.도메인.co.kr:5000 (기존 유지)
✅ https://nas.도메인.co.kr:8890 (LinkWave - HTTPS 추가)
```

### 핵심 전략
1. **기존 인증서 재사용**: 5000 포트에서 사용 중인 SSL 인증서 확인 및 재사용
2. **Nginx 설정 복사**: 5000 포트 설정을 참고하여 8890 포트 설정 추가
3. **포트 번호 유지**: 8890 포트 그대로 사용 (사용자 요구사항)
4. **코드 수정 최소화**: nginx 설정만 수정

**왜 이 방식인가?**
- ✅ 기존 HTTPS 인프라 활용
- ✅ 인증서 재사용으로 설정 간소화
- ✅ 포트 번호 변경 없음 (기존 URL 유지)
- ✅ 빠른 적용 (1-2시간)

---

## 📦 1단계: 기존 SSL 인증서 확인 (10분)

### 1.1 5000 포트 nginx 설정 확인

**어디에**: NAS 서버

**무엇을**: 5000 포트에서 사용 중인 SSL 인증서 경로 확인

**왜**: 동일한 인증서를 8890 포트에서 재사용하기 위함

**어떻게**:
```bash
# 5000 포트 nginx 설정 찾기
sudo grep -r "listen 5000" /etc/nginx/
sudo grep -r "listen.*5000.*ssl" /etc/nginx/

# 전체 설정 확인
sudo nginx -T | grep -A 50 "listen.*5000"

# SSL 인증서 경로 확인
sudo nginx -T | grep -A 50 "listen.*5000" | grep ssl_certificate
```

**확인할 항목**:
- `ssl_certificate` 경로 (예: `/etc/letsencrypt/live/nas.도메인.co.kr/fullchain.pem`)
- `ssl_certificate_key` 경로 (예: `/etc/letsencrypt/live/nas.도메인.co.kr/privkey.pem`)
- SSL 보안 설정 (protocols, ciphers 등)
- 기타 SSL 관련 설정

### 1.2 인증서 파일 존재 확인

**어디에**: NAS 서버

**무엇을**: 인증서 파일 실제 존재 및 유효성 확인

**어떻게**:
```bash
# 인증서 파일 목록 확인 (1.1에서 찾은 경로 사용)
sudo ls -la /etc/letsencrypt/live/nas.도메인.co.kr/

# 인증서 만료일 확인
sudo openssl x509 -enddate -noout -in /etc/letsencrypt/live/nas.도메인.co.kr/fullchain.pem

# 인증서 상세 정보 확인
sudo openssl x509 -text -noout -in /etc/letsencrypt/live/nas.도메인.co.kr/fullchain.pem | grep -A 2 "Subject Alternative Name"
```

**예상 출력**:
```
/etc/letsencrypt/live/nas.도메인.co.kr/
├── fullchain.pem    # 인증서 체인
├── privkey.pem      # 개인키
├── cert.pem         # 인증서
└── chain.pem        # 중간 인증서

만료일: notAfter=2025-XX-XX XX:XX:XX GMT
```

**중요**: 인증서가 와일드카드(`*.도메인.co.kr`) 또는 SAN(Subject Alternative Names)에 `nas.도메인.co.kr`이 포함되어 있으면 재사용 가능

---

## 🔧 2단계: 8890 포트 HTTPS 설정 추가 (30분 - 1시간)

### 2.1 Nginx 설정 백업

**어디에**: NAS 서버

**무엇을**: 기존 nginx 설정 전체 백업

**왜**: 문제 발생 시 롤백 가능

**어떻게**:
```bash
# nginx 전체 설정 백업
sudo cp -r /etc/nginx /etc/nginx.backup.$(date +%Y%m%d_%H%M%S)

# 백업 확인
ls -la /etc/nginx.backup.*
```

### 2.2 기존 8890 포트 HTTP 설정 확인

**어디에**: NAS 서버

**무엇을**: 현재 8890 포트 설정 내용 확인

**어떻게**:
```bash
# 8890 포트 설정 파일 찾기
sudo grep -r "listen 8890" /etc/nginx/

# 전체 설정 확인
sudo nginx -T | grep -B 5 -A 30 "listen.*8890"
```

**확인할 항목**:
- `root` 경로 (프론트엔드 빌드 파일 위치)
- `server_name` 설정
- `location` 블록 설정
- `proxy_pass` 설정 (있다면)
- 기타 커스텀 설정

**예상 설정 예시**:
```nginx
server {
    listen 8890;
    server_name nas.도메인.co.kr;

    root /path/to/linkwave-frontend/dist;
    index index.html;

    location / {
        try_files $uri $uri/ /index.html;
    }
}
```

### 2.3 8890 포트 HTTPS 설정 추가

**어디에**: 기존 8890 포트 설정 파일 (2.2에서 찾은 파일)

**무엇을**: SSL 설정 추가

**어떻게**:

**방법 1: 기존 server 블록 수정 (간단)**

기존 `listen 8890;`을 `listen 8890 ssl http2;`로 변경하고 SSL 설정 추가:

```nginx
server {
    listen 8890 ssl http2;          # HTTP에서 HTTPS로 변경
    listen [::]:8890 ssl http2;      # IPv6 지원 (선택 사항)
    server_name nas.도메인.co.kr;

    # SSL 인증서 (1단계에서 확인한 경로 사용)
    ssl_certificate /etc/letsencrypt/live/nas.도메인.co.kr/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/nas.도메인.co.kr/privkey.pem;

    # SSL 보안 설정 (5000 포트 설정에서 복사)
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;
    ssl_prefer_server_ciphers on;
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 10m;

    # HSTS (선택 사항)
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;

    # 기존 설정 그대로 유지
    root /path/to/linkwave-frontend/dist;  # 기존 경로 유지
    index index.html;

    location / {
        try_files $uri $uri/ /index.html;
    }

    # 기존 proxy_pass 설정이 있다면 그대로 유지
    # location /api/ {
    #     proxy_pass http://localhost:XXXX/;
    #     ...
    # }

    # 로그 (기존 로그 유지 또는 새로 지정)
    access_log /var/log/nginx/linkwave_8890_access.log;
    error_log /var/log/nginx/linkwave_8890_error.log;
}
```

**방법 2: HTTP와 HTTPS 별도 블록 (권장 - HTTP 리다이렉트)**

HTTP(8890) → HTTPS(8890) 리다이렉트 추가:

```nginx
# HTTP → HTTPS 리다이렉트
server {
    listen 8890;
    listen [::]:8890;
    server_name nas.도메인.co.kr;

    # HTTPS로 리다이렉트
    return 301 https://$server_name:8890$request_uri;
}

# HTTPS 서버
server {
    listen 8890 ssl http2;
    listen [::]:8890 ssl http2;
    server_name nas.도메인.co.kr;

    # SSL 인증서 (1단계에서 확인한 경로)
    ssl_certificate /etc/letsencrypt/live/nas.도메인.co.kr/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/nas.도메인.co.kr/privkey.pem;

    # SSL 보안 설정 (5000 포트 설정 복사)
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;
    ssl_prefer_server_ciphers on;
    ssl_session_cache shared:SSL:10m;

    # HSTS
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;

    # 기존 설정 복사
    root /path/to/linkwave-frontend/dist;
    index index.html;

    location / {
        try_files $uri $uri/ /index.html;
    }

    access_log /var/log/nginx/linkwave_8890_access.log;
    error_log /var/log/nginx/linkwave_8890_error.log;
}
```

### 2.4 설정 파일 활성화

**어디에**: NAS 서버

**무엇을**: 새 설정 파일 심볼릭 링크 생성

**어떻게**:
```bash
# 설정 파일 심볼릭 링크 (sites-available 사용 시)
sudo ln -s /etc/nginx/sites-available/linkwave /etc/nginx/sites-enabled/

# 설정 파일 문법 검사
sudo nginx -t

# 성공 시 출력:
# nginx: configuration file /etc/nginx/nginx.conf test is successful

# nginx 재시작
sudo systemctl reload nginx
# 또는
sudo systemctl restart nginx

# nginx 상태 확인
sudo systemctl status nginx
```

**에러 발생 시**:
```bash
# 에러 로그 확인
sudo tail -f /var/log/nginx/error.log

# 설정 파일 상세 테스트
sudo nginx -T
```

---

## 🔄 3단계: A 프로젝트 환경 설정 확인 (30분)

### 3.1 A 프로젝트 백엔드 API 확인

**어디에**: A 프로젝트 코드베이스

**무엇을**: 백엔드 API URL 및 포트 확인

**검색**:
```bash
# 프론트엔드에서 API URL 사용 위치 찾기
cd linkwave-frontend
grep -r "VITE_API_URL" src/
grep -r "api" .env* 2>/dev/null

# 백엔드 포트 하드코딩 확인
grep -r "localhost:" src/
grep -r "http://" src/
```

**예상 시나리오**:

1. **환경 변수 사용 중**:
   ```bash
   # .env 또는 .env.production
   VITE_API_URL=http://nas.도메인.co.kr:XXXX
   ```

2. **상대 경로 사용**:
   ```javascript
   // /api/... 형태로 호출 (nginx에서 프록시)
   fetch('/api/users')
   ```

3. **절대 경로 하드코딩**:
   ```javascript
   // 수정 필요!
   const API_URL = 'http://localhost:3000';
   ```

### 3.2 환경 변수 업데이트 (필요 시)

**Before** (예시):
```bash
# .env.production
VITE_API_URL=http://nas.도메인.co.kr:8890/api
# 또는
VITE_API_URL=http://localhost:3000
```

**After** (HTTPS 적용):
```bash
# .env.production
VITE_API_URL=https://nas.도메인.co.kr/api
```

**주의**:
- A 프로젝트 백엔드가 nginx 프록시를 사용한다면 `/api` 경로 설정 필요
- A 프로젝트 백엔드가 별도 포트라면 nginx에서 프록시 설정 추가

### 3.3 프론트엔드 재빌드 및 배포 (환경 변수 변경 시)

**어디에**: 개발 환경

**무엇을**: 프로덕션 빌드 및 서버 배포

**어떻게**:
```bash
# 프로덕션 빌드
npm run build

# 빌드 파일을 서버로 전송 (예시)
scp -r dist/* user@nas.도메인.co.kr:/path/to/linkwave-frontend/dist/

# 또는 서버에서 직접 빌드
cd /path/to/linkwave-frontend
git pull origin main
npm install
npm run build
```

**주의**: 환경 변수 변경이 없다면 재빌드 불필요

---

## 🔐 4단계: B 프로젝트(JAR) CORS 설정 (1시간)

### 4.1 B 프로젝트 CORS 설정 확인

**어디에**: B 프로젝트 JAR (코드 접근 불가)

**무엇을**: CORS 허용 도메인 확인

**왜**:
- 현재: `http://nas.도메인.co.kr:10000` 직접 접근
- 변경 후: `https://nas.도메인.co.kr/app` (또는 서브도메인) 경유 필요

**문제 상황**:
- B 프로젝트 코드베이스에 접근 불가
- JAR 실행 시 환경 변수로 CORS 설정 가능한지 확인 필요

**해결 방법 1: 환경 변수로 CORS 설정 (선호)**
```bash
# JAR 실행 시 환경 변수 추가
java -jar b-project.jar \
  --server.port=10000 \
  --cors.allowed-origins=https://nas.도메인.co.kr,https://app.도메인.co.kr
```

**해결 방법 2: Nginx에서 CORS 헤더 추가 (임시)**

```nginx
# B 프로젝트 프록시 location에 추가
location /app/ {
    proxy_pass http://localhost:10000/;

    # CORS 헤더 추가 (백엔드에서 설정 불가능한 경우)
    add_header 'Access-Control-Allow-Origin' 'https://nas.도메인.co.kr' always;
    add_header 'Access-Control-Allow-Methods' 'GET, POST, PUT, DELETE, OPTIONS' always;
    add_header 'Access-Control-Allow-Headers' 'Content-Type, Authorization' always;
    add_header 'Access-Control-Allow-Credentials' 'true' always;

    # OPTIONS 요청 처리 (preflight)
    if ($request_method = 'OPTIONS') {
        return 204;
    }

    # 기존 프록시 설정
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;
}
```

**주의**:
- B 프로젝트가 이미 CORS 헤더를 보내고 있다면 중복 헤더 문제 발생 가능
- 가능하면 JAR 실행 환경 변수로 설정하는 것이 권장됨

### 4.2 A 프로젝트 CORS 설정

**상황**: A 프로젝트는 코드베이스 접근 가능

**확인 사항**:
- A 프로젝트 백엔드가 HTTPS 허용하는지 확인
- CORS 설정에 `https://nas.도메인.co.kr` 포함 여부

**수정 필요 시** (A 프로젝트 백엔드 코드):
```javascript
// 예시: Express.js
app.use(cors({
  origin: [
    'http://localhost:5173',  // 개발 환경
    'http://nas.도메인.co.kr:8890',  // 기존
    'https://nas.도메인.co.kr'  // 신규 추가
  ],
  credentials: true
}));
```

### 4.3 신뢰할 수 있는 프록시 설정 (B 프로젝트)

**왜 필요한가?**
- nginx가 `X-Forwarded-For`, `X-Forwarded-Proto` 헤더를 추가
- B 프로젝트가 실제 클라이언트 IP와 HTTPS 여부를 인식하도록 설정

**Spring Boot 예시** (참고용):
```bash
# JAR 실행 시 환경 변수
java -jar b-project.jar \
  --server.forward-headers-strategy=native
```

**환경 변수로 불가능하면**: nginx 프록시 헤더만으로도 대부분 작동

---

## ⏰ 5단계: 인증서 자동 갱신 설정 (30분)

### 5.1 Certbot 자동 갱신 테스트

**어디에**: NAS 서버

**무엇을**: 인증서 갱신 드라이런 테스트

**왜**: Let's Encrypt 인증서는 90일마다 갱신 필요

**어떻게**:
```bash
# 갱신 테스트 (실제 갱신은 안 함)
sudo certbot renew --dry-run

# 성공 시 출력:
# Congratulations, all simulated renewals succeeded
```

### 5.2 자동 갱신 Cron Job 설정

**어디에**: NAS 서버 crontab

**무엇을**: 매일 자동 갱신 체크 및 nginx 재시작

**왜**: 인증서 만료 방지

**어떻게**:
```bash
# crontab 편집
sudo crontab -e

# 매일 새벽 2시에 갱신 체크 (30일 이내 만료 시 자동 갱신)
0 2 * * * certbot renew --quiet --deploy-hook "systemctl reload nginx"

# 또는 systemd timer 사용 (이미 설치되어 있을 수 있음)
sudo systemctl status certbot.timer
sudo systemctl enable certbot.timer
sudo systemctl start certbot.timer
```

**갱신 로그 확인**:
```bash
sudo tail -f /var/log/letsencrypt/letsencrypt.log
```

---

## 🧪 6단계: 테스트 및 검증 (1시간)

### 6.1 기본 HTTPS 접속 테스트

**테스트 항목**:
```bash
# 1. HTTP → HTTPS 리다이렉트 확인
curl -I http://nas.도메인.co.kr
# 응답: 301 Moved Permanently
# Location: https://nas.도메인.co.kr/

# 2. HTTPS 접속 확인
curl -I https://nas.도메인.co.kr
# 응답: 200 OK

# 3. SSL 인증서 유효성 검증
curl -vI https://nas.도메인.co.kr 2>&1 | grep -i "SSL\|certificate"

# 4. SSL Labs 테스트 (A+ 등급 목표)
# 브라우저에서: https://www.ssllabs.com/ssltest/analyze.html?d=nas.도메인.co.kr
```

### 6.2 프론트엔드 기능 테스트

**브라우저에서**:
1. `https://nas.도메인.co.kr` 접속
2. 브라우저 주소창 자물쇠 아이콘 확인
3. 개발자 도구 열기 (F12)
4. Console 탭에서 Mixed Content 경고 없는지 확인
5. Network 탭에서 모든 요청이 HTTPS인지 확인

**체크리스트**:
- [ ] 페이지 정상 로딩
- [ ] 이미지, CSS, JS 모두 HTTPS로 로드
- [ ] Mixed Content 경고 없음
- [ ] 브라우저 자물쇠 아이콘 표시

### 6.3 백엔드 API 테스트

**테스트 항목**:
```bash
# 1. /api 경로로 백엔드 접근 확인
curl -I https://nas.도메인.co.kr/api/health
# 또는 실제 API 엔드포인트
curl -I https://nas.도메인.co.kr/api/sms/list

# 2. 실제 로그인 테스트 (브라우저)
# - 로그인 페이지 접속
# - 계정 입력 후 로그인
# - Network 탭에서 API 요청 확인
#   - Request URL: https://nas.도메인.co.kr/api/auth/login
#   - Status: 200 OK
#   - Response 정상
```

**CORS 오류 발생 시**:
```
Console 에러 예시:
Access to XMLHttpRequest at 'https://nas.도메인.co.kr/api/...' from origin 'https://nas.도메인.co.kr' has been blocked by CORS policy
```

**해결**:
- 4.1 단계의 CORS 설정 재확인
- nginx CORS 헤더 추가 (임시 해결)
- 백엔드 개발팀에 CORS 설정 요청

### 6.4 보안 헤더 검증

**브라우저 개발자 도구 → Network 탭**:
```
응답 헤더 확인:
- strict-transport-security: max-age=31536000; includeSubDomains
- x-forwarded-proto: https
- content-security-policy (있다면)
```

**온라인 보안 테스트**:
- https://securityheaders.com/?q=https://nas.도메인.co.kr
- 목표: A 등급 이상

---

## 🔍 7단계: 모니터링 및 로그 설정 (선택 사항)

### 7.1 Nginx 로그 모니터링

**실시간 로그 확인**:
```bash
# 액세스 로그
sudo tail -f /var/log/nginx/linkwave_access.log

# 에러 로그
sudo tail -f /var/log/nginx/linkwave_error.log

# SSL 핸드셰이크 에러 확인
sudo grep -i "ssl" /var/log/nginx/error.log
```

### 7.2 인증서 만료 알림 설정

**Let's Encrypt 이메일 알림**:
- Certbot 설치 시 입력한 이메일로 만료 30일, 7일, 1일 전 알림 수신

**추가 모니터링 스크립트** (선택 사항):
```bash
# /usr/local/bin/check-ssl-expiry.sh
#!/bin/bash
DOMAIN="nas.도메인.co.kr"
DAYS_UNTIL_EXPIRY=$(echo | openssl s_client -servername $DOMAIN -connect $DOMAIN:443 2>/dev/null | openssl x509 -noout -checkend 2592000)

if [ $? -ne 0 ]; then
  echo "SSL certificate for $DOMAIN expires in less than 30 days!" | mail -s "SSL Certificate Expiry Warning" admin@example.com
fi
```

**Cron 등록**:
```bash
# 매주 월요일 9시에 실행
0 9 * * 1 /usr/local/bin/check-ssl-expiry.sh
```

---

## 🚨 트러블슈팅 가이드

### 문제 1: "연결이 비공개로 설정되어 있지 않습니다" 에러

**증상**: 브라우저에서 HTTPS 접속 시 경고 페이지

**원인**:
1. 인증서가 아직 발급되지 않음
2. nginx가 잘못된 인증서 경로 참조
3. 방화벽이 443 포트 차단

**해결**:
```bash
# 1. 인증서 파일 존재 확인
sudo ls -la /etc/letsencrypt/live/nas.도메인.co.kr/

# 2. nginx 설정 경로 확인
sudo nginx -T | grep ssl_certificate

# 3. 443 포트 리스닝 확인
sudo netstat -tlnp | grep :443

# 4. nginx 재시작
sudo systemctl restart nginx
```

### 문제 2: API 요청이 404 Not Found

**증상**: 프론트엔드에서 `/api/...` 호출 시 404 에러

**원인**:
1. nginx reverse proxy 설정 오류
2. 백엔드 JAR가 10000 포트에서 실행되지 않음
3. API 경로 불일치

**해결**:
```bash
# 1. 백엔드 JAR 실행 확인
sudo netstat -tlnp | grep :10000
# 또는
curl http://localhost:10000

# 2. nginx 프록시 로그 확인
sudo tail -f /var/log/nginx/linkwave_error.log

# 3. 백엔드 API 경로 확인
# 백엔드가 /api prefix 사용하는지 확인
# 예: 백엔드 실제 경로가 /sms/list라면
#     nginx: /api/sms/list → proxy_pass: http://localhost:10000/sms/list
```

**nginx 설정 수정 예시**:
```nginx
# 백엔드가 /api prefix를 사용하지 않는 경우
location /api/ {
    # /api/ 제거하고 전달
    rewrite ^/api/(.*)$ /$1 break;
    proxy_pass http://localhost:10000;
}
```

### 문제 3: CORS 에러

**증상**: Console에 CORS policy 에러

**해결**: 4.1 단계의 nginx CORS 헤더 추가

### 문제 4: 자동 갱신 실패

**증상**: Certbot 갱신 실패 이메일 수신

**원인**:
1. 80 포트가 차단됨 (Let's Encrypt 검증 실패)
2. nginx 설정에서 `/.well-known/acme-challenge/` 경로 차단

**해결**:
```bash
# 1. 80 포트 확인
sudo netstat -tlnp | grep :80

# 2. certbot 수동 갱신 시도
sudo certbot renew --force-renewal

# 3. nginx 설정 확인
sudo nginx -T | grep -A 5 "well-known"
```

### 문제 5: Mixed Content 경고

**증상**: 브라우저 Console에 "Mixed Content" 경고

**원인**: HTTPS 페이지에서 HTTP 리소스(이미지, API 등) 로드

**해결**:
```javascript
// 프론트엔드 코드에서 HTTP URL 찾기
grep -r "http://" src/

// 모두 HTTPS 또는 상대 경로로 변경
// Before: http://nas.도메인.co.kr/api/...
// After: https://nas.도메인.co.kr/api/...
// 또는: /api/... (상대 경로)
```

---

## 📊 예상 결과

### 보안 개선
- ✅ **암호화된 통신**: 모든 데이터 TLS 1.2/1.3로 암호화
- ✅ **중간자 공격 방지**: SSL 인증서로 서버 신원 검증
- ✅ **인증 정보 보호**: 로그인 세션 및 토큰 안전하게 전송
- ✅ **브라우저 신뢰**: 자물쇠 아이콘 표시, 경고 없음
- ✅ **두 프로젝트 모두 보안 강화**: A 프로젝트, B 프로젝트 모두 HTTPS 적용

### 사용자 경험
- ✅ **표준 HTTPS 포트**: 포트 번호 생략 가능
  - A 프로젝트: `https://nas.도메인.co.kr`
  - B 프로젝트: `https://nas.도메인.co.kr/app` 또는 `https://app.도메인.co.kr`
- ✅ **SEO 개선**: 검색 엔진이 HTTPS 우대
- ✅ **최신 웹 API 지원**: Service Worker, Geolocation 등 HTTPS 필수 API 사용 가능

### 운영
- ✅ **무료 인증서**: Let's Encrypt 무료
- ✅ **자동 갱신**: 90일마다 자동 갱신
- ✅ **단일 관리 지점**: nginx에서 모든 SSL 처리
- ✅ **코드 수정 최소화**: 두 프로젝트 모두 코드 수정 거의 불필요

---

## 📋 체크리스트

### 사전 준비
- [ ] NAS 서버 SSH 접속 확인
- [ ] 도메인 DNS A 레코드 설정 확인 (nas.도메인.co.kr)
- [ ] B 프로젝트용 서브도메인 설정 확인 (선택 사항: app.도메인.co.kr)
- [ ] 공유기 포트 포워딩 (80, 443)
- [ ] nginx 설치 확인
- [ ] A 프로젝트 8890 포트 실행 확인
- [ ] B 프로젝트 JAR 10000 포트 실행 확인

### A 프로젝트 현황 파악
- [ ] 기존 8890 포트 nginx 설정 확인 (`grep -r "listen 8890" /etc/nginx/`)
- [ ] A 프로젝트 프론트엔드 빌드 경로 확인
- [ ] A 프로젝트 백엔드 API 프록시 설정 확인
- [ ] A 프로젝트 백엔드 포트 확인

### 인증서 발급
- [ ] Certbot 설치
- [ ] 방화벽 80, 443 포트 개방
- [ ] 인증서 발급 (`certbot --nginx -d nas.도메인.co.kr`)
- [ ] 서브도메인 사용 시: `certbot --nginx -d nas.도메인.co.kr -d app.도메인.co.kr`
- [ ] 인증서 파일 생성 확인 (`/etc/letsencrypt/live/`)

### Nginx 설정
- [ ] 기존 nginx 설정 백업 (`cp -r /etc/nginx /etc/nginx.backup`)
- [ ] A 프로젝트 HTTPS 설정 작성
- [ ] B 프로젝트 reverse proxy 설정 작성
- [ ] HTTP → HTTPS 리다이렉트 설정
- [ ] SSL 인증서 경로 설정
- [ ] `nginx -t` 문법 검사 성공
- [ ] `systemctl reload nginx` 재시작

### A 프로젝트 환경 설정
- [ ] 프론트엔드 API URL 확인 (`grep -r "VITE_API_URL" src/`)
- [ ] 필요 시 `.env.production` 수정 (HTTP → HTTPS)
- [ ] 필요 시 프로덕션 빌드 (`npm run build`)
- [ ] 필요 시 빌드 파일 서버 배포
- [ ] A 프로젝트 백엔드 CORS 설정 확인

### B 프로젝트 설정
- [ ] B 프로젝트 CORS 설정 확인 (환경 변수 또는 nginx 헤더)
- [ ] X-Forwarded-Proto 헤더 처리 확인

### 자동 갱신
- [ ] `certbot renew --dry-run` 테스트 성공
- [ ] cron job 또는 systemd timer 설정 확인
- [ ] 갱신 알림 이메일 수신 확인

### 테스트 (A 프로젝트)
- [ ] HTTP → HTTPS 리다이렉트 테스트 (http://nas.도메인.co.kr → https://nas.도메인.co.kr)
- [ ] HTTPS 접속 성공 (https://nas.도메인.co.kr)
- [ ] 브라우저 자물쇠 아이콘 표시
- [ ] A 프로젝트 페이지 정상 로딩
- [ ] A 프로젝트 API 요청 정상 작동
- [ ] CORS 에러 없음
- [ ] Mixed Content 경고 없음

### 테스트 (B 프로젝트)
- [ ] B 프로젝트 HTTPS 접속 성공 (/app 또는 서브도메인)
- [ ] B 프로젝트 페이지 정상 로딩
- [ ] B 프로젝트 API 정상 작동
- [ ] CORS 에러 없음

### 보안 검증
- [ ] SSL Labs 테스트 A 등급 이상 (https://www.ssllabs.com/ssltest/)
- [ ] Security Headers 검증 (https://securityheaders.com/)

### 모니터링
- [ ] Nginx 로그 확인 (access, error)
- [ ] 인증서 만료일 확인 (`openssl x509 -enddate -noout -in /etc/letsencrypt/live/nas.도메인.co.kr/fullchain.pem`)

---

## 🔗 참고 자료

- [Let's Encrypt 공식 문서](https://letsencrypt.org/getting-started/)
- [Certbot 사용 가이드](https://certbot.eff.org/)
- [Nginx Reverse Proxy 설정](https://docs.nginx.com/nginx/admin-guide/web-server/reverse-proxy/)
- [Mozilla SSL Configuration Generator](https://ssl-config.mozilla.org/)
- [SSL Labs Server Test](https://www.ssllabs.com/ssltest/)

---

## 🎯 다음 단계 (배포 후)

1. **성능 최적화**:
   - HTTP/2 Server Push 고려
   - Gzip/Brotli 압축 활성화
   - 정적 파일 캐싱 설정

2. **보안 강화**:
   - Content Security Policy (CSP) 헤더 추가
   - X-Frame-Options 헤더 추가
   - Rate Limiting 설정 (DDoS 방지)

3. **모니터링**:
   - Prometheus + Grafana 연동
   - 업타임 모니터링 (UptimeRobot 등)
   - SSL 인증서 만료 알림 자동화

4. **백업**:
   - nginx 설정 Git 버전 관리
   - Let's Encrypt 인증서 백업 스크립트
   - 정기 설정 백업 자동화

---

**이 계획을 따라하면 1-2일 내에 안전한 HTTPS 환경을 구축할 수 있습니다.**
