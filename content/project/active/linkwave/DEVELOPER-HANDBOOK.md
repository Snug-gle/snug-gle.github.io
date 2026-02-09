---
created: 2025-12-03
---
# 🌊 LinkWave Developer Handbook

> Iotree LinkWave 개발자를 위한 완벽한 가이드

**버전:** 1.0.0
**최종 업데이트:** 2025-12-03

---

## 📋 목차

1. [시작하기](#1-시작하기)
2. [코딩 컨벤션](#2-코딩-컨벤션)
3. [Git 워크플로우](#3-git-워크플로우)
4. [이슈 및 커밋 작성 가이드](#4-이슈-및-커밋-작성-가이드)
5. [코드 리뷰 가이드](#5-코드-리뷰-가이드)
6. [아키텍처 패턴](#6-아키텍처-패턴)
7. [파일 및 디렉토리 구조 규칙](#7-파일-및-디렉토리-구조-규칙)
8. [테스트 작성 가이드](#8-테스트-작성-가이드)
9. [문서화 규칙](#9-문서화-규칙)
10. [배포 프로세스](#10-배포-프로세스)

---

## 1. 시작하기

### 1.1 개발 환경 설정

**필수 소프트웨어**
```bash
# Java 21 확인
java -version  # openjdk version "21.x.x"

# Node.js 20 확인
node -v  # v20.x.x

# Git 확인
git --version  # git version 2.40+

# Gradle 확인
./gradlew --version  # Gradle 8.5+
```

**IDE 설정**

```
추천 IDE:
├─ 백엔드: IntelliJ IDEA (Ultimate 또는 Community)
└─ 프론트: VS Code

필수 플러그인/확장:
├─ IntelliJ IDEA
│  ├─ Lombok Plugin
│  ├─ Google Java Format
│  └─ SonarLint
└─ VS Code
   ├─ ESLint
   ├─ Prettier
   ├─ GitLens
   └─ Auto Rename Tag
```

### 1.2 프로젝트 클론 및 실행

```bash
# 백엔드
git clone https://gitlab.company.com/iotree/iotree-linkwave-backend.git
cd iotree-linkwave-backend
./gradlew bootRun

# 프론트엔드
git clone https://gitlab.company.com/iotree/iotree-linkwave-frontend.git
cd iotree-linkwave-frontend
npm install
npm run dev
```

---

## 2. 코딩 컨벤션

### 2.1 Java (백엔드) - Google Java Style Guide

#### 2.1.1 Google Java Format 설정

**IntelliJ IDEA 설정**

```
1. Preferences → Plugins → "google-java-format" 검색 후 설치

2. Preferences → Other Settings → google-java-format Settings
   ☑ Enable google-java-format

3. Preferences → Editor → Code Style → Java
   Scheme: GoogleStyle (import)

4. 자동 포맷팅 단축키 설정
   Preferences → Keymap → "Reformat Code"
   단축키: Cmd+Alt+L (Mac) / Ctrl+Alt+L (Windows)
```

**Gradle 설정 (build.gradle.kts)**

```kotlin
plugins {
    id("com.diffplug.spotless") version "6.23.3"
}

spotless {
    java {
        googleJavaFormat("1.18.1")
        removeUnusedImports()
        trimTrailingWhitespace()
        endWithNewline()
    }
}
```

```bash
# 포맷 체크
./gradlew spotlessCheck

# 자동 포맷 적용
./gradlew spotlessApply
```

#### 2.1.2 네이밍 컨벤션

```java
// 클래스명: UpperCamelCase
public class MessageService { }
public class UserRepository { }

// 인터페이스: UpperCamelCase
public interface MessageSender { }

// 메서드명: lowerCamelCase (동사로 시작)
public void sendMessage() { }
public User findUserById(String id) { }
public boolean isValidPhone(String phone) { }

// 변수명: lowerCamelCase
String userName;
int messageCount;
List<Message> messageList;

// 상수: UPPER_SNAKE_CASE
public static final int MAX_RETRY_COUNT = 3;
public static final String DEFAULT_SENDER = "02-1234-5678";

// 패키지명: 소문자, 단어 구분 없음
package io.iotree.linkwave.service;
package io.iotree.linkwave.api.controller;
```

#### 2.1.3 코드 스타일

```java
// ✅ GOOD: 한 줄에 하나의 문장만
if (isValid) {
    processMessage();
    logSuccess();
}

// ❌ BAD: 한 줄에 여러 문장
if (isValid) { processMessage(); logSuccess(); }

// ✅ GOOD: 명확한 변수명
String phoneNumber = extractPhoneNumber(recipient);
boolean isValidFormat = validatePhoneFormat(phoneNumber);

// ❌ BAD: 애매한 약어
String pn = extract(r);
boolean v = validate(pn);

// ✅ GOOD: Optional 사용
public Optional<User> findUserById(String id) {
    return userRepository.findById(id);
}

// ✅ GOOD: Stream API 활용
List<String> validPhones = recipients.stream()
    .map(Recipient::getPhone)
    .filter(this::isValidPhone)
    .collect(Collectors.toList());

// ✅ GOOD: 일찍 반환 (Early Return)
public void processMessage(Message message) {
    if (message == null) {
        return;
    }

    if (!message.isValid()) {
        log.warn("Invalid message: {}", message);
        return;
    }

    // 실제 처리 로직
    doProcess(message);
}
```

#### 2.1.4 주석 작성 규칙

```java
/**
 * 메시지를 발송하고 결과를 반환합니다.
 *
 * @param request 발송 요청 정보
 * @param userId 사용자 ID
 * @return 발송 결과 (clientKey, status 포함)
 * @throws DuplicateMessageException 중복 발송 시도 시
 * @throws InvalidPhoneException 잘못된 전화번호 시
 */
public MessageResponse sendMessage(MessageRequest request, String userId) {
    // ...
}

// ✅ GOOD: 복잡한 로직에만 주석
// 중복 발송 방지를 위해 10분 이내의 동일한 메시지를 체크
String dedupHash = generateDedupHash(phone, content);
if (isDuplicate(dedupHash, 10)) {
    throw new DuplicateMessageException();
}

// ❌ BAD: 당연한 내용 주석
// 변수 초기화
int count = 0;
```

### 2.2 JavaScript (프론트엔드) - Airbnb Style Guide 기반

#### 2.2.1 ESLint & Prettier 설정

**package.json**

```json
{
  "devDependencies": {
    "eslint": "^8.56.0",
    "eslint-config-airbnb": "^19.0.4",
    "eslint-plugin-react": "^7.33.2",
    "eslint-plugin-react-hooks": "^4.6.0",
    "prettier": "^3.1.1",
    "eslint-config-prettier": "^9.1.0"
  }
}
```

**.eslintrc.js**

```javascript
module.exports = {
  extends: [
    'airbnb',
    'airbnb/hooks',
    'prettier'
  ],
  rules: {
    'react/jsx-filename-extension': [1, { extensions: ['.js', '.jsx'] }],
    'react/react-in-jsx-scope': 'off',
    'import/prefer-default-export': 'off',
    'no-console': ['warn', { allow: ['warn', 'error'] }],
    'react/prop-types': 'off', // JavaScript 프로젝트이므로
  },
};
```

**.prettierrc**

```json
{
  "semi": true,
  "singleQuote": true,
  "tabWidth": 2,
  "trailingComma": "es5",
  "printWidth": 100,
  "arrowParens": "always"
}
```

**VS Code 설정 (.vscode/settings.json)**

```json
{
  "editor.formatOnSave": true,
  "editor.defaultFormatter": "esbenp.prettier-vscode",
  "editor.codeActionsOnSave": {
    "source.fixAll.eslint": true
  },
  "eslint.validate": ["javascript", "javascriptreact"]
}
```

#### 2.2.2 네이밍 컨벤션

```javascript
// 컴포넌트: PascalCase
function MessageForm() { }
function SenderNumberSelector() { }

// 함수/변수: camelCase
const sendMessage = () => { };
const messageCount = 10;

// 상수: UPPER_SNAKE_CASE
const MAX_FILE_SIZE = 10485760;
const API_BASE_URL = 'http://localhost:8080/api/v1';

// 파일명:
// - 컴포넌트: PascalCase.jsx
//   MessageForm.jsx, SenderNumberSelector.jsx
// - 유틸/훅/서비스: camelCase.js
//   messageService.js, useMessageForm.js, validation.js

// Boolean 변수: is/has/should로 시작
const isValid = true;
const hasError = false;
const shouldRefetch = true;
```

#### 2.2.3 코드 스타일

```javascript
// ✅ GOOD: 명확한 화살표 함수
const sendMessage = async (request) => {
  const response = await messageApi.post('/messages', request);
  return response.data;
};

// ✅ GOOD: 구조 분해 할당
const { recipients, content, senderNumber } = messageFormData;

// ✅ GOOD: 템플릿 리터럴
const message = `${recipientCount}명에게 메시지를 발송합니다.`;

// ❌ BAD: 문자열 연결
const message = recipientCount + '명에게 메시지를 발송합니다.';

// ✅ GOOD: Optional Chaining & Nullish Coalescing
const userName = user?.profile?.name ?? 'Unknown';

// ✅ GOOD: 배열 메서드 활용
const validPhones = recipients
  .map((r) => r.phone)
  .filter((phone) => isValidPhone(phone));

// ✅ GOOD: 조건부 렌더링
{isLoading && <Spinner />}
{error && <ErrorMessage error={error} />}
{data && <MessageList messages={data} />}
```

#### 2.2.4 React 컴포넌트 작성 규칙

```javascript
// ✅ GOOD: 컴포넌트 구조
import React from 'react';
import { useMessageFormStore } from '@/stores/messageFormStore';
import { useSendMessage } from '@/hooks/useSendMessage';

/**
 * SMS 발송 폼 컴포넌트
 * 수신자 입력, 발신번호 선택, 내용 입력 기능 제공
 */
function SmsForm() {
  // 1. Hooks (상태, 라이프사이클)
  const formState = useMessageFormStore();
  const sendMessage = useSendMessage();

  // 2. 이벤트 핸들러
  const handleSubmit = async (e) => {
    e.preventDefault();
    await sendMessage.mutateAsync(formState);
  };

  // 3. 렌더링
  return (
    <form onSubmit={handleSubmit}>
      {/* JSX */}
    </form>
  );
}

export default SmsForm;
```

---

## 3. Git 워크플로우

### 3.1 브랜치 전략 (Git Flow)

```
main (프로덕션)
  └─ 항상 배포 가능한 상태 유지
  └─ 직접 커밋 금지, MR/PR만 허용
  └─ 태그: v1.0.0, v1.1.0 등

develop (개발)
  └─ 다음 릴리스를 위한 개발 브랜치
  └─ feature 브랜치 병합 대상
  └─ 자동 배포: 개발 서버

feature/* (기능 개발)
  └─ develop에서 분기
  └─ 명명: feature/이슈번호-간단한설명
  └─ 예: feature/123-add-sms-form

hotfix/* (긴급 수정)
  └─ main에서 분기
  └─ 명명: hotfix/이슈번호-간단한설명
  └─ 예: hotfix/456-fix-auth-bug

release/* (릴리스 준비)
  └─ develop에서 분기
  └─ 명명: release/버전
  └─ 예: release/1.0.0
```

### 3.2 브랜치 생성 및 작업 흐름

```bash
# 1. develop 브랜치 최신화
git switch develop
git pull origin develop

# 2. 기능 브랜치 생성
git switch -c feature/123-add-sms-form

# 3. 작업 및 커밋
git add .
git commit -m "feat: SMS 발송 폼 컴포넌트 추가"

# 4. 정기적으로 develop과 동기화
git switch develop
git pull origin develop
git switch feature/123-add-sms-form
git rebase develop

# 5. 원격 브랜치에 푸시
git push origin feature/123-add-sms-form

# 6. GitLab/GitHub에서 Merge Request 생성
# develop ← feature/123-add-sms-form

# 7. 코드 리뷰 후 병합
# 8. 로컬 브랜치 정리
git switch develop
git pull origin develop
git branch -d feature/123-add-sms-form
```

### 3.3 브랜치 명명 규칙

```
feature/[#이슈번호]-[간단한-설명]
  예: feature/123-add-sms-form
  예: feature/124-address-book-api
  (GitLab/GitHub에서 브랜치 이름의 이슈 번호를 인식하여 자동으로 링크를 생성합니다.)

bugfix/[#이슈번호]-[간단한-설명]
  예: bugfix/125-fix-phone-validation

hotfix/[#이슈번호]-[간단한-설명]
  예: hotfix/126-fix-auth-token

refactor/[#이슈번호]-[간단한-설명]
  예: refactor/127-improve-message-service

docs/[간단한-설명]
  예: docs/update-readme

test/[간단한-설명]
  예: test/add-message-service-tests
```

---

## 4. 이슈 및 커밋 작성 가이드

### 4.1 이슈 작성 템플릿

#### 기능 요청 (Feature Request)

```markdown
## 📝 기능 설명
SMS 발송 폼 컴포넌트를 추가합니다.

## 🎯 목적
사용자가 SMS를 작성하고 발송할 수 있는 UI를 제공합니다.

## ✅ 완료 조건 (Acceptance Criteria)
- [ ] 수신자 전화번호 입력 가능
- [ ] 발신번호 선택 가능
- [ ] 메시지 내용 입력 (최대 90byte)
- [ ] 즉시 발송 / 예약 발송 선택 가능
- [ ] 발송 버튼 클릭 시 API 호출
- [ ] 발송 결과 토스트 메시지 표시

## 📋 작업 목록 (Task List)
- [ ] SmsForm 컴포넌트 생성
- [ ] RecipientInput 컴포넌트 생성
- [ ] SenderNumberSelector 컴포넌트 생성
- [ ] ContentEditor 컴포넌트 생성
- [ ] useSendMessage 훅 생성
- [ ] API 연동 테스트

## 📎 참고 자료
- 디자인: [Figma 링크]
- API 문서: `/api/v1/messages` POST
```

#### 버그 리포트 (Bug Report)

```markdown
## 🐛 버그 설명
전화번호 유효성 검사가 010으로 시작하는 번호만 허용합니다.

## 🔄 재현 방법
1. SMS 발송 화면 접속
2. 수신자 번호에 "011-1234-5678" 입력
3. 추가 버튼 클릭

## 🎯 기대 동작
011, 016, 017, 018, 019로 시작하는 번호도 허용되어야 합니다.

## 💥 실제 동작
"올바른 전화번호를 입력해주세요" 에러 메시지가 표시됩니다.

## 🖼️ 스크린샷
[스크린샷 첨부]

## 🌍 환경
- OS: Windows 11
- Browser: Chrome 120
- Version: v0.1.0
```

### 4.2 커밋 메시지 규칙 (Conventional Commits)

#### 커밋 타입

```
feat:     새로운 기능 추가
fix:      버그 수정
docs:     문서 수정
style:    코드 포맷팅 (기능 변경 없음)
refactor: 리팩토링 (기능 변경 없음)
test:     테스트 추가/수정
chore:    빌드/설정 파일 수정
```

#### 커밋 메시지 형식

```
<타입>(<범위>): <제목>

<본문> (선택사항)

<푸터> (선택사항)
```

#### 예시

```bash
# ✅ GOOD: 기본 커밋
git commit -m "feat: SMS 발송 폼 컴포넌트 추가"

# ✅ GOOD: 범위 포함
git commit -m "feat(frontend): SMS 발송 폼 컴포넌트 추가"

# ✅ GOOD: 본문 포함
git commit -m "feat(frontend): SMS 발송 폼 컴포넌트 추가

- 수신자 입력 컴포넌트 (RecipientInput)
- 발신번호 선택 컴포넌트 (SenderNumberSelector)
- 내용 에디터 컴포넌트 (ContentEditor)
- useSendMessage 훅으로 API 연동"

# ✅ GOOD: 이슈 참조
git commit -m "feat(frontend): SMS 발송 폼 컴포넌트 추가

Closes #123"

# ✅ GOOD: Breaking Change
git commit -m "feat(api)!: 메시지 발송 API 응답 형식 변경

BREAKING CHANGE: response.messageId → response.clientKey로 변경"

# ❌ BAD: 애매한 메시지
git commit -m "수정"
git commit -m "작업 완료"
git commit -m "WIP"
```

#### 제목 작성 규칙

```
✅ DO:
- 50자 이내로 작성
- 첫 글자는 소문자
- 마침표 없음
- 명령형 현재 시제 ("추가했음" ❌, "추가" ✅)
- 이슈 번호 참조 시 본문이나 푸터에

❌ DON'T:
- "메시지 발송 기능을 추가했습니다." (과거형)
- "메시지 발송 기능 추가." (마침표)
- "Feat: 메시지 발송" (대문자)
```

### 4.3 GitLab 이슈 라벨

```
타입:
  feature       새로운 기능
  bug           버그
  enhancement   기능 개선
  refactor      리팩토링
  docs          문서화

우선순위:
  P0: Critical  치명적 (즉시 수정)
  P1: High      높음 (이번 스프린트)
  P2: Medium    보통 (다음 스프린트)
  P3: Low       낮음 (백로그)

상태:
  todo          할 일
  in-progress   진행 중
  review        리뷰 중
  done          완료

영역:
  backend       백엔드
  frontend      프론트엔드
  infra         인프라
  database      데이터베이스
```

---

## 5. 코드 리뷰 가이드

### 5.1 리뷰어를 위한 체크리스트

```
기능성
  ☐ 요구사항을 충족하는가?
  ☐ 엣지 케이스를 고려했는가?
  ☐ 에러 처리가 적절한가?

코드 품질
  ☐ 코딩 컨벤션을 따르는가?
  ☐ 변수/함수명이 명확한가?
  ☐ 주석이 필요한 부분에만 있는가?
  ☐ 중복 코드가 없는가?

성능
  ☐ N+1 쿼리 문제는 없는가?
  ☐ 불필요한 반복문은 없는가?
  ☐ 캐싱이 필요한 부분은 없는가?

보안
  ☐ SQL Injection 취약점은 없는가?
  ☐ XSS 취약점은 없는가?
  ☐ 민감 정보가 노출되지 않는가?

테스트
  ☐ 테스트 코드가 작성되었는가?
  ☐ 테스트가 통과하는가?
  ☐ 커버리지가 충분한가?
```

### 5.2 리뷰 코멘트 작성 방법

```
✅ GOOD: 구체적이고 건설적인 피드백
"이 부분은 Stream API를 사용하면 더 간결하게 작성할 수 있습니다:
recipients.stream()
  .map(Recipient::getPhone)
  .filter(this::isValidPhone)
  .collect(Collectors.toList());"

✅ GOOD: 질문 형식
"이 메서드는 여러 책임을 가지고 있는 것 같은데,
분리하는 것이 어떨까요? (단일 책임 원칙)"

✅ GOOD: 칭찬도 함께
"에러 처리가 잘 되어 있네요! 👍
다만 로그 레벨을 ERROR보다는 WARN이 적절할 것 같습니다."
```

### 5.3 MR/PR 체크리스트 (작성자용)

```markdown
## 체크리스트
- [ ] 로컬에서 테스트 완료
- [ ] 코딩 컨벤션 준수 (Spotless/Prettier 실행)
- [ ] 테스트 코드 작성
- [ ] API 문서 업데이트 (필요 시)
- [ ] 마이그레이션 스크립트 작성 (DB 변경 시)
- [ ] 환경 변수 업데이트 문서화 (필요 시)

## 변경 사항
- SMS 발송 폼 컴포넌트 추가
- useSendMessage 훅으로 API 연동
- 전화번호 유효성 검사 로직 추가

## 스크린샷 (UI 변경 시)
[스크린샷 첨부]

## 테스트 방법
1. SMS 발송 화면 접속
2. 수신자 번호 입력 (010-1234-5678)
3. 발신번호 선택
4. 메시지 내용 입력
5. "발송" 버튼 클릭
6. 발송 성공 토스트 확인
```

---

## 6. 아키텍처 패턴

### 6.1 백엔드 - 레이어드 아키텍처

```
┌────────────────────────────────────────┐
│       Controller (API Layer)           │
│  • REST 엔드포인트 정의                │
│  • 요청 검증 (@Valid)                  │
│  • 응답 DTO 반환                       │
└────────────────────────────────────────┘
              ↓
┌────────────────────────────────────────┐
│       Service (Business Layer)         │
│  • 비즈니스 로직                       │
│  • 트랜잭션 관리 (@Transactional)      │
│  • 여러 Repository 조합                │
└────────────────────────────────────────┘
              ↓
┌────────────────────────────────────────┐
│       Repository (Data Layer)          │
│  • 데이터 접근                         │
│  • JPA 쿼리 메서드                     │
│  • @Query 커스텀 쿼리                  │
└────────────────────────────────────────┘
```

**예시:**

```java
// Controller: API 엔드포인트만
@RestController
@RequestMapping("/api/v1/messages")
@RequiredArgsConstructor
public class MessageController {
    private final MessageService messageService;

    @PostMapping
    public ResponseEntity<MessageResponse> sendMessage(
            @Valid @RequestBody MessageRequest request,
            @AuthenticationPrincipal UserDetails userDetails) {

        MessageResponse response = messageService.sendMessage(
            request,
            userDetails.getUsername()
        );

        return ResponseEntity.ok(response);
    }
}

// Service: 비즈니스 로직
@Service
@RequiredArgsConstructor
@Transactional
public class MessageService {
    private final MessageSyncService messageSyncService;
    private final DedupService dedupService;
    private final SenderNumberRepository senderNumberRepository;

    public MessageResponse sendMessage(MessageRequest request, String userId) {
        // 1. 발신번호 검증
        validateSenderNumber(request.getSenderNumber(), userId);

        // 2. 중복 체크
        if (request.isDedupEnabled()) {
            checkDuplicates(request);
        }

        // 3. 동기화
        SyncResult result = messageSyncService.syncToMessageDb(request, userId);

        // 4. 응답 생성
        return buildResponse(result);
    }
}

// Repository: 데이터 접근만
public interface MessageRepository extends JpaRepository<UmsMsg, String> {
    boolean existsByDedupHashAndReqDateAfter(String dedupHash, LocalDateTime threshold);

    @Query("SELECT m FROM UmsMsg m WHERE m.userId = :userId AND m.reqDate BETWEEN :start AND :end")
    List<UmsMsg> findByUserIdAndDateRange(
        @Param("userId") String userId,
        @Param("start") LocalDateTime start,
        @Param("end") LocalDateTime end
    );
}
```

### 6.2 프론트엔드 - 컴포넌트 구조 패턴

#### 6.2.1 Container/Presentational 패턴

```
Container (스마트 컴포넌트)
  • 상태 관리 (useState, Zustand, TanStack Query)
  • 비즈니스 로직
  • API 호출
  • 이벤트 핸들러

Presentational (덤 컴포넌트)
  • props로 데이터 수신
  • UI 렌더링만
  • 재사용 가능
  • 상태 없음 (필요 시 로컬 UI 상태만)
```

**예시:**

```javascript
// Container: SmsPage.jsx
import React from 'react';
import { useMessageFormStore } from '@/stores/messageFormStore';
import { useSendMessage } from '@/hooks/useSendMessage';
import SmsForm from '@/components/forms/SmsForm';

function SmsPage() {
  // 상태 및 로직
  const formState = useMessageFormStore();
  const sendMessage = useSendMessage();

  const handleSubmit = async (data) => {
    await sendMessage.mutateAsync(data);
    formState.reset();
  };

  // Presentational 컴포넌트에 전달
  return (
    <SmsForm
      formData={formState}
      onSubmit={handleSubmit}
      isLoading={sendMessage.isPending}
    />
  );
}

// Presentational: SmsForm.jsx
import React from 'react';
import RecipientInput from '@/components/message/RecipientInput';
import ContentEditor from '@/components/message/ContentEditor';
import Button from '@/components/common/Button';

function SmsForm({ formData, onSubmit, isLoading }) {
  // props만 사용, 상태 없음
  return (
    <form onSubmit={(e) => { e.preventDefault(); onSubmit(formData); }}>
      <RecipientInput
        recipients={formData.recipients}
        onAdd={formData.addRecipient}
        onRemove={formData.removeRecipient}
      />

      <ContentEditor
        content={formData.content}
        onChange={formData.setContent}
        maxLength={90}
      />

      <Button type="submit" loading={isLoading}>
        발송
      </Button>
    </form>
  );
}

export default SmsForm;
```

#### 6.2.2 Custom Hook 패턴

```javascript
// ✅ GOOD: 재사용 가능한 로직을 Hook으로 분리
// hooks/useSendMessage.js
import { useMutation, useQueryClient } from '@tanstack/react-query';
import { messageApi } from '@/api/messageApi';
import { toast } from 'react-hot-toast';

export function useSendMessage() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: messageApi.sendMessage,
    onSuccess: (data) => {
      toast.success(`발송 완료: ${data.clientKey}`);
      queryClient.invalidateQueries({ queryKey: ['messages'] });
    },
    onError: (error) => {
      toast.error(error.response?.data?.message || '발송 실패');
    },
  });
}

// 사용
function SmsPage() {
  const sendMessage = useSendMessage(); // Hook 재사용

  const handleSubmit = async (data) => {
    await sendMessage.mutateAsync(data);
  };
}
```

---

## 7. 파일 및 디렉토리 구조 규칙

### 7.1 파일 크기 제한 및 분리 기준

#### 백엔드 (Java)

```
파일 크기 기준:
  • 클래스: 300줄 이하
  • 메서드: 50줄 이하
  • 파라미터: 4개 이하

분리 기준:
  ✅ 하나의 책임만 (Single Responsibility Principle)
  ✅ 관련 기능끼리 그룹화
  ✅ 공통 로직은 별도 유틸리티 클래스로
```

**예시: 큰 Service 클래스 분리**

```java
// ❌ BAD: 너무 많은 책임 (500줄+)
@Service
public class MessageService {
    public void sendMessage() { }
    public void validatePhone() { }
    public void uploadFile() { }
    public void calculateCost() { }
    public void generateClientKey() { }
    public void checkDuplicate() { }
    // ... 많은 메서드
}

// ✅ GOOD: 책임별로 분리
@Service
@RequiredArgsConstructor
public class MessageService {
    private final MessageValidator messageValidator;
    private final FileUploadService fileUploadService;
    private final CostCalculator costCalculator;
    private final ClientKeyGenerator clientKeyGenerator;
    private final DedupService dedupService;

    public MessageResponse sendMessage(MessageRequest request) {
        messageValidator.validate(request);
        String clientKey = clientKeyGenerator.generate();
        // ...
    }
}

// 각 클래스는 하나의 책임만
@Component
public class MessageValidator {
    public void validate(MessageRequest request) { }
    public void validatePhone(String phone) { }
    public void validateContent(String content) { }
}
```

#### 프론트엔드 (JavaScript)

```
파일 크기 기준:
  • 컴포넌트: 200줄 이하
  • Hook: 100줄 이하
  • 유틸 함수: 파일당 5개 이하

분리 기준:
  ✅ 컴포넌트가 3개 이상의 상태를 관리 → 분리 고려
  ✅ useEffect가 3개 이상 → Hook으로 분리
  ✅ 같은 로직이 2번 이상 반복 → 공통 Hook/유틸로
```

**예시: 큰 컴포넌트 분리**

```javascript
// ❌ BAD: 너무 많은 책임 (300줄+)
function SmsPage() {
  const [recipients, setRecipients] = useState([]);
  const [senderNumber, setSenderNumber] = useState('');
  const [content, setContent] = useState('');
  const [scheduledAt, setScheduledAt] = useState(null);
  const [files, setFiles] = useState([]);

  // 수신자 관련 로직 (50줄)
  const handleAddRecipient = () => { };
  const handleRemoveRecipient = () => { };
  const handleImportExcel = () => { };

  // 발송 관련 로직 (50줄)
  const handleSubmit = () => { };
  const validateForm = () => { };

  // 파일 관련 로직 (50줄)
  const handleFileUpload = () => { };
  const validateFile = () => { };

  // 거대한 JSX (100줄+)
  return ( /* ... */ );
}

// ✅ GOOD: 책임별로 분리
// pages/SmsPage.jsx (50줄)
function SmsPage() {
  const formState = useMessageFormStore(); // Zustand
  const sendMessage = useSendMessage();     // TanStack Query

  return (
    <div>
      <RecipientInput />
      <SenderNumberSelector />
      <ContentEditor />
      <ScheduleSelector />
      <SendButton />
    </div>
  );
}

// components/message/RecipientInput.jsx (80줄)
function RecipientInput() {
  const { recipients, addRecipient, removeRecipient } = useMessageFormStore();
  // 수신자 관련 UI만
}

// components/message/ContentEditor.jsx (60줄)
function ContentEditor() {
  const { content, setContent } = useMessageFormStore();
  // 내용 입력 UI만
}

// hooks/useSendMessage.js (30줄)
export function useSendMessage() {
  // 발송 로직만
}
```

### 7.2 디렉토리 구조 규칙

#### 백엔드

```
io.iotree.linkwave/
├── api/                    # Controller (HTTP 계층)
│   ├── MessageController.java
│   └── dto/                # API 전용 DTO
│       ├── request/
│       └── response/
│
├── domain/                 # 도메인 로직 (선택사항, 복잡한 경우)
│   ├── message/
│   │   ├── Message.java   # Domain Model
│   │   └── MessageService.java
│   └── user/
│
├── service/                # 비즈니스 로직
│   ├── MessageService.java
│   ├── MessageSyncService.java
│   └── DedupService.java
│
├── repository/             # 데이터 접근
│   ├── webdb/
│   └── messagedb/
│
├── entity/                 # JPA Entity
│   ├── webdb/
│   └── messagedb/
│
├── config/                 # 설정
│   ├── DatabaseConfig.java
│   └── SecurityConfig.java
│
└── util/                   # 유틸리티
    ├── ClientKeyGenerator.java
    └── PhoneFormatter.java
```

#### 프론트엔드

```
src/
├── api/                    # API 클라이언트
│   ├── client.js          # Axios 인스턴스
│   └── messageApi.js      # 메시지 API 함수
│
├── components/             # 컴포넌트
│   ├── common/            # 공통 컴포넌트 (Button, Input 등)
│   ├── message/           # 도메인별 컴포넌트
│   └── layout/            # 레이아웃 컴포넌트
│
├── pages/                  # 페이지 컴포넌트
│   ├── SmsPage.jsx
│   └── LmsPage.jsx
│
├── hooks/                  # Custom Hooks
│   ├── useSendMessage.js
│   └── useMessageList.js
│
├── stores/                 # Zustand 스토어
│   ├── authStore.js
│   └── messageFormStore.js
│
├── utils/                  # 유틸리티 함수
│   ├── validation.js
│   └── formatting.js
│
└── constants/              # 상수
    └── api.js
```

---

## 8. 테스트 작성 가이드

### 8.1 백엔드 테스트

#### 단위 테스트 (JUnit 5)

```java
@ExtendWith(MockitoExtension.class)
class MessageServiceTest {

    @Mock
    private MessageSyncService messageSyncService;

    @Mock
    private DedupService dedupService;

    @InjectMocks
    private MessageService messageService;

    @Test
    @DisplayName("메시지 발송 성공")
    void sendMessage_Success() {
        // Given
        MessageRequest request = MessageRequest.builder()
            .messageType("SMS")
            .senderNumber("02-1234-5678")
            .recipients(List.of(new Recipient("010-1234-5678")))
            .content("테스트 메시지")
            .build();

        when(messageSyncService.syncToMessageDb(any(), any()))
            .thenReturn(SyncResult.success("CLIENT_KEY_123"));

        // When
        MessageResponse response = messageService.sendMessage(request, "user123");

        // Then
        assertThat(response.getClientKey()).isEqualTo("CLIENT_KEY_123");
        assertThat(response.getStatus()).isEqualTo("ACCEPTED");
        verify(messageSyncService, times(1)).syncToMessageDb(any(), any());
    }

    @Test
    @DisplayName("중복 메시지 발송 시 예외 발생")
    void sendMessage_DuplicateException() {
        // Given
        MessageRequest request = createMessageRequest();
        when(dedupService.isDuplicate(any(), anyInt())).thenReturn(true);

        // When & Then
        assertThrows(DuplicateMessageException.class, () -> {
            messageService.sendMessage(request, "user123");
        });
    }
}
```

#### 통합 테스트 (TestContainers)

```java
@SpringBootTest
@Testcontainers
class MessageApiIntegrationTest {

    @Container
    static MySQLContainer<?> mysql = new MySQLContainer<>("mysql:8.0")
        .withDatabaseName("testdb")
        .withUsername("test")
        .withPassword("test");

    @Autowired
    private TestRestTemplate restTemplate;

    @Test
    @DisplayName("메시지 발송 API 통합 테스트")
    void sendMessageApi_Success() {
        // Given
        MessageRequest request = MessageRequest.builder()
            .messageType("SMS")
            .senderNumber("02-1234-5678")
            .recipients(List.of(new Recipient("010-1234-5678")))
            .content("통합 테스트")
            .build();

        // When
        ResponseEntity<MessageResponse> response = restTemplate
            .postForEntity("/api/v1/messages", request, MessageResponse.class);

        // Then
        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.OK);
        assertThat(response.getBody().getClientKey()).isNotNull();
    }
}
```

### 8.2 프론트엔드 테스트

#### 컴포넌트 테스트 (React Testing Library)

```javascript
import { render, screen, fireEvent } from '@testing-library/react';
import RecipientInput from './RecipientInput';

describe('RecipientInput', () => {
  it('수신자 추가 시 목록에 표시된다', () => {
    // Given
    render(<RecipientInput />);
    const input = screen.getByPlaceholderText('010-1234-5678');
    const addButton = screen.getByText('추가');

    // When
    fireEvent.change(input, { target: { value: '01012345678' } });
    fireEvent.click(addButton);

    // Then
    expect(screen.getByText(/01012345678/)).toBeInTheDocument();
  });

  it('잘못된 전화번호 입력 시 에러 메시지 표시', () => {
    // Given
    render(<RecipientInput />);
    const input = screen.getByPlaceholderText('010-1234-5678');
    const addButton = screen.getByText('추가');

    // When
    fireEvent.change(input, { target: { value: '123' } });
    fireEvent.click(addButton);

    // Then
    expect(screen.getByText('올바른 전화번호를 입력해주세요')).toBeInTheDocument();
  });
});
```

---

## 9. 문서화 규칙

### 9.1 README 작성 규칙

```markdown
# 프로젝트명

> 한 줄 설명

## 시작하기
(설치 및 실행 방법)

## 주요 기능
(핵심 기능 나열)

## 기술 스택
(사용 기술 명시)

## 문서
(추가 문서 링크)

## 기여
(기여 방법)

## 라이선스
```

### 9.2 API 문서화 (SpringDoc)

```java
@Tag(name = "Message", description = "메시지 발송 API")
@RestController
@RequestMapping("/api/v1/messages")
public class MessageController {

    @Operation(
        summary = "메시지 발송",
        description = "SMS, LMS, MMS 메시지를 발송합니다."
    )
    @ApiResponses({
        @ApiResponse(
            responseCode = "200",
            description = "발송 성공",
            content = @Content(schema = @Schema(implementation = MessageResponse.class))
        ),
        @ApiResponse(
            responseCode = "400",
            description = "잘못된 요청"
        )
    })
    @PostMapping
    public ResponseEntity<MessageResponse> sendMessage(
        @Parameter(description = "발송 요청 정보")
        @Valid @RequestBody MessageRequest request
    ) {
        // ...
    }
}
```

---

## 10. 배포 프로세스

### 10.1 심볼릭 링크를 통한 배포

#### 심볼릭 링크란?

```
심볼릭 링크 (Symbolic Link / Soft Link):
  실제 파일이나 디렉토리를 가리키는 포인터

윈도우의 "바로가기"와 유사하지만,
리눅스 시스템에서는 실제 파일처럼 투명하게 작동

예시:
  current → releases/20250103-140000/

  "current"는 실제 디렉토리가 아니라
  "releases/20250103-140000/"을 가리키는 링크
```

#### 왜 심볼릭 링크를 사용하나?

```
장점:
  ✅ 즉시 롤백 가능
     링크만 변경하면 이전 버전으로 복귀

  ✅ 무중단 배포
     새 버전 준비 → 링크 변경 → 재시작 (수초)

  ✅ 여러 버전 보관
     문제 발생 시 언제든 이전 버전 확인 가능

  ✅ 설정 파일 공유
     shared 디렉토리로 설정 파일 재사용
```

#### 배포 프로세스 상세

```bash
# 현재 상태
/opt/linkwave/backend/
├── current → releases/20250103-130000/  # 현재 실행 중
├── releases/
│   ├── 20250103-120000/  # 이전 버전
│   └── 20250103-130000/  # 현재 버전
└── shared/
    └── application-prod.yml

# Step 1: 새 릴리스 디렉토리 생성
RELEASE_DIR="/opt/linkwave/backend/releases/20250103-140000"
sudo -u linkwave mkdir -p $RELEASE_DIR

# Step 2: JAR 파일 복사
sudo -u linkwave cp build/libs/linkwave-backend-0.1.0.jar \
  $RELEASE_DIR/linkwave-backend.jar

# Step 3: 심볼릭 링크 업데이트 (원자적 연산)
sudo -u linkwave ln -sfn $RELEASE_DIR /opt/linkwave/backend/current

# ✨ 이 순간 current가 새 버전을 가리킴!
# /opt/linkwave/backend/current → releases/20250103-140000/

# Step 4: 서비스 재시작
sudo systemctl restart linkwave-backend

# Step 5: 헬스체크
sleep 5
curl http://localhost:8080/actuator/health

# Step 6: 이전 릴리스 정리 (최근 5개만 유지)
cd /opt/linkwave/backend/releases
ls -t | tail -n +6 | xargs -r sudo -u linkwave rm -rf

# 최종 상태
/opt/linkwave/backend/
├── current → releases/20250103-140000/  # 새 버전으로 변경됨!
├── releases/
│   ├── 20250103-120000/  # 이전 버전 (보관)
│   ├── 20250103-130000/  # 이전 버전 (보관)
│   └── 20250103-140000/  # 현재 실행 중
└── shared/
    └── application-prod.yml
```

#### 롤백 프로세스

```bash
# 문제 발생! 이전 버전으로 롤백해야 함

# Step 1: 이전 버전 확인
ls -lt /opt/linkwave/backend/releases
# 20250103-140000  (현재 - 문제 있음)
# 20250103-130000  (이전 - 안정 버전)

# Step 2: 심볼릭 링크를 이전 버전으로 변경
sudo -u linkwave ln -sfn \
  /opt/linkwave/backend/releases/20250103-130000 \
  /opt/linkwave/backend/current

# Step 3: 서비스 재시작
sudo systemctl restart linkwave-backend

# ✨ 롤백 완료! (1분 이내)
```

### 10.2 배포 체크리스트

```markdown
배포 전:
  ☐ develop 브랜치 최신 코드 pull
  ☐ 로컬 테스트 통과 확인
  ☐ CI/CD 파이프라인 통과 확인
  ☐ 데이터베이스 마이그레이션 스크립트 준비 (필요 시)
  ☐ 환경 변수 업데이트 확인

배포 중:
  ☐ 릴리스 노트 작성
  ☐ 배포 시작 공지 (팀 채널)
  ☐ 배포 스크립트 실행
  ☐ 헬스체크 통과 확인
  ☐ 주요 기능 smoke 테스트

배포 후:
  ☐ 모니터링 대시보드 확인
  ☐ 에러 로그 확인
  ☐ 배포 완료 공지
  ☐ 롤백 계획 준비 (문제 발생 시)
```

---

## 부록: 유용한 명령어

### A.1 Git

```bash
# 브랜치 정리
git branch -d feature/123-add-sms-form  # 로컬 삭제
git push origin --delete feature/123-add-sms-form  # 원격 삭제

# 커밋 수정
git commit --amend -m "새로운 커밋 메시지"

# Stash 사용
git stash  # 임시 저장
git stash pop  # 복원

# 리베이스
git rebase develop  # develop 브랜치 기준으로 재배치
```

### A.2 Gradle

```bash
# 빌드
./gradlew clean build

# 테스트
./gradlew test

# 포맷 체크
./gradlew spotlessCheck

# 포맷 적용
./gradlew spotlessApply

# 의존성 확인
./gradlew dependencies
```

### A.3 npm

```bash
# 린트 체크
npm run lint

# 포맷 체크
npm run format:check

# 포맷 적용
npm run format

# 빌드
npm run build
```

---

## 마무리

이 핸드북은 **살아있는 문서**입니다. 팀의 성장과 함께 계속 업데이트됩니다.

**질문이나 개선 제안이 있다면:**
- GitLab 이슈 생성: [링크]
- 팀 채널에 메시지: #dev-linkwave
- 이메일: dev-team@iotree.com

---

**Happy Coding! 🌊**

_"Clean code is not written by following a set of rules. You know you are working on clean code when each routine you read turns out to be pretty much what you expected."_ - Robert C. Martin
