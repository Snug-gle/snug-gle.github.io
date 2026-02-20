# 블로그 퀴즈 기능 구현 가이드

> Gemini API + GitHub Actions로 주간 퀴즈를 자동 생성하고 Quartz 블로그에 인터랙티브 UI로 제공한다.

---

## 전체 흐름

```
[매주 일요일 자동 실행]
GitHub Actions
    │
    ├─ content/resource/topics/*.md 읽기
    │
    ├─ Gemini API 호출 → 퀴즈 5문제 생성
    │
    ├─ quartz/static/quizzes/YYYY-WXX.json 저장
    │
    └─ git commit & push → GitHub Pages 자동 배포
                                    │
                                    ▼
                    브라우저: /quizzes 페이지에서 인터랙티브 퀴즈
```

---

## 사전 준비

### 1. Gemini API 키 발급

1. [Google AI Studio](https://aistudio.google.com) 접속
2. **Get API key** → **Create API key**
3. 키 복사 (무료 티어: 분당 15 요청, 일 1500 요청)

### 2. GitHub Secret 등록

`snug-gle.github.io` 레포 → **Settings** → **Secrets and variables** → **Actions** → **New repository secret**

| Name | Value |
|------|-------|
| `GEMINI_API_KEY` | 발급받은 API 키 |

### 3. 의존성 확인

로컬 테스트용 (Node.js 22 이상 필요):

```bash
cd .links/snug-gle.github.io
node --version   # v22 이상이어야 함
```

---

## 구현 파일 목록

```
snug-gle.github.io/
├── scripts/
│   └── generate-quiz.mjs         ← Step 1: 퀴즈 생성 스크립트
├── quartz/
│   └── static/
│       └── quizzes/              ← Step 2: 생성된 퀴즈 JSON 저장 위치
│           └── 2026-W08.json
├── content/
│   └── quizzes/
│       └── index.md              ← Step 3: 블로그 퀴즈 페이지 (UI)
└── .github/
    └── workflows/
        └── quiz-gen.yml          ← Step 4: GitHub Actions 워크플로우
```

---

## Step 1: 퀴즈 생성 스크립트

`scripts/generate-quiz.mjs` 파일을 생성한다.

```js
// scripts/generate-quiz.mjs
import { GoogleGenerativeAI } from "@google/generative-ai"
import fs from "fs"
import path from "path"

// ──────────────────────────────────────────
// 설정
// ──────────────────────────────────────────
const TOPICS_DIR = "./content/resource/topics"   // 읽어올 노트 경로
const OUTPUT_DIR = "./quartz/static/quizzes"     // 퀴즈 JSON 저장 경로
const QUESTIONS_PER_QUIZ = 5                     // 문제 수
const FILES_TO_SAMPLE = 3                        // 한 번에 읽을 노트 수

// ──────────────────────────────────────────
// 주차 계산 유틸리티
// ──────────────────────────────────────────
function getISOWeek(date) {
  const d = new Date(date)
  d.setHours(0, 0, 0, 0)
  d.setDate(d.getDate() + 4 - (d.getDay() || 7))
  const yearStart = new Date(d.getFullYear(), 0, 1)
  const week = Math.ceil((((d - yearStart) / 86400000) + 1) / 7)
  return `${d.getFullYear()}-W${String(week).padStart(2, "0")}`
}

// ──────────────────────────────────────────
// 마크다운 파일 수집
// ──────────────────────────────────────────
function collectMarkdownFiles(dir) {
  const results = []
  if (!fs.existsSync(dir)) return results

  function walk(current) {
    for (const entry of fs.readdirSync(current, { withFileTypes: true })) {
      const fullPath = path.join(current, entry.name)
      if (entry.isDirectory()) {
        walk(fullPath)
      } else if (entry.name.endsWith(".md") && !entry.name.startsWith("_")) {
        results.push(fullPath)
      }
    }
  }
  walk(dir)
  return results
}

// ──────────────────────────────────────────
// 최근 수정된 파일 N개 선택
// ──────────────────────────────────────────
function pickRecentFiles(files, n) {
  return files
    .map(f => ({ path: f, mtime: fs.statSync(f).mtimeMs }))
    .sort((a, b) => b.mtime - a.mtime)
    .slice(0, n)
    .map(f => f.path)
}

// ──────────────────────────────────────────
// Gemini API 호출
// ──────────────────────────────────────────
async function generateQuiz(noteContents) {
  const genAI = new GoogleGenerativeAI(process.env.GEMINI_API_KEY)
  const model = genAI.getGenerativeModel({ model: "gemini-2.0-flash" })

  const combinedContent = noteContents.join("\n\n---\n\n")

  const prompt = `
아래는 개발자가 공부한 기술 노트야. 이 내용을 바탕으로 학습 이해도를 확인하는 퀴즈 ${QUESTIONS_PER_QUIZ}문제를 만들어줘.

요구사항:
- 각 문제는 4개의 선택지를 가진 객관식
- 정답은 하나
- 노트에 명시된 내용을 근거로 출제 (추측성 문제 금지)
- 한국어로 작성
- 답변은 아래 JSON 형식으로만 출력 (마크다운 코드블록, 설명 텍스트 없이 순수 JSON만)

JSON 형식:
{
  "topics": ["주제1", "주제2"],
  "questions": [
    {
      "question": "문제 내용",
      "options": ["선택지A", "선택지B", "선택지C", "선택지D"],
      "answer": 0,
      "explanation": "이 보기가 정답인 이유 (노트 내용 근거)"
    }
  ]
}

기술 노트:
${combinedContent}
`.trim()

  const result = await model.generateContent(prompt)
  const text = result.response.text().trim()

  // JSON 파싱 (Gemini가 가끔 코드블록으로 감쌀 수 있음)
  const jsonMatch = text.match(/\{[\s\S]*\}/)
  if (!jsonMatch) throw new Error("JSON을 파싱할 수 없음: " + text.slice(0, 200))

  return JSON.parse(jsonMatch[0])
}

// ──────────────────────────────────────────
// 메인
// ──────────────────────────────────────────
async function main() {
  const week = getISOWeek(new Date())
  const outputFile = path.join(OUTPUT_DIR, `${week}.json`)

  // 이미 생성됐으면 스킵 (수동 재실행 시 덮어쓰려면 이 조건 제거)
  if (fs.existsSync(outputFile)) {
    console.log(`이미 생성됨: ${outputFile}`)
    return
  }

  console.log(`퀴즈 생성 중... (${week})`)

  // 파일 수집 및 선택
  const allFiles = collectMarkdownFiles(TOPICS_DIR)
  if (allFiles.length === 0) {
    console.error("노트 파일을 찾을 수 없음:", TOPICS_DIR)
    process.exit(1)
  }
  const selected = pickRecentFiles(allFiles, FILES_TO_SAMPLE)
  console.log("선택된 노트:", selected.map(f => path.relative(".", f)))

  // 파일 내용 읽기 (frontmatter 포함, 길이 제한)
  const noteContents = selected.map(f => {
    const content = fs.readFileSync(f, "utf-8")
    return content.slice(0, 3000)  // 토큰 절약: 파일당 3000자
  })

  // 퀴즈 생성
  const quiz = await generateQuiz(noteContents)

  // 메타데이터 추가
  const output = {
    week,
    generated: new Date().toISOString().split("T")[0],
    sourceFiles: selected.map(f => path.relative(TOPICS_DIR, f)),
    ...quiz
  }

  // 저장
  fs.mkdirSync(OUTPUT_DIR, { recursive: true })
  fs.writeFileSync(outputFile, JSON.stringify(output, null, 2), "utf-8")
  console.log("저장 완료:", outputFile)
}

main().catch(err => {
  console.error(err)
  process.exit(1)
})
```

### 의존성 설치

`package.json`의 `dependencies`에 추가:

```json
"@google/generative-ai": "^0.21.0"
```

그리고 설치:

```bash
npm install @google/generative-ai
```

### 로컬 테스트

```bash
GEMINI_API_KEY=your_key_here node scripts/generate-quiz.mjs
```

생성된 JSON 예시 (`quartz/static/quizzes/2026-W08.json`):

```json
{
  "week": "2026-W08",
  "generated": "2026-02-20",
  "sourceFiles": ["spring/역할 기반 분리 CQRS.md", "database/잠금.md"],
  "topics": ["Spring", "Database"],
  "questions": [
    {
      "question": "message_history를 영구 Read Model로 재정의한 핵심 이유는?",
      "options": [
        "조회 성능 최적화",
        "ums_log에 user_id와 메시지 본문이 없어 폴백 불가",
        "스케줄러 관리 편의성",
        "CQRS 패턴 요구사항"
      ],
      "answer": 1,
      "explanation": "ums_log는 인프라 레벨 원시 데이터라 user_id가 없어 사용자 조회용 폴백이 불가합니다."
    }
  ]
}
```

---

## Step 2: quartz/static/quizzes/ 폴더 생성

```bash
mkdir -p quartz/static/quizzes
```

빌드 후 이 폴더의 JSON 파일은 `/static/quizzes/2026-W08.json` 경로로 접근 가능하다.

---

## Step 3: 블로그 퀴즈 페이지 (UI)

`content/quizzes/index.md` 파일을 생성한다.

````markdown
---
title: Weekly Quiz
description: 공부한 내용을 퀴즈로 복습해보세요
tags:
  - quiz
  - learning
---

# Weekly Quiz

공부한 기술 노트를 기반으로 매주 자동 생성되는 퀴즈입니다.

<div id="quiz-root"></div>

<style>
#quiz-root { font-family: inherit; }
.quiz-card {
  border: 1px solid var(--lightgray);
  border-radius: 8px;
  padding: 1.5rem;
  margin: 1.5rem 0;
}
.quiz-meta {
  color: var(--gray);
  font-size: 0.85rem;
  margin-bottom: 1.5rem;
}
.quiz-question {
  font-weight: 600;
  margin-bottom: 1rem;
  line-height: 1.5;
}
.quiz-options { list-style: none; padding: 0; margin: 0; }
.quiz-options li {
  margin: 0.5rem 0;
}
.quiz-options button {
  width: 100%;
  text-align: left;
  padding: 0.6rem 1rem;
  border: 1px solid var(--lightgray);
  border-radius: 6px;
  background: var(--light);
  color: var(--dark);
  cursor: pointer;
  font-size: 0.95rem;
  transition: background 0.15s, border-color 0.15s;
}
.quiz-options button:hover:not(:disabled) {
  background: var(--highlight);
  border-color: var(--secondary);
}
.quiz-options button.correct {
  background: #d1fae5;
  border-color: #10b981;
  color: #065f46;
}
.quiz-options button.wrong {
  background: #fee2e2;
  border-color: #ef4444;
  color: #991b1b;
}
.quiz-explanation {
  margin-top: 1rem;
  padding: 0.75rem 1rem;
  background: var(--highlight);
  border-left: 3px solid var(--secondary);
  border-radius: 0 6px 6px 0;
  font-size: 0.9rem;
  display: none;
}
.quiz-explanation.visible { display: block; }
.quiz-score {
  text-align: center;
  padding: 2rem;
  border: 1px solid var(--lightgray);
  border-radius: 8px;
  margin: 1rem 0;
}
.quiz-score .score-number {
  font-size: 3rem;
  font-weight: 700;
  color: var(--secondary);
}
.quiz-progress {
  color: var(--gray);
  font-size: 0.85rem;
  margin-bottom: 1rem;
}
.quiz-btn {
  display: inline-block;
  padding: 0.5rem 1.2rem;
  background: var(--secondary);
  color: white;
  border: none;
  border-radius: 6px;
  cursor: pointer;
  font-size: 0.9rem;
  margin-top: 1rem;
}
.quiz-btn:hover { opacity: 0.85; }
.quiz-list { list-style: none; padding: 0; }
.quiz-list li {
  padding: 0.6rem 0;
  border-bottom: 1px solid var(--lightgray);
}
.quiz-list a { text-decoration: none; }
.quiz-list a:hover { text-decoration: underline; }
</style>

<script>
(async function() {
  const root = document.getElementById("quiz-root")

  // ── 주차 계산 ──
  function getISOWeek(date) {
    const d = new Date(date)
    d.setHours(0, 0, 0, 0)
    d.setDate(d.getDate() + 4 - (d.getDay() || 7))
    const yearStart = new Date(d.getFullYear(), 0, 1)
    const week = Math.ceil((((d - yearStart) / 86400000) + 1) / 7)
    return `${d.getFullYear()}-W${String(week).padStart(2, "0")}`
  }

  const currentWeek = getISOWeek(new Date())

  // ── 퀴즈 데이터 로드 ──
  async function loadQuiz(week) {
    const url = `/static/quizzes/${week}.json`
    const res = await fetch(url)
    if (!res.ok) return null
    return res.json()
  }

  // ── 퀴즈 렌더링 ──
  function renderQuiz(quiz) {
    let current = 0
    let score = 0
    const answered = new Array(quiz.questions.length).fill(false)

    function renderQuestion(idx) {
      const q = quiz.questions[idx]
      const progress = `${idx + 1} / ${quiz.questions.length}`

      root.innerHTML = `
        <div class="quiz-meta">
          ${quiz.week} · ${quiz.topics?.join(", ") || ""}
          · 출처: ${quiz.sourceFiles?.join(", ") || ""}
        </div>
        <div class="quiz-progress">문제 ${progress}</div>
        <div class="quiz-card">
          <div class="quiz-question">Q${idx + 1}. ${q.question}</div>
          <ul class="quiz-options">
            ${q.options.map((opt, i) => `
              <li>
                <button data-idx="${i}" onclick="window.__quizAnswer(${i})">
                  ${String.fromCharCode(65 + i)}. ${opt}
                </button>
              </li>
            `).join("")}
          </ul>
          <div class="quiz-explanation" id="explanation">
            ${q.explanation}
          </div>
        </div>
        ${answered[idx] ? `<button class="quiz-btn" onclick="window.__quizNext()">
          ${idx < quiz.questions.length - 1 ? "다음 문제 →" : "결과 보기"}
        </button>` : ""}
      `
    }

    function renderResult() {
      const pct = Math.round((score / quiz.questions.length) * 100)
      const emoji = pct >= 80 ? "🎉" : pct >= 60 ? "👍" : "📚"
      root.innerHTML = `
        <div class="quiz-score">
          <div class="score-number">${score} / ${quiz.questions.length}</div>
          <div style="font-size:1.5rem; margin:0.5rem 0">${emoji}</div>
          <div>${pct}% 정답률</div>
          ${pct < 80 ? `<div style="color:var(--gray);font-size:0.85rem;margin-top:0.5rem">
            관련 노트를 다시 읽어보세요
          </div>` : ""}
          <button class="quiz-btn" onclick="location.reload()">다시 풀기</button>
        </div>
      `
    }

    window.__quizAnswer = function(selectedIdx) {
      if (answered[current]) return
      answered[current] = true

      const q = quiz.questions[current]
      const buttons = root.querySelectorAll(".quiz-options button")
      buttons.forEach(btn => btn.disabled = true)
      buttons[selectedIdx].classList.add(selectedIdx === q.answer ? "correct" : "wrong")
      if (selectedIdx !== q.answer) buttons[q.answer].classList.add("correct")
      document.getElementById("explanation").classList.add("visible")

      if (selectedIdx === q.answer) score++

      // 다음 버튼 추가
      const nextBtn = document.createElement("button")
      nextBtn.className = "quiz-btn"
      nextBtn.textContent = current < quiz.questions.length - 1 ? "다음 문제 →" : "결과 보기"
      nextBtn.onclick = window.__quizNext
      root.querySelector(".quiz-card").after(nextBtn)
    }

    window.__quizNext = function() {
      current++
      if (current >= quiz.questions.length) {
        renderResult()
      } else {
        renderQuestion(current)
      }
    }

    renderQuestion(0)
  }

  // ── 과거 퀴즈 목록 렌더링 ──
  function renderArchive(weeks) {
    return `
      <h2>지난 퀴즈</h2>
      <ul class="quiz-list">
        ${weeks.map(w => `<li><a href="/static/quizzes/${w}.json" target="_blank">${w}</a></li>`).join("")}
      </ul>
    `
  }

  // ── 메인 ──
  root.innerHTML = `<p>퀴즈를 불러오는 중...</p>`
  const quiz = await loadQuiz(currentWeek)

  if (!quiz) {
    root.innerHTML = `
      <p>이번 주 퀴즈가 아직 없습니다. (${currentWeek})</p>
      <p style="color:var(--gray);font-size:0.9rem">
        매주 일요일 자동 생성됩니다.
      </p>
    `
  } else {
    renderQuiz(quiz)
  }
})()
</script>
````

---

## Step 4: GitHub Actions 워크플로우

`.github/workflows/quiz-gen.yml` 파일을 생성한다.

```yaml
name: Generate Weekly Quiz

on:
  schedule:
    - cron: '0 9 * * 0'   # 매주 일요일 오전 9시 UTC (오후 6시 KST)
  workflow_dispatch:        # 수동 실행 허용

jobs:
  generate-quiz:
    runs-on: ubuntu-latest
    permissions:
      contents: write       # git push 권한

    steps:
      - name: Checkout
        uses: actions/checkout@v4
        with:
          fetch-depth: 1

      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: '22'
          cache: 'npm'

      - name: Install dependencies
        run: npm ci

      - name: Sync vault content
        run: npm run sync
        # content/resource/topics/ 에 최신 노트가 필요하므로 sync 먼저 실행

      - name: Generate quiz
        env:
          GEMINI_API_KEY: ${{ secrets.GEMINI_API_KEY }}
        run: node scripts/generate-quiz.mjs

      - name: Commit and push quiz
        run: |
          git config user.name "Quiz Bot"
          git config user.email "action@github.com"
          git add quartz/static/quizzes/
          git diff --staged --quiet || git commit -m "chore: weekly quiz $(date -u +'%Y-W%V')"
          git push
```

> **주의**: `npm run sync`는 vault(`links/MyJourneyContinues`)가 있어야 동작한다. GitHub Actions에서는 vault가 없으므로, **sync 단계를 제거**하고 `content/resource/topics/`를 별도로 관리하거나, 아래 대안을 사용한다.

### sync 없이 동작하는 대안

vault의 `resource/topics/`를 별도 GitHub 레포로 분리하거나, snug-gle.github.io 레포에 이미 커밋된 `content/resource/topics/`를 읽도록 수정:

```yaml
# sync 단계 제거 후 그냥 실행
# content/resource/topics/ 는 마지막 빌드 결과가 이미 레포에 있어야 함
- name: Generate quiz
  env:
    GEMINI_API_KEY: ${{ secrets.GEMINI_API_KEY }}
  run: node scripts/generate-quiz.mjs
```

`content/resource/topics/`가 `.gitignore`에 있다면 제거해야 한다. 현재 `.gitignore` 확인:

```bash
cat .links/snug-gle.github.io/.gitignore | grep content
```

---

## Step 5: 로컬 테스트

```bash
cd .links/snug-gle.github.io

# 1. 퀴즈 생성 테스트
GEMINI_API_KEY=your_key node scripts/generate-quiz.mjs

# 2. JSON 생성 확인
cat quartz/static/quizzes/$(date +%Y-W%V).json | head -30

# 3. 빌드 및 미리보기
npm run serve
# → http://localhost:8080/quizzes 에서 UI 확인
```

---

## 구현 순서 요약

| 순서 | 할 일 | 파일 |
|------|-------|------|
| 1 | `@google/generative-ai` 설치 | `package.json` |
| 2 | 퀴즈 생성 스크립트 작성 | `scripts/generate-quiz.mjs` |
| 3 | 로컬에서 스크립트 테스트 | - |
| 4 | 퀴즈 UI 페이지 작성 | `content/quizzes/index.md` |
| 5 | 로컬 빌드로 UI 확인 | `npm run serve` |
| 6 | GitHub Secret 등록 | GitHub Settings |
| 7 | GitHub Actions 워크플로우 작성 | `.github/workflows/quiz-gen.yml` |
| 8 | Actions 수동 실행으로 테스트 | GitHub → Actions 탭 |

---

## 추가 개선 아이디어 (나중에)

- **틀린 문제 재출제**: `localStorage`에 저장해 다음 방문 시 복습
- **주차별 목록**: `/quizzes` 페이지에 과거 퀴즈 아카이브 제공
- **난이도 태그**: 노트의 frontmatter `difficulty` 필드 활용
- **주제 선택**: 특정 topic(Spring, Database 등)만 퀴즈로 출제
- **퀴즈 이메일 알림**: GitHub Actions에서 생성 완료 후 자신에게 메일 발송

---

## 자주 발생하는 문제

| 증상 | 원인 | 해결 |
|------|------|------|
| `JSON을 파싱할 수 없음` | Gemini가 코드블록으로 감쌈 | 스크립트의 jsonMatch 정규식이 처리함 |
| `퀴즈를 불러오는 중...` 에서 멈춤 | JSON 경로 불일치 | `/static/quizzes/` 경로 확인 |
| Actions에서 sync 실패 | vault가 없음 | sync 단계 제거, 직접 content/ 사용 |
| 문제 품질이 낮음 | 노트가 너무 짧음 | `FILES_TO_SAMPLE` 줄이고 `slice(0, 5000)` 늘리기 |
