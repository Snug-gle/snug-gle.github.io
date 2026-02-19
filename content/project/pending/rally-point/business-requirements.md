---
tags:
  - project
  - rally-point
  - requirements
  - user-service
category: project
status: in-progress
created: 2025-10-29
modified: 2025-10-29
---
# RallyPoint User Service - 비즈니스 요구사항

## 1. 핵심 기능 요구사항

### 1.1 회원 관리 (User Management)

#### ✅ 이미 구현된 기능
- 회원가입 (이메일, 비밀번호 기반)
- JWT 기반 인증
- OAuth2 소셜 로그인 (Kakao)
- 기본 프로필 관리

#### 📋 추가 개발이 필요한 기능

##### 회원가입 확장
- [ ] 이메일 인증 프로세스
  - 회원가입 시 인증 메일 발송
  - 인증 링크 클릭으로 계정 활성화
  - 미인증 계정 일정 기간 후 자동 삭제 (7일)

- [ ] 추가 소셜 로그인 연동
  - Google OAuth2
  - Naver OAuth2
  - Apple Sign In

- [ ] 회원 등급 시스템
  - ROOKIE: 신규 가입자 (0-10 매치)
  - INTERMEDIATE: 중급 (11-50 매치)
  - ADVANCED: 고급 (51-100 매치)
  - PRO: 프로 (101+ 매치)
  - VIP: 유료 멤버십 회원

##### 프로필 관리 확장
- [ ] 상세 프로필 정보
  - 테니스 경력 (년수)
  - 선호 포지션 (단식/복식)
  - NTRP 레벨 (1.0 ~ 7.0)
  - 선호 플레이 시간대
  - 자기소개

- [ ] 프로필 사진 관리
  - 이미지 업로드 (S3 연동)
  - 썸네일 자동 생성
  - 프로필 사진 이력 관리

- [ ] 플레이 스타일 태그
  - 공격형/수비형/밸런스형
  - 베이스라인/네트플레이
  - 커스텀 태그 추가 가능

##### 보안 및 인증
- [ ] 비밀번호 정책 강화
  - 최소 8자, 영문/숫자/특수문자 조합
  - 비밀번호 변경 이력 관리
  - 최근 3개 비밀번호 재사용 방지

- [ ] 2단계 인증 (2FA)
  - TOTP 기반 (Google Authenticator)
  - SMS 인증 (선택적)

- [ ] 세션 관리
  - 다중 디바이스 세션 관리
  - 의심스러운 로그인 감지 및 알림
  - 원격 로그아웃 기능

### 1.2 회원 활동 추적 (User Activity Tracking)

- [ ] 플레이 통계
  - 총 매치 수
  - 승률 통계
  - 선호 코트/시간대 분석
  - 월별 활동 그래프

- [ ] 리워드 시스템
  - 활동 포인트 적립
  - 출석 체크 보너스
  - 매치 완료 보상
  - 리뷰 작성 보상

- [ ] 배지 시스템
  - 첫 매치 완료 배지
  - 연속 출석 배지
  - 100회 매치 달성 배지
  - 시즌별 특별 배지

### 1.3 회원 간 상호작용 (User Interaction)

- [ ] 친구 시스템
  - 친구 추가/삭제
  - 친구 요청 승인/거절
  - 친구 목록 관리
  - 친구와 매치 우선 매칭

- [ ] 차단 기능
  - 특정 사용자 차단
  - 차단된 사용자와 매칭 방지
  - 차단 목록 관리

- [ ] 평가 시스템
  - 매치 후 상대방 평가 (1-5 별점)
  - 매너 점수 산출
  - 평가 댓글 기능
  - 신고 기능 (부적절한 행동)

### 1.4 알림 설정 (Notification Preferences)

- [ ] 알림 채널별 설정
  - 이메일 알림
  - SMS 알림
  - 푸시 알림
  - 카카오톡 알림

- [ ] 알림 유형별 제어
  - 예약 확정/취소 알림
  - 매칭 성공 알림
  - 친구 요청 알림
  - 마케팅 알림
  - 시스템 공지 알림

### 1.5 회원 검증 및 관리 (User Verification & Management)

- [ ] MSA 간 사용자 검증 API
  - 사용자 존재 여부 확인
  - 사용자 권한 확인
  - 사용자 상태 확인 (활성/정지/탈퇴)
  - 벌크 사용자 정보 조회

- [ ] 관리자 기능
  - 사용자 검색 및 필터링
  - 사용자 상태 변경 (정지/활성화)
  - 사용자 통계 대시보드
  - 신고 처리 및 제재

### 1.6 탈퇴 및 개인정보 관리

- [ ] 회원 탈퇴
  - 탈퇴 사유 수집
  - 즉시 탈퇴 vs 유예기간 탈퇴 (30일)
  - 탈퇴 후 데이터 보관 정책
  - 재가입 제한 정책

- [ ] 개인정보 다운로드
  - GDPR 준수 데이터 다운로드
  - 활동 내역 다운로드
  - 결제 내역 다운로드

---

## 2. 비기능 요구사항

### 2.1 성능
- 회원가입 API 응답 시간: 1초 이내
- 로그인 API 응답 시간: 500ms 이내
- 동시 접속자 10,000명 처리 가능
- JWT 토큰 검증 시간: 10ms 이내

### 2.2 보안
- 모든 비밀번호 BCrypt 암호화 (strength 12)
- JWT Secret Key 환경변수 관리
- SQL Injection 방지
- XSS 공격 방지
- CSRF 토큰 적용

### 2.3 가용성
- 서비스 가용성: 99.9% (연간 다운타임 8.76시간 이내)
- 자동 헬스체크 (/actuator/health)
- 장애 발생 시 자동 복구

### 2.4 확장성
- Stateless 아키텍처 (JWT 기반)
- Redis 세션 클러스터링 준비
- 수평 확장 가능한 구조

---

## 3. 데이터 모델 확장 요구사항

### 3.1 추가 테이블 설계 필요

```sql
-- 사용자 활동 통계
user_statistics (
  id, user_id, total_matches, win_count,
  total_hours, favorite_court_id, created_at
)

-- 친구 관계
user_friends (
  id, user_id, friend_id, status,
  requested_at, accepted_at
)

-- 사용자 평가
user_ratings (
  id, rater_id, ratee_id, match_id,
  rating, comment, created_at
)

-- 차단 목록
user_blocks (
  id, blocker_id, blocked_id, reason, created_at
)

-- 배지
user_badges (
  id, user_id, badge_type, earned_at
)

-- 알림 설정
user_notification_settings (
  id, user_id, channel, type, enabled
)
```

---

## 4. 외부 연동 요구사항

### 4.1 MSA 서비스 간 연동
- Court Service: 사용자 예약 내역 조회
- Match Service: 사용자 매칭 이력 조회
- Market Service: 사용자 거래 내역 조회
- Notification Service: 알림 발송 요청

### 4.2 외부 서비스 연동
- 이메일 발송: AWS SES or SendGrid
- SMS 발송: AWS SNS or Twilio
- 이미지 저장: AWS S3
- 캐싱: Redis
- 이벤트 브로커: Kafka

---

## 5. 우선순위 로드맵

### Phase 1 (1-2개월)
1. 이메일 인증 프로세스
2. 프로필 확장 (경력, 레벨, 프로필 사진)
3. MSA 사용자 검증 API
4. 친구 시스템 기본 기능

### Phase 2 (3-4개월)
1. 추가 소셜 로그인 (Google, Naver)
2. 평가 시스템
3. 알림 설정 관리
4. 회원 등급 시스템
5. 2단계 인증

### Phase 3 (5-6개월)
1. 플레이 통계 및 분석
2. 리워드 시스템
3. 배지 시스템
4. 관리자 대시보드

### Phase 4 (장기)
1. AI 기반 매칭 추천
2. 개인화된 코칭 제안
3. 게임화 요소 확대

---

**작성일**: 2025-10-29
**작성자**: Claude Code
**상태**: 초안 (v1.0)
