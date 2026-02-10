---
created: 2026-01-22
---
# Perf Script Pipeline - HAR-JMX 상관관계 분석 도구

> 업무 프로젝트 | 2025.10 - 2025.11 (5주) | Frontend Developer

## 프로젝트 개요

HAR/JTL 파일 분석을 통해 HTTP 요청/응답 간 동적 파라미터 상관관계를 추출하고, AI 기반으로 JMeter RegEx Extractor를 추천하여 성능 테스트 스크립트를 최적화하는 도구.

## 나의 기여

**Frontend 개발 60%** (606 insertions, 384 deletions, 30+ commits)

### 핵심 성과

#### 성능 최적화 🚀
- **가상 스크롤링**: 10,000+ 행 테이블 렌더링 90% 개선 (10초 → 1초)
- **React Query 캐싱**: 불필요한 API 요청 80% 감소
- **페이지네이션 전략**: 100 → 500 → 1000 items/page 최적화

#### 기술 스택
- **Frontend**: React 19, TypeScript, Vite
- **Routing**: TanStack Router
- **State**: TanStack Query (API 캐싱)
- **Table**: TanStack Table + TanStack Virtual
- **UI**: Tailwind CSS, Radix UI
- **Backend**: Spring Boot (Java 21), Spring AI (OpenAI), LDAP

## 프로젝트 문서

### 기술 문서
- [[architecture]] - 프로젝트 아키텍처 및 기술 상세

### 면접 준비
- [[area/career/interview-prep/perf-script-pipeline]] - 면접 대비 자료
  - Q&A 형식 정리
  - 성과 수치화
  - 기술적 챌린지와 해결 방법

## 주요 기능

1. **파일 분석**
   - HAR (HTTP Archive) 파싱
   - JTL (JMeter Test Log) 파싱

2. **상관관계 분석**
   - 동적 파라미터 추출 (Response → Request)
   - AI 기반 RegEx Extractor 추천

3. **스크립트 생성**
   - JMX (JMeter) 자동 생성
   - 상관관계 자동 적용

## 학습 포인트

- **대규모 데이터 렌더링**: Virtual Scrolling 원리와 적용
- **서버 상태 관리**: React Query 캐싱 전략
- **AI 통합**: Spring AI를 통한 OpenAI 활용
- **팀 협업**: API 계약 정의, 코드 리뷰

## 관련 노트

- [[area/career/개발자 포트폴리오]] - 포트폴리오에 포함됨
- [[resource/topics/_React MOC]] - React 기술 참고

---

*성능 최적화는 사용자 경험을 위한 필수 투자*
