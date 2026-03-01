---
tags: [claude-code, agent, index, automation]
created: 2026-02-04
---

# Claude Code Agent 인덱스

> [!tip] Claude Code 커스텀 Agent
> 반복적인 작업을 자동화하기 위한 커스텀 agent 프롬프트 모음입니다.
> 원본 위치: `~/.claude/agents/`

## Agent 목록

### 📝 문서화
- [[api-docs-generator]] - API 문서 자동 생성 (Spring REST Docs 스타일)
- [[component-docs-generator]] - 컴포넌트 문서 생성

### 🔍 코드 품질
- [[code-reviewer]] - 코드 리뷰 (Java/Kotlin, TypeScript/React)
- [[tdd-test-architect]] - TDD 기반 테스트 코드 생성

### 🏗️ 스캐폴딩
- [[scaffold-backend]] - Spring Boot 백엔드 스캐폴딩
- [[scaffold-frontend]] - React 프론트엔드 스캐폴딩

### 📚 지식 관리
- [[knowledge-base]] - Obsidian 노트 생성/관리
- [[system-architect]] - 시스템 아키텍처 설계

## 사용법

Claude Code에서 agent 호출:
```
agent <agent-name>을 사용해서 <작업 내용>
```

예시:
```
agent tdd-test-architect를 사용해서 ContactService 테스트 코드 생성해줘
agent code-reviewer를 사용해서 이 코드 리뷰해줘
```

## Slash Commands (Skills)

> [!info] Agents vs Skills
> **Agents**: Claude가 자율적으로 다단계 작업을 수행하는 서브프로세스
> **Skills**: `/명령어`로 호출하는 프롬프트 템플릿 (`~/.claude/commands/`에 위치)

### 🎓 학습 지원
- [[guide-me]] — `/guide-me` : 구현하며 배우는 학습 지원 모드 (Senior/Peer 멘토 역할)

### 📓 로깅
- [[mjc-log]] — `/mjc-log` : 세션 종료 후 MyJourneyContinues Vault 일일 로그 자동 작성

---

## 관련 문서

- [[QUIZ-GENERATOR]] - Gemini MCP 퀴즈 자동화
- [[AUTOMATION-EXAMPLES]] - 자동화 예제 모음
