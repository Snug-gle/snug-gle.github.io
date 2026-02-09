---
tags:
  - project
  - rally-point
  - git
  - issue-tracking
  - versioning
  - tag-management
category: project
status: in-progress
created: 2025-10-29
updated: 2025-10-29
---

# RallyPoint User Service - Issue & Tag 관리 가이드

## 1. GitHub Issue 관리 전략

### 1.1 Issue 생성 원칙

모든 작업은 **반드시 Issue를 먼저 생성**한 후 진행합니다.

#### Issue 생성 시점

- ✅ 새로운 기능 개발 전
- ✅ 버그 발견 시
- ✅ 리팩토링 계획 시
- ✅ 문서 작성/업데이트 전
- ✅ 성능 개선 작업 전

#### Issue 작성 규칙

```
Title: [{Type}] {간결한 설명}

Type:
- Feature: 새 기능
- Bug: 버그
- Refactor: 리팩토링
- Docs: 문서
- Perf: 성능 개선
- Test: 테스트

예시:
- [Feature] 이메일 인증 기능 추가
- [Bug] JWT 토큰 만료 시간 오류
- [Refactor] UserService 레이어 분리
```

---

## 2. Issue 템플릿

### 2.1 Feature Request 템플릿

**파일 위치**: `.github/ISSUE_TEMPLATE/feature_request.md`

```markdown
---
name: Feature Request
about: 새로운 기능 제안
title: '[Feature] '
labels: 'enhancement'
assignees: ''
---

## 📋 기능 설명
<!-- 이 기능이 필요한 이유와 기대 효과를 설명해주세요 -->

## 💡 제안 내용
<!-- 구현하고자 하는 기능을 구체적으로 설명해주세요 -->

## ✅ 작업 내용
<!-- 체크리스트 형태로 작성 -->
- [ ] Task 1
- [ ] Task 2
- [ ] Task 3
- [ ] 테스트 코드 작성
- [ ] 문서 업데이트

## 🛠 기술 스택
<!-- 사용할 기술이나 라이브러리를 명시 -->
- Spring Boot Mail
- Redis
- 등등...

## 📚 참고 자료
<!-- 관련 문서나 레퍼런스 첨부 -->
- [Link 1](URL)
- [Link 2](URL)

## 📅 예상 소요 기간
<!-- 예: 3일, 1주일 등 -->

## 우선순위
<!-- High / Medium / Low -->
- [ ] High
- [ ] Medium
- [ ] Low
```

### 2.2 Bug Report 템플릿

**파일 위치**: `.github/ISSUE_TEMPLATE/bug_report.md`

```markdown
---
name: Bug Report
about: 버그 리포트
title: '[Bug] '
labels: 'bug'
assignees: ''
---

## 🐛 버그 설명
<!-- 발생한 버그를 간단히 설명 -->

## 🔄 재현 방법
<!-- 버그를 재현하는 단계를 상세히 작성 -->
1. '...' 로 이동
2. '...' 클릭
3. '...' 입력
4. 에러 발생

## 🎯 예상 동작
<!-- 정상적으로 동작해야 하는 방식 -->

## 💥 실제 동작
<!-- 실제로 어떻게 동작하는지 -->

## 🖼 스크린샷
<!-- 필요한 경우 스크린샷 첨부 -->

## 🌐 환경
- OS: [e.g. macOS 14.0]
- Java Version: [e.g. 21]
- Spring Boot Version: [e.g. 3.3.3]
- Browser: [e.g. Chrome 120]

## 📝 에러 로그
```
에러 로그나 스택 트레이스를 여기에 붙여넣기
```

## 🔍 추가 정보
<!-- 기타 도움이 될 만한 정보 -->

## 심각도
- [ ] Critical (서비스 중단)
- [ ] High (주요 기능 불가)
- [ ] Medium (일부 기능 제한)
- [ ] Low (사소한 문제)
```

### 2.3 Refactoring 템플릿

**파일 위치**: `.github/ISSUE_TEMPLATE/refactoring.md`

```markdown
---
name: Refactoring
about: 코드 리팩토링
title: '[Refactor] '
labels: 'refactoring'
assignees: ''
---

## 🎯 리팩토링 목적
<!-- 왜 이 리팩토링이 필요한지 -->

## 📍 대상 코드
<!-- 리팩토링할 파일/클래스/메서드 -->
- `src/main/java/com/example/UserService.java`
- `UserController.java` 의 `createUser()` 메서드

## 🔨 개선 방안
<!-- 어떻게 개선할 것인지 -->
1. 방법 1
2. 방법 2

## ✅ 작업 내용
- [ ] 코드 분석
- [ ] 리팩토링 적용
- [ ] 테스트 검증
- [ ] 성능 비교

## 📊 기대 효과
<!-- 리팩토링 후 기대되는 개선 사항 -->
- 가독성 향상
- 성능 개선 (예: 30% 감소)
- 유지보수성 향상

## ⚠️ 주의사항
<!-- 리팩토링 시 주의할 점 -->
```

---

## 3. Issue Labels 체계

### 3.1 카테고리별 Label

#### Type Labels (작업 유형)

| Label | 색상 | 설명 |
|-------|------|------|
| `enhancement` | `#84b6eb` | 새로운 기능 |
| `bug` | `#d73a4a` | 버그 |
| `refactoring` | `#fbca04` | 리팩토링 |
| `documentation` | `#0075ca` | 문서 |
| `performance` | `#d4c5f9` | 성능 개선 |
| `test` | `#c5def5` | 테스트 |
| `security` | `#ee0701` | 보안 |
| `dependencies` | `#0366d6` | 의존성 업데이트 |

#### Priority Labels (우선순위)

| Label | 색상 | 설명 |
|-------|------|------|
| `priority: critical` | `#b60205` | 즉시 처리 필요 |
| `priority: high` | `#d93f0b` | 높은 우선순위 |
| `priority: medium` | `#fbca04` | 보통 우선순위 |
| `priority: low` | `#0e8a16` | 낮은 우선순위 |

#### Status Labels (상태)

| Label | 색상 | 설명 |
|-------|------|------|
| `status: in-progress` | `#fef2c0` | 작업 중 |
| `status: blocked` | `#d73a4a` | 블로킹됨 |
| `status: review` | `#a2eeef` | 리뷰 중 |
| `status: on-hold` | `#ffffff` | 보류 중 |

#### Component Labels (컴포넌트)

| Label | 색상 | 설명 |
|-------|------|------|
| `component: auth` | `#c2e0c6` | 인증 관련 |
| `component: api` | `#bfdadc` | API 관련 |
| `component: database` | `#d4c5f9` | 데이터베이스 |
| `component: security` | `#ee0701` | 보안 |

#### Effort Labels (작업량)

| Label | 색상 | 설명 |
|-------|------|------|
| `effort: small` | `#c5def5` | < 1일 |
| `effort: medium` | `#bfdadc` | 1-3일 |
| `effort: large` | `#d4c5f9` | > 3일 |

#### Additional Labels

| Label | 색상 | 설명 |
|-------|------|------|
| `good first issue` | `#7057ff` | 초보자 적합 |
| `help wanted` | `#008672` | 도움 필요 |
| `question` | `#d876e3` | 질문 |
| `duplicate` | `#cfd3d7` | 중복 |
| `wontfix` | `#ffffff` | 수정 안 함 |

### 3.2 Label 사용 예시

```
Issue #5: [Feature] 이메일 인증 기능 추가

Labels:
- enhancement
- priority: high
- component: auth
- effort: medium
- milestone: v1.1.0
```

---

## 4. Milestone 관리

### 4.1 Milestone 생성 규칙

```
Title: v{major}.{minor}.{patch}
Due Date: YYYY-MM-DD
Description: 이번 릴리스의 주요 내용
```

#### 예시

```
Title: v1.1.0
Due Date: 2025-12-31

Description:
이메일 인증 및 프로필 확장 기능 릴리스

주요 기능:
- 이메일 인증 프로세스
- 프로필 확장 (경력, 레벨, 프로필 사진)
- 친구 시스템 기본 기능
- 성능 개선

목표:
- 사용자 활동 30% 증가
- 회원가입 전환율 20% 개선
```

### 4.2 Milestone과 Issue 연결

```bash
# GitHub CLI 사용
gh issue create \
  --title "[Feature] 이메일 인증" \
  --label "enhancement,priority:high" \
  --milestone "v1.1.0"
```

---

## 5. Git Tag 관리

### 5.1 Semantic Versioning (SemVer)

RallyPoint는 **Semantic Versioning 2.0.0**을 따릅니다.

```
v{MAJOR}.{MINOR}.{PATCH}

MAJOR: 하위 호환성이 깨지는 변경
MINOR: 하위 호환성을 유지하는 기능 추가
PATCH: 하위 호환성을 유지하는 버그 수정
```

#### 버전 증가 규칙

| 변경 유형 | 버전 증가 | 예시 |
|----------|----------|------|
| 새로운 기능 추가 | MINOR | v1.0.0 → v1.1.0 |
| 버그 수정 | PATCH | v1.1.0 → v1.1.1 |
| API 변경 (Breaking) | MAJOR | v1.1.1 → v2.0.0 |
| 보안 패치 | PATCH | v1.1.1 → v1.1.2 |

### 5.2 Tag 생성 가이드

#### 주석 태그 생성 (권장)

```bash
git tag -a v1.1.0 -m "Release v1.1.0

주요 변경사항:
- 이메일 인증 기능 추가 (#5)
- 프로필 확장 기능 (#6, #7)
- 친구 시스템 기본 기능 (#8)
- JWT 토큰 만료 버그 수정 (#23)

성능 개선:
- 사용자 조회 쿼리 최적화
- Redis 캐싱 적용

Breaking Changes:
- 없음

Contributors:
- @sanghoon
"

# 원격에 푸시
git push origin v1.1.0
```

#### 간단한 태그 생성

```bash
# 간단한 태그 (비권장)
git tag v1.1.0
git push origin v1.1.0
```

### 5.3 Pre-release Tag

베타, RC(Release Candidate) 버전:

```bash
# 베타 버전
git tag -a v1.1.0-beta.1 -m "Beta 1 for v1.1.0"

# Release Candidate
git tag -a v1.1.0-rc.1 -m "Release Candidate 1 for v1.1.0"

# 알파 버전
git tag -a v1.1.0-alpha.1 -m "Alpha 1 for v1.1.0"
```

### 5.4 Tag 조회

```bash
# 모든 태그 조회
git tag

# 패턴 검색
git tag -l "v1.*"

# 태그 상세 정보
git show v1.1.0

# 태그와 커밋 히스토리
git log --oneline --decorate --graph
```

### 5.5 Tag 삭제

```bash
# 로컬 태그 삭제
git tag -d v1.1.0

# 원격 태그 삭제
git push origin --delete v1.1.0

# 또는
git push origin :refs/tags/v1.1.0
```

### 5.6 Tag Checkout

```bash
# 특정 태그로 체크아웃
git checkout v1.1.0

# 태그로부터 브랜치 생성
git checkout -b hotfix-1.1.1 v1.1.0
```

---

## 6. Release Notes 작성

### 6.1 Release Notes 템플릿

```markdown
# Release v1.1.0

**Release Date**: 2025-12-31

## 🎉 새로운 기능

- **이메일 인증**: 회원가입 시 이메일 인증 프로세스 추가 (#5)
- **프로필 확장**: 테니스 경력, NTRP 레벨, 프로필 사진 지원 (#6, #7)
- **친구 시스템**: 친구 추가/삭제 기능 추가 (#8)

## 🐛 버그 수정

- JWT 토큰 만료 시간 계산 오류 수정 (#23)
- 프로필 업데이트 시 트랜잭션 오류 수정 (#24)

## 🚀 성능 개선

- 사용자 조회 쿼리 최적화 (응답 시간 40% 감소)
- Redis 캐싱 적용 (DB 부하 50% 감소)

## 🔧 리팩토링

- UserService 레이어 분리 및 재구성 (#15)
- 예외 처리 구조 개선 (#16)

## 📚 문서

- API 문서 업데이트
- 개발 가이드 추가

## ⚠️ Breaking Changes

없음

## 🔗 의존성 업데이트

- Spring Boot 3.3.3 → 3.3.5
- JWT 라이브러리 0.12.5 → 0.12.6

## 📦 설치 방법

### Docker

```bash
docker pull ghcr.io/your-org/rallypoint-user-service:v1.1.0
docker run -p 9090:9090 ghcr.io/your-org/rallypoint-user-service:v1.1.0
```

### JAR 파일

```bash
java -jar rallypoint-user-service-1.1.0.jar
```

## 🙏 기여자

- @sanghoon
- @contributor1
- @contributor2

## 📝 전체 변경 사항

전체 변경사항은 [CHANGELOG.md](CHANGELOG.md)를 참고하세요.

**Full Changelog**: https://github.com/org/repo/compare/v1.0.0...v1.1.0
```

### 6.2 GitHub Release 생성

```bash
# GitHub CLI 사용
gh release create v1.1.0 \
  --title "Release v1.1.0" \
  --notes-file release-notes.md \
  build/libs/rallypoint-user-service-1.1.0.jar
```

---

## 7. CHANGELOG 관리

### 7.1 CHANGELOG.md 형식

**파일 위치**: `CHANGELOG.md`

```markdown
# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- 2단계 인증 (2FA) 기능 개발 중

### Changed

### Deprecated

### Removed

### Fixed

### Security

## [1.1.0] - 2025-12-31

### Added
- 이메일 인증 프로세스 (#5)
- 프로필 확장 (경력, 레벨) (#6)
- 프로필 사진 업로드 (#7)
- 친구 시스템 (#8)

### Changed
- UserService 레이어 구조 개선 (#15)

### Fixed
- JWT 토큰 만료 버그 수정 (#23)

### Performance
- 사용자 조회 쿼리 최적화
- Redis 캐싱 적용

## [1.0.1] - 2025-11-15

### Fixed
- 회원가입 시 이메일 중복 체크 오류 (#10)

### Security
- SQL Injection 취약점 수정 (#11)

## [1.0.0] - 2025-10-01

### Added
- 회원가입 기능
- JWT 기반 인증
- OAuth2 소셜 로그인 (Kakao)
- 기본 프로필 관리

[Unreleased]: https://github.com/org/repo/compare/v1.1.0...HEAD
[1.1.0]: https://github.com/org/repo/compare/v1.0.1...v1.1.0
[1.0.1]: https://github.com/org/repo/compare/v1.0.0...v1.0.1
[1.0.0]: https://github.com/org/repo/releases/tag/v1.0.0
```

### 7.2 자동 CHANGELOG 생성

```bash
# conventional-changelog 사용
npm install -g conventional-changelog-cli

# CHANGELOG 자동 생성
conventional-changelog -p angular -i CHANGELOG.md -s

# 또는 GitHub CLI
gh api repos/{owner}/{repo}/releases/generate-notes \
  -f tag_name=v1.1.0 \
  -f target_commitish=main \
  -f previous_tag_name=v1.0.0
```

---

## 8. Issue 및 Tag 자동화

### 8.1 Issue 자동 닫기

커밋 메시지에 키워드 포함:

```bash
git commit -m "[#5] feat: 이메일 인증 기능 완료

Closes #5"

# 여러 Issue 닫기
git commit -m "Fix multiple bugs

Closes #23
Closes #24
Closes #25"
```

키워드:
- `Closes #123`
- `Fixes #123`
- `Resolves #123`

### 8.2 자동 Tag 생성

**파일 위치**: `.github/workflows/auto-tag.yml`

```yaml
name: Auto Tag

on:
  push:
    branches:
      - main

jobs:
  tag:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0

      - name: Bump version and push tag
        uses: anothrNick/github-tag-action@v1
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
          WITH_V: true
          DEFAULT_BUMP: patch
```

---

## 9. 프로젝트 보드 활용

### 9.1 GitHub Projects 설정

```
Board: RallyPoint User Service v1.1.0

Columns:
- 📋 Backlog
- 🔜 To Do
- 🚧 In Progress
- 👀 In Review
- ✅ Done

Automation:
- Issue 생성 시 → Backlog
- 브랜치 생성 시 → In Progress
- PR 생성 시 → In Review
- PR 머지 시 → Done
```

### 9.2 이슈 템플릿에 프로젝트 자동 추가

```markdown
---
name: Feature Request
about: 새로운 기능 제안
title: '[Feature] '
labels: 'enhancement'
assignees: ''
projects: ['RallyPoint User Service']
---
```

---

## 10. Best Practices

### 10.1 Issue 작성 시

✅ **DO**
- 명확하고 구체적인 제목
- 재현 가능한 단계 제공
- 스크린샷/로그 첨부
- 관련 Label 및 Milestone 지정
- 작업량 추정

❌ **DON'T**
- 모호한 제목 ("버그 수정")
- 여러 기능을 하나의 Issue에
- 중복 Issue 생성
- Label 누락

### 10.2 Tag 관리 시

✅ **DO**
- 주석 태그 사용
- 의미 있는 태그 메시지
- Semantic Versioning 준수
- CHANGELOG 업데이트

❌ **DON'T**
- 임의로 태그 삭제
- 이미 배포된 태그 수정
- 태그 메시지 생략

### 10.3 Release 시

✅ **DO**
- Release Notes 작성
- Breaking Changes 명시
- Migration Guide 제공
- 배포 전 충분한 테스트

❌ **DON'T**
- 테스트 없이 배포
- Breaking Changes 숨기기
- 문서 업데이트 누락

---

**작성일**: 2025-10-29
**작성자**: Claude Code
**상태**: 초안 (v1.0)
