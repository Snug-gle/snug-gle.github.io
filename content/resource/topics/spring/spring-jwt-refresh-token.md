---
tags: [spring, jwt, refresh-token, authentication, redis, rtr, security]
category: spring
created: 2026-01-06
status: complete
description: JWT Refresh Token Rotation(RTR) 패턴과 Redis 기반 토큰 관리를 통한 안전한 인증 시스템 구현 가이드
---

# JWT Refresh Token 구현 가이드: RTR 패턴 및 Redis 기반 관리

> JWT Access Token과 Refresh Token을 활용한 안전한 인증 시스템 구축. Refresh Token Rotation (RTR) 패턴과 Redis 기반 토큰 관리를 심층적으로 다룹니다.

---

## 개요
이 문서는 JWT Access Token과 Refresh Token을 활용하여 안전하고 사용자 친화적인 인증 시스템을 구축하는 가이드입니다. 특히 업계 표준인 Refresh Token Rotation (RTR) 패턴과 Redis 기반 토큰 관리 방식을 심층적으로 다루며, 백엔드와 프론트엔드 양측의 구현 전략 및 보안 고려사항을 상세히 제시합니다.

## Part 1: Refresh Token 구현 가이드 (기본)

# Refresh Token 구현 가이드

## 목차
1. [개요](#개요)
2. [현재 상태 분석](#현재-상태-분석)
3. [Refresh Token 플로우](#refresh-token-플로우)
4. [백엔드 구현 가이드](#백엔드-구현-가이드)
5. [프론트엔드 구현 가이드](#프론트엔드-구현-가이드)
6. [보안 고려사항](#보안-고려사항)

---

## 개요

### 목적
JWT **Access Token**과 **Refresh Token**을 활용한 안전한 인증 시스템을 구축합니다.

### Access Token vs Refresh Token

| 구분 | Access Token | Refresh Token |
|------|--------------|---------------|
| **용도** | API 요청 인증 | Access Token 재발급 |
| **만료 시간** | 짧음 (15분~1시간) | 김 (7일~30일) |
| **저장 위치** | 메모리 (Zustand) | HttpOnly Cookie 또는 localStorage |
| **노출 위험** | 높음 (매 요청마다 전송) | 낮음 (재발급 시에만 사용) |
| **토큰 형식** | JWT (username, role 포함) | UUID (단순 식별자) |

### 왜 Refresh Token이 필요한가?

1. **보안 강화**: Access Token 만료 시간을 짧게 하여 탈취 위험 감소
2. **사용자 경험**: 자동 재로그인으로 원활한 서비스 이용
3. **세션 관리**: Refresh Token 무효화로 강제 로그아웃 가능

---

## 현재 상태 분석

### 백엔드 현황

####이미 구현된 부분

1. **RefreshToken 엔티티** (`domain/RefreshToken.java`)
   ```java
   - id: Long (PK)
   - userId: UUID (사용자 식별)
   - token: String (UUID, unique index)
   - expiresAt: LocalDateTime
   - deviceInfo: String (선택)
   - ipAddress: String (선택)
   - isExpired(): boolean 메서드
   ```

2. **RefreshTokenRepository** (`infra/jpa/repository/RefreshTokenRepository.java`)
   ```java
   - findByToken(String): Optional<RefreshToken>
   - deleteByToken(String): void
   - deleteByUserId(UUID): void
   - findActiveTokensByUserId(UUID, LocalDateTime): List<RefreshToken>
   ```

3. **JwtTokenProvider**
   ```java
   - generateAccessToken(username, role): String (JWT 생성)
   - generateRefreshToken(): String (UUID 생성)
   - validationToken(token): boolean
   - getUsernameFromToken(token): String
   - getRoleFromToken(token): String
   ```

4. **설정 값** (`application.yml`)
   ```yaml
   linkwave.jwt:
     access-token-expiration: 3600000  # 1시간 (밀리초)
     refresh-token-expiration: 604800000  # 7일 (밀리초)
   ```

####미구현된 부분

1. **AuthService에 Refresh Token 저장 로직 없음**
   - 현재 `login()`, `signupAndIssueToken()`에서 Refresh Token 생성/저장 안 함
   - Access Token만 발급

2. **Refresh Token 재발급 API 없음**
   - `POST /api/v1/auth/refresh` 엔드포인트 미구현

3. **프론트엔드에서 Refresh Token 활용 로직 불완전**
   - `client.ts`의 401 처리에서 `/auth/refresh` 호출하지만 백엔드 미구현

---

## Refresh Token 플로우

### 1. 로그인 시

```
사용자 → POST /api/v1/auth/login (username, password)
       ↓
AuthService
  - 인증 검증
  - Access Token 생성 (JWT, 1시간)
  - Refresh Token 생성 (UUID, 7일)
  - Refresh Token → DB 저장 (userId, token, expiresAt)
       ↓
Response: {accessToken, refreshToken, ...}
       ↓
프론트엔드
  - accessToken → Zustand (메모리)
  - refreshToken → localStorage
```

### 2. API 요청 시

```
사용자 → GET /api/v1/user/profile
       ↓
Request Interceptor
  - Authorization: Bearer {accessToken} 추가
       ↓
백엔드 (JwtAuthenticationFilter)
  - Access Token 검증
  - 유효하면 → SecurityContext에 인증 정보 저장 → 요청 처리
  - 만료되면 → 401 Unauthorized 응답
```

### 3. Access Token 만료 시

```
프론트엔드 → GET /api/v1/user/profile
           ↓
           401 Unauthorized
           ↓
Response Interceptor
  - localStorage에서 refreshToken 조회
  - POST /api/v1/auth/refresh (refreshToken 전송)
           ↓
백엔드 (AuthController.refresh)
  - Refresh Token 검증 (DB 조회, 만료 확인)
  - 새 Access Token 생성
  - (선택) Refresh Token 갱신 (Refresh Token Rotation)
           ↓
Response: {accessToken, refreshToken}
           ↓
프론트엔드
  - 새 accessToken → Zustand 업데이트
  - 원래 요청 재시도 (retry)
  - 성공 → 사용자는 로그아웃 없이 계속 사용
```

### 4. Refresh Token 만료 시

```
프론트엔드 → POST /api/v1/auth/refresh
           ↓
           401 Unauthorized (Refresh Token 만료/유효하지 않음)
           ↓
Response Interceptor
  - Zustand 초기화 (logout)
  - /login 페이지로 리다이렉트
```

---

## 백엔드 구현 가이드

### 1단계: DTO 정의

####`application/dto/request/auth/RefreshTokenRequest.java`

```java
package io.iotree.linkwave.application.dto.request.auth;

import jakarta.validation.constraints.NotBlank;

public record RefreshTokenRequest(
    @NotBlank(message = "Refresh Token은 필수입니다.")
    String refreshToken
) {}
```

####`application/dto/response/auth/RefreshTokenResponse.java`

```java
package io.iotree.linkwave.application.dto.response.auth;

import lombok.Builder;

@Builder
public record RefreshTokenResponse(
    String accessToken,
    String refreshToken,  // 선택: Refresh Token Rotation 적용 시
    String tokenType
) {
  public RefreshTokenResponse {
    if (tokenType == null) {
      tokenType = "Bearer";
    }
  }
}
```

**TODO**:
- [ ] RefreshTokenRequest.java 생성
- [ ] RefreshTokenResponse.java 생성

---


### 2단계: AuthService 확장

####`application/service/AuthService.java` (수정)

```java
package io.iotree.linkwave.application.service;

// 기존 import ...
import io.iotree.linkwave.domain.RefreshToken;
import io.iotree.linkwave.infra.jpa.repository.RefreshTokenRepository;
import java.time.LocalDateTime;

@Slf4j
@Service
@RequiredArgsConstructor
public class AuthService {

  private final UserRepository userRepository;
  private final OrganizationRepository organizationRepository;
  private final UserQueryMapper userQueryMapper;
  private final PasswordEncoder passwordEncoder;
  private final JwtTokenProvider jwtTokenProvider;
  private final RefreshTokenRepository refreshTokenRepository;  // 추가

  @Value("${linkwave.jwt.refresh-token-expiration}")
  private long refreshTokenExpiration;

  /**
   * 로그인 (수정)
   */
  @Transactional
  public LoginResponse login(LoginRequest request) {
    log.info("로그인 시도: username={}", request.username());

    // 1. 사용자 조회 및 인증
    UserLoginQueryDto user = 
        userQueryMapper
            .findByUsername(request.username())
            .orElseThrow(() -> new BusinessException(ErrorCode.INVALID_CREDENTIALS));

    if (!passwordEncoder.matches(request.password(), user.password())) {
      throw new BusinessException(ErrorCode.INVALID_CREDENTIALS);
    }

    if (!"ACTIVE".equals(user.status())) {
      throw new BusinessException(ErrorCode.USER_INACTIVE);
    }

    // 2. Access Token 생성
    String accessToken = jwtTokenProvider.generateAccessToken(user.username(), user.role());

    // TODO: 3. Refresh Token 생성 및 저장
    // Hint: jwtTokenProvider.generateRefreshToken() 호출
    // Hint: RefreshToken 엔티티 생성 후 refreshTokenRepository.save()
    // Hint: expiresAt = LocalDateTime.now().plusMillis(refreshTokenExpiration)
    String refreshToken = null; // 구현 필요

    log.info("로그인 성공: userId={}", user.userId());

    return LoginResponse.builder()
        .accessToken(accessToken)
        .refreshToken(refreshToken)  // 추가
        .tokenType("Bearer")
        .userId(user.userId())
        .username(user.username())
        .role(user.role())
        .userType(user.userType())
        .organizationId(user.organizationId())
        .build();
  }

  /**
   * 회원가입 (수정)
   */
  @Transactional
  public LoginResponse signupAndIssueToken(SignUpRequest request) {
    // ... 기존 로직 유지 ...

    // TODO: Refresh Token 생성 및 저장 (login()과 동일한 방식)
    String refreshToken = null; // 구현 필요

    return LoginResponse.builder()
        .accessToken(accessToken)
        .refreshToken(refreshToken)  // 추가
        .tokenType("Bearer")
        // ... 기존 필드들 ...
        .build();
  }

  /**
   * Refresh Token으로 Access Token 재발급
   */
  @Transactional
  public RefreshTokenResponse refreshAccessToken(String refreshToken) {
    log.info("Access Token 재발급 요청");

    // TODO: 1. Refresh Token 조회
    // Hint: refreshTokenRepository.findByToken(refreshToken)
    // Hint: 없으면 ErrorCode.REFRESH_TOKEN_NOT_FOUND 예외
    RefreshToken storedToken = null; // 구현 필요

    // TODO: 2. 만료 확인
    // Hint: storedToken.isExpired()
    // Hint: 만료되었으면 ErrorCode.REFRESH_TOKEN_EXPIRED 예외
    // Hint: 만료된 토큰은 DB에서 삭제

    // TODO: 3. 사용자 조회
    // Hint: userQueryMapper.findByUserId(storedToken.getUserId())
    // Hint: 없으면 ErrorCode.USER_NOT_FOUND 예외
    UserLoginQueryDto user = null; // 구현 필요

    // TODO: 4. 새 Access Token 생성
    String newAccessToken = jwtTokenProvider.generateAccessToken(user.username(), user.role());

    // TODO: 5. (선택) Refresh Token Rotation 적용
    // Hint: 기존 Refresh Token 삭제 후 새로운 Refresh Token 생성
    // Hint: 보안 강화를 위해 권장
    // String newRefreshToken = jwtTokenProvider.generateRefreshToken();
    // refreshTokenRepository.deleteByToken(refreshToken);
    // RefreshToken newToken = RefreshToken.builder()...
    // refreshTokenRepository.save(newToken);

    log.info("Access Token 재발급 완료: userId={}", user.userId());

    return RefreshTokenResponse.builder()
        .accessToken(newAccessToken)
        // .refreshToken(newRefreshToken)  // Rotation 적용 시
        .tokenType("Bearer")
        .build();
  }

  /**
   * 로그아웃 (Refresh Token 무효화)
   */
  @Transactional
  public void logout(UUID userId) {
    // TODO: 사용자의 모든 Refresh Token 삭제
    // Hint: refreshTokenRepository.deleteByUserId(userId)

    log.info("로그아웃: userId={}", userId);
  }
}
```

**구현 인사이트**:
1. **Refresh Token 저장**:
   ```java
   String refreshToken = jwtTokenProvider.generateRefreshToken();
   RefreshToken token = RefreshToken.builder()
       .userId(user.userId())
       .token(refreshToken)
       .expiresAt(LocalDateTime.now().plusMillis(refreshTokenExpiration))
       .build();
   refreshTokenRepository.save(token);
   ```

2. **Refresh Token Rotation**:
  - 재발급 시 기존 Refresh Token 삭제 후 새로운 Refresh Token 발급
  - 보안 강화 (Refresh Token 재사용 방지)
  - 선택사항이지만 권장

3. **만료된 Refresh Token 처리**:
  - `isExpired()` 확인 후 예외 발생
  - DB에서 삭제하여 불필요한 데이터 제거

**TODO**:
- [ ] login()에 Refresh Token 생성/저장 로직 추가
- [ ] signupAndIssueToken()에 Refresh Token 생성/저장 로직 추가
- [ ] refreshAccessToken() 메서드 구현
- [ ] logout() 메서드 구현

---


### 3단계: AuthController 확장

####`api/AuthController.java` (수정)

```java
package io.iotree.linkwave.api;

// 기존 import ...
import io.iotree.linkwave.application.dto.request.auth.RefreshTokenRequest;
import io.iotree.linkwave.application.dto.response.auth.RefreshTokenResponse;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.core.userdetails.UserDetails;

@Slf4j
@RestController
@RequiredArgsConstructor
@RequestMapping("/api/v1/auth")
public class AuthController {

  private final AuthService authService;

  // ... 기존 메서드들 (signup, login, checkUsername) ...

  /**
   * Access Token 재발급
   * POST /api/v1/auth/refresh
   */
  @PostMapping("/refresh")
  public ResponseEntity<ApiResponse<RefreshTokenResponse>> refreshToken(
      @Valid @RequestBody RefreshTokenRequest request) {

    log.info("Access Token 재발급 요청");

    // TODO: AuthService.refreshAccessToken(request.refreshToken()) 호출
    RefreshTokenResponse response = null; // 구현 필요

    return ResponseEntity.ok(ApiResponse.success(response));
  }

  /**
   * 로그아웃
   * POST /api/v1/auth/logout
   */
  @PostMapping("/logout")
  public ResponseEntity<ApiResponse<Void>> logout(
      @AuthenticationPrincipal UserDetails userDetails) {

    log.info("로그아웃 요청: username={}", userDetails.getUsername());

    // TODO: UserService.findUserIdByUsername() 호출하여 userId 추출
    // TODO: AuthService.logout(userId) 호출

    return ResponseEntity.ok(ApiResponse.success(null));
  }
}
```

**TODO**:
- [ ] refreshToken() 엔드포인트 구현
- [ ] logout() 엔드포인트 구현

---


### 4단계: LoginResponse 수정

####`application/dto/response/auth/LoginResponse.java` (수정)

```java
package io.iotree.linkwave.application.dto.response.auth;

import java.util.UUID;
import lombok.Builder;

@Builder
public record LoginResponse(
    String accessToken,
    String refreshToken,  // 추가
    String tokenType,
    String username,      // userId 제거됨 (JWT에서 추출 가능)
    String role,
    String userType,
    UUID organizationId
) {
  public LoginResponse {
    if (tokenType == null) {
      tokenType = "Bearer";
    }
  }
}
```

**변경사항**:
- ✅ **userId 필드 제거**: JWT 토큰에서 username을 추출하여 서버에서 userId 획득
- ✅ **refreshToken 필드 추가**: Refresh Token 저장용

**TODO**:
- [ ] types/auth.ts에 refreshToken 필드 추가
- [ ] types/auth.ts에서 userId 제거

---


### 5단계: ErrorCode 확인

####`common/exception/ErrorCode.java`

```java
// 이미 정의되어 있음 (확인만 하면 됨)

// 인증 관련 (A001-A006)
INVALID_CREDENTIALS (401, "A001", "Invalid credentials"),
INVALID_TOKEN (401, "A002", "Invalid token"),
EXPIRED_TOKEN (401, "A003", "Token has expired"),
REFRESH_TOKEN_NOT_FOUND (401, "A004", "Refresh token not found"),
REFRESH_TOKEN_EXPIRED (401, "A005", "Refresh token has expired"),
UNAUTHORIZED (401, "A006", "Unauthorized"),
```

**TODO**:
- [ ] ErrorCode 확인 (이미 정의되어 있음)

---


### 6단계: 테스트

#### curl로 API 테스트

**1. 로그인**
```bash
curl -X POST http://localhost:8080/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "username": "testuser",
    "password": "password123"
  }'

# 응답
{
  "success": true,
  "data": {
    "accessToken": "eyJhbGciOiJIUzI1...",
    "refreshToken": "f47ac10b-58cc-4372-a567-0e02b2c3d479",
    "tokenType": "Bearer",
    ...
  }
}
```

**2. Refresh Token으로 Access Token 재발급**
```bash
curl -X POST http://localhost:8080/api/v1/auth/refresh \
  -H "Content-Type: application/json" \
  -d '{
    "refreshToken": "f47ac10b-58cc-4372-a567-0e02b2c3d479"
  }'

# 응답
{
  "success": true,
  "data": {
    "accessToken": "eyJhbGciOiJIUzI1...",
    "tokenType": "Bearer"
  }
}
```

**3. 로그아웃**
```bash
curl -X POST http://localhost:8080/api/v1/auth/logout \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN"
```

---

## 프론트엔드 구현 가이드

### 1단계: 타입 정의

####`types/auth.ts` (수정)

```typescript
// 기존 타입에 refreshToken 추가, userId 제거

export interface LoginResponse {
  accessToken: string
  refreshToken: string  // 추가
  tokenType: string
  username: string      // userId 제거됨
  role: UserRole
  userType: UserType
  organizationId?: string
}

export interface RefreshTokenRequest {
  refreshToken: string
}

export interface RefreshTokenResponse {
  accessToken: string
  refreshToken?: string  // Rotation 적용 시
  tokenType: string
}
```

**변경사항**:
- ✅ **userId 제거**: authStore에서 userId 필드 및 파라미터 제거
- ✅ **refreshToken 추가**: Refresh Token 저장용

**TODO**:
- [ ] types/auth.ts에 refreshToken 필드 추가
- [ ] types/auth.ts에서 userId 제거

---


### 2단계: authStore 수정

####`stores/authStore.ts` (수정)

```typescript
import { create } from 'zustand'
import { persist } from 'zustand/middleware'

interface AuthState {
  token: string | null
  // refreshToken은 localStorage에 별도 저장하므로 store에 포함하지 않음
  isAuthenticated: boolean
  username: string | null      // userId 제거됨
  role: UserRole | null
  userType: UserType | null
  organizationId: string | null

  login: (
    token: string,
    username: string,            // userId 제거됨
    role: UserRole,
    userType: UserType,
    organizationId?: string
  ) => void
  logout: () => void
  updateToken: (token: string) => void
}

export const useAuthStore = create<AuthState>()(
  persist(
    (set) => ({
      token: null,
      isAuthenticated: false,
      userId: null,
      username: null,
      role: null,
      userType: null,
      organizationId: null,

      login: (token, userId, username, role, userType, organizationId) => {
        set({
          token,
          isAuthenticated: true,
          userId,
          username,
          role,
          userType,
          organizationId,
        })
      },

      logout: () => {
        // TODO: localStorage에서 refreshToken 삭제
        // Hint: localStorage.removeItem('refresh-token')

        set({
          token: null,
          isAuthenticated: false,
          userId: null,
          username: null,
          role: null,
          userType: null,
          organizationId: null,
        })
      },

      updateToken: (token) => set({ token }),
    }),
    {
      name: 'auth-storage',
      partialize: (state) => ({
        token: state.token,
        isAuthenticated: state.isAuthenticated,
        userId: state.userId,
        username: state.username,
        role: state.role,
        userType: state.userType,
        organizationId: state.organizationId,
      }),
      // 액션(함수)은 JSON 직렬화가 불가능하므로 상태(데이터)만 저장
    }
  )
)
```

**변경사항**:
- ✅ **userId 제거**: authStore에서 userId 필드 및 파라미터 제거
- ✅ **login() 시그니처 변경**: userId 파라미터 제거

**TODO**:
- [ ] logout()에서 localStorage의 refreshToken 삭제 로직 추가
- [ ] authStore에서 userId 관련 코드 제거

---


### 3단계: authApi 수정

####`api/authApi.ts` (수정)

```typescript
import type { LoginRequest, LoginResponse, RefreshTokenResponse } from '@/types/auth'
import { client } from './client'

export const authApi = {
  // ... 기존 메서드들 ...

  /**
   * 로그인 (수정)
   */
  login: async (username: string, password: string): Promise<LoginResponse> => {
    const response = await client.post<ApiResponse<LoginResponse>>('/auth/login', {
      username,
      password,
    })

    if (response.success && response.data) {
      // TODO: refreshToken을 localStorage에 저장
      // Hint: localStorage.setItem('refresh-token', response.data.refreshToken)

      return response.data
    }

    throw new Error(response.error?.message || '로그인 실패')
  },

  /**
   * Access Token 재발급
   * POST /api/v1/auth/refresh
   */
  refreshToken: async (refreshToken: string): Promise<RefreshTokenResponse> => {
    // TODO: client.post<ApiResponse<RefreshTokenResponse>>('/auth/refresh', { refreshToken }) 호출
    // TODO: response.data 반환
    // TODO: (선택) Rotation 적용 시 새 refreshToken을 localStorage에 저장

    throw new Error('구현 필요')
  },

  /**
   * 로그아웃
   * POST /api/v1/auth/logout
   */
  logout: async (): Promise<void> => {
    // TODO: client.post('/auth/logout') 호출
    // TODO: localStorage에서 refreshToken 삭제

    throw new Error('구현 필요')
  },
}
```

**TODO**:
- [ ] login()에서 refreshToken을 localStorage에 저장
- [ ] refreshToken() 메서드 구현
- [ ] logout() 메서드 구현

---


### 4단계: client.ts 수정 (401 처리)

####`api/client.ts` (수정)

```typescript
import axios from 'axios'
import { useAuthStore } from '@/stores/authStore'
import { authApi } from './authApi'

const client = axios.create({
  baseURL: import.meta.env.VITE_API_BASE_URL || '/api/v1',
  timeout: 30000,
})

// Request Interceptor
client.interceptors.request.use((config) => {
  const token = useAuthStore.getState().token
  if (token) {
    config.headers.Authorization = `Bearer ${token}`
  }
  return config
})

// Response Interceptor
let isRefreshing = false
let failedQueue: any[] = []

const processQueue = (error: any, token: string | null = null) => {
  failedQueue.forEach((prom) => {
    if (error) {
      prom.reject(error)
    } else {
      prom.resolve(token)
    }
  })
  failedQueue = []
}

client.interceptors.response.use(
  (response) => response.data,
  async (error) => {
    const originalRequest = error.config

    // 401 Unauthorized 처리
    if (error.response?.status === 401 && !originalRequest._retry) {
      if (isRefreshing) {
        // TODO: 다른 요청이 이미 refresh 중이면 대기
        // Hint: Promise로 큐에 추가하고, refresh 완료 시 재시도
        return new Promise((resolve, reject) => {
          failedQueue.push({ resolve, reject })
        })
          .then((token) => {
            originalRequest.headers.Authorization = `Bearer ${token}`
            return client(originalRequest)
          })
          .catch((err) => Promise.reject(err))
      }

      originalRequest._retry = true
      isRefreshing = true

      // TODO: localStorage에서 refreshToken 조회
      const refreshToken = localStorage.getItem('refresh-token')

      if (!refreshToken) {
        // Refresh Token이 없으면 로그아웃 처리
        useAuthStore.getState().logout()
        window.location.href = '/login'
        return Promise.reject(error)
      }

      try {
        // TODO: authApi.refreshToken(refreshToken) 호출
        // Hint: 새 accessToken 받아서 Zustand 업데이트
        // Hint: 원래 요청 재시도
        const response = null // 구현 필요

        // const response = await authApi.refreshToken(refreshToken)
        // useAuthStore.getState().updateToken(response.accessToken)
        // processQueue(null, response.accessToken)
        // originalRequest.headers.Authorization = `Bearer ${response.accessToken}`
        // return client(originalRequest)

        throw new Error('구현 필요')
      } catch (refreshError) {
        // Refresh Token도 만료되었으면 로그아웃
        processQueue(refreshError, null)
        useAuthStore.getState().logout()
        window.location.href = '/login'
        return Promise.reject(refreshError)
      } finally {
        isRefreshing = false
      }
    }

    return Promise.reject(error)
  }
)

export { client }
```

**구현 인사이트**:
1. **isRefreshing 플래그**: 중복 refresh 요청 방지
2. **failedQueue**: refresh 중인 동안 대기하는 요청들을 큐에 추가
3. **processQueue()**: refresh 완료 후 큐의 모든 요청을 재시도
4. **_retry 플래그**: 무한 루프 방지

**TODO**:
- [ ] 401 처리에서 authApi.refreshToken() 호출 구현
- [ ] processQueue() 활용하여 대기 중인 요청 재시도

---


### 5단계: LoginPage 수정

####`pages/LoginPage.tsx` (수정)

```typescript
// login mutation의 onSuccess에서 refreshToken 처리

const loginMutation = useMutation({
  mutationFn: ({ username, password }: { username: string; password: string }) =>
    authApi.login(username, password),
  onSuccess: (data) => {
    // TODO: authStore.login() 호출 (refreshToken 제외)
    // Hint: refreshToken은 이미 authApi.login()에서 localStorage에 저장됨

    authStore.login(
      data.accessToken,
      data.userId,
      data.username,
      data.role as UserRole,
      data.userType as UserType,
      data.organizationId
    )

    showSuccess('로그인 성공')
    navigate({ to: '/dashboard' })
  },
  onError: (error: any) => {
    showError('로그인 실패', error)
  },
})
```

**TODO**:
- [ ] LoginPage의 login mutation 확인 (수정 불필요)

---

## 보안 고려사항

### 1. Refresh Token 저장 위치

| 위치 | 장점 | 단점 | 권장 여부 |
|------|------|------|----------|
| **localStorage** | 구현 간단, 페이지 새로고침 시에도 유지 | XSS 공격에 취약 | ⚠️ 주의 필요 |
| **HttpOnly Cookie** | XSS 공격 방어, 브라우저가 자동 관리 | CSRF 공격 가능 (대응 필요) | ✅ 권장 |
| **메모리** | 가장 안전 | 페이지 새로고침 시 손실 | ❌ 비권장 |

**권장: HttpOnly Cookie + SameSite=Strict + CSRF Token**

### 2. Refresh Token Rotation

- 재발급 시 기존 Refresh Token 무효화
- 새로운 Refresh Token 발급
- Refresh Token 재사용 방지

### 3. Device/IP 추적

- RefreshToken 엔티티의 `deviceInfo`, `ipAddress` 활용
- 이상 징후 감지 (다른 IP에서 접속 등)

### 4. 만료 시간 설정

- **Access Token**: 15분~1시간
- **Refresh Token**: 7일~30일
- 보안과 사용자 경험의 균형 고려

---

## 구현 체크리스트

### 백엔드
- [ ] RefreshTokenRequest, RefreshTokenResponse DTO 생성
- [ ] AuthService.login()에 Refresh Token 생성/저장 로직 추가
- [ ] AuthService.signupAndIssueToken()에 Refresh Token 생성/저장 로직 추가
- [ ] AuthService.refreshAccessToken() 구현
- [ ] AuthService.logout() 구현
- [ ] AuthController.refreshToken() 엔드포인트 추가
- [ ] AuthController.logout() 엔드포인트 추가
- [ ] LoginResponse에 refreshToken 필드 추가
- [ ] API 통합 테스트

### 프론트엔드
- [ ] types/auth.ts에 refreshToken 관련 타입 추가
- [ ] authStore.logout()에서 refreshToken 삭제
- [ ] authApi.login()에서 refreshToken을 localStorage에 저장
- [ ] authApi.refreshToken() 구현
- [ ] authApi.logout() 구현
- [ ] client.ts의 401 처리에서 refresh 로직 완성
- [ ] 로그인/로그아웃 플로우 테스트

---

## 추가 학습 자료

### Refresh Token 보안
- [OWASP JWT Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/JSON_Web_Token_for_Java_Cheat_Sheet.html)
- [Refresh Token Rotation](https://auth0.com/docs/secure/tokens/refresh-tokens/refresh-token-rotation)

### Redis
- [Spring Data Redis](https://spring.io/projects/spring-data-redis)
- [Redis Security](https://redis.io/docs/management/security/)

### Cookie Security
- [HttpOnly Cookie](https://owasp.org/www-community/HttpOnly)
- [SameSite Cookie](https://web.dev/samesite-cookies-explained/)

---

## 마무리

이 가이드를 따라 구현하시면서 다음과 같은 인사이트를 얻으실 수 있습니다:

1. **RTR 패턴의 실전 활용**: Refresh Token 재사용 방지
2. **Redis 기반 토큰 관리**: TTL 자동 관리, 빠른 조회
3. **HttpOnly Cookie 활용**: XSS 방어
4. **Silent Refresh**: 사용자 경험 유지
5. **JWT Claims 설계**: userId를 JWT에 포함하여 DB 조회 최소화
6. **보안 강화**: CSRF, XSS, Token Reuse 방어

구현 중 막히는 부분이 있으면 기존 코드를 참고하세요!

## 정리

- JWT Access Token + Refresh Token 이중 토큰 구조로 보안과 사용자 경험을 모두 확보할 수 있다
- Refresh Token Rotation(RTR) 패턴을 적용하면 탈취된 Refresh Token의 재사용을 방지할 수 있다
- Redis를 Refresh Token 저장소로 활용하면 TTL 기반 자동 만료 관리와 빠른 조회가 가능하다
- 프론트엔드의 401 인터셉터에서 자동 갱신(Silent Refresh) 구현 시, 동시 요청 큐잉(`isRefreshing` + `failedQueue`)이 필수적이다
- HttpOnly Cookie + SameSite 설정이 localStorage보다 안전한 Refresh Token 저장 방식이다

## References

- [OWASP JWT Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/JSON_Web_Token_for_Java_Cheat_Sheet.html)
- [Auth0 - Refresh Token Rotation](https://auth0.com/docs/secure/tokens/refresh-tokens/refresh-token-rotation)
- [Spring Data Redis](https://spring.io/projects/spring-data-redis)
- [OWASP HttpOnly Cookie](https://owasp.org/www-community/HttpOnly)
- [SameSite Cookies Explained](https://web.dev/samesite-cookies-explained/)