---
tags: [claude-code, agent, index, automation]
created: 2026-02-04
---

# Claude Code Agent 인덱스

> [!tip] Claude Code 커스텀 Agent
> 반복적인 작업을 자동화하기 위한 커스텀 agent 프롬프트 모음입니다.
> 원본 위치: `~/.claude/agents/`

## Agent 목록

> [!tip] 모델 전략
> `haiku` — 파일 R/W, 템플릿 문서화 | `sonnet` — 코드 생성/분석 | `opus` — 아키텍처 결정

### 📝 문서화 (haiku)
- [[api-docs]] - API 문서 자동 생성 (Spring REST Docs 스타일)
- [[component-docs]] - React 컴포넌트 문서 생성 (Storybook 스타일)

### 🔍 코드 품질 (sonnet)
- [[code-reviewer]] - 코드 리뷰 (Java/Kotlin, TypeScript/React)
- [[test-writer]] - TDD 기반 테스트 코드 생성 (JUnit5/Jest)

### 🦴 스켈레톤 생성 (sonnet)
- [[skeleton-backend]] - Spring Boot 백엔드 레이어 뼈대 생성
- [[skeleton-frontend]] - React 컴포넌트/훅/스토어 뼈대 생성

### 📚 지식 관리
- [[knowledge-base]] `haiku` — Obsidian 노트 생성/관리, **Vault 일일 로그 작성 포함**
- [[system-architect]] `opus` — 시스템 아키텍처 설계 및 DDD

## 사용법

Claude Code에서 agent 호출:
```
agent <agent-name>을 사용해서 <작업 내용>
```

예시:
```
agent test-writer를 사용해서 ContactService 테스트 코드 생성해줘
agent code-reviewer를 사용해서 이 코드 리뷰해줘
vault에 기록해줘  →  knowledge-base agent 직접 호출
```

## Slash Commands (Skills)

> [!info] Agents vs Skills
> **Agents**: 독립 실행 서브프로세스, 파일 R/W 등 도구 접근 가능
> **Skills**: `/명령어`로 호출하는 프롬프트 주입 템플릿 (`~/.claude/commands/`에 위치)
> → 도구가 필요한 작업은 Agent, 행동 모드 변경은 Skill

### 🎓 학습 지원
- [[guide-me]] — `/guide-me` : 구현하며 배우는 학습 지원 모드 (Senior/Peer 멘토 역할)

> [!note] mjc-log 제거 (2026-03-04)
> `/mjc-log` skill 삭제됨 — knowledge-base agent에 daily log 형식이 내장되어 직접 호출로 대체

---

## 관련 문서

- [[QUIZ-GENERATOR]] - Gemini MCP 퀴즈 자동화
- [[AUTOMATION-EXAMPLES]] - 자동화 예제 모음
