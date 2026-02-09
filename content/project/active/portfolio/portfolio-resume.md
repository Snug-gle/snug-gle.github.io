---
created: 2026-02-04
draft: true
title: "상훈 | Full-stack Developer 포트폴리오"
author: "상훈"
date: 2025-01-01
geometry: margin=2cm
fontsize: 11pt
---

# 상훈 | Full-stack Developer

> "측정하고, 개선하고, 문서화하는 개발자"

**Email**: your@email.com | **GitHub**: github.com/yourname | **Phone**: 010-0000-0000

---

## 👤 About

| 항목 | 내용 |
|------|------|
| **학력** | 건국대학교 (서울캠퍼스) 법학과 졸업 (2015.08) |
| **경력** | 아이오트리 (SI) — 2022.07 ~ 현재 |
| **역할** | Full-stack Developer (Backend & Frontend) |

### Career Timeline

| 기간 | 프로젝트 | 역할 |
|------|----------|------|
| 2024 ~ 현재 | **LinkWave** — 멀티채널 메시징 플랫폼 | Full-stack Developer |
| 2025.10 ~ 2025.11 | **Performance Tester** — 성능 분석 도구 | Frontend Developer |
| 2025.06 ~ 현재 | **Rally-Point** — 테니스 매칭 플랫폼 (개인) | Full-stack Developer |
| 2022 ~ 2024 | **Mafra** — 상담 시스템 | Backend/Frontend Developer |

---

## 🎯 핵심 성과

| 지표 | 성과 | 프로젝트 |
|------|------|----------|
| **성능 최적화** | 렌더링 시간 90% 단축 (5초 → 0.5초) | Performance Tester |
| **데이터베이스 최적화** | 조회 성능 80% 향상 | LinkWave |
| **학습 습관** | 6권 이상 기술 서적 학습 | Real MySQL, Spring, React 등 |
| **프로젝트 경험** | 3개 회사 프로젝트 완료 | LinkWave, Performance Tester, Mafra |

---

## 💼 프로젝트 경험

### 1. LinkWave - Multi-channel Messaging Platform ★

**회사**: IoTree Inc. | **기간**: 2024년 ~ 현재 | **역할**: Full-stack Developer

**프로젝트 개요**
- B2B SaaS 멀티채널 메시징 플랫폼 (SMS/LMS/MMS)
- 사용자/조직 관리, 메시지 발송, 주소록 관리 등

**핵심 기여**

**1) Hybrid Database Strategy 설계 및 구현**
- **문제**: User/Organization은 CRUD 중심, Message/Log는 대용량 쓰기가 필요
- **해결**: 도메인별로 다른 기술 선택
  - User/Organization: JPA (생산성)
  - Message/Log: MyBatis (성능)
- **결과**: 조회 성능 80% 향상, 생산성과 성능 모두 달성

**2) JWT RS256 인증 시스템 구현**
- **문제**: HS256 (대칭키)는 보안 위험
- **해결**: RS256 (Public/Private Key)로 마이그레이션
- **결과**: 보안성 향상, 확장 가능한 인증 시스템

**3) 중복 방지 시스템 (DEDUP_HASH)**
- **문제**: 사용자 실수로 중복 메시지 발송
- **해결**: MD5 해시 기반 중복 검사 (`phone|content`)
- **결과**: 중복 메시지 99% 차단

**4) 월별 파티션 테이블 설계**
- **문제**: 발송 이력 테이블 급격히 증가 (일 10만+ 건)
- **해결**: 월별 파티션 테이블 + 복합 인덱스 전략
- **결과**: 조회 성능 80% 향상, 인덱스 크기 86% 감소

**5) 디자인 시스템 구축 (Frontend)**
- **철학**: "Clarity Through Connection"
- **구현**: shadcn/ui + Tailwind CSS 기반 컴포넌트 라이브러리
- **결과**: 일관된 UI/UX, 개발 속도 향상

**기술 스택**
- Backend: Spring Boot 4.0, Java 21, JPA, MyBatis, MySQL 8.0
- Frontend: React 19, TanStack Router, Tailwind CSS
- DevOps: GitLab CI/CD, Docker, Nginx

**배운 점**
- "은탄환은 없다" - 상황에 맞는 기술 선택의 중요성
- 이론(Real MySQL 8.0)을 실전(LinkWave)에 즉시 적용
- 측정 기반 최적화 (EXPLAIN, 실행 계획 분석)

---

### 2. Performance Tester - React 19 성능 분석 도구

**기간**: 2025년 10-11월 (5주) | **역할**: Frontend Developer (전담)

**프로젝트 개요**
- 웹 애플리케이션 성능 테스트 결과 분석 도구
- 동적 파라미터 간 상관관계 자동 추출
- JMeter 테스트 스크립트 최적화

**핵심 기여**

**1) 대용량 데이터 테이블 렌더링 최적화**
- **문제**: 10,000개 데이터 렌더링 시 브라우저 멈춤 (5초 소요)
- **해결 과정**:
  - 1차: 서버 사이드 페이징 (100개) → UX 문제
  - 2차: 페이징 500개 → 개선되었지만 부족
  - 3차: 페이징 1000개 + TanStack Virtual 가상화
- **결과**:
  - 렌더링 시간 90% 단축 (5초 → 0.5초)
  - 메모리 사용량 70% 감소

**2) 불필요한 API 요청 제거**
- **문제**: 중복 요청, 조건 없는 요청, 무한 루프
- **해결**: React Query 캐싱 전략
  - `staleTime`: 5분 (데이터 신선도)
  - `gcTime`: 10분 (캐시 보관)
  - `enabled`: 조건부 쿼리
- **결과**: 네트워크 요청 80% 감소

**3) 사용자 경험 개선**
- 검색 중 성능 테스트 변경 방지 (버튼 disable)
- 로딩 상태 시각화 (Spinner + Progress bar)
- 특수문자 유효성 검사
- 툴팁으로 긴 텍스트 미리보기

**기술 스택**
- React 19, TypeScript, Vite
- TanStack Query, Table, Virtual
- Tailwind CSS, Radix UI
- React Hook Form, Zod

**배운 점**
- 성능 최적화는 측정과 점진적 개선이 중요
- React DevTools Profiler로 병목 지점 파악
- 완벽한 설계는 없다, 지속적 개선이 핵심

---

### 3. Rally-Point - MSA 테니스 코트 예약 플랫폼

**기간**: 2025년 6월 ~ 현재 | **역할**: Full-stack Developer (개인 프로젝트)

**프로젝트 개요**
- MSA 기반 테니스 코트 예약, 매칭, 중고 거래 통합 플랫폼
- 9개 서비스로 도메인 분리

**핵심 기여**

**1) MSA 아키텍처 설계**
- 도메인: user, court, match, market, bid, notification, search, batch, gateway
- Bounded Context 정의
- 서비스 간 통신 (Kafka, REST)

**2) Kafka 이벤트 기반 아키텍처**
- 예약 생성/취소 이벤트 발행 (`reservation-events`)
- 도메인 간 이벤트 전파
- 실패 처리 및 재시도 전략 (DLQ)

**3) Redis 활용 전략**
- 캐싱: 예약 현황 빠른 조회
- 세션 관리: JWT 토큰 관리
- 분산 락: 동시 예약 방지 (Redisson)
- 대기열 관리: Redis List

**4) Spring Batch**
- 만료 예약 정리
- 보고서 생성 (일/주/월)
- 대기열 일괄 처리

**기술 스택**
- Backend: Spring Boot, Kotlin, Java
- Messaging: Kafka, Redis
- Search: Elasticsearch
- Batch: Spring Batch
- Gateway: Spring Cloud Gateway

**배운 점**
- MSA 설계: Bounded Context의 중요성
- 이벤트 기반 아키텍처: Event Sourcing, Saga Pattern
- 운영 고려사항: 모니터링, 메시지 보장

---

## 🛠️ 기술 스택

### Backend
- **언어**: Java 21, Kotlin
- **프레임워크**: Spring Boot 4.0, Spring Security, Spring Data JPA
- **데이터베이스**: MySQL 8.0, JPA/Hibernate, MyBatis
- **메시징**: Kafka, Redis
- **기타**: Spring Batch, Elasticsearch

### Frontend
- **언어**: TypeScript, JavaScript
- **프레임워크**: React 19, Next.js
- **라이브러리**: TanStack Query, Router, Table, Virtual
- **스타일링**: Tailwind CSS, shadcn/ui
- **도구**: Vite

### DevOps
- **CI/CD**: GitLab CI/CD, GitHub Actions
- **컨테이너**: Docker, Docker Compose
- **웹서버**: Nginx
- **버전관리**: Git

---

## 📚 학습 여정

### 학습한 서적 (6+권)
1. **Real MySQL 8.0** - 실행 계획, 인덱스, 파티션 → LinkWave 프로젝트 적용
2. **자바의 신** - Java 기초부터 심화
3. **자바 알고리즘 인터뷰 with 코틀린** - 알고리즘 & 자료구조
4. **LLM을 활용한 실전 AI 애플리케이션 개발** - LLM, 트랜스포머
5. **StreetCoder** - 실용적인 코딩 기법
6. **알고리즘 문제 해결을 위한 수학** - 알고리즘 & 수학

### 학습 방법
```
이론 학습 (책/강의) → 실전 적용 (프로젝트) → 문서화 (Obsidian) → 회고 (KPT)
```

### 예시: Real MySQL → LinkWave
- Real MySQL 8.0 학습 → 월별 파티션 테이블 개념 습득 → LinkWave 프로젝트에 적용 → 조회 성능 80% 향상

---

## 💡 개발 철학

### 1. 측정한다 (Measure)
> "추측이 아닌 측정으로 개선한다"

- React DevTools Profiler로 병목 지점 파악
- Chrome DevTools로 네트워크 요청 분석
- EXPLAIN으로 쿼리 실행 계획 확인

### 2. 개선한다 (Improve)
> "점진적 개선의 힘을 믿는다"

- Performance Tester: 100 → 500 → 1000개 페이징으로 점진적 개선
- LinkWave: 단일 테이블 → 월별 파티션으로 최적화
- 완벽한 설계는 없다, 지속적 개선이 중요

### 3. 문서화한다 (Document)
> "배운 것을 공유한다"

- PARA 방법론으로 체계적 관리
- 프로젝트 아키텍처 문서 작성
- 학습 노트를 Obsidian으로 정리

---

## 🎓 실무 경험

### Mafra 프로젝트 (상담 시스템)
**역할**: Backend/Full-stack Developer

**담당 기능 (15+)**
- SMS 메시지 리스트 표시, 알림 관리, 악성 민원 관리
- 고객 정보 관리, 메뉴 관리, 콜백 관리
- 접속 로그 관리, QA 수행, 상담 유형 관리
- 캠페인 관리, 사이트 링크 관리

**배운 점**
- Spring Boot CRUD 구현
- 데이터베이스 설계 및 쿼리 최적화
- Git 협업, 이슈 트래킹, QA 프로세스

---

## 🌱 성장 가능성

### 지속적인 학습
- 6권 이상 기술 서적 학습
- PARA 방법론으로 체계적 지식 관리
- 매일 KPT 형식 로그 작성

### 최신 기술 학습
- React 19 (최신 버전, 2024년 12월 릴리즈)
- Spring Boot 4.0 & Java 21
- TanStack 생태계 (Query v5, Table v8)

### 실전 적용
- 학습한 내용을 프로젝트에 즉시 적용
- Real MySQL → LinkWave (조회 성능 80% 향상)
- TanStack → Performance Tester (렌더링 90% 개선)

### 문제 해결 능력
- 초기 설계 미흡 → 점진적 개선으로 최적화
- 측정 기반 의사결정
- 사용자 피드백 반영

---

## 📫 연락처

**Email**: your@email.com
**GitHub**: github.com/yourname
**LinkedIn**: linkedin.com/in/yourname
**Blog**: yourname.github.io
**Phone**: 010-0000-0000

---

## 부록: 프로젝트 상세

### LinkWave - 기술적 도전과 해결

#### 1. Hybrid Database Strategy

**설계 결정 과정:**
```
1. 문제 인식
   - User/Organization: CRUD 중심, 관계 복잡
   - Message/Log: 대용량 쓰기, 복잡한 쿼리

2. 학습
   - Real MySQL 8.0 책 읽기
   - JPA vs MyBatis 비교 분석

3. 결정
   - User/Organization → JPA (생산성)
   - Message/Log → MyBatis (성능)

4. 결과
   - 조회 성능 80% 향상
   - 생산성과 성능 균형 달성
```

**구현 예시 (JPA):**
```java
@Entity
public class User {
    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID userId;

    @ManyToOne(fetch = FetchType.LAZY)
    private Organization organization;
}
```

**구현 예시 (MyBatis):**
```java
@Mapper
public interface UmsMsgMapper {
    void insertMessage(UmsMsg msg);

    boolean existsByDedupHashAndReqDateAfter(
        @Param("dedupHash") String dedupHash,
        @Param("reqDate") LocalDateTime reqDate
    );
}
```

**월별 파티션 테이블:**
```sql
CREATE TABLE ums_log_202501 (
    log_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    req_date DATETIME NOT NULL,
    dedup_hash VARCHAR(32),

    INDEX idx_req_date (req_date),
    INDEX idx_dedup_hash (dedup_hash, req_date)
) ENGINE=InnoDB;
```

**성과:**
- 조회 시간: 15초 → 3초 (80% 향상)
- 인덱스 크기: 5GB → 700MB/월 (86% 감소)

---

#### 2. JWT RS256 인증

**구현:**
```java
@Service
public class JwtService {
    private final PrivateKey privateKey;
    private final PublicKey publicKey;

    public String generateAccessToken(User user) {
        return Jwts.builder()
            .subject(user.getUserId().toString())
            .claim("username", user.getUsername())
            .claim("role", user.getUserRole().name())
            .signWith(privateKey, SignatureAlgorithm.RS256)
            .compact();
    }

    public Claims validateToken(String token) {
        return Jwts.parser()
            .verifyWith(publicKey)
            .build()
            .parseSignedClaims(token)
            .getPayload();
    }
}
```

**성과:**
- 보안성 향상 (Public Key 검증)
- 확장 가능한 인증 시스템

---

### Performance Tester - 최적화 과정

#### 가상화 렌더링

**구현:**
```typescript
const rowVirtualizer = useVirtualizer({
  count: data.length,
  getScrollElement: () => parentRef.current,
  estimateSize: () => 35,
  overscan: 10,
});

return (
  <div ref={parentRef} style={{ height: '600px', overflow: 'auto' }}>
    <div style={{ height: `${rowVirtualizer.getTotalSize()}px` }}>
      {rowVirtualizer.getVirtualItems().map((virtualRow) => (
        <TableRow key={virtualRow.index}>
          {/* 화면에 보이는 행만 렌더링 */}
        </TableRow>
      ))}
    </div>
  </div>
);
```

**성과:**
- 10,000개 행도 부드럽게 스크롤
- 메모리 사용량 70% 감소

---

#### React Query 캐싱

**구현:**
```typescript
const { data, isLoading } = useQuery({
  queryKey: ['correlation-source', perfTestId, pagination],
  queryFn: () => fetchCorrelationSource(perfTestId, pagination),
  staleTime: 1000 * 60 * 5,  // 5분 캐싱
  gcTime: 1000 * 60 * 10,    // 10분 GC
  enabled: !!perfTestId,      // 조건부 쿼리
});
```

**성과:**
- API 요청 80% 감소
- 로딩 상태 자동 관리

---

**작성일**: 2025년 1월 17일
**문서 버전**: v1.0
**페이지 수**: 약 10페이지
