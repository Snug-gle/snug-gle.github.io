---
created: 2026-02-28
tags:
  - project
  - active
  - investflow
  - ai
  - finance
status: planning
---

# InvestFlow v1 — AI 금융 인텔리전스 플랫폼

> "공시·뉴스를 직접 읽는 수고 없이, AI가 요약·분석·질의응답을 대신한다"

---

## 제품 개요

세 가지 기능을 하나의 플랫폼으로 통합한다.

| 기능 | 설명 |
|------|------|
| 📰 AI 뉴스 다이제스트 | 금융 뉴스 자동 수집 → AI 요약 → 뉴스레터 발송 |
| 📈 주식 분석 (investFlow) | KRX 주가 + DART 재무 데이터 + AI 인사이트 |
| 🔍 RAG 공시 검색 | DART 공시 임베딩 → 자연어 질의응답 |

**수익 모델:** FREE / PRO(월 9,900원) 구독 플랜

---

## 전체 흐름

```mermaid
flowchart TD
    subgraph 데이터_수집["🗄️ 데이터 수집 (자동, 무료 API)"]
        KRX["KRX API\n주가 데이터"]
        DART["DART API\n공시·재무"]
        RSS["뉴스 RSS\n네이버 금융"]
    end

    subgraph AI_처리["🤖 AI 처리 (Spring AI + OpenAI)"]
        SUMMARY["뉴스 요약\ngpt-4o-mini"]
        EMBED["공시 임베딩\ntext-embedding-3-small"]
        RAG["RAG 질의응답\nQuestionAnswerAdvisor"]
    end

    subgraph 저장소["💾 저장소"]
        PG["PostgreSQL\n주가·뉴스·유저"]
        CHROMA["ChromaDB (로컬)\n벡터 저장소"]
    end

    subgraph 서비스["🖥️ 서비스"]
        DASHBOARD["대시보드\n관심종목 + 주가"]
        NEWSFEED["뉴스피드\nAI 요약 뉴스"]
        RAGUI["공시 검색\n자연어 Q&A"]
        LETTER["뉴스레터\n주간 자동 발송"]
    end

    KRX --> PG
    DART --> PG
    DART --> EMBED --> CHROMA
    RSS --> SUMMARY --> PG

    PG --> DASHBOARD
    PG --> NEWSFEED
    CHROMA --> RAG --> RAGUI
    PG --> LETTER
```

---

## 시스템 구성도

```mermaid
flowchart LR
    subgraph FE["Frontend\nReact 19 + TanStack"]
        UI["Dashboard / 뉴스피드\nRAG검색 / 구독관리"]
    end

    subgraph BE["Backend\nSpring Boot 4 / Kotlin"]
        API["api 모듈\nREST + Rate Limit"]
        APP["application 모듈\nUseCase"]
        CORE["core 모듈\nDomain + Port"]
        INFRA["infra 모듈\nAdapters"]
    end

    subgraph INFRA_EXT["External"]
        OAI["OpenAI API"]
        KRX2["KRX"]
        DART2["DART"]
    end

    subgraph INFRA_LOCAL["Raspberry Pi"]
        PG2["PostgreSQL"]
        CH2["ChromaDB"]
        NGINX["Nginx\nBlue-Green"]
    end

    UI -- "/api/*" --> API
    API --> APP --> CORE
    INFRA --> CORE
    INFRA --> OAI
    INFRA --> KRX2
    INFRA --> DART2
    INFRA --> PG2
    INFRA --> CH2
    NGINX --> API
```

---

## 개발 단계

```mermaid
gantt
    title InvestFlow v1 개발 로드맵
    dateFormat YYYY-MM-DD
    section M1 기반
        도메인 모델 + KRX API + 관심종목 CRUD     :m1, 2026-03-01, 2w
    section M2 뉴스
        뉴스 크롤링 + AI 요약 + 뉴스피드          :m2, after m1, 2w
    section M3 RAG
        DART 공시 임베딩 + 자연어 질의응답         :m3, after m2, 3w
    section M4 뉴스레터
        구독 + 이메일 자동 발송                    :m4, after m3, 1w
    section M5 수익화
        플랜 제한 + Toss Payments 연동            :m5, after m4, 2w
```

---

## RAG 선택: Spring AI로 직접 구축

```
❌ Flowise / LangChain → Python 서버 추가, 기술스택 분리
✅ Spring AI           → Spring 생태계 내 완결, 추상화 제공

Spring AI가 제공:
  DocumentReader  → 공시 문서 파싱
  TextSplitter    → 청킹
  EmbeddingModel  → text-embedding-3-small
  VectorStore     → ChromaDB 연결
  QuestionAnswerAdvisor → RAG 파이프라인
```

---

## 비용

| 항목 | 월 비용 |
|------|---------|
| Raspberry Pi 전기 | ~3,000원 |
| OpenAI API 전체 | ~5,000~15,000원 |
| **합계** | **~10,000~20,000원** |

손익분기점: **PRO 구독자 2명**

---

## 저장소

- Backend: `.links/invest-flow/invest-flow-backend/`
- Frontend: `.links/invest-flow/invest-flow-frontend/`
- 운영: `mystudy.iptime.org` (Raspberry Pi, Blue-Green)
