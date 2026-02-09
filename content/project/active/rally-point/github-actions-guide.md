---
tags:
  - project
  - rally-point
  - ci-cd
  - github-actions
  - automation
category: project
status: in-progress
created: 2025-10-29
updated: 2025-10-29
---

# RallyPoint User Service - GitHub Actions 가이드

## 1. 현재 CI/CD 구성

### 1.1 기존 Workflow 분석

**파일 위치**: `.github/workflows/ci.yml`

```yaml
name: CI
on:
  push:
    branches-ignore:
      - main

jobs:
  lint:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout code
        uses: actions/checkout@v4
        with:
          submodules: true
      - name: Set up JDK
        uses: actions/setup-java@v4
        with:
          distribution: 'temurin'
          java-version: '21'
      - name: Validate Gradle wrapper
        uses: gradle/actions/wrapper-validation@v4
      - name: Cache .gradle
        uses: burrunan/gradle-cache-action@v2

  build:
    runs-on: ubuntu-latest
    needs: lint
    steps:
      - name: Checkout code
        uses: actions/checkout@v4
        with:
          submodules: true
      - name: Set up JDK
        uses: actions/setup-java@v4
        with:
          distribution: 'temurin'
          java-version: '21'
      - name: Cache .gradle
        uses: burrunan/gradle-cache-action@v2
      - name: Set up Gradle Permission
        run: chmod +x ./gradlew
      - name: Build
        run: ./gradlew -s build
```

### 1.2 현재 구성 설명

| Job | 목적 | 실행 조건 |
|-----|------|----------|
| `lint` | Gradle Wrapper 검증 및 캐싱 | main 제외 모든 브랜치 push |
| `build` | 프로젝트 빌드 및 테스트 | lint 성공 후 실행 |

---

## 2. 개선된 CI/CD Workflow

### 2.1 향상된 CI Workflow

**파일 위치**: `.github/workflows/ci.yml`

```yaml
name: CI

on:
  push:
    branches-ignore:
      - main
  pull_request:
    branches:
      - develop
      - main

env:
  JAVA_VERSION: '21'
  JAVA_DISTRIBUTION: 'temurin'

jobs:
  # Job 1: 코드 검증
  validation:
    name: Validate Code
    runs-on: ubuntu-latest
    steps:
      - name: Checkout code
        uses: actions/checkout@v4
        with:
          submodules: true
          fetch-depth: 0  # 전체 히스토리 (SonarQube 등을 위해)

      - name: Set up JDK ${{ env.JAVA_VERSION }}
        uses: actions/setup-java@v4
        with:
          distribution: ${{ env.JAVA_DISTRIBUTION }}
          java-version: ${{ env.JAVA_VERSION }}

      - name: Validate Gradle wrapper
        uses: gradle/actions/wrapper-validation@v4

      - name: Setup Gradle
        uses: gradle/actions/setup-gradle@v4

  # Job 2: 테스트 실행
  test:
    name: Run Tests
    runs-on: ubuntu-latest
    needs: validation
    steps:
      - name: Checkout code
        uses: actions/checkout@v4
        with:
          submodules: true

      - name: Set up JDK ${{ env.JAVA_VERSION }}
        uses: actions/setup-java@v4
        with:
          distribution: ${{ env.JAVA_DISTRIBUTION }}
          java-version: ${{ env.JAVA_VERSION }}

      - name: Setup Gradle
        uses: gradle/actions/setup-gradle@v4

      - name: Run tests
        run: ./gradlew test --stacktrace

      - name: Generate test report
        if: always()
        uses: dorny/test-reporter@v1
        with:
          name: Test Results
          path: '**/build/test-results/test/*.xml'
          reporter: java-junit

      - name: Upload test results
        if: failure()
        uses: actions/upload-artifact@v4
        with:
          name: test-results
          path: '**/build/test-results/test/'
          retention-days: 7

  # Job 3: 빌드
  build:
    name: Build Application
    runs-on: ubuntu-latest
    needs: test
    steps:
      - name: Checkout code
        uses: actions/checkout@v4
        with:
          submodules: true

      - name: Set up JDK ${{ env.JAVA_VERSION }}
        uses: actions/setup-java@v4
        with:
          distribution: ${{ env.JAVA_DISTRIBUTION }}
          java-version: ${{ env.JAVA_VERSION }}

      - name: Setup Gradle
        uses: gradle/actions/setup-gradle@v4

      - name: Build with Gradle
        run: ./gradlew build -x test --stacktrace

      - name: Upload build artifacts
        uses: actions/upload-artifact@v4
        with:
          name: build-artifacts
          path: build/libs/*.jar
          retention-days: 7

  # Job 4: 코드 품질 검사
  code-quality:
    name: Code Quality Analysis
    runs-on: ubuntu-latest
    needs: validation
    steps:
      - name: Checkout code
        uses: actions/checkout@v4
        with:
          submodules: true
          fetch-depth: 0

      - name: Set up JDK ${{ env.JAVA_VERSION }}
        uses: actions/setup-java@v4
        with:
          distribution: ${{ env.JAVA_DISTRIBUTION }}
          java-version: ${{ env.JAVA_VERSION }}

      - name: Setup Gradle
        uses: gradle/actions/setup-gradle@v4

      - name: Run Checkstyle
        run: ./gradlew checkstyleMain checkstyleTest --stacktrace
        continue-on-error: true

      - name: Run PMD
        run: ./gradlew pmdMain pmdTest --stacktrace
        continue-on-error: true

      - name: Run SpotBugs
        run: ./gradlew spotbugsMain spotbugsTest --stacktrace
        continue-on-error: true

  # Job 5: 보안 스캔
  security:
    name: Security Scan
    runs-on: ubuntu-latest
    needs: validation
    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Run Trivy vulnerability scanner
        uses: aquasecurity/trivy-action@master
        with:
          scan-type: 'fs'
          scan-ref: '.'
          format: 'sarif'
          output: 'trivy-results.sarif'

      - name: Upload Trivy results to GitHub Security
        uses: github/codeql-action/upload-sarif@v3
        if: always()
        with:
          sarif_file: 'trivy-results.sarif'

      - name: Dependency Check
        run: ./gradlew dependencyCheckAnalyze --stacktrace
        continue-on-error: true
```

### 2.2 CD Workflow (배포)

**파일 위치**: `.github/workflows/cd.yml`

```yaml
name: CD

on:
  push:
    branches:
      - main
    tags:
      - 'v*.*.*'

env:
  JAVA_VERSION: '21'
  JAVA_DISTRIBUTION: 'temurin'
  REGISTRY: ghcr.io
  IMAGE_NAME: ${{ github.repository }}

jobs:
  # Job 1: 빌드 및 테스트
  build-and-test:
    name: Build and Test
    runs-on: ubuntu-latest
    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Set up JDK ${{ env.JAVA_VERSION }}
        uses: actions/setup-java@v4
        with:
          distribution: ${{ env.JAVA_DISTRIBUTION }}
          java-version: ${{ env.JAVA_VERSION }}

      - name: Setup Gradle
        uses: gradle/actions/setup-gradle@v4

      - name: Build and Test
        run: ./gradlew clean build --stacktrace

      - name: Upload JAR
        uses: actions/upload-artifact@v4
        with:
          name: application-jar
          path: build/libs/*.jar

  # Job 2: Docker 이미지 빌드 및 푸시
  docker-build-push:
    name: Build and Push Docker Image
    runs-on: ubuntu-latest
    needs: build-and-test
    permissions:
      contents: read
      packages: write
    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Set up Docker Buildx
        uses: docker/setup-buildx-action@v3

      - name: Log in to Container Registry
        uses: docker/login-action@v3
        with:
          registry: ${{ env.REGISTRY }}
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}

      - name: Extract metadata
        id: meta
        uses: docker/metadata-action@v5
        with:
          images: ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}
          tags: |
            type=ref,event=branch
            type=semver,pattern={{version}}
            type=semver,pattern={{major}}.{{minor}}
            type=sha

      - name: Build and push Docker image
        uses: docker/build-push-action@v5
        with:
          context: .
          push: true
          tags: ${{ steps.meta.outputs.tags }}
          labels: ${{ steps.meta.outputs.labels }}
          cache-from: type=gha
          cache-to: type=gha,mode=max

  # Job 3: 배포
  deploy:
    name: Deploy to Production
    runs-on: ubuntu-latest
    needs: docker-build-push
    if: startsWith(github.ref, 'refs/tags/v')
    environment:
      name: production
      url: https://api.rallypoint.com
    steps:
      - name: Deploy to Kubernetes
        run: |
          echo "Deploying to production..."
          # kubectl apply -f k8s/deployment.yml

      - name: Notify deployment
        uses: 8398a7/action-slack@v3
        with:
          status: ${{ job.status }}
          text: 'Deployment completed!'
          webhook_url: ${{ secrets.SLACK_WEBHOOK }}
        if: always()
```

### 2.3 Release Workflow

**파일 위치**: `.github/workflows/release.yml`

```yaml
name: Release

on:
  push:
    tags:
      - 'v*.*.*'

permissions:
  contents: write

jobs:
  create-release:
    name: Create Release
    runs-on: ubuntu-latest
    steps:
      - name: Checkout code
        uses: actions/checkout@v4
        with:
          fetch-depth: 0

      - name: Generate changelog
        id: changelog
        uses: metcalfc/changelog-generator@v4.3.1
        with:
          myToken: ${{ secrets.GITHUB_TOKEN }}

      - name: Create Release
        uses: softprops/action-gh-release@v1
        with:
          body: |
            ## Changes in this release
            ${{ steps.changelog.outputs.changelog }}

            ## Installation
            ```bash
            docker pull ghcr.io/${{ github.repository }}:${{ github.ref_name }}
            ```
          files: |
            build/libs/*.jar
          draft: false
          prerelease: false
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

---

## 3. Workflow 트리거 규칙

### 3.1 CI Workflow 트리거

```yaml
on:
  push:
    branches-ignore:
      - main
  pull_request:
    branches:
      - develop
      - main
```

| 이벤트 | 조건 | 실행 |
|--------|------|------|
| Push | feature/*, hotfix/* 브랜치 | ✅ |
| Push | main 브랜치 | ❌ (CD로 처리) |
| Pull Request | develop, main 대상 | ✅ |

### 3.2 CD Workflow 트리거

```yaml
on:
  push:
    branches:
      - main
    tags:
      - 'v*.*.*'
```

| 이벤트 | 조건 | 실행 |
|--------|------|------|
| Push | main 브랜치 | ✅ |
| Tag | v1.0.0 형식 | ✅ |

---

## 4. GitHub Actions Secrets 설정

### 4.1 필수 Secrets

프로젝트 Settings → Secrets and variables → Actions에서 설정:

| Secret 이름 | 설명 | 예시 |
|-------------|------|------|
| `DOCKER_USERNAME` | Docker Hub 사용자명 | `myusername` |
| `DOCKER_PASSWORD` | Docker Hub 비밀번호 | `****` |
| `SLACK_WEBHOOK` | Slack Webhook URL | `https://hooks.slack.com/...` |
| `SONAR_TOKEN` | SonarQube 토큰 | `sqp_****` |
| `AWS_ACCESS_KEY_ID` | AWS 액세스 키 | `AKIA****` |
| `AWS_SECRET_ACCESS_KEY` | AWS 시크릿 키 | `****` |
| `K8S_CONFIG` | Kubernetes 설정 | Base64 인코딩된 kubeconfig |

### 4.2 Environment Variables

프로젝트 루트에 `.env.example` 파일 생성:

```bash
# Database
DB_URL=jdbc:mysql://localhost:3304/rallypoint
DB_USERNAME=your_username
DB_PASSWORD=your_password

# JWT
JWT_SECRET_KEY=your-secret-key
JWT_EXPIRE_TIME=86400000

# OAuth2
KAKAO_CLIENT_ID=your_client_id
KAKAO_CLIENT_SECRET=your_client_secret

# Redis
REDIS_HOST=localhost
REDIS_PORT=6379

# AWS S3
AWS_S3_BUCKET=rallypoint-uploads
AWS_REGION=ap-northeast-2
```

---

## 5. 고급 Workflow 패턴

### 5.1 Matrix 빌드 (다중 버전 테스트)

```yaml
jobs:
  test:
    strategy:
      matrix:
        java-version: [17, 21]
        os: [ubuntu-latest, windows-latest, macos-latest]
    runs-on: ${{ matrix.os }}
    steps:
      - uses: actions/checkout@v4
      - name: Set up JDK ${{ matrix.java-version }}
        uses: actions/setup-java@v4
        with:
          java-version: ${{ matrix.java-version }}
      - run: ./gradlew test
```

### 5.2 Conditional Jobs

```yaml
jobs:
  deploy:
    if: github.ref == 'refs/heads/main' && github.event_name == 'push'
    runs-on: ubuntu-latest
    steps:
      - name: Deploy
        run: echo "Deploying..."
```

### 5.3 Manual Workflow (workflow_dispatch)

```yaml
name: Manual Deploy

on:
  workflow_dispatch:
    inputs:
      environment:
        description: 'Environment to deploy'
        required: true
        type: choice
        options:
          - dev
          - staging
          - production
      version:
        description: 'Version to deploy'
        required: true
        type: string

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - name: Deploy ${{ inputs.version }} to ${{ inputs.environment }}
        run: |
          echo "Deploying version ${{ inputs.version }} to ${{ inputs.environment }}"
```

---

## 6. 캐싱 전략

### 6.1 Gradle 캐싱

```yaml
- name: Setup Gradle
  uses: gradle/actions/setup-gradle@v4
  with:
    cache-read-only: ${{ github.ref != 'refs/heads/main' }}
```

### 6.2 Docker Layer 캐싱

```yaml
- name: Build Docker image
  uses: docker/build-push-action@v5
  with:
    cache-from: type=gha
    cache-to: type=gha,mode=max
```

### 6.3 의존성 캐싱

```yaml
- name: Cache Gradle packages
  uses: actions/cache@v4
  with:
    path: |
      ~/.gradle/caches
      ~/.gradle/wrapper
    key: ${{ runner.os }}-gradle-${{ hashFiles('**/*.gradle*', '**/gradle-wrapper.properties') }}
    restore-keys: |
      ${{ runner.os }}-gradle-
```

---

## 7. 알림 및 리포팅

### 7.1 Slack 알림

```yaml
- name: Notify Slack
  uses: 8398a7/action-slack@v3
  with:
    status: ${{ job.status }}
    fields: repo,message,commit,author,action,eventName,ref,workflow
    webhook_url: ${{ secrets.SLACK_WEBHOOK }}
  if: always()
```

### 7.2 테스트 리포트

```yaml
- name: Publish Test Report
  uses: dorny/test-reporter@v1
  if: always()
  with:
    name: Test Results
    path: '**/build/test-results/test/*.xml'
    reporter: java-junit
    fail-on-error: true
```

### 7.3 코드 커버리지

```yaml
- name: Generate Jacoco Report
  run: ./gradlew jacocoTestReport

- name: Upload coverage to Codecov
  uses: codecov/codecov-action@v4
  with:
    files: ./build/reports/jacoco/test/jacocoTestReport.xml
    flags: unittests
    name: codecov-umbrella
```

---

## 8. 보안 Best Practices

### 8.1 Secrets 사용

```yaml
# ❌ Bad: 평문으로 비밀번호 노출
env:
  DB_PASSWORD: "mypassword"

# ✅ Good: Secrets 사용
env:
  DB_PASSWORD: ${{ secrets.DB_PASSWORD }}
```

### 8.2 권한 최소화

```yaml
permissions:
  contents: read        # 코드 읽기만 허용
  packages: write       # 패키지 쓰기 허용
  pull-requests: write  # PR 업데이트 허용
```

### 8.3 의존성 보안 스캔

```yaml
- name: Run Snyk Security Scan
  uses: snyk/actions/gradle@master
  env:
    SNYK_TOKEN: ${{ secrets.SNYK_TOKEN }}
```

---

## 9. 디버깅 및 트러블슈팅

### 9.1 로그 레벨 증가

```yaml
- name: Run tests with debug
  run: ./gradlew test --debug --stacktrace
```

### 9.2 SSH를 통한 디버깅

```yaml
- name: Setup tmate session
  uses: mxschmitt/action-tmate@v3
  if: ${{ failure() }}
```

### 9.3 Artifact 업로드

```yaml
- name: Upload logs
  uses: actions/upload-artifact@v4
  if: failure()
  with:
    name: logs
    path: build/logs/
    retention-days: 7
```

---

## 10. 성능 최적화

### 10.1 Job 병렬 실행

```yaml
jobs:
  test:
    # ...
  lint:
    # ...
  security:
    # ...
# 위 3개 job은 병렬 실행됨
```

### 10.2 조건부 실행

```yaml
- name: Run integration tests
  if: contains(github.event.head_commit.message, '[integration]')
  run: ./gradlew integrationTest
```

### 10.3 Build 최적화

```yaml
- name: Build
  run: |
    ./gradlew build \
      --build-cache \
      --parallel \
      --max-workers=4 \
      -x test
```

---

## 11. Workflow 예시 모음

### 11.1 PR Auto Labeler

**파일 위치**: `.github/workflows/labeler.yml`

```yaml
name: Labeler
on:
  pull_request:
    types: [opened, synchronize]

jobs:
  label:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/labeler@v5
        with:
          repo-token: ${{ secrets.GITHUB_TOKEN }}
```

**설정 파일**: `.github/labeler.yml`

```yaml
'feature':
  - 'src/**/*.java'

'test':
  - 'src/test/**'

'documentation':
  - '**/*.md'

'dependencies':
  - 'build.gradle.kts'
  - 'gradle.properties'
```

### 11.2 Dependency Update Bot

**파일 위치**: `.github/dependabot.yml`

```yaml
version: 2
updates:
  - package-ecosystem: "gradle"
    directory: "/"
    schedule:
      interval: "weekly"
    reviewers:
      - "your-username"
    labels:
      - "dependencies"
      - "java"

  - package-ecosystem: "github-actions"
    directory: "/"
    schedule:
      interval: "weekly"
    reviewers:
      - "your-username"
    labels:
      - "dependencies"
      - "ci"
```

---

**작성일**: 2025-10-29
**작성자**: Claude Code
**상태**: 초안 (v1.0)
