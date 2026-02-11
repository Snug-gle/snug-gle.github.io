---
created: 2026-01-22
tags:
  - moc
  - dashboard
---

# 🏠 My Development Journey

> 밀도 높은 삶과 개발자 커리어를 위한 지식 베이스

## 🎯 현재 집중 (Projects)

### 🚀 Active Projects
- [[project/active/linkwave/index|📱 LinkWave]] - 멀티채널 메시징 플랫폼 (CQRS, JWT+RTR, Multi-tenant)
- [[project/active/conference-study/index|🎤 Conference Study]] - Attiead 팀 컨퍼런스 스터디

### ⏸️ Pending Projects
- [[project/pending/rally-point/architecture|🎾 Rally-Point]] - MSA 기반 테니스 매칭 플랫폼 (중단)
- [[project/pending/investFlow/2025-11-13_Deployment_Setup_and_Refactoring|📈 InvestFlow]] - 주식 분석 플랫폼 (중단)

### ✅ Completed Projects
- ⚡ Perf Script Pipeline - HAR-JMX 상관관계 분석 파이프라인 (2025.10-11)
  - 성능 최적화: 렌더링 90% 개선, API 요청 80% 감소

### 💼 Project Inbox
- [[project/inbox/README|📥 New Ideas]] - 빠른 아이디어 캡처

## 🌱 지속적 성장 (Areas)

### 💼 Career
- [[area/career/portfolio-for-blog|📄 Developer Portfolio]] - 블로그 배포용 포트폴리오
- [[area/career/portfolio-resume|📋 Portfolio Resume]] - 이력서
- [[area/career/interview-prep/종합-가이드|💡 Interview Prep]] - 면접 준비 자료
- [[area/career/Why Developer|❤️ Why Developer]] - 개발자가 된 이유

### 📚 Learning & Work
- [[area/learning/learning-log/README|📖 Learning Journey]]
- [[area/work/README|🏢 Work Notes]] - MAFRA 프로젝트 등
- [[area/log/README|📅 Daily Logs]] - 일일 기록

## 📚 지식 베이스 (Resources)

### Core Technologies
- [[resource/topics/java/_Java MOC|☕ Java]]
- [[resource/topics/spring/_Spring MOC|🍃 Spring]]
- [[resource/topics/database/_Database MOC|🗄️ Database]]

### Frontend
- [[resource/topics/frontend/react/_React MOC|⚛️ React]]
- [[resource/topics/frontend/typescript/_TypeScript MOC|📘 TypeScript]]
- [[resource/topics/frontend/vue/_Vue MOC|💚 Vue.js]]

### Cloud & Infrastructure
- [[resource/topics/aws/_AWS MOC|☁️ AWS]]
- [[resource/topics/infrastructure/_Infrastructure MOC|🏗️ Infrastructure]]

### AI & Advanced
- [[resource/topics/llm-ai/_LLM & AI MOC|🤖 LLM & AI]]
- [[resource/topics/algorithms/_Algorithm MOC|🧮 Algorithms]]
- [[resource/topics/architecture/_Architecture MOC|🏛️ Architecture]]

## 📊 최근 활동

### 이번 주 학습
```dataview
LIST
FROM #learning-log
WHERE file.ctime >= date(today) - dur(7 days)
SORT file.ctime DESC
LIMIT 5
```

### 최근 수정된 자료
```dataview
TABLE file.mtime as "Updated", tags as "Tags"
FROM #resource
SORT file.mtime DESC
LIMIT 10
```

## 🏷️ 주요 태그
`#java` `#spring` `#react` `#typescript` `#aws` `#llm` `#msa`

---
## 🗂️ Quick Links

### 📁 Archive
- [[archive/README|📦 Archived Items]] - 완료된 프로젝트 및 비활성 자료

### 🛠️ Vault Management
- [[VAULT-IMPROVEMENT-PLAN|🎯 Vault Improvement Plan]] - Vault 개선 계획

---

**Vault 건강도: 7.5/10** 📈 (Phase 1+2 완료)

*Last updated: 2026-01-22*
*PARA 방법론 기반 vault 재구조화 진행 중 (Phase 3)*
