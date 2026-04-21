---
tags:
  - infrastructure
  - git
  - gradle
  - java
  - code-quality
  - spotless
  - pre-commit
category: resource
created: 2026-04-21
related:
  - git-workflow-guide
  - github-actions-guide
---

# 🛠 Java/Gradle 프로젝트 pre-commit hook — `.githooks/` 패턴

> `.git/hooks/`의 버전 관리 문제를 해결하고, Gradle 태스크로 팀 전체에 자동 배포하는 `.githooks/` 패턴을 정리합니다. LinkWave 백엔드에서 Spotless(Google Java Format) 연동까지 실전 적용한 경험을 담았습니다.

---

## 📌 문제: `.git/hooks/`는 버전 관리가 안 된다

Git hooks는 강력하지만 `.git/` 디렉토리에 위치하기 때문에 태생적인 한계가 있습니다.

```
.git/
└── hooks/
    ├── pre-commit      ← 버전 관리 X, 팀원에게 자동 배포 불가
    ├── commit-msg
    └── ...
```

**문제점**:
1. `.git/` 디렉토리는 `git add`로 추적할 수 없음
2. 팀원이 저장소를 클론해도 hooks가 적용되지 않음
3. 새로운 팀원이 합류할 때 수동으로 복사/설치해야 함
4. hooks가 업데이트되어도 팀원에게 자동 반영되지 않음

---

## 🔍 해결책: `.githooks/` + `git config core.hooksPath`

Git 2.9+부터 hooks 디렉토리 경로를 설정으로 변경할 수 있습니다.

```bash
git config core.hooksPath .githooks
```

이 설정 하나로 Git은 `.git/hooks/` 대신 `.githooks/`를 참조합니다. `.githooks/`는 일반 디렉토리이므로 버전 관리가 가능합니다.

```
project-root/
├── .githooks/
│   └── pre-commit      ← 버전 관리 O, git push로 팀 공유 가능
├── build.gradle.kts
└── src/
```

---

## 🛠 Gradle `installGitHooks` 태스크 구현

팀원이 `./gradlew installGitHooks`를 한 번만 실행하면 설정이 완료되도록 Gradle 태스크를 구성합니다.

### `.githooks/pre-commit`

```sh
#!/bin/sh
echo "Running spotlessCheck..."
./gradlew spotlessCheck
if [ $? -ne 0 ]; then
    echo "spotlessCheck failed. Run './gradlew spotlessApply' to auto-fix."
    exit 1
fi
```

파일 생성 후 실행 권한을 반드시 부여해야 합니다.

```bash
chmod +x .githooks/pre-commit
```

### `build.gradle.kts`

```kotlin
tasks.register("installGitHooks") {
    group = "git hooks"
    description = "Install git hooks by setting core.hooksPath to .githooks"

    doLast {
        // Gradle Kotlin DSL의 doLast 블록에서는 exec {} DSL을 사용할 수 없음
        // → ProcessBuilder로 직접 프로세스 실행
        val result = ProcessBuilder("git", "config", "core.hooksPath", ".githooks")
            .inheritIO()
            .start()
            .waitFor()

        if (result == 0) {
            println("Git hooks installed: core.hooksPath = .githooks")
        } else {
            throw GradleException("Failed to set git core.hooksPath")
        }
    }
}
```

> [!tip] Best Practice
> `build.gradle.kts`의 최상위 `exec {}` 블록(설정 단계)에서는 `ProcessBuilder`가 필요합니다. 그러나 Gradle 8.x 이상에서는 `tasks.register`의 `doLast` 내부에서 `project.exec {}` 를 사용하는 것이 더 관용적입니다. 프로젝트 환경에 따라 두 방식 모두 고려하세요.

---

## 🔍 `exec {}` DSL이 안 되는 이유

Gradle Kotlin DSL의 `doLast` 블록은 `Action<Task>` 람다이며, 이 컨텍스트에서 `exec {}` 는 `Task`의 확장 함수가 아닙니다. 컴파일 에러가 발생합니다.

```kotlin
// 컴파일 에러 발생
tasks.register("installGitHooks") {
    doLast {
        exec {  // Unresolved reference: exec
            commandLine("git", "config", "core.hooksPath", ".githooks")
        }
    }
}

// 올바른 방법 1: ProcessBuilder
tasks.register("installGitHooks") {
    doLast {
        ProcessBuilder("git", "config", "core.hooksPath", ".githooks")
            .inheritIO().start().waitFor()
    }
}

// 올바른 방법 2: project.exec {} (Gradle 7.6+)
tasks.register("installGitHooks") {
    doLast {
        project.exec {
            commandLine("git", "config", "core.hooksPath", ".githooks")
        }
    }
}
```

---

## 🚀 Spotless (Google Java Format) 연동

### `build.gradle.kts` Spotless 설정

```kotlin
plugins {
    id("com.diffplug.spotless") version "6.25.0"
}

spotless {
    java {
        googleJavaFormat("1.22.0")
        importOrder()
        removeUnusedImports()
    }
    kotlin {
        ktlint("1.2.1")
    }
    kotlinGradle {
        ktlint("1.2.1")
    }
}
```

### 워크플로우

```
git commit
    │
    ▼
pre-commit hook
    │
    ▼ ./gradlew spotlessCheck
    │
    ├── 통과 → 커밋 완료
    │
    └── 실패 → 커밋 차단
           │
           ▼ ./gradlew spotlessApply (자동 포맷 적용)
           │
           ▼ git add . && git commit (재시도)
```

> [!warning] 주의 사항
> `spotlessCheck`는 포맷 위반 시 커밋을 차단하지만 자동으로 수정하지는 않습니다. `spotlessApply`를 실행해야 파일이 수정됩니다. pre-commit hook에서 `spotlessApply`를 자동 실행하고 싶다면 hook에서 직접 호출할 수 있지만, 스테이징 영역이 변경될 수 있으므로 주의가 필요합니다.

### LinkWave 실전 트러블슈팅

GitLab CI에서 `spotlessCheck` 실패가 반복되어 pre-commit hook으로 로컬에서 미리 차단하도록 구성했습니다. 첫 커밋 후 발생한 문제:

```
> Task :spotlessCheck FAILED
  The following files had format violations:
    src/main/java/com/example/domain/user/User.java
      @@ -1,6 +1,6 @@
      -import com.example.domain.group.Group;
      -import jakarta.persistence.*;
      +import com.example.domain.group.Group;
      +
      +import jakarta.persistence.*;
```

Google Java Format은 import 블록을 `java.*` → `javax.*` → `jakarta.*` → 서드파티 → 내부 패키지 순서로, 각 블록 사이에 빈 줄을 요구합니다. `spotlessApply`로 자동 수정 후 재커밋했습니다.

---

## 🔗 Husky (프론트엔드)와 비교

| 항목 | `.githooks/` + Gradle | Husky (npm) |
|------|----------------------|------------|
| 생태계 | Java/Gradle 프로젝트 | Node.js/npm 프로젝트 |
| 설치 명령 | `./gradlew installGitHooks` | `npm install` (자동) |
| hooks 위치 | `.githooks/` | `.husky/` |
| Git 설정 | `core.hooksPath` 수동 설정 필요 | `prepare` 스크립트로 자동 |
| lint-staged 연동 | 별도 스크립트 작성 | `lint-staged` 패키지 사용 |
| CI 환경 | `core.hooksPath` 설정 필요 없음 (CI에서 직접 실행) | `HUSKY=0` 환경변수로 비활성화 |

---

## 📋 팀 온보딩 체크리스트

새 팀원이 저장소를 클론한 후 한 번만 실행:

```bash
# 1. 저장소 클론
git clone <repo-url>
cd <project-dir>

# 2. Git hooks 설치 (단 한 번)
./gradlew installGitHooks

# 3. 확인
git config core.hooksPath
# 출력: .githooks
```

이후 모든 `git commit`에서 자동으로 `spotlessCheck`가 실행됩니다.

---

## 🔗 Related Concepts

- [[git-workflow-guide|Git Flow 가이드]] — 브랜치 전략, 커밋 컨벤션
- [[github-actions-guide|GitHub Actions 가이드]] — CI/CD 파이프라인에서 spotlessCheck 연동
- [[resource/topics/infrastructure/_Infrastructure MOC|Infrastructure MOC]]

---

## 📚 References

- [Git 공식 문서 — core.hooksPath](https://git-scm.com/docs/git-config#Documentation/git-config.txt-corehooksPath)
- [Spotless Gradle Plugin](https://github.com/diffplug/spotless/tree/main/plugin-gradle)
- [Google Java Format](https://github.com/google/google-java-format)
