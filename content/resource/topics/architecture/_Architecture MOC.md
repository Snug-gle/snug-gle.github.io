---
created: 2026-02-05
tags:
  - moc
  - resource
  - architecture
  - software-design
category: architecture
---

# 🏛️ Software Architecture MOC

> 소프트웨어 아키텍처 학습 로드맵

## 📍 현재 위치
- 학습 단계: **초중급**
- 실전 적용: [[project/pending/rally-point/architecture|Rally-Point 프로젝트]] MSA 설계

---

## 🌱 기초 개념

### 아키텍처란?
- 소프트웨어 아키텍처의 정의
- 좋은 아키텍처의 특징
- 아키텍처 설계 원칙
- SOLID 원칙

### 설계 패턴
- Creational Patterns
- Structural Patterns
- Behavioral Patterns
- MVC, MVP, MVVM

---

## 🏗️ 아키텍처 패턴

### Monolithic Architecture
- 모놀리식 장단점
- 레이어드 아키텍처
- Clean Architecture
- Hexagonal Architecture

### Microservices Architecture (MSA)
- MSA 개념과 특징
- 서비스 분리 전략
- API Gateway 패턴
- Service Mesh
- Event-Driven Architecture

---

## 🔧 개발 방법론

### Upstream Development
- [[Upstream Development]] - 업스트림 개발 철학
- 오픈소스 기여 방법론
- 커뮤니티 주도 개발

### Attiead 스터디
- [[attiead-clean-architecture|Clean Architecture 스터디]] - Attiead 팀
- [[attiead-ddd-study|DDD 스터디]] - Attiead 팀

### 구현 전략
- [[기능-구현-우선순위-결정-의존성-기반-사고법|🎯 기능 구현 우선순위 결정]] - 의존성 기반 사고법

### 협업 방식
- Agile 방법론
- DevOps 문화
- CI/CD 파이프라인

---

## 🌐 분산 시스템

### 핵심 개념
- CAP 이론
- Eventual Consistency
- Saga Pattern
- CQRS (Command Query Responsibility Segregation)

### 메시징 & 이벤트
- 🔗 [[resource/topics/infrastructure/attiead-kafka-study|Apache Kafka]]
- Message Queue 패턴
- Pub/Sub 패턴
- Event Sourcing

---

## 📊 데이터 아키텍처

### 데이터 관리 전략
- Database per Service
- Shared Database
- 🔗 [[resource/topics/database/_Database MOC|Database 설계]]

### 캐싱 전략
- Redis 활용 (캐싱 전략, Session 관리)
- CDN 활용
- Cache Invalidation

---

## 🚀 실전 프로젝트 적용

### Rally-Point 아키텍처
- [[project/pending/rally-point/architecture|전체 아키텍처 설계]]
- MSA 도메인 분리
- 서비스 간 통신 전략
- 데이터 일관성 유지

### 아키텍처 결정 기록 (ADR)
```dataview
LIST
FROM #architecture AND #adr
SORT file.ctime DESC
```

---

## 🔍 품질 속성

### 주요 품질 속성
- **확장성** (Scalability)
- **가용성** (Availability)
- **성능** (Performance)
- **보안** (Security)
- **유지보수성** (Maintainability)

### 트레이드오프 분석
- 복잡도 vs 유연성
- 일관성 vs 가용성
- 성능 vs 정확성

---

## 📚 학습 자료

### 책
- 클린 아키텍처 (Robert C. Martin)
- 마이크로서비스 패턴
- Domain-Driven Design
- Building Microservices

### 관련 노트
```dataview
LIST
FROM #architecture OR #software-design
WHERE !contains(file.name, "MOC")
SORT file.mtime DESC
```

---

## 🔗 관련 MOC
- → [[resource/topics/spring/_Spring MOC|Spring MOC]]
- → [[resource/topics/infrastructure/_Infrastructure MOC|Infrastructure MOC]]
- → [[resource/topics/database/_Database MOC|Database MOC]]
- ← [[resource/topics/java/_Java MOC|Java MOC]]

## 🎯 학습 목표
- [ ] MSA 패턴 심화 학습
- [ ] DDD 개념 이해 및 적용
- [ ] Event-Driven Architecture 실습
- [ ] 시스템 설계 인터뷰 준비
- [ ] Rally-Point 아키텍처 문서화 완성
- [ ] 아키텍처 리팩토링 경험

---
*Last updated: 2025-10-29*
