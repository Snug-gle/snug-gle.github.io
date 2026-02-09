---
created: 2025-11-13
---
# 2025-11-13 InvestFlow: 배포 인프라 구축 및 코드 리팩토링

#InvestFlow #Deployment #CI/CD #DevOps #Nginx #Docker #GitHubActions #BlueGreenDeployment #Spring #React #Refactoring #RaspberryPi #2025-11-13

## 개요

2025년 11월 13일, InvestFlow 프로젝트의 백엔드 및 프론트엔드 배포 인프라를 구축하고 CI/CD 파이프라인을 설정하며, 불필요한 코드를 정리하는 작업을 수행했습니다.

## 주요 목표

- Blue-Green 무중단 배포 전략 구현
- Nginx를 통한 프론트엔드/백엔드 통합 아키텍처 구축
- GitHub Actions 기반 CI/CD 파이프라인 자동화
- 프로젝트 코드베이스 정리 및 초기화

## 백엔드 변경사항 (invest-flow-BE)

### Git 커밋

- `e9ea48a` (2025-11-13 17:08:26): chore: nginx.conf 수정

### 주요 파일 변경

- `DEPLOYMENT.md` 추가: Blue-Green 배포 가이드 문서 작성 (539줄)
- `GITHUB_SECRETS.md` 업데이트
- `nginx.conf` 수정: 프론트엔드 정적 파일 서빙 및 API 프록시 설정
- GitHub Actions workflow 수정 (`.github/workflows/dev-server-deploy.yml`)
- `deploy.sh` 스크립트 개선

## 프론트엔드 변경사항 (investflow-prototype-FE)

### Git 커밋

- `fedb4f1` (2025-11-13 17:10:19): chore: docs 수정
- `8121dbe` (2025-11-13 15:41:12): test: try deployment FE
- `343cd00` (2025-11-13 15:30:35): fix: correct CSS import case sensitivity
- `c91c859` (2025-11-13 15:27:57): fix: remove test step from deployment workflows
- `eac796c` (2025-11-13 15:22:51): chore: reset to boilerplate state
- `3221cb6` (2025-11-13 13:48:23): feat: add develop/main branch deployment strategy

### 주요 파일 변경

- `FRONTEND_DEPLOYMENT.md` 추가: 프론트엔드/백엔드 통합 배포 가이드 문서 작성 (423줄)
- `README.md` 대폭 수정
- 제거된 코드:
  - `stockApi` 관련 코드 및 테스트
  - 컴포넌트: `Header`, `ResultCard`
  - Hooks: `useStockData`
  - MSW (Mock Service Worker) 관련 코드
- 페이지 리팩토링: `AnalysisPage`, `HomePage`
- GitHub Actions workflows 수정: `dev-deploy.yml`, `prod-deploy.yml`

## 구현 상세

### 배포 아키텍처

```
┌─────────────────────────────────────────────┐
│          Raspberry Pi (Port 80)             │
├─────────────────────────────────────────────┤
│                   Nginx                     │
│  ┌───────────────────────────────────────┐  │
│  │  / → Frontend Static Files            │  │
│  │      (/var/www/investflow-frontend)   │  │
│  │                                        │  │
│  │  /api/* → Backend API Proxy           │  │
│  │      (→ localhost:8081 or 8082)       │  │
│  └───────────────────────────────────────┘  │
│                                             │
│  ┌─────────────┐      ┌─────────────┐      │
│  │   Blue      │      │   Green     │      │
│  │ Port 8081   │      │ Port 8082   │      │
│  │   (Docker)  │ ←→   │   (Docker)  │      │
│  └─────────────┘      └─────────────┘      │
│    Blue-Green Deployment                    │
└─────────────────────────────────────────────┘
```

### 배포 인프라

- **Blue-Green 무중단 배포**: 안정적인 서비스 업데이트를 위한 전략 구현
  - Blue (Port 8081)와 Green (Port 8082) 두 환경 운영
  - 헬스체크 통과 시 Nginx upstream 자동 전환
  - 배포 실패 시 자동 롤백
- **Nginx 리버스 프록시**:
  - 프론트엔드 정적 파일 서빙 (`/`)
  - 백엔드 API 요청 라우팅 (`/api/*`)
  - Keepalive 설정으로 성능 최적화
- **Raspberry Pi 배포 환경**: 실제 운영 환경으로 활용

### CI/CD 파이프라인

- **GitHub Actions**:
  - `develop` 브랜치: 개발 환경 자동 배포
  - `main` 브랜치: 운영 환경 자동 배포 (테스트 포함)
- **Docker 컨테이너화**:
  - Multi-platform 이미지 빌드 (ARM64, AMD64)
  - Docker Hub에 이미지 푸시
  - Blue-Green 배포 스크립트 자동 실행

### 문서화

- **DEPLOYMENT.md** (백엔드): Blue-Green 배포 가이드
  - 초기 설정 (Raspberry Pi, SSH, Docker, Nginx)
  - GitHub Secrets 설정
  - 배포 프로세스 및 롤백 방법
  - 트러블슈팅 가이드
- **FRONTEND_DEPLOYMENT.md** (프론트엔드): 통합 배포 가이드
  - 배포 아키텍처 다이어그램
  - 브랜치 전략
  - 로컬 개발 환경 설정
  - 배포 플로우 요약

### 코드 정리

불필요한 기능 제거를 통해 프로젝트를 보일러플레이트 상태로 초기화:
- Stock API 관련 기능 제거 (향후 재구현 예정)
- Mock Service Worker 제거 (실제 API 사용)
- 사용하지 않는 컴포넌트 및 훅 제거
- 핵심 기능 개발에 집중할 수 있도록 코드베이스 단순화

## 트러블슈팅 히스토리

배포 과정에서 해결한 주요 문제들:

1. **SSH 포트 설정**: GitHub Actions에서 포트 2222 접속 문제
2. **SSH 키 Passphrase**: 자동 인증을 위해 passphrase 제거
3. **네트워크 연결**: DDNS 도메인 사용으로 외부 접근 가능하도록 설정
4. **Docker 이미지 이름**: 워크플로우와 배포 스크립트 간 이미지 이름 통일
5. **Docker Compose 버전**: V2 문법으로 변경 (`docker-compose` → `docker compose`)

자세한 내용은 백엔드 저장소의 `DEPLOYMENT.md` 참조.

## 기술 스택

- **Backend**: Spring Boot, Gradle, Docker
- **Frontend**: React 19, TypeScript, Vite
- **Infrastructure**: Nginx, Docker, Raspberry Pi
- **CI/CD**: GitHub Actions
- **Deployment**: Blue-Green Deployment Strategy

## 관련 링크

- [[resource/topics/infrastructure/Blue-Green Deployment]]
- [[resource/topics/infrastructure/Nginx]]
- [[resource/topics/infrastructure/Docker]]
- [[resource/topics/spring/Spring Boot]]
- [[resource/topics/frontend/react/React]]

## 향후 계획

- [ ] Stock API 재구현
- [ ] 사용자 인증 시스템 구축
- [ ] 포트폴리오 분석 기능 개발
- [ ] HTTPS 설정 (Let's Encrypt)
- [ ] 모니터링 및 알림 시스템 구축
