---
created: 2026-01-22
---
# Gemini MCP 설정 가이드 (Windows + Mac)

> Cross-platform Gemini MCP 설정 for Obsidian Vault Automation

## 🌐 환경 정보

**사용자 환경**:
- 💻 Windows (WSL2) + Mac
- 📁 Vault 위치: `/mnt/d/private/MyJourneyContinues` (WSL) 또는 동기화된 Mac 경로
- 🔄 Cross-platform 동기화 필요

---

## 📋 Prerequisites

### Windows (WSL2)
```bash
# Node.js 설치 확인
node --version  # v18+ 권장
npm --version

# Claude Code 설치 확인
claude --version
```

### Mac
```bash
# Homebrew로 Node.js 설치
brew install node

# Claude Code 설치
npm install -g @anthropics/claude-code
```

---

## 🔧 Gemini MCP 설정

### 1. MCP 서버 설정 파일 위치

#### Windows (WSL2)
```bash
~/.config/claude-code/mcp_settings.json
```

#### Mac
```bash
~/Library/Application Support/Claude Code/mcp_settings.json
```

### 2. Gemini MCP 서버 설정

**공통 설정** (`mcp_settings.json`):

```json
{
  "mcpServers": {
    "gemini": {
      "command": "npx",
      "args": [
        "-y",
        "@modelcontextprotocol/server-gemini"
      ],
      "env": {
        "GEMINI_API_KEY": "YOUR_GEMINI_API_KEY_HERE"
      }
    }
  }
}
```

### 3. Gemini API Key 발급

1. **Google AI Studio 접속**: https://aistudio.google.com/
2. **API Key 생성**:
   - "Get API Key" 클릭
   - 새 API Key 생성
3. **Key 복사 및 저장**

### 4. API Key 안전하게 저장

#### 방법 1: 환경 변수 (권장)

**Windows (WSL2)**:
```bash
# ~/.bashrc 또는 ~/.zshrc에 추가
echo 'export GEMINI_API_KEY="your-api-key-here"' >> ~/.bashrc
source ~/.bashrc
```

**Mac**:
```bash
# ~/.zshrc 또는 ~/.bash_profile에 추가
echo 'export GEMINI_API_KEY="your-api-key-here"' >> ~/.zshrc
source ~/.zshrc
```

그 다음 `mcp_settings.json`에서:
```json
{
  "mcpServers": {
    "gemini": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-gemini"],
      "env": {
        "GEMINI_API_KEY": "${GEMINI_API_KEY}"
      }
    }
  }
}
```

#### 방법 2: 직접 설정 (간편하지만 덜 안전)

```json
{
  "mcpServers": {
    "gemini": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-gemini"],
      "env": {
        "GEMINI_API_KEY": "AIza..."
      }
    }
  }
}
```

⚠️ **주의**: API Key를 git에 커밋하지 마세요!

### 5. MCP 서버 활성화

#### Windows (WSL2)
```bash
# Claude Code 재시작
claude code

# MCP 서버 확인
# Claude Code에서 다음 명령 실행
/mcp list
```

#### Mac
```bash
# 동일하게 Claude Code 실행
claude code

# MCP 서버 확인
/mcp list
```

---

## 🔄 Cross-Platform 동기화 전략

### 옵션 1: Git 기반 동기화 (권장)

**Windows에서**:
```bash
cd /mnt/d/private/MyJourneyContinues
git add .
git commit -m "Update vault"
git push
```

**Mac에서**:
```bash
cd ~/Documents/MyJourneyContinues  # 또는 다른 경로
git pull
```

**`.gitignore` 설정**:
```gitignore
# Obsidian 설정은 동기화하지 않음
.obsidian/workspace*
.obsidian/cache

# 환경별 MCP 설정
.claude-code/
```

### 옵션 2: 클라우드 동기화 (Dropbox, iCloud, OneDrive)

**주의사항**:
- `.obsidian/` 폴더는 동기화해도 됨
- MCP 설정은 각 환경에서 별도 관리
- API Key는 각 환경의 환경 변수로 관리

---

## 🤖 Gemini MCP 사용 예시

### 1. 주간 리뷰 자동 생성

```bash
# Claude Code에서
gemini: "area/log/ 디렉토리의 지난 주 일일 로그를 분석하여
        주간 리뷰를 작성해줘. 템플릿은 archive/templates/weekly-review-template.md를 참고해."
```

### 2. 프로젝트 진행 상황 분석

```bash
gemini: "project/active/linkwave/ 디렉토리의 모든 문서를 읽고
        현재 진행 상황, 완료된 기능, 남은 작업을 요약해줘."
```

### 3. 월간 성장 리포트

```bash
gemini: "다음을 분석하여 월간 성장 리포트를 작성해줘:
        - area/log/daily/2026-01-* (일일 로그)
        - project/active/ (프로젝트 진행)
        - resource/topics/ (학습 내용)

        템플릿: archive/templates/monthly-review-template.md"
```

### 4. 포트폴리오 업데이트 제안

```bash
gemini: "project/active/performance-tester/와 project/active/linkwave-project-summary.md를
        분석하여 area/career/개발자 포트폴리오.md에 추가할 핵심 성과를 추출해줘."
```

### 5. 학습 자료 연결 제안

```bash
gemini: "resource/book/RealMySQL 8.0/ 디렉토리를 읽고
        어떤 프로젝트와 연결할 수 있는지,
        어떤 MOC에 링크를 추가하면 좋을지 제안해줘."
```

---

## 🛠️ Automation Scripts

### Windows (PowerShell) - `generate-weekly-review.ps1`

```powershell
#!/usr/bin/env pwsh
# generate-weekly-review.ps1

$vaultPath = "/mnt/d/private/MyJourneyContinues"
$weekNumber = (Get-Date).ToString("W")
$year = (Get-Date).Year

# Gemini로 주간 리뷰 생성
claude code --prompt @"
gemini: '$vaultPath/area/log/daily/'에서 지난 7일간의 로그를 분석하여
'$vaultPath/area/log/weekly/$year-W$weekNumber.md' 파일을 생성해줘.
템플릿: '$vaultPath/archive/templates/weekly-review-template.md'
"@
```

### Mac (Bash) - `generate-weekly-review.sh`

```bash
#!/bin/bash
# generate-weekly-review.sh

VAULT_PATH="$HOME/Documents/MyJourneyContinues"
WEEK_NUMBER=$(date +%V)
YEAR=$(date +%Y)

# Gemini로 주간 리뷰 생성
claude code --prompt "
gemini: '$VAULT_PATH/area/log/daily/'에서 지난 7일간의 로그를 분석하여
'$VAULT_PATH/area/log/weekly/$YEAR-W$WEEK_NUMBER.md' 파일을 생성해줘.
템플릿: '$VAULT_PATH/archive/templates/weekly-review-template.md'
"
```

**실행 권한 부여 (Mac/WSL)**:
```bash
chmod +x generate-weekly-review.sh
```

---

## 📅 자동화 스케줄링

### Windows (Task Scheduler)

1. **작업 스케줄러** 열기
2. **기본 작업 만들기**
3. **트리거**: 매주 일요일 저녁 9시
4. **작업**: PowerShell 스크립트 실행
5. **경로**: `C:\path\to\generate-weekly-review.ps1`

### Mac (cron)

```bash
# crontab 편집
crontab -e

# 매주 일요일 21:00에 실행
0 21 * * 0 /path/to/generate-weekly-review.sh
```

---

## 🔍 Troubleshooting

### MCP 서버가 시작되지 않을 때

**Windows (WSL2)**:
```bash
# Node.js 버전 확인
node --version  # 18 이상이어야 함

# npx 캐시 클리어
npm cache clean --force

# MCP 서버 수동 테스트
npx -y @modelcontextprotocol/server-gemini
```

**Mac**:
```bash
# 동일한 명령어 실행
node --version
npm cache clean --force
npx -y @modelcontextprotocol/server-gemini
```

### API Key 오류

```bash
# 환경 변수 확인
echo $GEMINI_API_KEY

# Key가 없으면 다시 설정
export GEMINI_API_KEY="your-key"
```

### Cross-platform 경로 문제

**Windows (WSL2) 경로**:
```
/mnt/d/private/MyJourneyContinues
```

**Windows 네이티브 경로**:
```
D:\private\MyJourneyContinues
```

**Mac 경로 예시**:
```
/Users/username/Documents/MyJourneyContinues
```

**스크립트에서 환경 감지**:
```bash
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    VAULT_PATH="/mnt/d/private/MyJourneyContinues"
elif [[ "$OSTYPE" == "darwin"* ]]; then
    VAULT_PATH="$HOME/Documents/MyJourneyContinues"
fi
```

---

## 🎯 권장 Workflow

### 일일 (Daily)
1. 아침: Obsidian에서 daily note 작성 (템플릿 사용)
2. 저녁: 하루 회고 작성
3. **자동**: 내일의 daily note 템플릿 생성 (optional)

### 주간 (Weekly)
1. **일요일 저녁**: 자동 스크립트로 주간 리뷰 초안 생성
2. 초안 검토 및 수정
3. 다음 주 목표 설정

### 월간 (Monthly)
1. **월말 일요일**: Gemini로 월간 리포트 생성
2. 프로젝트 진행률 업데이트
3. 포트폴리오 업데이트
4. 다음 달 목표 설정

---

## 📦 설치 요약

### 빠른 시작 (Quick Start)

**1단계: Gemini API Key 발급**
```
https://aistudio.google.com/ 에서 발급
```

**2단계: 환경 변수 설정**
```bash
# Windows (WSL2)
echo 'export GEMINI_API_KEY="your-key"' >> ~/.bashrc
source ~/.bashrc

# Mac
echo 'export GEMINI_API_KEY="your-key"' >> ~/.zshrc
source ~/.zshrc
```

**3단계: MCP 설정 파일 생성**
```bash
# Windows (WSL2)
mkdir -p ~/.config/claude-code

# Mac
mkdir -p ~/Library/Application\ Support/Claude\ Code
```

**4단계: mcp_settings.json 작성**
```json
{
  "mcpServers": {
    "gemini": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-gemini"],
      "env": {
        "GEMINI_API_KEY": "${GEMINI_API_KEY}"
      }
    }
  }
}
```

**5단계: Claude Code 재시작**
```bash
claude code
```

**6단계: 테스트**
```bash
# Claude Code에서
gemini: "Hello! Can you read files in my vault?"
```

---

## 🎉 완료!

이제 Windows와 Mac 양쪽에서 Gemini MCP를 사용할 수 있어!

**다음 단계**:
1. [[AUTOMATION-EXAMPLES]] - 자동화 예제 모음
2. [[area/log/README]] - 로그 시스템 사용법
3. [[archive/templates/]] - 사용 가능한 템플릿들

---

*Cross-platform productivity with AI assistance!*

**작성일**: 2026-01-22
**업데이트**: 필요시 수정
