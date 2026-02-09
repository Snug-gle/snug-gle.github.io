---
created: 2026-01-22
---
# Automation Examples - Gemini MCP 활용

> Obsidian Vault 자동화 실전 예제 모음

## 📚 목차

1. [주간 리뷰 생성](#주간-리뷰-생성)
2. [월간 리포트 생성](#월간-리포트-생성)
3. [프로젝트 진행 분석](#프로젝트-진행-분석)
4. [포트폴리오 업데이트](#포트폴리오-업데이트)
5. [학습 자료 연결](#학습-자료-연결)
6. [코드 통계 생성](#코드-통계-생성)

---

## 🔄 주간 리뷰 생성

### Claude Code에서 실행

```
gemini: "다음 작업을 수행해줘:

1. area/log/daily/ 폴더의 최근 7일 로그 파일을 읽어
2. 주요 활동, 학습 내용, 완료한 작업을 분석하고
3. archive/templates/weekly-review-template.md를 기반으로
4. area/log/weekly/2026-W04.md 파일을 생성해줘

분석 포인트:
- 가장 많이 작업한 프로젝트
- 새로 배운 기술/개념
- 해결한 주요 문제
- 다음 주 추천 목표"
```

### 자동화 스크립트 (Bash/Mac)

**파일**: `scripts/weekly-review.sh`

```bash
#!/bin/bash

VAULT_PATH="$HOME/Documents/MyJourneyContinues"
WEEK=$(date +%V)
YEAR=$(date +%Y)
OUTPUT="$VAULT_PATH/area/log/weekly/$YEAR-W$WEEK.md"

# Gemini로 주간 리뷰 생성
claude code << EOF
gemini: "area/log/daily/ 폴더의 최근 7일 로그를 분석하여
주간 리뷰를 생성해줘.

템플릿: archive/templates/weekly-review-template.md
출력 위치: $OUTPUT

분석 내용:
- 프로젝트별 시간 투자
- 학습한 기술 요약
- 주요 성과 3가지
- 다음 주 권장 목표"
EOF

echo "✅ Weekly review created: $OUTPUT"
```

### 자동화 스크립트 (PowerShell/Windows)

**파일**: `scripts/weekly-review.ps1`

```powershell
$VaultPath = "D:\private\MyJourneyContinues"
$Week = (Get-Date).ToString("W")
$Year = (Get-Date).Year
$Output = "$VaultPath\area\log\weekly\$Year-W$Week.md"

$prompt = @"
gemini: "area/log/daily/ 폴더의 최근 7일 로그를 분석하여
주간 리뷰를 생성해줘.

템플릿: archive/templates/weekly-review-template.md
출력 위치: $Output

분석 내용:
- 프로젝트별 시간 투자
- 학습한 기술 요약
- 주요 성과 3가지
- 다음 주 권장 목표"
"@

claude code --prompt $prompt

Write-Host "✅ Weekly review created: $Output"
```

---

## 📊 월간 리포트 생성

### Claude Code에서 실행

```
gemini: "2026년 1월 월간 리포트를 생성해줘:

데이터 소스:
1. area/log/daily/2026-01-* (일일 로그 전체)
2. area/log/weekly/2026-W* (주간 리뷰들)
3. project/active/ (프로젝트 진행 상황)
4. resource/topics/ (새 학습 자료)

분석 요청:
- 이번 달 총 학습 시간 추정
- 프로젝트별 진행률 요약
- 새로 학습한 기술 TOP 3
- 가장 큰 성과 1가지
- 다음 달 집중 영역 제안

템플릿: archive/templates/monthly-review-template.md
출력: area/log/monthly/2026-01.md"
```

### Cron 자동화 (Mac/Linux)

```bash
# 매월 마지막 일요일 21:00 실행
0 21 28-31 * * [ "$(date +\%u)" = 7 ] && /path/to/monthly-review.sh
```

---

## 🚀 프로젝트 진행 분석

### LinkWave 프로젝트 분석

```
gemini: "LinkWave 프로젝트를 분석해줘:

분석 대상:
- project/active/linkwave/README.md
- project/active/linkwave-project-summary.md
- project/active/linkwave/ 폴더의 모든 마크다운 파일

분석 요청:
1. 현재 구현 완료된 기능 리스트
2. 진행 중인 작업
3. 남은 작업 (TODO 추출)
4. 기술적 챌린지 및 해결 방법
5. 다음 마일스톤 제안

출력 형식: 프로젝트 상태 리포트 (마크다운)"
```

### 모든 프로젝트 요약

```
gemini: "project/active/ 폴더의 모든 프로젝트를 스캔하여
각 프로젝트의 진행 상황을 요약해줘:

프로젝트별 출력:
- 프로젝트명
- 현재 상태 (Active/Paused/Near Completion)
- 이번 주 진행 사항
- 다음 주 계획
- 예상 완료 시점

출력: project-status-dashboard.md"
```

---

## 💼 포트폴리오 업데이트

### 성과 추출

```
gemini: "다음 프로젝트들을 분석하여 포트폴리오에 추가할
핵심 성과를 추출해줘:

프로젝트:
1. project/active/performance-tester/
2. project/active/linkwave-project-summary.md

추출 포인트:
- 정량적 성과 (숫자로 표현 가능한 것)
  예: '렌더링 90% 개선', 'API 요청 80% 감소'
- 사용한 기술 스택
- 해결한 기술적 문제
- 아키텍처 결정 및 이유

출력 형식: area/career/개발자 포트폴리오.md에 추가할 섹션"
```

### 기술 스택 업데이트

```
gemini: "vault 전체를 스캔하여 내가 사용한 기술 스택을 정리해줘:

스캔 위치:
- project/active/ (실제 사용 기술)
- resource/topics/ (학습한 기술)
- area/log/ (언급된 기술)

출력 형식:
## 기술 스택 (2026년 1월 기준)

### Backend
- 기술명 (숙련도, 사용 프로젝트)

### Frontend
- 기술명 (숙련도, 사용 프로젝트)

### DevOps
- 기술명 (숙련도, 사용 프로젝트)

숙련도 기준:
- ⭐⭐⭐⭐ (Expert): 실무 프로젝트 3개 이상
- ⭐⭐⭐ (Advanced): 실무 프로젝트 1-2개
- ⭐⭐ (Intermediate): 학습 완료, 토이 프로젝트
- ⭐ (Beginner): 학습 중"
```

---

## 🔗 학습 자료 연결

### 책 노트와 프로젝트 연결

```
gemini: "resource/book/RealMySQL 8.0/ 폴더를 읽고
다음을 분석해줘:

1. 각 챕터의 핵심 개념
2. 어느 프로젝트에 적용할 수 있는지
   - LinkWave의 CQRS, 파티션 테이블
   - RallyPoint의 데이터베이스 설계

3. resource/topics/database/_Database MOC.md에
   어떤 링크를 추가하면 좋을지

출력 형식:
- 챕터별 프로젝트 매칭
- MOC 업데이트 제안 (마크다운 형식)"
```

### MOC 강화 제안

```
gemini: "다음 MOC 파일들을 읽고 개선 제안을 해줘:

대상 MOC:
- resource/topics/java/_Java MOC.md
- resource/topics/spring/_Spring MOC.md
- resource/topics/algorithms/_Algorithm MOC.md

개선 제안 요청:
1. 누락된 중요 주제
2. 추가할 프로젝트 연결
3. 책 노트와의 링크 기회
4. MOC 간 상호 참조 제안

출력: MOC 개선 액션 아이템 리스트"
```

---

## 📈 코드 통계 생성

### Git 통계 (프로젝트별)

**스크립트**: `scripts/git-stats.sh`

```bash
#!/bin/bash

PROJECTS=(
    "/home/sanghoon/project/iotree-linkwave"
    # 다른 프로젝트 경로 추가
)

for PROJECT in "${PROJECTS[@]}"; do
    echo "## $(basename $PROJECT)"
    cd $PROJECT

    echo "### 이번 달 커밋"
    git log --since="1 month ago" --oneline | wc -l

    echo "### 코드 변경"
    git log --since="1 month ago" --shortstat --oneline | \
        awk '/files? changed/ {files+=$1; inserted+=$4; deleted+=$6} \
        END {print files " files, +" inserted " -" deleted}'

    echo ""
done
```

### Claude Code로 통계 요청

```
gemini: "다음 프로젝트들의 개발 통계를 분석해줘:

프로젝트:
1. /home/sanghoon/project/iotree-linkwave

분석 요청:
- 최근 30일 커밋 수
- 추가/삭제된 라인 수
- 주요 변경 파일 TOP 5
- 가장 활발했던 주

참고: .git 디렉토리는 읽을 수 없으니,
프로젝트 문서와 코드 파일을 기반으로 추정해줘"
```

---

## 🎯 Smart Suggestions

### 다음 학습 추천

```
gemini: "내 학습 이력과 프로젝트를 분석하여
다음 학습할 기술을 추천해줘:

분석 데이터:
- resource/topics/ (현재 학습 기술)
- project/active/ (프로젝트에서 사용 중인 기술)
- area/log/ (최근 관심사)

추천 기준:
1. 현재 프로젝트에 바로 적용 가능
2. 커리어 발전에 도움
3. 기존 지식과 시너지
4. 2026년 트렌드

출력: 학습 추천 리스트 (우선순위, 이유, 학습 자료)"
```

### 아카이브 후보 찾기

```
gemini: "vault를 스캔하여 아카이브 후보를 찾아줘:

스캔 조건:
1. project/active/에서 3개월 이상 업데이트 없는 프로젝트
2. area/work/에서 6개월 이상 업데이트 없는 영역
3. resource/에서 오래된 기술 자료 (예: 구 버전)

각 후보에 대해:
- 파일 경로
- 마지막 수정 일자
- 아카이브 이유
- 추천 액션

출력: 아카이브 후보 리스트"
```

---

## 🔧 유틸리티 자동화

### 링크 무결성 체크

```
gemini: "vault의 모든 링크를 체크해줘:

체크 항목:
1. 깨진 내부 링크 [[존재하지않는파일]]
2. 고아 파일 (다른 파일에서 링크되지 않는 파일)
3. 중복 링크 (같은 파일을 여러 번 링크)

출력:
- 깨진 링크 리스트
- 고아 파일 리스트 (상위 10개)
- 링크 통계 (총 링크 수, 파일당 평균)"
```

### Vault 건강도 체크

```
gemini: "vault 건강도를 분석해줘:

분석 항목:
1. 파일 정리 상태
   - 빈 파일 (50줄 미만)
   - 최근 6개월 업데이트 없는 파일

2. 링크 밀도
   - 링크가 없는 파일 비율
   - MOC 연결 상태

3. PARA 준수도
   - 잘못 배치된 파일
   - inbox 상태

4. 템플릿 사용
   - 일관성 체크

출력: Vault 건강도 리포트 (점수, 개선 제안)"
```

---

## 📅 스케줄링 예제

### Mac (launchd)

**파일**: `~/Library/LaunchAgents/com.vault.weekly-review.plist`

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
    "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.vault.weekly-review</string>

    <key>ProgramArguments</key>
    <array>
        <string>/path/to/weekly-review.sh</string>
    </array>

    <key>StartCalendarInterval</key>
    <dict>
        <key>Weekday</key>
        <integer>0</integer> <!-- Sunday -->
        <key>Hour</key>
        <integer>21</integer>
        <key>Minute</key>
        <integer>0</integer>
    </dict>

    <key>RunAtLoad</key>
    <false/>
</dict>
</plist>
```

**활성화**:
```bash
launchctl load ~/Library/LaunchAgents/com.vault.weekly-review.plist
```

### Windows (Task Scheduler XML)

**파일**: `weekly-review-task.xml`

```xml
<?xml version="1.0" encoding="UTF-16"?>
<Task version="1.2">
  <Triggers>
    <CalendarTrigger>
      <StartBoundary>2026-01-26T21:00:00</StartBoundary>
      <ScheduleByWeek>
        <DaysOfWeek>
          <Sunday />
        </DaysOfWeek>
        <WeeksInterval>1</WeeksInterval>
      </ScheduleByWeek>
    </CalendarTrigger>
  </Triggers>
  <Actions>
    <Exec>
      <Command>powershell.exe</Command>
      <Arguments>-File "D:\scripts\weekly-review.ps1"</Arguments>
    </Exec>
  </Actions>
</Task>
```

**가져오기**:
```powershell
schtasks /Create /XML weekly-review-task.xml /TN "Vault Weekly Review"
```

---

## 💡 Pro Tips

### 1. 배치 처리

여러 작업을 한 번에:

```
gemini: "다음 작업들을 순서대로 수행해줘:

1. 주간 리뷰 생성 (최근 7일 로그)
2. 프로젝트 진행 상황 분석 (project/active/)
3. 포트폴리오 성과 추출
4. 다음 주 학습 추천

각 작업의 결과를 별도 파일로 저장:
- area/log/weekly/2026-W04.md
- reports/project-status-2026-01-22.md
- reports/portfolio-update-2026-01-22.md
- reports/learning-recommendations-2026-01-22.md"
```

### 2. 컨텍스트 제공

더 정확한 분석을 위해:

```
gemini: "주간 리뷰를 작성할 때:

컨텍스트:
- 나는 Full-Stack 개발자야
- 현재 LinkWave 프로젝트가 우선순위 1번
- 이직 준비 중이라 포트폴리오 업데이트가 중요해
- React 19, Spring Boot 4.0을 주로 사용해

이 컨텍스트를 고려해서 주간 리뷰를 작성해줘"
```

### 3. 출력 형식 지정

```
gemini: "프로젝트 분석 결과를
다음 형식으로 출력해줘:

## 프로젝트명

### 진행 상황
- [ ] 기능 1 (80%)
- [ ] 기능 2 (50%)
- [x] 기능 3 (완료)

### 이번 주 하이라이트
> 한 줄 요약

### 다음 주 계획
1.
2.
3.

---
"
```

---

## 🎉 완료!

이제 Gemini MCP로 Vault를 자동화할 수 있어!

**관련 문서**:
- [[GEMINI-MCP-SETUP]] - MCP 설정 가이드
- [[archive/templates/]] - 사용 가능한 템플릿들
- [[area/log/README]] - 로그 시스템 사용법

---

*Automation is not about being lazy, it's about being efficient*

**작성일**: 2026-01-22
**업데이트**: 필요시 수정
