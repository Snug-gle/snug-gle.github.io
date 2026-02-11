---
created: 2025-11-28
tags:
  - moc
  - resource
  - spring
  - backend
category: backend
---

# 🍃 Spring Framework MOC

> Spring 생태계 학습 지도 - 이론부터 실전까지

## 📍 현재 위치
- 학습 단계: **중급** (JPA 최적화 집중)
- 실전 적용: [[project/pending/rally-point/architecture|Rally-Point 프로젝트]]

---

## 🌱 기초 개념

### Core Concepts
- Spring Framework란
- IoC와 DI
- Bean 생명주기
- 스프링 컨테이너

### 학습 자료
- 📚 [[resource/lecture/spring/spring|Spring 강의 노트]]
- 📚 [[resource/lecture/DateApp/Spring 생태계의 이해]]

---

## 📦 Data Access (JPA)

### 기본
- [[Spring Data JPA]] - 기본 사용법
- [[JPA]] - JPA 개념
- [[mapping]] - 엔티티 매핑
- [[엔티티 관계]] - 관계 설정

### 성능 최적화 ⚡
- [[ManyToOne(fetch = FetchType.LAZY)]] - 지연 로딩 전략
- [[지연 로딩]] - Lazy Loading 깊이 이해
- [[더티 체킹]] - 변경 감지 메커니즘
- 🔗 연결: [[resource/topics/database/교착 상태|교착 상태 해결]]
- 🔗 연결: [[resource/topics/database/잠금|데이터베이스 잠금]]

### 실무 패턴
- [[spring-boot-best-practices|Spring Boot 실무 패턴]] - 팩토리 메서드, Auditing, Snowflake ID, 테스트 전략
- [[development-principles|개발 원칙 가이드]] - DDD 레이어 아키텍처, JPA, 보안, 테스트, API 설계

### 실전 이슈
```dataview
LIST
FROM #spring AND #troubleshooting
```

---

## 🚀 실전 프로젝트 연결

### Rally-Point에서의 Spring 활용
- [[project/pending/rally-point/architecture#도메인 설계|MSA 도메인 설계]]
- [[project/pending/rally-point/user-domain|User Service]] - Spring Boot + JPA
- Redis 연동, Kafka 이벤트 처리

### 배운 점 & 회고
```dataview
LIST
FROM #spring AND #learning-log
SORT file.ctime DESC
```

---

## 🔗 관련 MOC
- ← [[resource/topics/java/_Java MOC|Java MOC]]
- ← [[resource/topics/database/_Database MOC|Database MOC]]
- → [[resource/topics/architecture/_Architecture MOC|Architecture MOC]]

## 🎯 다음 학습 목표
- [ ] Spring Security 심화
- [ ] Spring WebFlux 공부
- [ ] Spring Batch 실전 적용

---
*Last updated: 2025-10-29*
