---
created: 2026-03-11
---
---
created: 2026-01-22
title: Portfolio
---
# 상훈 | Full-stack Developer

> Upstream First — 오픈소스 생태계 위에서 성장하고, 배운 것을 커뮤니티에 돌려주는 개발자

Java/Spring + React/TypeScript | 2022 ~

---

## 주요 프로젝트: LinkWave

**멀티채널 메시징 플랫폼** — B2B SaaS (SMS/LMS/MMS/KakaoTalk/RCS)

`Spring Boot` `React` `MySQL` `Redis` `JPA + MyBatis`

- **CQRS 하이브리드 ORM**: CRUD 중심 도메인(User/Org)은 JPA, 대용량 쓰기(Message/Log)는 MyBatis — 생산성과 성능 동시 달성 → [[resource/topics/architecture/cqrs-hybrid-orm-linkwave|구현 상세]]
- **커서 기반 페이징 (Keyset Pagination)**: 이중 커서(requestedAt + clientKey)로 후반 페이지도 O(1) 성능, Base64 불투명 커서 → [[resource/topics/database/cursor-pagination-linkwave|구현 상세]]
- **JWT HS256 기반 인증 + Refresh Token Rotation**: HMAC-SHA256 대칭키 인증, 슬라이딩 윈도우 리프레시로 보안성 확보
- **월별 파티션 테이블**: 조회 성능 80% 향상, 인덱스 크기 86% 감소
- **멀티테넌트 데이터 격리 + RBAC**: 조직별 데이터 분리와 역할 기반 접근 제어
- **디자인 시스템**: shadcn/ui + Tailwind CSS 컴포넌트 라이브러리 ("Clarity Through Connection")

→ [[area/career/projects/linkwave|자세히 보기]]

---

## 실무 경험

### Perf Script Pipeline — AI 성능 테스트 자동화
`React 19` `TypeScript` `TanStack` `Spring AI`
**2025.08 ~ 2025.11 | 제이드크로스 (Kbank)**

- HAR 병합 → JMX/JTL 추출 → AI 상관관계 분석 → JMeter 스크립트 최적화
- 가상 스크롤링으로 10,000건 렌더링 시간 90% 단축, React Query 캐싱으로 API 요청 80% 감소
- Spring AI + VectorDB 활용 JMeter 스크립트 지능형 검색 프로토타입 구현

→ [[area/career/projects/perf-script-pipeline|자세히 보기]]

### 콜센터 고객상담 웹서비스
`Spring Boot` `Vue.js` `MariaDB` `AUIGrid`
**2025.04 ~ 2025.07 | 위컴즈 (농림부)**

- 악성민원관리 도메인 추가, 콜백 자동 분배 기능 구현
- 스케줄러 → Redis Pub/Sub → WebSocket 파이프라인으로 실시간 알림 구현

→ [[area/career/projects/webconsole|자세히 보기]]

### 기업 메시징 유지보수
`Spring Boot` `Vue.js` `MyBatis` `Oracle/MySQL`
**2023.05 ~ 2025.03 (약 2년) | LGU+**

- Uplus 문자 발송 에이전트 커스터마이징·버전 관리·배포, 고객사 서버 이전 지원
- (기업은행) 외부 암호화 모듈 연동, (한화생명) 문자 발송 프로토콜(bind4) 규격 추가
- UMS 웹 템플릿 통합 메시지 발송 API 구현 및 UI 추가

### 초기 경력 (2022.07 ~ 2023.04)
`Spring Framework` `JSP` `Oracle` `MyBatis`

- **가톨릭학원** (2022.11~2023.04): Tomcat 9 → 10.1 마이그레이션, Jakarta EE 전환 이슈 해결
- **마켓컬리** (2022.07~2022.10): 대량 발송 PL/SQL 반복문 쿼리 작성 및 테스트

---

## 기술 스택

**Backend**: Java 21, Spring Boot, JPA, MyBatis, MySQL, Redis
**Frontend**: React, TypeScript, TanStack (Query/Router/Table), Tailwind CSS, shadcn/ui
**DevOps**: Docker, Nginx, GitHub Actions, GitLab CI/CD
**Architecture**: CQRS, Multi-tenant, RBAC, DDD

---

## 학습과 성장

- 6권 이상 기술 서적 학습 및 실전 적용 — Real MySQL 8.0 → LinkWave 파티셔닝, TanStack → Perf Script Pipeline 가상화
- PARA 방법론 기반 Obsidian vault로 체계적 지식 관리
- 매일 KPT 회고 작성, 지속적 개선
