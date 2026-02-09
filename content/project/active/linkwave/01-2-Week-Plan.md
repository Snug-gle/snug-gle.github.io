---
created: 2025-12-26
---
# LinkWave: 2주 집중 개발 계획 (2025-12-27 ~ 2026-01-09)

이 문서는 앞으로 2주간 진행할 핵심 기능 개발 계획을 정의합니다. 목표는 **인증된 사용자가 실제로 메시지를 발송**하는 End-to-End 흐름을 완성하는 것입니다.

## 최우선 목표 (Sprint Goal)

> **사용자가 로그인하고, 메시지를 작성하여, 성공적으로 발송 요청을 보낼 수 있다.**

## 주차별 개발 계획

### 1주차 (2025-12-27 ~ 2026-01-02): 인증 시스템 완성

1주차 목표는 백엔드와 프론트엔드의 인증 시스템을 완전히 연동하여, 안전한 API 통신 기반을 마련하는 것입니다.

#### 백엔드 (Backend)
- **Task 1: JWT 인프라 구현**
  - `JwtTokenProvider`, `CustomUserDetailsService` 등 Spring Security 관련 클래스 구현.
  - Access Token 및 Refresh Token 발급 로직 구현 (`AuthService`).
  - `SecurityConfig` 설정을 통해 API 엔드포인트별 접근 제어 (permit all, authenticated).
- **Task 2: 인증 API 완성**
  - 로그인 API: `passwordEncoder.matches`를 사용한 비밀번호 검증 및 토큰 발급.
  - 토큰 갱신 API: Refresh Token을 받아 새로운 Access Token 발급.
  - 로그아웃 API: DB에 저장된 Refresh Token 삭제.

#### 프론트엔드 (Frontend)
- **Task 3: API 타입 및 함수 정의**
  - `src/types/` 디렉토리에 API 요청/응답 타입 정의 (Login, Signup 등).
  - `src/api/authApi.ts`에 실제 API 호출 함수 구현.
- **Task 4: 로그인 페이지 연동**
  - `/login` 페이지에서 실제 `authApi.login` 호출.
  - 성공 시 `authStore`와 `userStore`에 사용자 정보 및 토큰 저장.
  - API 에러 발생 시 사용자에게 피드백 표시.
- **Task 5: 회원가입 플로우 연동**
  - 단계별 회원가입 컴포넌트에서 `signupApi` 호출 로직 연동.
  - 회원가입 성공 시 자동 로그인 처리.

### 2주차 (2026-01-05 ~ 2026-01-09): 핵심 메시지 발송 기능 구현

2주차 목표는 1주차에 구현된 인증을 바탕으로, 실제 메시지(SMS)를 발송하는 핵심 기능을 구현하는 것입니다.

#### 백엔드 (Backend)
- **Task 6: 메시지 발송 API 구현 (MyBatis)**
  - `UmsMsgMapper` (MyBatis) 인터페이스 및 XML 쿼리 작성 (메시지 `INSERT`).
  - MySQL 기반 중복 발송 방지 로직 구현 (`SELECT` + `INSERT`).
- **Task 7: `MessageService` 구현**
  - 메시지 발송 요청을 받아 `UmsMsg` 객체를 생성하고 `UmsMsgMapper`를 통해 DB에 저장.
  - `clientKey`, `dedupHash` 등 주요 값 생성 로직 구현.
  - `@Transactional`을 사용하여 메시지 저장 및 통계 업데이트의 원자성 보장.

#### 프론트엔드 (Frontend)
- **Task 8: 메시지 발송 폼 상태 관리**
  - `src/stores/messageFormStore.ts`를 구현하여 수신자, 내용, 발송 옵션 등 폼 상태 관리.
- **Task 9: SMS 발송 페이지 연동**
  - `/sms` 페이지에서 `messageFormStore`의 상태를 이용해 UI 렌더링.
  - '발송' 버튼 클릭 시 `messageApi.sendMessage` 호출.
  - 발송 요청 성공/실패에 따른 사용자 피드백 (e.g., react-hot-toast).

## 예상 결과물 (2주 후)

- 사용자는 웹사이트를 통해 회원가입하고 로그인할 수 있다.
- 로그인한 사용자는 SMS 발송 페이지에서 수신자 번호와 메시지 내용을 입력하여 발송을 요청할 수 있다.
- 발송된 요청은 백엔드 DB(`ums_msg` 테이블)에 정상적으로 기록된다.
- 모든 API 요청은 JWT 토큰을 통해 인증된다.
