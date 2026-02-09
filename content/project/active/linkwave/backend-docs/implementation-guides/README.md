---
created: 2025-12-26
---
# LinkWave 구현 가이드

이 문서는 LinkWave 프로젝트의 백엔드 아키텍처와 핵심 기능 구현 방법을 안내합니다.

---

## 📌 시작하기

### ⭐ 필독 문서

| 문서 | 설명 |
|------|------|
| [00-GETTING-STARTED.md](./00-GETTING-STARTED.md) | **전체 로드맵**, Phase별 구현 순서 |
| [IMPLEMENTATION-CHECKLIST.md](./IMPLEMENTATION-CHECKLIST.md) | 구현 체크리스트 및 실무 인사이트 |

---

## 📚 구현 가이드 목차

### Phase 1-5: 인증 및 기초

| Phase | 문서 | 주제 | 핵심 내용 |
|:-----:|------|------|----------|
| 1 | [01-EXCEPTION-HANDLING.md](./01-EXCEPTION-HANDLING.md) | 예외 처리 | ErrorCode, BusinessException, GlobalExceptionHandler |
| 2 | [02-ORGANIZATION_DOMAIN.md](./02-ORGANIZATION_DOMAIN.md) | Organization 도메인 | 개인/법인 구분, 휴대폰 인증 |
| 3 | [03-JWT-INFRASTRUCTURE.md](./03-JWT-INFRASTRUCTURE.md) | JWT 인프라 ⭐ | JwtTokenProvider, SecurityConfig |
| 4 | [04-USER-AUTH.md](./04-USER-AUTH.md) | User 인증 | 회원가입/로그인 (CQRS) |
| 5 | [05-CONFIGURATION.md](./05-CONFIGURATION.md) | 설정 파일 | build.gradle.kts, application.yml |
| 5 | [05-SERVICE-PERMISSIONS.md](./05-SERVICE-PERMISSIONS.md) | 권한 관리 | JSON 기반 서비스 권한 |

### Phase 6-7: 핵심 도메인

| Phase | 문서 | 주제 | 핵심 내용 |
|:-----:|------|------|----------|
| 6 | [06-UMS-MESSAGE-FLOW.md](./06-UMS-MESSAGE-FLOW.md) | **UMS 발송** ⭐ | SNAP 연동, 즉시/예약/대량 발송, 취소 |
| 7 | [07-STATISTICS-ANALYTICS.md](./07-STATISTICS-ANALYTICS.md) | **통계 분석** | 배치 집계, 대시보드 API |

---

## 🏗️ 핵심 참고 문서

| 문서 | 위치 | 설명 |
|------|------|------|
| 백엔드 설계 | [../backend-design.md](../backend-design.md) | 전체 설계 명세, JPA/MyBatis 패턴 |
| SNAP 분석 | [../SNAP-AGENT-ANALYSIS.md](../SNAP-AGENT-ANALYSIS.md) | SNAP Agent 상세 분석 |
| SNAP 연동 | [../snap/README.md](../snap/README.md) | SNAP 연동 가이드 |

---

## 🚀 권장 학습 순서

```
Week 1: 기초 다지기
├── Phase 1: 예외 처리 (0.5일)
├── Phase 2: Organization (1일)
├── Phase 3: JWT 인프라 (1.5일) ⭐ 가장 중요
└── Phase 4: User 인증 (1일)

Week 2: 설정 및 핵심 도메인
├── Phase 5: 설정 파일 (0.5일)
└── Phase 6: UMS 메시지 발송 (2.5일) ⭐

Week 3: 통계 및 고도화
├── Phase 7: 통계 및 분석 (2일)
└── 테스트 및 디버깅 (1일)
```

---

## 💡 학습 팁

### 코드를 직접 타이핑하세요
```java
// ❌ 복사/붙여넣기 → 금방 잊어버림
// ✅ 직접 타이핑 → 손에 익고 이해도 향상
```

### 디버깅하며 배우세요
- 브레이크포인트를 걸고 실행 흐름 따라가기
- 변수 값 확인하며 동작 이해

### 로그를 적극 활용하세요
```java
log.info("📨 메시지 발송: channel={}, count={}", channel, phones.size());
```

---

## 📁 프로젝트 구조

```
src/main/java/io/iotree/linkwave/
├── api/                           # Controller (REST API)
│   ├── AuthController.java
│   ├── MessageController.java
│   └── StatisticsController.java
├── application/                   # Service (비즈니스 로직)
│   ├── service/
│   │   ├── AuthService.java
│   │   ├── MessageService.java
│   │   └── StatisticsService.java
│   └── dto/
│       ├── request/
│       └── response/
├── domain/                        # Entity (도메인 모델)
│   ├── user/
│   │   ├── User.java             # JPA
│   │   └── Organization.java     # JPA
│   ├── message/
│   │   └── UmsMsg.java           # JPA (읽기용)
│   └── statistics/
│       └── UmsStatsDaily.java    # JPA
├── infra/                         # Infrastructure
│   ├── jpa/
│   │   └── repository/
│   └── mybatis/
│       ├── mapper/               # MyBatis Mapper
│       └── dto/                  # MyBatis DTO
├── common/                        # 공통 모듈
│   ├── exception/
│   ├── response/
│   └── security/
└── config/                        # 설정
    ├── SecurityConfig.java
    └── MyBatisConfig.java
```

---

## 🆘 문제 해결

1. **에러 로그를 자세히 읽으세요**
2. **디버거로 변수 값을 확인하세요**
3. **각 가이드의 "자주하는 실수" 섹션을 확인하세요**

---

**준비되셨나요? [00-GETTING-STARTED.md](./00-GETTING-STARTED.md)부터 시작해보세요!** 🎯
