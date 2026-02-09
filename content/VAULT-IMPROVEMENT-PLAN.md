---
created: 2026-01-22
---
# Obsidian Vault 개선 계획

> 현재 상태: 5.8/10 → 목표: 8.5/10
>
> 작성일: 2026-01-22

## 현재 상태 요약

### 강점 ✓
- **훌륭한 MOC 시스템**: 11개의 체계적인 주제별 MOC
- **명확한 PARA 구조**: 프로젝트/영역/자료/아카이브 구분
- **포괄적인 프로젝트 문서**: LinkWave, RallyPoint 상세 문서화
- **꾸준한 일일 기록**: 32개의 로그 파일로 일관된 실천
- **잘 정리된 주제**: 자료 주제별 카테고리화

### 문제점 ⚠️
- **빈 파일 7개**: 내용 없는 파일들이 vault 지저분하게 만듦
- **중복 파일**: LinkWave 요약 파일 3개, frontend-design 2개
- **잘못 배치된 파일**: 면접 준비, 포트폴리오가 project에 있음
- **아카이브 미활용**: 완료된 프로젝트가 정리되지 않음
- **링크 부족**: 73%의 파일이 고립됨 (다른 파일과 연결 없음)
- **inbox 정체**: 6개월 된 파일이 inbox에 남아있음

---

## 개선 계획 (4주)

### Phase 1: 대청소 (Week 1) 🧹

#### 1.1 빈 파일 삭제
```
- area/log/2025-09-30.md (0 bytes)
- area/log/2025-10-09.md (0 bytes)
- area/log/무제.md (0 bytes)
- area/log/무제 1.md (0 bytes)
- project/inbox/무제.md (0 bytes)
- resource/book/자바 알고리즘 인터뷰 with 코틀린/버블정렬.md (0 bytes)
- resource/daily/라이프사이클 후크.md (0 bytes)
```

#### 1.2 파일 재배치

**Career 관련 파일들 통합**:
```
project/active/면접 준비 종합 가이드.md
  → area/career/interview-prep/종합-가이드.md

project/active/블로그용-포트폴리오.md
  → area/career/portfolio-for-blog.md

project/active/Performance Tester 프로젝트 면접 준비.md
  → area/career/interview-prep/performance-tester.md
```

**TypeScript 파일 정리**:
```
/TypeScript-타입-시스템-기초.md (루트)
  → resource/topics/frontend/typescript/type-system-basics.md
```

**Templates 이동** (CLAUDE.md 규칙 준수):
```
/templates/
  → archive/templates/
```

#### 1.3 Inbox 처리
```
project/inbox/코드 관리 페이지.md
  → 검토 후 적절한 위치로 이동 또는 삭제
```

---

### Phase 2: 통합 및 정리 (Week 2) 📦

#### 2.1 LinkWave 문서 통합

**현재** (중복):
- `project/active/linkwave-project-summary.md` (15KB)
- `project/active/linkwave/00-Project-Summary.md` (3KB)
- `project/active/linkwave/README.md` (22KB)

**개선** (하나로 통합):
```
project/active/linkwave/
├── PROJECT-OVERVIEW.md (통합된 요약)
├── architecture.md
├── backend-notes.md
├── frontend-notes.md
└── implementation-guides/
    ├── auth-implementation.md
    ├── message-system.md
    └── ...
```

#### 2.2 Performance Tester 문서 정리

**현재** (분산):
- `project/active/Performance Tester - 프로젝트 아키텍처.md`
- `project/active/Performance Tester 프로젝트 면접 준비.md`

**개선**:
```
project/active/performance-tester/
├── README.md (overview)
├── architecture.md
└── interview-prep.md
```

#### 2.3 작은 파일 처리

**1-5줄 파일 정책**:
- 확장 가능하면 → 10줄 이상으로 작성
- 확장 불가하면 → 관련 파일에 병합
- 불필요하면 → 삭제

**대상 파일**:
- `area/work/branch/mafra/QA.md` (1줄)
- `area/work/branch/mafra/sms 메시지 리스트 표시.md` (1줄)
- `resource/book/StreetCoder/Index-StreetCoder.md` (1줄)
- 기타 6-10줄 파일 21개

---

### Phase 3: 링크 강화 (Week 3) 🔗

#### 3.1 책 노트 → 주제 MOC 연결

**예시**:
```markdown
# RealMySQL 8.0 - 실행 계획

## 내용
...

## Related Notes
- [[_Database MOC]]
- [[MySQL 옵티마이저와 힌트]]
- [[LinkWave 프로젝트]] - 월별 파티션 적용 사례
```

#### 3.2 카테고리별 README 추가

**생성 필요**:
```
area/career/README.md - 경력 개발 가이드
area/work/README.md - 업무 프로젝트 개요
area/learning/README.md - 학습 로그 설명
resource/book/README.md - 독서 목록 및 진행 상황
resource/topics/README.md - 주제 카테고리 안내
```

#### 3.3 일일 로그 연결

**현재**: 32개 로그가 고립됨
**개선**: 주간/월간 리뷰 노트 생성
```
area/log/
├── daily/
│   ├── 2025-11-06.md
│   └── ...
├── weekly/
│   └── 2025-W45.md (일일 로그 요약)
└── monthly/
    └── 2025-11.md (월간 회고)
```

---

### Phase 4: 아카이브 체계 구축 (Week 4) 📚

#### 4.1 아카이브 구조 생성

```
archive/
├── README.md (아카이브 기준 및 사용법)
├── projects/ (완료된 프로젝트)
│   └── (미래에 완료된 프로젝트 이동)
├── areas/ (비활성 영역)
│   └── work/
│       └── (완료된 업무 프로젝트)
├── resources/ (구 버전 자료)
│   └── (오래된 강의 노트)
└── templates/
    ├── daily-note-template.md
    └── 템플릿.md
```

#### 4.2 아카이브 기준 수립

**프로젝트 아카이브 기준**:
- 완료 후 3개월 지난 프로젝트
- 더 이상 활동하지 않는 프로젝트
- 참고용으로만 유지

**영역 아카이브 기준**:
- 더 이상 담당하지 않는 업무
- 완료된 학습 과정

**자료 아카이브 기준**:
- 버전이 크게 업데이트된 기술 자료
- 더 이상 사용하지 않는 프레임워크

---

## Gemini MCP 활용 방안 🤖

### 자동화 기능

#### 1. 일일 요약 생성
```bash
# MCP를 통해 일일 로그를 요약하여 주간 리뷰 생성
gemini: "area/log/daily/2025-01-15.md부터 2025-01-21.md까지의
        주요 활동을 요약하여 주간 리뷰를 작성해줘"
```

#### 2. 프로젝트 진행 상황 분석
```bash
# LinkWave 프로젝트 문서들을 분석하여 진행률 리포트 생성
gemini: "project/active/linkwave/ 디렉토리의 모든 문서를 분석하여
        현재 진행 상황, 완료된 기능, 남은 작업을 정리해줘"
```

#### 3. 학습 내용 연결
```bash
# 새로운 책 노트를 기존 지식과 연결
gemini: "이 RealMySQL 노트를 읽고 기존의 Database MOC와
        LinkWave 프로젝트와 어떻게 연결할지 제안해줘"
```

#### 4. 월간 회고 생성
```bash
# 한 달간의 로그를 분석하여 성장 리포트 생성
gemini: "2025년 1월의 모든 일일 로그, 프로젝트 진행, 학습 내용을
        분석하여 월간 성장 리포트를 작성해줘"
```

#### 5. 포트폴리오 자동 업데이트
```bash
# 새로운 프로젝트 성과를 포트폴리오에 자동 반영
gemini: "Performance Tester 프로젝트 문서를 분석하여
        포트폴리오에 추가할 핵심 성과를 추출해줘"
```

---

## 새로운 Vault 구조 (목표)

```
MyJourneyContinues/
├── index.md ⭐ (메인 허브)
│
├── project/
│   ├── README.md (프로젝트 개요)
│   ├── active/
│   │   ├── linkwave/
│   │   │   ├── PROJECT-OVERVIEW.md (통합 요약)
│   │   │   ├── architecture.md
│   │   │   ├── backend-notes.md
│   │   │   └── frontend-notes.md
│   │   ├── performance-tester/
│   │   │   ├── README.md
│   │   │   └── architecture.md
│   │   ├── rally-point/
│   │   └── investFlow/
│   └── inbox/
│       └── (항상 깨끗하게 유지)
│
├── area/
│   ├── README.md
│   ├── career/
│   │   ├── README.md
│   │   ├── 개발자 포트폴리오.md
│   │   ├── portfolio-for-blog.md
│   │   ├── Why Developer.md
│   │   └── interview-prep/
│   │       ├── 종합-가이드.md
│   │       └── performance-tester.md
│   ├── learning/
│   │   ├── README.md
│   │   └── learning-log/
│   ├── log/
│   │   ├── README.md
│   │   ├── daily/ (일일 로그)
│   │   ├── weekly/ (주간 리뷰)
│   │   └── monthly/ (월간 회고)
│   └── work/
│       ├── README.md
│       └── branch/
│           ├── mafra/
│           └── jade/
│
├── resource/
│   ├── README.md
│   ├── book/
│   │   ├── README.md (독서 목록)
│   │   ├── RealMySQL 8.0/
│   │   ├── 자바 알고리즘 인터뷰 with 코틀린/
│   │   └── LLM을 활용한 실전 AI 애플리케이션 개발/
│   ├── lecture/
│   │   └── README.md
│   ├── topics/
│   │   ├── README.md (주제 가이드)
│   │   ├── _Algorithm MOC.md
│   │   ├── _Database MOC.md
│   │   ├── _Java MOC.md
│   │   ├── _Spring MOC.md
│   │   ├── _React MOC.md
│   │   └── ...
│   └── snippets/
│
├── archive/
│   ├── README.md (아카이브 정책)
│   ├── projects/
│   ├── areas/
│   ├── resources/
│   └── templates/
│       ├── daily-note-template.md
│       └── 템플릿.md
│
├── .obsidian/ (Obsidian 설정)
└── CLAUDE.md (AI 가이드)
```

---

## 유지 관리 체크리스트

### 일일 (Daily)
- [ ] inbox에 새 노트 추가
- [ ] 일일 로그 작성
- [ ] 새 노트에 최소 2개 이상 링크 추가

### 주간 (Weekly)
- [ ] inbox 처리 (0개 목표)
- [ ] 일일 로그를 주간 리뷰로 요약
- [ ] 새로 추가된 노트를 MOC에 연결
- [ ] Gemini로 주간 학습 요약 생성

### 월간 (Monthly)
- [ ] 완료된 프로젝트 아카이브로 이동
- [ ] 월간 회고 작성
- [ ] 포트폴리오 업데이트
- [ ] 링크 감사 (orphaned files 찾기)
- [ ] Gemini로 월간 성장 리포트 생성

### 분기별 (Quarterly)
- [ ] Vault 건강도 체크
- [ ] 아카이브 정리
- [ ] MOC 재구성
- [ ] 전체 링크 구조 점검

---

## 기대 효과

### Vault 건강도 개선
```
현재: 5.8/10

Phase 1 완료 → 6.5/10 (빈 파일 제거, 재배치)
Phase 2 완료 → 7.5/10 (통합, 중복 제거)
Phase 3 완료 → 8.2/10 (링크 강화)
Phase 4 완료 → 8.5/10 (아카이브 체계)
```

### 개선 후 점수 예상

| 항목 | 현재 | 목표 | 개선 |
|------|------|------|------|
| PARA 준수 | 7/10 | 9/10 | +2 |
| 파일 정리 | 6/10 | 9/10 | +3 |
| 상호 링크 | 5/10 | 8/10 | +3 |
| 콘텐츠 품질 | 6/10 | 8/10 | +2 |
| 아카이브 활용 | 2/10 | 8/10 | +6 |
| Inbox 관리 | 3/10 | 9/10 | +6 |
| **전체 건강도** | **5.8/10** | **8.5/10** | **+2.7** |

---

## 다음 단계

1. ✅ **이 개선 계획 검토**
2. ⬜ **Phase 1 실행 승인** (빈 파일 삭제, 재배치)
3. ⬜ **Phase 2 실행** (통합 및 정리)
4. ⬜ **Phase 3 실행** (링크 강화)
5. ⬜ **Phase 4 실행** (아카이브 구축)
6. ⬜ **Gemini MCP 자동화 설정**
7. ⬜ **유지 관리 체크리스트 시작**

---

*작성: Claude Code*
*날짜: 2026-01-22*
