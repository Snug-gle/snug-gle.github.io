---
created: 2026-01-22
tags:
  - moc
  - resource
  - llm
  - ai
  - ml
category: llm-ai
---

# 🤖 LLM & AI MOC

> 대규모 언어 모델과 AI 학습 로드맵

## 📍 현재 위치
- 학습 단계: **초중급** (RAG 시스템 구축 중심)
- 실전 적용: LLM 기반 프로젝트 준비 중

---

## 🌱 기초 개념

### LLM 아키텍처
- [[트랜스포머 아키텍처]] - Transformer의 작동 원리
- [[멀티 모달 LLM]] - 텍스트를 넘어선 AI

### 학습 자료
- 📚 **[[LLM을 활용한 실전 AI 애플리케이션 개발]]**
  - [[1부 'LLM의 기초 뼈대 세우기'|LLM의 기초 뼈대 세우기]]
  - [[허킹페이스'의 트랜스포머 라이브러리 사용법 익히는 것을 목표|Hugging Face Transformers 사용법]]

---

## 🔧 LLM 운영 (LLMOps)

### 개발 & 배포
- [[LLMOps]] - LLM 시스템 운영 개론
- 프롬프트 엔지니어링
- 모델 파인튜닝 전략
- 비용 최적화

### 모니터링 & 관리
```dataview
LIST
FROM #llm AND #ops
```

---

## 🔍 RAG (Retrieval-Augmented Generation)

### 핵심 구성요소
- [[임베딩 모델]] - 벡터 임베딩의 이해
- [[파인콘]] - 벡터 데이터베이스
- [[리랭커(Reranker)]] - 검색 결과 재정렬

### RAG 파이프라인
1. 문서 청킹 및 임베딩
2. 벡터 저장소 구축
3. 유사도 검색
4. 컨텍스트 생성
5. LLM 응답 생성

---

## 🚀 실전 적용

### 실전 프로젝트
- **[[archive/projects/perf-script-pipeline/|Perf Script Pipeline]]** - Spring AI + OpenAI 통합
  - AI 기반 RegEx Extractor 추천
  - 프롬프트 엔지니어링 실전 경험

### Attiead 스터디
- [[attiead-llm-study|Attiead LLM 스터디]] - 팀 스터디

### 프로젝트 아이디어
- RAG 기반 문서 QA 시스템
- 개인 지식 베이스 어시스턴트
- 코드 분석 도구

### 기술 스택
- **벡터 DB**: Pinecone, Weaviate, ChromaDB
- **LLM**: GPT-4, Claude, Gemini
- **프레임워크**: LangChain, LlamaIndex

---

## 📚 추가 학습 자료

### 관련 토픽
```dataview
LIST
FROM #llm OR #ai
WHERE !contains(file.name, "MOC")
SORT file.mtime DESC
```

---

## 🔗 관련 MOC
- → [[resource/topics/algorithms/_Algorithm MOC|Algorithm MOC]]
- → [[resource/topics/infrastructure/_Infrastructure MOC|Infrastructure MOC]]

## 🎯 다음 학습 목표
- [ ] LangChain 심화 학습
- [ ] 프롬프트 엔지니어링 마스터
- [ ] RAG 시스템 실제 구축
- [ ] 파인튜닝 실습
- [ ] LLM 평가 메트릭 이해

---
*Last updated: 2025-10-29*
