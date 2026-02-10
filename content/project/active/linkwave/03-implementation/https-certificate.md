---
created: 2026-02-10
tags:
  - linkwave
  - frontend
  - https
  - certificate
---

> 이 문서는 linkwave-docs의 HTTPS_CERTIFICATE.md를 요약한 것입니다.

# HTTPS Certificate Setup Guide

## 1. 개요

LinkWave 프론트엔드/백엔드의 HTTPS 인증서 설정 가이드. 개발 환경과 프로덕션 환경 모두 포함.

---

## 2. 개발 환경 (Self-Signed)

### mkcert를 이용한 로컬 인증서 생성

```bash
# mkcert 설치
brew install mkcert  # macOS
choco install mkcert # Windows

# 로컬 CA 설치
mkcert -install

# 인증서 생성
mkcert localhost 127.0.0.1 ::1
# → localhost+2.pem, localhost+2-key.pem
```

### Vite 개발 서버 HTTPS 설정

```typescript
// vite.config.ts
export default defineConfig({
  server: {
    https: {
      key: fs.readFileSync('./localhost+2-key.pem'),
      cert: fs.readFileSync('./localhost+2.pem'),
    },
    port: 3000,
  },
})
```

### Spring Boot HTTPS 설정

```yaml
# application-local.yml
server:
  ssl:
    key-store: classpath:keystore.p12
    key-store-password: ${SSL_KEYSTORE_PASSWORD}
    key-store-type: PKCS12
  port: 8443
```

---

## 3. 프로덕션 환경

### Let's Encrypt + Certbot

```bash
# Certbot 설치
sudo apt install certbot python3-certbot-nginx

# 인증서 발급
sudo certbot --nginx -d linkwave.example.com

# 자동 갱신 설정
sudo certbot renew --dry-run
```

### Nginx SSL 설정

```nginx
server {
    listen 443 ssl http2;
    server_name linkwave.example.com;

    ssl_certificate /etc/letsencrypt/live/linkwave.example.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/linkwave.example.com/privkey.pem;

    # SSL 보안 설정
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256;
    ssl_prefer_server_ciphers off;

    # HSTS
    add_header Strict-Transport-Security "max-age=63072000" always;

    location / {
        root /var/www/linkwave;
        try_files $uri $uri/ /index.html;
    }

    location /api {
        proxy_pass http://localhost:8080;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}

# HTTP → HTTPS 리다이렉트
server {
    listen 80;
    server_name linkwave.example.com;
    return 301 https://$server_name$request_uri;
}
```

---

## 4. 인증서 갱신

### 자동 갱신 (Cron)
```bash
# /etc/cron.d/certbot
0 0 1 * * root certbot renew --quiet --post-hook "systemctl reload nginx"
```

### 수동 갱신
```bash
sudo certbot renew
sudo systemctl reload nginx
```

---

## 5. 트러블슈팅

| 문제 | 원인 | 해결 |
|------|------|------|
| ERR_CERT_AUTHORITY_INVALID | 자체 서명 인증서 | mkcert -install로 CA 등록 |
| Mixed Content | HTTP 리소스 포함 | 모든 URL을 https://로 변경 |
| 인증서 만료 | 갱신 미실행 | certbot renew |
| CORS 오류 | HTTPS/HTTP 혼용 | 프론트/백엔드 모두 HTTPS |

---

## Related Documents

- [[frontend-deployment|Frontend Deployment]]
- [[backend-deployment|Backend Deployment]]
