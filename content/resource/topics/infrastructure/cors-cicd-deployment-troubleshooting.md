---
tags: [infrastructure, troubleshooting, cors, cicd, deployment, nginx, vite, gitlab-ci]
category: infrastructure
created: 2026-01-06
status: complete
description: 배포 서버에서 발생한 CORS 오류, CI/CD 환경변수 설정 문제, Nginx 설정 파일 배포 경로 문제를 해결하고 Vite 환경변수 로딩, CI/CD 배포 스크립트 분리 패턴, CORS 동작 원리 등에 대한 교훈을 정리
---

# CORS 오류와 CI/CD 배포 환경 설정 트러블슈팅: Nginx, Vite, GitLab CI 통합 가이드

> 배포 서버에서 마주한 CORS "Missing Allow Origin" 오류, CI/CD 환경변수 관리 혼란, Nginx 설정 파일 배포 경로 문제를 해결하는 과정을 상세히 설명합니다. Vite의 환경변수 로딩 메커니즘, CI/CD와 배포 스크립트 분리 패턴, 그리고 Nginx를 활용한 CORS 처리 전략을 통해 안정적인 배포 환경을 구축하는 실전 경험을 공유합니다.

---

## 개요
이 문서는 LinkWave 프로젝트 배포 과정에서 발생한 복합적인 문제들을 해결한 경험을 공유합니다. 주요 문제로는 배포 서버에서 발생한 CORS "Missing Allow Origin" 오류, CI/CD 파이프라인에서의 환경변수 설정 혼란, 그리고 Nginx 설정 파일 배포 경로 문제 등이 있었습니다. 이러한 문제들을 해결하기 위해 Vite의 환경변수 로딩 메커니즘, CI/CD와 배포 스크립트의 효과적인 분리 패턴, Nginx를 통한 CORS 처리 전략 등을 분석하고 적용했습니다. 본 가이드는 안정적이고 효율적인 CI/CD 및 배포 환경을 구축하는 데 필요한 실전적인 지식과 교훈을 제공합니다.

## 문제 상황

LinkWave 프로젝트의 배포 서버(nas.iotree.co.kr:8890)에서 API 요청 시 다음과 같은 문제들이 발생했습니다.

1.  **CORS "Missing Allow Origin" 오류**:
    API 요청이 200 OK 상태 코드로 성공적으로 응답을 받았음에도 불구하고, 브라우저 콘솔에서 "CORS header 'Access-Control-Allow-Origin' missing" 오류가 발생하며 요청이 차단되었습니다. 이는 Nginx 설정 파일이 제대로 적용되지 않았거나, CORS 관련 설정에 오류가 있음을 시사했습니다.

2.  **환경변수 파일 적용 혼란**:
    CI/CD 과정에서 `.env.production`과 `.env.dev` 파일 중 어떤 파일이 적용되는지 불명확했습니다. 특히 CI/CD 스크립트에서 `cp .env.dev .env` 명령 후 `npm run build`를 실행했음에도 불구하고, `npm run build`가 기본적으로 `--mode production`으로 실행되어 `.env.production` 파일의 내용이 `.env.dev` 내용을 덮어쓰는 문제가 발생했습니다. 이로 인해 잘못된 API 기본 URL (포트가 누락된 `https://nas.iotree.co.kr/api/v1`)이 프론트엔드 빌드에 포함되었고, 이는 Synology NAS의 기본 웹 서버(443 포트)로 요청을 보내는 예상치 못한 결과를 초래하여 CORS 오류의 직접적인 원인이 되었습니다.

3.  **Nginx 설정 파일 배포 경로 문제**:
    CI/CD 파이프라인에서 Nginx 설정 파일을 `/etc/nginx/conf.d/` 경로로 직접 전송하는 것이 root 권한 문제로 인해 불가능했습니다. 이로 인해 Nginx 설정 파일이 올바르게 배포되지 않아 Nginx의 프록시 및 CORS 관련 설정이 적용되지 않는 문제가 있었습니다. `deploy.sh` 스크립트에서 Nginx 설정 파일을 찾는 경로가 잘못되어 해당 파일을 시스템 경로로 복사하는 데도 실패했습니다.

## 원인 분석

문제의 핵심 원인은 다음과 같습니다.

### Vite 환경변수 로딩 메커니즘의 오해

Vite는 환경변수를 다음 순서로 로딩합니다.
1.  `.env` 파일 읽기
2.  `.env.[mode]` 파일 읽기 (빌드 `--mode`에 따라)
3.  나중에 읽은 파일이 이전 값을 덮어씁니다.

기존 CI/CD 스크립트는 `cp .env.dev .env` 후 `npm run build` (기본 `--mode production`)를 실행하여 `.env.production`이 `.env` (`.env.dev`의 내용)를 덮어쓰는 방식으로 동작했습니다. `.env.production`에 포트가 누락된 `VITE_API_BASE_URL`이 설정되어 있었고, 이 잘못된 URL이 빌드 시 프론트엔드 코드에 삽입되어 브라우저가 API 요청을 443 포트로 보내게 만들었습니다.

### Nginx 설정 파일 권한 및 경로 문제

Nginx 설정 파일은 일반적으로 `/etc/nginx/conf.d/`와 같은 시스템 경로에 위치하며, 이는 root 권한이 필요합니다. CI/CD 에이전트는 제한된 권한으로 실행되므로 이 경로에 직접 파일을 쓸 수 없습니다. `deploy.sh` 스크립트도 Nginx 설정 파일의 실제 위치를 제대로 참조하지 못하여 시스템 경로로 복사하는 데 실패했습니다.

## 해결 과정

### 1. 환경변수 설정 분석 및 수정

*   **`.env.production` 파일 주석 처리**: 현재 개발/운영 환경이 통합되어 있으므로, `.env.production` 파일의 내용을 주석 처리하여 불필요한 환경변수 오버라이드를 방지했습니다.
*   **CI/CD 빌드 모드 명시**: `npm run build -- --mode dev` 명령어를 사용하여 빌드 시 명시적으로 `.env.dev` 파일을 사용하도록 지정했습니다. 이를 통해 `.env.dev` 파일의 `VITE_API_BASE_URL=/api/v1` 상대 경로가 올바르게 적용되도록 했습니다. 상대 경로를 사용함으로써 브라우저가 현재 접속한 도메인과 포트(`https://nas.iotree.co.kr:8890`)를 기준으로 API 요청을 보내게 되어 Nginx 프록시가 올바르게 동작할 수 있게 되었습니다.

### 2. Nginx 설정 파일 배포 경로 수정

CI/CD 파이프라인에서 Nginx 설정 파일을 서버의 사용자 홈 디렉토리 내 특정 경로(` /home/sanghpark/app/link-wave/nginx/`)로 전송하도록 변경했습니다.
`deploy.sh` 스크립트는 이 새로운 경로에서 Nginx 설정 파일을 읽어 `sudo cp` 명령어를 통해 `/etc/nginx/conf.d/`로 복사하도록 수정했습니다. 이 2단계 접근 방식을 통해 CI/CD 에이전트의 권한 문제와 `deploy.sh` 스크립트의 파일 접근 문제를 모두 해결했습니다.

**수정된 `.gitlab-ci.yml` 예시:**
```yaml
- ssh -p 8122 sanghpark@nas.iotree.co.kr "mkdir -p /home/sanghpark/app/link-wave/nginx"
- scp -P 8122 nginx/conf.d/linkwave.conf sanghpark@nas.iotree.co.kr:/home/sanghpark/app/link-wave/nginx/linkwave.conf
```

**수정된 `deploy.sh` 예시:**
```bash
if [ -f "$APP_DIR/nginx/linkwave.conf" ]; then
    sudo cp "$APP_DIR/nginx/linkwave.conf" "$NGINX_CONF_DIR/linkwave.conf"
fi
sudo systemctl reload nginx
```

### 3. `deploy.sh`의 역할 재정립

`deploy.sh` 스크립트는 GitLab CI에서 직접 수행하기 어려운 권한이 필요한 작업(Nginx 설정 파일 복사, Nginx 재시작, 서비스 재시작 등)을 서버 측에서 `sudo` 권한으로 실행하기 위한 핵심적인 역할을 수행하도록 명확히 했습니다. 또한, 배포 실패 시 자동 롤백 기능을 포함하여 안정성을 높였습니다.

## 설계 결정과 이유 (왜 이 방식을 선택했는가)

### CI/CD와 배포 스크립트 분리 패턴

CI/CD 파이프라인과 서버 내 `deploy.sh` 스크립트의 역할을 분리하는 것은 권한 관리와 배포 안정성을 높이는 효과적인 패턴입니다. CI/CD는 빌드와 사용자 홈 디렉토리로의 파일 전송 등 제한적인 권한만으로 수행 가능한 작업을 담당하고, `deploy.sh`는 `sudo` 권한이 필요한 시스템 레벨 작업(Nginx 설정 복사, 서비스 재시작 등)을 서버에서 직접 수행하도록 했습니다. 이 분리 패턴은 권한 문제를 해결하고, 배포 프로세스의 각 단계를 명확히 하여 문제 발생 시 디버깅을 용이하게 합니다.

### 상대 경로 API URL 활용

프론트엔드의 API URL을 `/api/v1`과 같은 **상대 경로**로 설정한 것은 배포 환경에 구애받지 않는 유연한 구성을 위한 것입니다. 이는 브라우저가 현재 접속한 도메인과 포트(`https://nas.iotree.co.kr:8890` 등)를 기준으로 API 요청을 보내도록 하여, Nginx의 리버스 프록시 설정(`location /api/`)과 자연스럽게 연동됩니다. 절대 경로를 사용하고 포트가 누락될 경우 발생했던 문제(기본 443 포트로 요청)를 방지하며, 환경 변수 관리의 복잡성을 줄입니다.

### Nginx를 통한 CORS 처리

CORS(Cross-Origin Resource Sharing) 문제는 브라우저의 보안 정책으로 인해 발생하며, 이를 백엔드 애플리케이션(`Spring Security`)에서 직접 처리하는 대신 **API Gateway 역할의 Nginx**에서 처리하도록 했습니다. Nginx에서 `Access-Control-Allow-Origin`, `Access-Control-Allow-Credentials` 등의 헤더를 응답에 추가함으로써, 백엔드 애플리케이션은 CORS 정책에 대해 신경 쓸 필요 없이 비즈니스 로직에 집중할 수 있습니다. 또한 `proxy_hide_header`를 사용하여 백엔드에서 실수로 추가될 수 있는 CORS 헤더를 제거하고 Nginx에서 통일된 CORS 헤더를 제공함으로써 일관된 정책을 유지합니다. 이는 백엔드 코드의 복잡성을 줄이고, CORS 정책 변경 시 Nginx 설정만 수정하면 되는 관리의 이점을 제공합니다.

### 개발/운영 서버 통합 관리 (`.env.dev` 중심)

현재는 개발 및 운영 환경이 하나의 서버에서 통합되어 운영되고 있으므로, `.env.dev` 파일을 중심으로 환경변수를 관리하도록 단순화했습니다. 이는 불필요한 환경 파일 분리를 피하고 관리의 복잡성을 줄이며, 추후 별도의 운영 서버가 구축될 경우 `.env.production` 파일을 활성화하여 쉽게 전환할 수 있도록 유연성을 확보했습니다.

## 배운 점

1.  **Vite 환경변수 메커니즘의 명확한 이해**: `Vite`의 `mode` 시스템과 `.env` 파일 로딩 순서가 빌드 결과에 어떤 영향을 미치는지 정확히 이해하는 것이 중요합니다. 특히 `--mode` 플래그의 사용과 기본값(`production`)을 인지하고 명시적으로 빌드 모드를 지정하는 것이 환경변수 혼란을 방지하는 핵심입니다. 환경변수는 빌드 타임에 결정되며, 빌드 후에는 변경 불가능하다는 점을 명심해야 합니다.

2.  **CI/CD 권한 제약과 배포 스크립트의 중요성**: GitLab CI와 같은 CI/CD 도구는 보안상의 이유로 제한된 권한으로 실행됩니다. 따라서 시스템 파일을 변경하거나 서비스를 재시작하는 등의 `sudo` 권한이 필요한 작업은 서버에서 별도로 실행되는 배포 스크립트(`deploy.sh`)에 위임해야 합니다. 이 2단계 접근 방식은 권한 문제를 해결하고 CI/CD 파이프라인의 안정성을 확보하는 데 필수적입니다.

3.  **API URL 상대 경로 활용의 이점**: 프론트엔드에서 API 요청 URL을 상대 경로(`예: /api/v1`)로 설정하는 것은 유연한 배포 환경 구축에 매우 유리합니다. 브라우저가 현재 접속한 도메인과 포트를 자동으로 사용하므로, 개발/테스트/운영 등 다양한 환경에서 별도의 환경변수 변경 없이 Nginx와 같은 리버스 프록시를 통해 요청을 올바른 백엔드로 전달할 수 있습니다.

4.  **CORS 처리의 책임 분리**: CORS는 브라우저 보안 정책이며, 백엔드 애플리케이션이 아닌 Nginx와 같은 API Gateway/리버스 프록시 계층에서 처리하는 것이 일반적이고 권장됩니다. Nginx에서 `Access-Control-Allow-Origin` 및 `Access-Control-Allow-Credentials` 헤더를 관리함으로써 백엔드 애플리케이션의 코드 복잡성을 줄이고, CORS 정책 변경 시 더 빠르고 유연하게 대응할 수 있습니다. `proxy_hide_header`를 사용하여 백엔드에서 불필요하게 추가되는 CORS 헤더를 제거하는 것도 중요합니다.

5.  **배포 자동화 시 롤백 계획의 필요성**: `deploy.sh`와 같은 배포 스크립트에 배포 실패 시 이전 버전으로 자동 롤백하는 로직을 포함하는 것은 배포 안정성 확보에 매우 중요합니다. 이는 서비스 중단을 최소화하고 빠른 복구를 가능하게 합니다.

---

## References
[명시적인 참조가 없어 빈 섹션으로 유지합니다.]