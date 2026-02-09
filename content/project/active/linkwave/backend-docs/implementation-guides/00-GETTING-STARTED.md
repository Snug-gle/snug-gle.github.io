---
created: 2025-12-26
---
# LinkWave 구현 가이드 시작하기

## 📚 개요

이 가이드는 LinkWave 프로젝트의 백엔드를 **직접 구현**하기 위한 단계별 가이드입니다.

### 🎯 학습 목표

- Spring Security + JWT 인증 시스템 이해
- CQRS 패턴 (JPA + MyBatis) 활용
- SNAP Agent 연동을 통한 메시지 발송
- 통계 집계 및 대시보드 구현

---

## 🏗️ 전체 아키텍처

```
┌─────────────────────────────────────────────────────────────┐
│                    Presentation Layer                        │
│  AuthController, MessageController, StatisticsController     │
└─────────────────────┬───────────────────────────────────────┘
                      │
┌─────────────────────▼───────────────────────────────────────┐
│                   Application Layer                          │
│  AuthService, MessageService, StatisticsService              │
└─────────────────────┬───────────────────────────────────────┘
                      │
┌─────────────────────▼───────────────────────────────────────┐
│                  Infrastructure Layer                        │
│  JPA: UserRepository, OrganizationRepository                 │
│  MyBatis: UmsMsgMapper, UmsLogQueryMapper                    │
└─────────────────────┬───────────────────────────────────────┘
                      │
┌─────────────────────▼───────────────────────────────────────┐
│                       Database                               │
│  users, organizations, ums_msg, ums_log, ums_stats_daily     │
└─────────────────────────────────────────────────────────────┘
```

---

## 📋 구현 순서

### Phase 1: 예외 처리 및 공통 구조 ⭐ 필수

- ErrorCode enum
- BusinessException
- GlobalExceptionHandler
- ApiResponse, ErrorResponse

👉 **가이드**: [01-EXCEPTION-HANDLING.md](./01-EXCEPTION-HANDLING.md)

---

### Phase 2: Organization 도메인

- Organization Entity
- 개인/법인 사용자 구분
- 휴대폰 인증, 사업자 인증

👉 **가이드**: [02-ORGANIZATION_DOMAIN.md](./02-ORGANIZATION_DOMAIN.md)

---

### Phase 3: JWT 인프라 ⭐ 핵심

- JwtTokenProvider
- RefreshToken Entity
- JwtAuthenticationFilter
- SecurityConfig

👉 **가이드**: [03-JWT-INFRASTRUCTURE.md](./03-JWT-INFRASTRUCTURE.md)

---

### Phase 4: User 도메인 및 인증

- User Entity (CQRS 패턴)
- 회원가입 (JPA), 로그인 (MyBatis)
- 토큰 재발급/로그아웃

👉 **가이드**: [04-USER-AUTH.md](./04-USER-AUTH.md)

---

### Phase 5: 설정 및 권한

- build.gradle.kts
- application.yml
- 서비스별 권한 관리

👉 **가이드**: [05-CONFIGURATION.md](./05-CONFIGURATION.md), [05-SERVICE-PERMISSIONS.md](./05-SERVICE-PERMISSIONS.md)

---

### Phase 6: UMS 메시지 발송 ⭐ 핵심 도메인

- SNAP Agent 연동
- ums_msg 직접 INSERT
- 즉시/예약/대량 발송
- 예약 발송 취소

👉 **가이드**: [06-UMS-MESSAGE-FLOW.md](./06-UMS-MESSAGE-FLOW.md)
👉 **참고**: [SNAP Agent 분석](../SNAP-AGENT-ANALYSIS.md), [SNAP 연동 가이드](../snap/README.md)

---

### Phase 7: 통계 및 분석

- ums_stats_daily 테이블
- 시간별 배치 집계
- 대시보드 API

👉 **가이드**: [07-STATISTICS-ANALYTICS.md](./07-STATISTICS-ANALYTICS.md)

---

## 🚀 시작하기

### 1. 사전 준비

```bash
# Java 21 확인
java -version

# MySQL 8.0+ 실행 확인
mysql --version

# 프로젝트 빌드
./gradlew build
```

### 2. 권장 학습 순서

```
Week 1: 기초
├── Phase 1: 예외 처리 (0.5일)
├── Phase 2: Organization (1일)
├── Phase 3: JWT 인프라 (1.5일) ⭐
└── Phase 4: User 인증 (1일)

Week 2: 설정 및 UMS
├── Phase 5: 설정 파일 (0.5일)
└── Phase 6: UMS 메시지 발송 (2.5일) ⭐

Week 3: 통계 및 고도화
├── Phase 7: 통계 및 분석 (2일)
└── 테스트 및 디버깅 (1일)
```

### 3. 코드 포맷팅

```bash
./gradlew spotlessApply
```

### 4. 테스트

```bash
./gradlew test
```

---

## 💡 학습 팁

### 코드를 직접 타이핑하세요

- ❌ 복사/붙여넣기 → 금방 잊어버림
- ✅ 직접 타이핑 → 손에 익고 이해도 향상

### 디버깅하며 배우세요

```java
// 브레이크포인트 걸고 값 확인
log.debug("userId={}, token={}", userId, token);
```

### 로그를 적극 활용하세요

```java
log.info("메시지 발송 요청: channel={}, count={}", channel, phones.size());
```

---

## 📚 핵심 참고 문서

| 문서                                                         | 설명               |
| ------------------------------------------------------------ | ------------------ |
| [backend-design.md](../backend-design.md)                    | 전체 설계 명세     |
| [SNAP-AGENT-ANALYSIS.md](../SNAP-AGENT-ANALYSIS.md)          | SNAP 에이전트 분석 |
| [IMPLEMENTATION-CHECKLIST.md](./IMPLEMENTATION-CHECKLIST.md) | 구현 체크리스트    |

---

## 🆘 문제 해결

1. **에러 로그를 자세히 읽으세요**
2. **디버거로 변수 값을 확인하세요**
3. **각 가이드의 "자주하는 실수" 섹션을 확인하세요**

---

**준비되셨나요? Phase 1부터 시작해봅시다!** 👉 [01-EXCEPTION-HANDLING.md](./01-EXCEPTION-HANDLING.md)
