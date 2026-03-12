---
tags: [claude-code, agent, index, automation]
created: 2026-02-04
---

# Claude Code Agent Index

> [!tip] Claude Code Custom Agents
> A collection of custom agent prompts for automating repetitive tasks.
> Source location: `~/.claude/agents/`

## Agent List

> [!tip] Model Strategy
> `haiku` — file R/W, template documentation | `sonnet` — code generation/analysis | `opus` — architecture decisions

### Documentation (haiku)
- [[api-docs]] - API documentation generation (Spring REST Docs style)
- [[component-docs]] - React component documentation (Storybook style)

### Code Quality (sonnet)
- [[code-reviewer]] - Code review (Java/Kotlin, TypeScript/React)
- [[test-writer]] - TDD-based test generation (JUnit5/Jest)

### Skeleton Generation (sonnet)
- [[skeleton-backend]] - Spring Boot backend layer scaffolding
- [[skeleton-frontend]] - React component/hook/store scaffolding

### Knowledge Management
- [[knowledge-base]] `haiku` — Obsidian note creation/management, **including daily log writing**
- [[system-architect]] `opus` — System architecture design and DDD

## Usage

Invoke an agent in Claude Code:
```
Use agent <agent-name> to <task description>
```

Examples:
```
Use agent test-writer to generate tests for ContactService
Use agent code-reviewer to review this code
Log to vault  →  invoke knowledge-base agent directly
```

## Slash Commands (Skills)

> [!info] Agents vs Skills
> **Agents**: Independent subprocess with tool access (file R/W, etc.)
> **Skills**: Prompt injection templates invoked via `/command` (located in `~/.claude/commands/`)
> → Use Agent for tool-required tasks, Skill for behavior mode changes

### Learning Support
- [[guide-me]] — `/guide-me` : Learning-by-doing mode (Senior/Peer mentor role)

> [!note] mjc-log removed (2026-03-04)
> `/mjc-log` skill deleted — daily log format is now built into the knowledge-base agent; invoke it directly instead

---

## Related Documents

- [[QUIZ-GENERATOR]] - Gemini MCP quiz automation
- [[AUTOMATION-EXAMPLES]] - Automation example collection
