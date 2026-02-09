---
tags: [quiz, gemini, automation]
created: 2026-02-04
---

# 퀴즈 자동 생성 가이드

> [!info] Gemini MCP를 활용한 랜덤 퀴즈 생성

## 기본 퀴즈 생성

```
gemini: "resource/topics/ 폴더에서 랜덤으로 3개 주제를 선택하여
각 주제당 2개씩 퀴즈를 생성해줘.

퀴즈 형식:
## Q1. [주제명]
**질문**: ...

<details>
<summary>정답 보기</summary>

**정답**: ...
**해설**: ...
**관련 노트**: [[노트 링크]]
</details>

출력 위치: resource/quiz/$(date +%Y-%m-%d)-quiz.md"
```

## 특정 주제 퀴즈

```
gemini: "다음 주제들에서 퀴즈를 생성해줘:
- resource/topics/spring/역할 기반 분리 CQRS.md
- resource/topics/testing/Mockito 테스트 어노테이션.md

주제당 3문제씩 생성.
난이도: 중급
형식: 객관식 + 단답형 혼합"
```

## 복습 퀴즈 (틀린 문제 중심)

```
gemini: "resource/quiz/ 폴더의 최근 퀴즈들을 분석하여
틀렸거나 어려웠던 주제를 파악하고,
해당 주제에서 추가 퀴즈 5문제를 생성해줘.

힌트: '다시 복습' 태그가 있는 문제 중심으로"
```

## 주간 종합 퀴즈

```
gemini: "이번 주 학습 로그를 분석하여 (area/learning/learning-log/)
학습한 모든 주제에서 종합 퀴즈를 생성해줘.

조건:
- 총 10문제
- 난이도 배분: 쉬움 3, 중간 4, 어려움 3
- 실무 적용 문제 포함"
```

## 퀴즈 유형

### 1. 개념 이해

```markdown
## Q. @Mock과 @MockitoBean의 차이는?

**질문**: 두 어노테이션의 가장 큰 차이점은 무엇인가요?

<details>
<summary>정답 보기</summary>

**정답**: Spring 컨텍스트 사용 여부

**해설**: 
- @Mock: 순수 Mockito, Spring 없음
- @MockitoBean: Spring 컨텍스트 필요

**관련 노트**: [[Mockito 테스트 어노테이션]]
</details>
```

### 2. 코드 분석

```markdown
## Q. 다음 코드의 문제점은?

```java
@ExtendWith(MockitoExtension.class)
class ServiceTest {
    @MockitoBean private Repository repo;  // ← 문제!
}
```

<details>
<summary>정답 보기</summary>

**정답**: @MockitoBean은 Spring 컨텍스트 없이 사용 불가

**해설**: @ExtendWith(MockitoExtension.class)는 순수 Mockito 환경이므로 @Mock을 사용해야 함

**관련 노트**: [[Spring Boot 4.0 테스트 전략]]
</details>
```

### 3. 의사결정

```markdown
## Q. 다음 상황에서 JPA vs MyBatis?

**상황**: 사용자 프로필 수정 후 저장

<details>
<summary>정답 보기</summary>

**정답**: JPA (Command Layer)

**해설**: 엔티티 상태 변경이 목적이므로 JPA를 사용. Dirty Checking으로 자동 저장.

**관련 노트**: [[역할 기반 분리 CQRS]]
</details>
```

## 자동화 스크립트

### 일일 퀴즈 생성 (PowerShell)

```powershell
$date = Get-Date -Format "yyyy-MM-dd"
$prompt = @"
gemini: "resource/topics/에서 랜덤 3주제,
각 2문제씩 퀴즈 생성.
출력: resource/quiz/$date-quiz.md"
"@

claude code --prompt $prompt
```

### 주간 퀴즈 생성 (매주 일요일)

```powershell
# Task Scheduler에 등록
$prompt = @"
gemini: "이번 주 학습 내용 기반 종합 퀴즈 10문제 생성.
area/learning/learning-log/ 참고.
출력: resource/quiz/weekly-$(Get-Date -Format 'yyyy-Www').md"
"@
```

## 관련 문서

- [[_Quiz Index]] - 퀴즈 목록
- [[AUTOMATION-EXAMPLES]] - Gemini MCP 자동화 예제
- [[GEMINI-MCP-SETUP]] - MCP 설정 가이드
