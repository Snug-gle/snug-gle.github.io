---
created: 2025-11-28
---
# PUBLISHING.md

이 문서는 Obsidian Vault를 웹페이지로 발행하기 위한 규칙을 정의합니다.

## 🎯 발행 목표

- 개인적인 기록(`area/log`, `area/private` 등)을 제외하고, 개발자로서의 지식과 성장 과정을 외부에 공유할 수 있는 '디지털 가든'을 만든다.

## 📂 폴더 구조 및 발행 규칙

### 🌐 공개 (Public)

이 폴더들은 웹에 발행될 핵심 콘텐츠입니다.

- **`index.md`**: 웹의 메인 페이지 역할을 합니다.
- **`README.md`**: 프로젝트 소개 페이지입니다.
- **`resource/`**: 모든 하위 폴더를 포함합니다. 책, 강의 노트 등 지식의 핵심입니다.
- **`project/active/`**: 현재 진행 중인 프로젝트 관련 문서로, 성과를 보여주기 좋습니다.
- **`area/career/`**: 커리어에 대한 고민과 성찰을 공유합니다.
- **`area/learning/`**: 학습 계획과 과정을 공유합니다.
- **`archive/`**: 완료된 프로젝트나 과거의 기록 중 공유하고 싶은 것을 포함할 수 있습니다.

### 🔒 비공개 (Private)

이 폴더들은 개인적인 내용이나 미완성된 생각을 담고 있으므로 발행에서 제외합니다.

- **`area/log/`**: 매일의 생각이나 회의록 등 개인적인 기록입니다.
- **`area/private/`**: 개인적인 정보가 포함되어 있습니다.
- **`area/work/`**: 회사 업무 관련 내용이 포함될 수 있으므로, 보안을 위해 제외하는 것을 강력히 권장합니다.
- **`project/inbox/`**: 정제되지 않은 아이디어나 임시 파일이 위치합니다.
- **`project/pending/`**: 현재 진행하지 않는 프로젝트입니다.
- **`.obsidian/`, `.trash/`, `.idea/`, `.makemd/`, `.claude/`**: Obsidian 및 다른 도구들의 설정 폴더입니다.
- **`CLAUDE.md`, `GEMINI.md`**: AI 모델을 위한 안내 파일입니다.

---

## ⚙️ 발행 제외 목록 (Ignore List)

웹페이지 발행 도구(예: Netlify, Vercel, Quartz)에서 사용할 수 있는 제외 목록 예시입니다.

```
# Private Areas
/area/log/
/area/private/
/area/work/

# Internal Projects
/project/inbox/
/project/pending/

# Tooling and Configuration
/.obsidian/
/.trash/
/.idea/
/.makemd/
/.claude/
/CLAUDE.md
/GEMINI.md
/PUBLISHING.md

# Git files
.gitignore
```
