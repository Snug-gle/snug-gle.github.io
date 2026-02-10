---
created: 2026-02-10
tags:
  - linkwave
  - frontend
  - deployment
---

> 이 문서는 linkwave-docs의 frontend/DEPLOYMENT.md를 요약한 것입니다.

# LinkWave Frontend 배포 가이드

## 1. 배포 개요

### 배포 방식
**정적 파일 직접 배포** (Docker 미사용)
- 빌드: GitLab CI/CD → Vite → `dist/` 생성
- 전송: `scp`로 서버 전송
- 배포: `deploy.sh` → 백업 → 교체 → Nginx 재시작
- 서빙: Nginx 정적 파일 + `/api` 리버스 프록시

### 배포 아키텍처
```
개발자 PC → git push (develop)
  ↓
GitLab CI/CD
  [Build] npm ci → npm run lint → npm run build → dist/
  [Deploy] SCP → SSH → deploy.sh
  ↓
배포 서버 (nas.iotree.co.kr)
  Nginx (8890)
    ├── 정적 파일 서빙 (/frontend)
    └── /api/* → Spring Boot (18080) 프록시
```

---

## 2. 서버 환경

- **호스트**: `nas.iotree.co.kr` (SSH: 8122)
- **배포 경로**: `/home/sanghpark/app/link-wave/frontend`
- **백업 경로**: `/home/sanghpark/app/link-wave/frontend-backup`
- **Nginx 설정**: `/etc/nginx/conf.d/linkwave.conf`

---

## 3. GitLab CI/CD 자동 배포

### 파이프라인
1. **build** (자동): `npm ci` → `npm run lint` → `npm run build` → dist/ Artifact
2. **deploy** (수동): SCP 전송 → SSH 접속 → deploy.sh 실행

### deploy.sh 동작
1. 기존 앱 백업 (`/frontend` → `/frontend-backup`)
2. 새 앱 배포 (`dist/` → `/frontend`)
3. Nginx 설정 업데이트 및 재시작

---

## 4. 수동 배포

```bash
# 1. 로컬 빌드
npm ci && npm run build

# 2. 서버 전송
scp -P 8122 -r dist/ sanghpark@nas.iotree.co.kr:/home/sanghpark/app/link-wave/frontend-new/

# 3. SSH 접속 후 교체
ssh -p 8122 sanghpark@nas.iotree.co.kr
cd /home/sanghpark/app/link-wave
mv frontend frontend-backup-$(date +%Y%m%d)
mv frontend-new frontend

# 4. Nginx 재시작
sudo nginx -t && sudo systemctl reload nginx
```

---

## 5. Nginx 설정

```nginx
server {
    listen 8890;
    server_name nas.iotree.co.kr;

    root /home/sanghpark/app/link-wave/frontend;
    index index.html;

    # SPA fallback
    location / {
        try_files $uri $uri/ /index.html;
    }

    # API 프록시
    location /api/ {
        proxy_pass http://localhost:18080;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }

    # 정적 파일 캐시
    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff2)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
}
```

---

## 6. 롤백

```bash
# 백업에서 복원
cd /home/sanghpark/app/link-wave
mv frontend frontend-failed
mv frontend-backup frontend
sudo systemctl reload nginx
```

---

## 7. 트러블슈팅

| 문제 | 원인 | 해결 |
|------|------|------|
| 404 에러 | SPA fallback 미설정 | `try_files` 확인 |
| API 502 | 백엔드 미실행 | 백엔드 프로세스 확인 |
| 캐시 문제 | 이전 버전 캐시 | 브라우저 캐시 클리어 |
| 권한 오류 | 파일 권한 | `chmod -R 755 frontend/` |

---

## Related Documents

- [[backend-deployment|Backend Deployment]]
- [[https-certificate|HTTPS Certificate Setup]]
