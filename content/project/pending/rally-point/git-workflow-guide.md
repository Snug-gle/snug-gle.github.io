---
tags:
  - project
  - rally-point
  - git
  - git-flow
  - workflow
  - best-practices
category: project
status: in-progress
created: 2025-10-29
modified: 2025-10-29
---
# RallyPoint User Service - Git Workflow 가이드

## 1. Git Flow 전략 개요

RallyPoint 프로젝트는 **Git Flow** 전략을 따릅니다.

### 1.1 브랜치 구조

```
main (프로덕션)
  │
  ├── develop (개발 통합)
  │     │
  │     ├── feature/issue-1 (기능 개발)
  │     ├── feature/issue-2
  │     └── feature/issue-3
  │
  ├── release/v1.0.0 (릴리스 준비)
  │
  └── hotfix/critical-bug (긴급 수정)
```

### 1.2 브랜치 설명

| 브랜치 | 용도 | 생명주기 | 보호 |
|--------|------|---------|------|
| `main` | 프로덕션 배포 브랜치 | 영구 | ✅ |
| `develop` | 개발 통합 브랜치 | 영구 | ✅ |
| `feature/*` | 새 기능 개발 | 임시 | ❌ |
| `release/*` | 릴리스 준비 | 임시 | ✅ |
| `hotfix/*` | 긴급 버그 수정 | 임시 | ❌ |

---

## 2. 브랜치 명명 규칙

### 2.1 Feature 브랜치

```bash
feature/issue-{이슈번호}
feature/issue-{이슈번호}-{간단한-설명}

# 예시
feature/issue-1
feature/issue-5-add-email-verification
feature/issue-12-oauth-google
```

### 2.2 Release 브랜치

```bash
release/v{major}.{minor}.{patch}

# 예시
release/v1.0.0
release/v1.1.0
release/v2.0.0
```

### 2.3 Hotfix 브랜치

```bash
hotfix/{이슈번호}-{간단한-설명}
hotfix/v{버전}-{간단한-설명}

# 예시
hotfix/23-jwt-token-expiration
hotfix/v1.0.1-security-patch
```

---

## 3. Git Flow 워크플로우

### 3.1 신규 기능 개발

#### Step 1: Issue 생성

GitHub Issues에서 작업할 이슈를 생성합니다.

```
Title: [Feature] 이메일 인증 기능 추가
Labels: enhancement, user-service
Milestone: v1.1.0

Description:
## 목적
회원가입 시 이메일 인증 프로세스 추가

## 작업 내용
- [ ] 이메일 인증 토큰 생성
- [ ] 인증 메일 발송 API
- [ ] 인증 확인 API
- [ ] 테스트 코드 작성

## 기술 스택
- Spring Boot Mail
- Redis (토큰 저장)
```

#### Step 2: Feature 브랜치 생성

```bash
# develop 브랜치에서 최신 코드 pull
git checkout develop
git pull origin develop

# feature 브랜치 생성 및 이동
git checkout -b feature/issue-5-email-verification

# 또는 한 번에
git checkout -b feature/issue-5-email-verification develop
```

#### Step 3: 개발 진행

```bash
# 코드 작성
# ...

# 변경사항 스테이징
git add .

# 커밋 (커밋 메시지 규칙 준수)
git commit -m "[#5] feat: 이메일 인증 토큰 생성 기능 추가"

# 원격 브랜치에 푸시
git push -u origin feature/issue-5-email-verification
```

#### Step 4: Pull Request 생성

GitHub에서 Pull Request 생성:

```
Title: [#5] 이메일 인증 기능 추가

Description:
## 변경 사항
- 이메일 인증 토큰 생성 로직 추가
- 인증 메일 발송 기능 구현
- 인증 확인 API 엔드포인트 추가

## 테스트
- [x] 단위 테스트 작성 완료
- [x] 통합 테스트 작성 완료
- [x] 로컬 환경에서 동작 확인

## 관련 이슈
Closes #5

## 스크린샷
(필요한 경우 추가)

## 체크리스트
- [x] 코드 리뷰 준비 완료
- [x] 테스트 통과
- [x] CI 통과
- [x] 문서 업데이트
```

Base: `develop` ← Compare: `feature/issue-5-email-verification`

#### Step 5: 코드 리뷰 및 머지

1. CI/CD 자동 실행 확인 (lint, test, build)
2. 최소 1명 이상의 승인 필요
3. 리뷰 피드백 반영
4. Squash and Merge 또는 Merge Commit

```bash
# 머지 후 로컬 브랜치 정리
git checkout develop
git pull origin develop
git branch -d feature/issue-5-email-verification

# 원격 브랜치 삭제 (자동 삭제되지 않은 경우)
git push origin --delete feature/issue-5-email-verification
```

### 3.2 릴리스 준비

#### Step 1: Release 브랜치 생성

```bash
# develop에서 최신 코드 pull
git checkout develop
git pull origin develop

# release 브랜치 생성
git checkout -b release/v1.1.0
```

#### Step 2: 버전 정보 업데이트

```bash
# build.gradle.kts 버전 업데이트
# version = "1.1.0"

git add build.gradle.kts
git commit -m "chore: bump version to 1.1.0"

# 원격에 푸시
git push -u origin release/v1.1.0
```

#### Step 3: 릴리스 테스트 및 버그 수정

```bash
# 버그 발견 시 수정
git commit -m "fix: 릴리스 테스트 중 발견된 버그 수정"
git push origin release/v1.1.0
```

#### Step 4: main과 develop에 머지

```bash
# main에 머지
git checkout main
git pull origin main
git merge --no-ff release/v1.1.0
git push origin main

# develop에도 머지 (릴리스 중 수정사항 반영)
git checkout develop
git pull origin develop
git merge --no-ff release/v1.1.0
git push origin develop

# release 브랜치 삭제
git branch -d release/v1.1.0
git push origin --delete release/v1.1.0
```

#### Step 5: Tag 생성

```bash
# main 브랜치에서 태그 생성
git checkout main
git pull origin main

# 주석 태그 생성
git tag -a v1.1.0 -m "Release version 1.1.0

- 이메일 인증 기능 추가
- 프로필 확장 (경력, 레벨)
- 친구 시스템 기본 기능
- 성능 개선 및 버그 수정"

# 태그 푸시
git push origin v1.1.0

# 모든 태그 푸시
git push origin --tags
```

### 3.3 Hotfix (긴급 수정)

#### Step 1: Hotfix 브랜치 생성

```bash
# main에서 hotfix 브랜치 생성
git checkout main
git pull origin main
git checkout -b hotfix/23-jwt-expiration-bug
```

#### Step 2: 버그 수정

```bash
# 버그 수정 코드 작성
git add .
git commit -m "[#23] fix: JWT 토큰 만료 시간 오류 수정"
git push -u origin hotfix/23-jwt-expiration-bug
```

#### Step 3: main과 develop에 머지

```bash
# main에 머지
git checkout main
git merge --no-ff hotfix/23-jwt-expiration-bug
git push origin main

# 패치 버전 태그 생성
git tag -a v1.1.1 -m "Hotfix v1.1.1: JWT 토큰 만료 버그 수정"
git push origin v1.1.1

# develop에도 머지
git checkout develop
git merge --no-ff hotfix/23-jwt-expiration-bug
git push origin develop

# hotfix 브랜치 삭제
git branch -d hotfix/23-jwt-expiration-bug
git push origin --delete hotfix/23-jwt-expiration-bug
```

---

## 4. 커밋 메시지 컨벤션

### 4.1 커밋 메시지 형식

```
[#{이슈번호}] {타입}: {제목}

{본문}

{푸터}
```

### 4.2 타입 (Type)

| 타입 | 설명 | 예시 |
|------|------|------|
| `feat` | 새로운 기능 추가 | `[#5] feat: 이메일 인증 기능 추가` |
| `fix` | 버그 수정 | `[#23] fix: JWT 토큰 만료 오류 수정` |
| `refactor` | 코드 리팩토링 | `[#15] refactor: UserService 메서드 분리` |
| `style` | 코드 포맷팅 | `[#8] style: Google Java Format 적용` |
| `test` | 테스트 코드 추가/수정 | `[#12] test: 회원가입 통합 테스트 추가` |
| `docs` | 문서 수정 | `[#20] docs: README 업데이트` |
| `chore` | 빌드/설정 변경 | `[#4] chore: Gradle dependency 업데이트` |
| `perf` | 성능 개선 | `[#18] perf: 사용자 조회 쿼리 최적화` |

### 4.3 커밋 메시지 예시

#### 간단한 커밋

```bash
git commit -m "[#5] feat: 이메일 인증 토큰 생성 기능 추가"
```

#### 상세한 커밋

```bash
git commit -m "[#5] feat: 이메일 인증 기능 추가

- EmailVerificationService 클래스 추가
- Redis를 활용한 인증 토큰 저장 (TTL 24시간)
- 이메일 발송 API 엔드포인트 추가

Closes #5"
```

---

## 5. Git 명령어 가이드

### 5.1 자주 사용하는 명령어

#### 브랜치 관리

```bash
# 브랜치 목록 확인
git branch                    # 로컬 브랜치
git branch -r                 # 원격 브랜치
git branch -a                 # 모든 브랜치

# 브랜치 생성 및 이동
git checkout -b feature/issue-5

# 브랜치 이동
git checkout develop

# 브랜치 삭제
git branch -d feature/issue-5           # 로컬 브랜치 삭제
git push origin --delete feature/issue-5 # 원격 브랜치 삭제

# 원격 브랜치 가져오기
git fetch origin
git checkout -b feature/issue-5 origin/feature/issue-5
```

#### 커밋 관리

```bash
# 스테이징
git add .                     # 모든 변경사항
git add src/main/java         # 특정 디렉토리
git add *.java                # 특정 확장자

# 커밋
git commit -m "메시지"
git commit --amend            # 마지막 커밋 수정

# 커밋 히스토리 확인
git log
git log --oneline
git log --graph --all --oneline
```

#### 동기화

```bash
# 원격 저장소에서 가져오기
git fetch origin              # 가져오기만
git pull origin develop       # 가져오고 병합

# 원격 저장소에 보내기
git push origin feature/issue-5
git push -u origin feature/issue-5  # 최초 푸시 시
```

#### 변경사항 확인

```bash
# 상태 확인
git status

# 변경사항 확인
git diff                      # 작업 디렉토리 vs 스테이징
git diff --staged             # 스테이징 vs 마지막 커밋
git diff develop              # 현재 브랜치 vs develop

# 특정 파일 변경사항
git diff src/main/java/User.java
```

#### 되돌리기

```bash
# 작업 디렉토리 변경사항 취소
git checkout -- {파일명}
git restore {파일명}          # Git 2.23+

# 스테이징 취소
git reset HEAD {파일명}
git restore --staged {파일명} # Git 2.23+

# 커밋 취소
git reset --soft HEAD~1       # 커밋만 취소 (변경사항 유지)
git reset --mixed HEAD~1      # 커밋 + 스테이징 취소
git reset --hard HEAD~1       # 모든 변경사항 취소 (주의!)

# 특정 커밋으로 되돌리기
git revert {커밋해시}         # 새로운 커밋 생성 (권장)
```

### 5.2 고급 명령어

#### Rebase (주의해서 사용)

```bash
# develop의 최신 변경사항을 feature 브랜치에 적용
git checkout feature/issue-5
git rebase develop

# 충돌 발생 시
git status                    # 충돌 파일 확인
# 충돌 해결 후
git add .
git rebase --continue

# rebase 취소
git rebase --abort
```

#### Cherry-pick

```bash
# 특정 커밋만 가져오기
git cherry-pick {커밋해시}

# 여러 커밋 가져오기
git cherry-pick {커밋1} {커밋2} {커밋3}
```

#### Stash (임시 저장)

```bash
# 변경사항 임시 저장
git stash
git stash save "작업 중인 내용"

# stash 목록 확인
git stash list

# stash 적용
git stash apply               # 가장 최근 stash 적용
git stash apply stash@{2}     # 특정 stash 적용

# stash 적용 및 삭제
git stash pop

# stash 삭제
git stash drop stash@{0}
git stash clear               # 모든 stash 삭제
```

#### 태그 관리

```bash
# 태그 생성
git tag v1.0.0                        # 간단한 태그
git tag -a v1.0.0 -m "Release 1.0.0"  # 주석 태그 (권장)

# 과거 커밋에 태그
git tag -a v0.9.0 {커밋해시} -m "Beta release"

# 태그 목록
git tag
git tag -l "v1.*"

# 태그 정보 확인
git show v1.0.0

# 태그 푸시
git push origin v1.0.0        # 특정 태그
git push origin --tags        # 모든 태그

# 태그 삭제
git tag -d v1.0.0             # 로컬 태그 삭제
git push origin --delete v1.0.0  # 원격 태그 삭제
```

---

## 6. Git Issue 관리

### 6.1 Issue 템플릿

#### Feature Request

```markdown
## 기능 설명
이 기능이 필요한 이유와 기대 효과를 설명해주세요.

## 제안 내용
구현하고자 하는 기능을 구체적으로 설명해주세요.

## 작업 내용
- [ ] Task 1
- [ ] Task 2
- [ ] Task 3

## 기술 스택
사용할 기술이나 라이브러리를 명시해주세요.

## 참고 자료
관련 문서나 레퍼런스를 첨부해주세요.
```

#### Bug Report

```markdown
## 버그 설명
발생한 버그를 간단히 설명해주세요.

## 재현 방법
1.
2.
3.

## 예상 동작
정상적으로 동작해야 하는 방식을 설명해주세요.

## 실제 동작
실제로 어떻게 동작하는지 설명해주세요.

## 환경
- OS:
- Java Version:
- Spring Boot Version:

## 스크린샷
(필요한 경우)

## 추가 정보
에러 로그나 스택 트레이스를 첨부해주세요.
```

### 6.2 Issue Labels

| Label | 설명 | 색상 |
|-------|------|------|
| `enhancement` | 새 기능 | 🟢 Green |
| `bug` | 버그 | 🔴 Red |
| `documentation` | 문서 관련 | 🔵 Blue |
| `performance` | 성능 개선 | 🟡 Yellow |
| `security` | 보안 관련 | 🟠 Orange |
| `refactoring` | 리팩토링 | 🟣 Purple |
| `testing` | 테스트 관련 | 🟤 Brown |
| `high priority` | 높은 우선순위 | 🔴 Red |
| `good first issue` | 초보자에게 적합 | 🟢 Green |

### 6.3 Milestone 활용

```
Milestone: v1.1.0
Due Date: 2025-12-31
Description: 이메일 인증 및 프로필 확장 기능 릴리스

Issues:
- #5 이메일 인증 기능 추가
- #6 프로필 확장 (경력, 레벨)
- #7 프로필 사진 업로드
```

---

## 7. GitHub Actions 연동

### 7.1 자동 Issue 라벨링

커밋 메시지에 따라 자동으로 Issue에 라벨 추가:

```yaml
# .github/workflows/label-issue.yml
name: Auto Label Issue
on:
  issues:
    types: [opened]

jobs:
  label:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/labeler@v4
```

### 7.2 PR 자동 머지

CI 통과 + 리뷰 승인 시 자동 머지:

```yaml
# .github/workflows/auto-merge.yml
name: Auto Merge
on:
  pull_request_review:
    types: [submitted]

jobs:
  auto-merge:
    if: github.event.review.state == 'approved'
    runs-on: ubuntu-latest
    steps:
      - uses: pascalgn/automerge-action@v0.15.6
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

---

## 8. 주의사항 및 Best Practices

### 8.1 절대 하지 말아야 할 것

❌ **main 브랜치에 직접 커밋**
```bash
git checkout main
git commit -m "직접 수정"  # 절대 금지!
```

❌ **force push (공용 브랜치)**
```bash
git push -f origin develop  # 절대 금지!
```

❌ **대용량 파일 커밋**
```bash
git add large-file.zip  # 100MB 이상 파일 금지
```

❌ **민감 정보 커밋**
```bash
# application.yml에 실제 비밀번호 커밋 금지
password: "real-password"  # 금지!

# 환경변수 사용
password: ${DB_PASSWORD}   # 권장
```

### 8.2 권장 사항

✅ **작고 의미 있는 커밋**
```bash
# Good: 한 가지 기능에 집중
git commit -m "[#5] feat: 이메일 인증 토큰 생성"
git commit -m "[#5] feat: 인증 메일 발송 기능"

# Bad: 여러 기능을 한 번에
git commit -m "[#5] feat: 이메일 인증, 프로필 수정, 버그 수정"
```

✅ **정기적인 동기화**
```bash
# 하루에 최소 1회 develop과 동기화
git checkout feature/issue-5
git pull origin develop
```

✅ **브랜치 수명 최소화**
```bash
# feature 브랜치는 1주일 이내 완료 권장
# 너무 오래 유지하면 conflict 가능성 증가
```

✅ **.gitignore 적극 활용**
```
# IDE
.idea/
*.iml

# 빌드 산출물
build/
out/

# 로그
log/
*.log

# 환경변수
.env
application-local.yml
```

---

## 9. 트러블슈팅

### 9.1 Merge Conflict 해결

```bash
# conflict 발생 시
git status  # 충돌 파일 확인

# 충돌 파일 열어서 수동 해결
# <<<<<<< HEAD
# 현재 브랜치 내용
# =======
# 머지하려는 브랜치 내용
# >>>>>>> feature/issue-5

# 충돌 해결 후
git add {충돌파일}
git commit -m "merge: resolve conflict with develop"
```

### 9.2 실수로 잘못된 브랜치에 커밋한 경우

```bash
# 현재 브랜치: develop (실수)
# 원래 브랜치: feature/issue-5

# Step 1: 커밋 해시 확인
git log --oneline -1

# Step 2: 올바른 브랜치로 이동
git checkout feature/issue-5

# Step 3: 커밋 가져오기
git cherry-pick {커밋해시}

# Step 4: develop에서 커밋 취소
git checkout develop
git reset --hard HEAD~1
```

### 9.3 원격 브랜치 동기화 문제

```bash
# 원격 브랜치가 삭제되었는데 로컬에 남아있는 경우
git fetch --prune

# 또는
git remote prune origin
```

---

**작성일**: 2025-10-29
**작성자**: Claude Code
**상태**: 초안 (v1.0)
