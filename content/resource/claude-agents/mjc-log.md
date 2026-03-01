---
tags: [claude-code, skill, slash-command, logging, obsidian]
created: 2026-02-26
type: slash-command
location: "~/.claude/commands/mjc-log.md"
---

# /mjc-log — MyJourneyContinues 세션 로그

> [!tip] Slash Command
> `~/.claude/commands/mjc-log.md`에 위치. Claude Code에서 `/mjc-log`로 호출.

세션이 끝날 때 호출한다. `knowledge-base` 에이전트를 활용해
오늘 작업 내용을 Obsidian Vault 일일 로그에 자동으로 정리한다.

> [!note] 역할 분리
> - `dev/raw/` 기록 → Gemini 담당 (이 스킬에서 제외)
> - Vault 일일 로그 → 이 스킬 (`/mjc-log`)

## 작성 위치

```
/mnt/d/private/MyJourneyContinues/area/log/YYYY/MM/YYYY-MM-DD.md
```

파일이 이미 존재하면 내용을 보완하여 업데이트한다.

## 원본 프롬프트

```markdown
오늘 대화에서 작업한 내용을 Obsidian Vault 일일 로그에 정리한다.
knowledge-base 에이전트를 활용하여 작성한다.

작성 위치:
/mnt/d/private/MyJourneyContinues/area/log/YYYY/MM/YYYY-MM-DD.md
(오늘 날짜 기준. 파일이 존재하면 보완 업데이트)

dev/raw는 작성하지 않는다. Gemini가 담당한다.

파일 형식 (frontmatter 포함):
---
created: YYYY-MM-DD
tags: [daily-note, log, {프로젝트명}]
date: YYYY-MM-DD
---

# YYYY-MM-DD (요일)

### 오늘의 하이라이트
### 프로젝트 진행 상황
### 학습 로그
### 인박스 (메모)
### 내일 할 일

작성 기준:
- 학습 로그 우선: 오늘 질문하고 이해한 개념, 설계 결정 이유 중점
- 재현 가능하게: 이 로그만 봐도 왜 이렇게 구현했는지 알 수 있어야 함
- 코드 스니펫 포함: 핵심 패턴은 코드로 남긴다
- 잠재적 개선 포인트: 미처리 예외, 향후 개선사항도 인박스에 기록
```

## 설치

다른 PC에서 사용할 때:
```bash
mkdir -p ~/.claude/commands
# 원본 프롬프트를 ~/.claude/commands/mjc-log.md 에 저장
# vault 경로(/mnt/d/private/...)는 PC 환경에 맞게 수정
```

> [!warning] 경로 주의
> `/mnt/d/private/MyJourneyContinues/` 경로는 WSL 환경 기준.
> 다른 OS에서는 vault 실제 경로로 수정 필요.
