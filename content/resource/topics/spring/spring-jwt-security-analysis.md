---
tags: [spring, jwt, security, vulnerabilities, enhancement, blacklist, refresh-token-rotation]
category: spring
created: 2026-01-22
status: complete
description: JWT 인증 로직의 보안 취약점을 분석하고 Access Token Blacklist 및 Refresh Token Rotation 강화를 통해 보안을 강화하는 가이드
---

# JWT 인증 보안 취약점 분석 및 강화 가이드

> JWT 기반 인증 시스템에서 발견된 주요 보안 취약점들을 심층적으로 분석하고, Access Token Blacklist 및 Refresh Token Rotation 강화 메커니즘을 통해 보안 수준을 향상시키는 실전 가이드입니다.

---

## 개요
이 문서는 JWT 기반 인증 시스템에서 흔히 발생할 수 있는 보안 취약점들을 상세히 분석합니다. 특히 로그아웃 후 Access Token 재사용 문제와 Refresh Token 재사용 시도에 대한 방어 미흡 문제를 중심으로 다루며, 이를 해결하기 위한 Access Token Blacklist 구현 및 Refresh Token Rotation 강화 방안을 제시합니다.

## Part 1: JWT 인증 로직 보안 취약점 분석 (2026-01-22)

# JWT 인증 로직 보안 취약점 분석 (2026-01-22)

## 1. 개요

기존 인증 시스템의 로그아웃 및 토큰 재발급 과정에서 두 가지 주요 보안 취약점이 발견되었습니다. 이 문서는 각 취약점의 원인과 잠재적 위험 시나리오를 기술합니다.

---

## 2. 취약점 상세 분석

### 취약점 1: 로그아웃 후에도 Access Token 재사용 가능

-   **현상:** 사용자가 로그아웃을 해도, 만료되지 않은 Access Token이 즉시 무효화되지 않았습니다.
-   **원인:** `AuthService`의 `logout` 로직이 Redis에 저장된 Refresh Token만 삭제하고, Access Token에 대해서는 아무런 조치를 취하지 않았습니다.
-   **위험 시나리오:**
    1.  **토큰 탈취:** 공격자가 XSS, 중간자 공격(MITM) 등의 방법으로 특정 사용자의 Access Token을 탈취합니다. (예: 만료 시간 30분 남음)
    2.  **사용자 로그아웃:** 사용자는 토큰 탈취 사실을 인지하지 못하고 정상적으로 서비스를 이용한 후 로그아웃합니다. 서버는 Refresh Token을 삭제합니다.
    3.  **공격자 악용:** 공격자는 탈취한 Access Token을 사용하여 서버에 API 요청을 보냅니다.
    4.  **서버 오판:** 서버는 해당 Access Token이 유효한 서명을 가지고 있고 아직 만료되지 않았으므로, 정상적인 요청으로 오인하고 민감한 정보(예: 사용자 프로필)를 응답합니다. 공격자는 토큰이 만료될 때까지 계속해서 사용자의 권한을 도용할 수 있습니다.

### 취약점 2: Refresh Token 재사용 시도에 대한 방어 미흡

-   **현상:** 만료되었거나 탈취된 Refresh Token을 사용하여 재발급을 시도할 경우, 서버가 이를 거절만 할 뿐 추가적인 보안 조치를 취하지 않았습니다.
-   **원인:** `AuthService`의 `refresh` 로직에서, 클라이언트가 보낸 Refresh Token과 Redis에 저장된 토큰이 일치하지 않으면 단순히 `INVALID_TOKEN` 예외만 발생시켰습니다.
-   **위험 시나리오 (Refresh Token Rotation Attack):**
    1.  **토큰 탈취:** 공격자가 사용자의 Refresh Token(`refresh-v1`)을 탈취합니다.
    2.  **사용자 재발급:** 정상 사용자가 Access Token 만료로 인해 재발급을 요청합니다. 서버는 새로운 Access Token과 새로운 Refresh Token(`refresh-v2`)을 발급하고, 저장소의 토큰을 `refresh-v2`로 업데이트합니다.
    3.  **공격자 재사용 시도:** 공격자가 이전에 탈취했던 `refresh-v1`을 사용하여 토큰 재발급을 시도합니다.
    4.  **기존 시스템의 대응:** 서버는 저장된 `refresh-v2`와 공격자가 보낸 `refresh-v1`이 일치하지 않음을 확인하고 "유효하지 않은 토큰"이라고 거절합니다.
    5.  **문제점:** 여기서 공격은 실패했지만, 서버는 '누군가 비정상적인 토큰으로 재발급을 시도했다'는 사실을 인지하고도 **아무런 후속 조치를 하지 않습니다.** 정상 사용자는 계속 `refresh-v2`로 서비스를 이용할 수 있으며, 자신의 계정이 공격받고 있다는 사실조차 알 수 없습니다. 이는 잠재적인 계정 탈취 시도를 탐지하고 대응할 기회를 놓치는 것입니다. 더 안전한 방법은, 이런 불일치 시도가 감지되면 즉시 모든 세션을 만료시켜 사용자에게 비정상적인 활동이 있었음을 알리고 재로그인을 유도하는 것입니다.

## Part 2: JWT 인증 보안 강화 가이드 (2026-01-22)

# JWT 인증 보안 강화 가이드 (2026-01-22)

## 1. 개요

본 문서는 JWT(JSON Web Token) 기반 인증 시스템에서 발견된 두 가지 주요 보안 취약점(로그아웃 후 Access Token 재사용 가능, Refresh Token 재사용 시도 방어 미흡)을 해결하기 위한 구현 상세 가이드와, 이를 통해 얻은 보안 관련 개발 경험을 공유합니다.

---

## 2. 구현 상세 가이드

### 2.1. Access Token Blacklist를 이용한 즉시 무효화

로그아웃 시 Access Token이 즉시 무효화되도록 Blacklist 메커니즘을 도입했습니다.

#### 2.1.1. Access Token Blacklist Store 구현 (`AccessTokenBlacklistStore.java`)

Redis를 활용하여 블랙리스트에 등록된 Access Token을 관리하는 컴포넌트를 새로 생성했습니다. 토큰의 남은 유효 시간 동안만 Redis에 저장됩니다.

-   **파일:** `src/main/java/io.iotree.linkwave/infra/redis/AccessTokenBlacklistStore.java`
-   **주요 기능:**
    *   `blacklist(String accessToken, long expiryMillis)`: Access Token을 블랙리스트에 추가하고, 남은 만료 시간만큼만 유지합니다.
    *   `isBlacklisted(String accessToken)`: 특정 Access Token이 블랙리스트에 등록되어 있는지 확인합니다.

#### 2.1.2. JWT Token Provider 수정 (`JwtTokenProvider.java`)

Access Token의 남은 유효 시간을 밀리초 단위로 계산하는 메서드를 추가했습니다.

-   **파일:** `src/main/java/io.iotree.linkwave/common/security/JwtTokenProvider.java`
-   **추가 메서드:** `getRemainingExpirationMillis(String token)`

#### 2.1.3. 인증 컨트롤러 및 서비스 로직 수정 (`AuthController.java`, `AuthService.java`)

로그아웃 요청 시 Access Token을 추출하고 이를 Blacklist에 등록하도록 로직을 수정했습니다.

-   **`AuthController.java` (로그아웃 엔드포인트 수정):**
    *   `HttpServletRequest`를 통해 `Authorization` 헤더에서 Access Token을 추출합니다.
    *   추출된 Access Token과 사용자 이름을 `AuthService.logout` 메서드에 전달합니다.
    *   Refresh Token 쿠키를 올바르게 즉시 만료시키도록 `ResponseCookie`를 사용하여 `maxAge(0)`으로 설정했습니다.
-   **`AuthService.java` (로그아웃 메서드 수정):**
    *   메서드 시그니처를 `logout(String username, String accessToken)`으로 변경했습니다.
    *   주입받은 `AccessTokenBlacklistStore`를 사용하여 전달받은 Access Token을 블랙리스트에 추가합니다. 이때 `JwtTokenProvider`를 통해 토큰의 남은 유효 시간을 계산하여 전달합니다.
    *   기존 Refresh Token 삭제 로직은 유지됩니다.

#### 2.1.4. JWT 인증 필터 수정 (`JwtAuthenticationFilter.java`)

모든 요청 처리 전에 Access Token이 블랙리스트에 등록되어 있는지 확인하는 로직을 추가했습니다.

-   **파일:** `src/main/java/io.iotree.linkwave/common/security/JwtAuthenticationFilter.java`
-   **추가 로직:** 토큰 유효성 검증 후, `AccessTokenBlacklistStore.isBlacklisted(token)`을 호출하여 토큰이 블랙리스트에 있다면 `BusinessException(ErrorCode.INVALID_TOKEN)`을 발생시켜 요청을 거부합니다.

### 2.2. Refresh Token 탈취 대응 강화

Refresh Token 불일치 감지 시 즉각적인 세션 무효화를 통해 보안을 강화했습니다.

#### 2.2.1. 인증 서비스 로직 수정 (`AuthService.java`)

토큰 재발급 과정에서 Refresh Token 불일치가 발생하면, 단순히 에러를 반환하는 것을 넘어 현재 저장된 Refresh Token을 강제로 삭제하여 해당 사용자의 모든 세션을 무효화합니다.

-   **파일:** `src/main/java/io.iotree.linkwave/application/service/AuthService.java`
-   **수정 내용:** `refresh` 메서드 내 `if (!refreshTokenStore.matches(user.userId(), currentRefreshToken))` 블록 안에서, `BusinessException`을 throw하기 전에 `refreshTokenStore.delete(user.userId())`를 추가했습니다.

---

## 3. 개발 경험을 통해 알게 된 점 (Lessons Learned)

### 3.1. JWT의 Stateless 특성과 즉시 무효화의 필요성

JWT의 주요 장점은 서버가 사용자 세션 상태를 저장할 필요가 없어 확장성이 뛰어나다는 점(Stateless)입니다. 그러나 이 특성은 로그아웃 시 기존에 발급된 Access Token을 서버 측에서 즉시 무효화하기 어렵게 만듭니다. Access Token Blacklist는 이러한 JWT의 본질적인 제약을 보완하여, 사용자가 로그아웃했음에도 불구하고 만료 시간까지 유효한 Access Token을 악용하는 것을 방지하는 필수적인 보안 메커니즘입니다. 즉, 순수하게 Stateless한 JWT를 사용하면서도 '즉시 무효화'라는 Stateful한 요구사항을 만족시키기 위한 현실적인 절충안입니다.

### 3.2. Refresh Token Rotation 및 탈취 시도 방어의 중요성

Refresh Token은 Access Token보다 긴 유효 기간을 가지므로, 탈취되었을 경우 더 큰 위험을 초래할 수 있습니다. `refresh` 과정에서 `refreshTokenStore.matches()`를 통해 클라이언트가 제공한 Refresh Token과 서버에 저장된 토큰을 비교하는 것은 매우 중요합니다.
여기에 더해, 만약 이 두 토큰이 일치하지 않을 경우(예: 공격자가 오래된 또는 탈취된 Refresh Token으로 재사용을 시도할 때), 단순히 요청을 거부하는 것을 넘어 **서버에 저장된 모든 Refresh Token을 즉시 삭제**하는 것이 강력한 보안 조치입니다. 이는 일명 "Refresh Token Rotation Attack" 방어 전략의 핵심입니다. 공격 시도를 감지하면 해당 사용자의 모든 활성 세션을 강제로 종료시켜, 공격자가 탈취한 토큰을 사용하여 추가적인 Access Token을 발급받지 못하도록 완전히 차단합니다. 이를 통해 사용자는 재로그인을 요구받게 되어 비정상적인 활동이 있었음을 인지하게 되고, 관리자도 공격 시도를 포착할 수 있는 단서를 얻을 수 있습니다.