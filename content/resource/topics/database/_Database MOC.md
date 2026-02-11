---
created: 2026-01-22
tags:
  - moc
  - resource
  - database
  - mysql
category: database
---

# 🗄️ Database MOC

> 데이터베이스 이론과 실전 - MySQL을 중심으로

## 📍 현재 위치
- 학습 단계: **중급** (MySQL 성능 최적화 집중)
- 실전 적용: [[project/pending/rally-point/architecture|Rally-Point 프로젝트]]

---

## 🌱 기초 개념

### SQL 기본
- [[JOIN]] - 테이블 조인의 이해
- 인덱스 설계
- 쿼리 최적화

### 학습 자료
- 📚 **[[RealMySQL 8.0|RealMySQL 8.0 책 노트]]**
  - [[실행계획|실행계획 분석]]
  - [[옵티마이저와 힌트|옵티마이저와 힌트]]
  - [[고급 최적화|고급 최적화]]
  - [[11.5 insert|Insert 최적화]]

---

## ⚡ 성능 최적화

### 동시성 제어
- [[잠금]] - Lock 메커니즘
- [[교착 상태]] - Deadlock 이해와 해결
- 트랜잭션 격리 수준
- MVCC (Multi-Version Concurrency Control)

### 실전 이슈
```dataview
LIST
FROM #database AND #troubleshooting
```

---

## 🔗 Spring과의 연결

### JPA 성능 최적화
- 🔗 [[resource/topics/spring/지연 로딩|지연 로딩 전략]]
- 🔗 [[resource/topics/spring/더티 체킹|변경 감지]]
- 🔗 [[resource/topics/spring/ManyToOne(fetch = FetchType.LAZY)|Lazy Fetching]]

### N+1 문제 해결
- Fetch Join 활용
- Batch Size 설정
- EntityGraph 사용

---

## 🚀 실전 프로젝트 연결

### Rally-Point에서의 Database 활용
- [[project/pending/rally-point/architecture#데이터베이스 설계|DB 스키마 설계]]
- 인덱스 전략
- 쿼리 성능 튜닝

### LinkWave에서의 Database 활용
- [[project/active/linkwave/index|LinkWave 프로젝트]]
  - CQRS 패턴: JPA (User Domain) + MyBatis (Message Domain)
  - 월별 파티션 테이블로 대용량 메시지 로그 관리
  - DEDUP_HASH 인덱스 활용한 중복 방지

### 배운 점 & 회고
```dataview
LIST
FROM #database AND #learning-log
SORT file.ctime DESC
```

---

## 🔗 관련 MOC
- → [[resource/topics/spring/_Spring MOC|Spring MOC]]
- → [[resource/topics/infrastructure/_Infrastructure MOC|Infrastructure MOC]]

## 🎯 다음 학습 목표
- [ ] 파티셔닝 전략 학습
- [ ] Replication 구성 실습
- [ ] 쿼리 분석 도구 활용
- [ ] NoSQL과의 비교 학습

---
*Last updated: 2026-02-10*
