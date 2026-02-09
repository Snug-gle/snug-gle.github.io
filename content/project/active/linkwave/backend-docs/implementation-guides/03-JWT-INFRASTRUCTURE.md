---
created: 2025-12-26
---
# Phase 3: JWT 인프라

## 📖 개념 설명

### JWT (JSON Web Token)란?

- 사용자 인증 정보를 안전하게 전달하는 토큰
- Stateless: 서버에 세션 저장 불필요
- Header.Payload.Signature 구조

### Access Token vs Refresh Token

| 구분 | Access Token | Refresh Token |
|------|-------------|---------------|
| 용도 | API 요청 인증 | Access Token 재발급 |
| 만료 시간 | 짧음 (1시간) | 길 (7일) |
| 저장 위치 | 메모리 | DB |
| Payload | userId, email, role | userId만 |

### 인증 흐름

```
1. 로그인 → Access Token + Refresh Token 발급
2. API 요청 → Access Token 검증
3. Access Token 만료 → Refresh Token으로 재발급
4. 로그아웃 → Refresh Token 삭제
```

## 🎯 구현 목표

- [ ] JWT 의존성 추가 (build.gradle.kts)
- [ ] JWT 설정 추가 (application.yml)
- [ ] JwtTokenProvider 작성
- [ ] RefreshToken Entity 작성
- [ ] RefreshTokenRepository 작성
- [ ] CustomUserDetailsService 작성
- [ ] JwtAuthenticationFilter 작성
- [ ] JwtAuthenticationEntryPoint 작성
- [ ] SecurityConfig 작성

---

## 📝 0. 의존성 추가 (build.gradle.kts)

**Phase 5에서 다루지만 먼저 추가해야 합니다!**

`build.gradle.kts`의 `dependencies` 블록에 추가:

```kotlin
dependencies {
    // ... 기존 의존성 ...

    // JWT
    implementation("io.jsonwebtoken:jjwt-api:0.12.3")
    runtimeOnly("io.jsonwebtoken:jjwt-impl:0.12.3")
    runtimeOnly("io.jsonwebtoken:jjwt-jackson:0.12.3")
}
```

추가 후:
```bash
./gradlew build
```

---

## 📝 1. application.yml 설정

**Phase 5에서 다루지만 먼저 추가해야 합니다!**

`src/main/resources/application.yml`에 추가:

```yaml
linkwave:
  jwt:
    secret: ${JWT_SECRET:YourBase64EncodedSecretKeyMustBeAtLeast256BitsLongForHS256AlgorithmToWorkProperlyAndSecurely}
    access-token-expiration: 3600000      # 1시간 (ms)
    refresh-token-expiration: 604800000   # 7일 (ms)
```

**중요**: secret은 최소 256비트 (43자 이상) Base64 문자열이어야 합니다!

---

## 📝 2. JwtTokenProvider.java

**위치**: `src/main/java/io/iotree/linkwave/config/JwtTokenProvider.java`

### 역할
- JWT 토큰 생성, 검증, 파싱
- Access Token은 JWT, Refresh Token은 UUID

### 전체 코드

```java
package io.iotree.linkwave.config;

import io.iotree.linkwave.common.exception.BusinessException;
import io.iotree.linkwave.common.exception.ErrorCode;
import io.jsonwebtoken.*;
import io.jsonwebtoken.io.Decoders;
import io.jsonwebtoken.security.Keys;
import jakarta.annotation.PostConstruct;
import java.security.Key;
import java.util.Date;
import java.util.UUID;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

@Slf4j
@Component
public class JwtTokenProvider {

  @Value("${linkwave.jwt.secret}")
  private String secretKey;

  @Value("${linkwave.jwt.access-token-expiration}")
  private long accessTokenExpiration;

  @Value("${linkwave.jwt.refresh-token-expiration}")
  private long refreshTokenExpiration;

  private Key key;

  @PostConstruct
  public void init() {
    byte[] keyBytes = Decoders.BASE64.decode(secretKey);
    this.key = Keys.hmacShaKeyFor(keyBytes);
  }

  // 1. Access Token 생성
  public String generateAccessToken(Long userId, String email, String role) {
    Date now = new Date();
    Date expiry = new Date(now.getTime() + accessTokenExpiration);

    return Jwts.builder()
        .setSubject(email) // 주체 (이메일)
        .claim("userId", userId)
        .claim("role", role)
        .setIssuedAt(now)
        .setExpiration(expiry)
        .signWith(key, SignatureAlgorithm.HS256)
        .compact();
  }

  // 2. Refresh Token 생성 (UUID 사용)
  public String generateRefreshToken() {
    return UUID.randomUUID().toString();
  }

  // 3. 토큰 검증
  public boolean validateToken(String token) {
    try {
      Jwts.parserBuilder().setSigningKey(key).build().parseClaimsJws(token);
      return true;
    } catch (ExpiredJwtException e) {
      log.error("Token expired: {}", e.getMessage());
      throw new BusinessException(ErrorCode.EXPIRED_TOKEN);
    } catch (JwtException | IllegalArgumentException e) {
      log.error("Invalid token: {}", e.getMessage());
      throw new BusinessException(ErrorCode.INVALID_TOKEN);
    }
  }

  // 4. 토큰에서 이메일 추출
  public String getEmailFromToken(String token) {
    Claims claims =
        Jwts.parserBuilder().setSigningKey(key).build().parseClaimsJws(token).getBody();
    return claims.getSubject();
  }

  // 5. 토큰에서 userId 추출
  public Long getUserIdFromToken(String token) {
    Claims claims =
        Jwts.parserBuilder().setSigningKey(key).build().parseClaimsJws(token).getBody();
    return claims.get("userId", Long.class);
  }

  // 6. 토큰에서 role 추출
  public String getRoleFromToken(String token) {
    Claims claims =
        Jwts.parserBuilder().setSigningKey(key).build().parseClaimsJws(token).getBody();
    return claims.get("role", String.class);
  }

  public long getAccessTokenExpiration() {
    return accessTokenExpiration;
  }

  public long getRefreshTokenExpiration() {
    return refreshTokenExpiration;
  }
}
```

### 주요 메서드 설명

#### init()
- `@PostConstruct`: 빈 생성 후 자동 실행
- secret을 Base64 디코딩하여 Key 객체 생성

#### generateAccessToken()
- JWT 토큰 생성
- Payload: subject(email), userId, role
- 서명 알고리즘: HS256

#### validateToken()
- 토큰 파싱하여 검증
- 만료 시: `EXPIRED_TOKEN`
- 잘못된 토큰: `INVALID_TOKEN`

### 체크포인트
- [ ] `@Component` 어노테이션이 있나요?
- [ ] init() 메서드에 `@PostConstruct`가 있나요?
- [ ] secretKey를 Base64 디코딩했나요?

---

## 📝 3. RefreshToken.java (Entity)

**위치**: `src/main/java/io/iotree/linkwave/domain/token/RefreshToken.java`

### 설명
- Refresh Token을 DB에 저장
- 로그아웃 시 삭제하여 무효화

### 전체 코드

```java
package io.iotree.linkwave.domain.token;

import jakarta.persistence.*;
import java.time.LocalDateTime;
import lombok.AccessLevel;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import org.springframework.data.annotation.CreatedDate;
import org.springframework.data.jpa.domain.support.AuditingEntityListener;

@Entity
@Table(
    name = "refresh_tokens",
    indexes = {
      @Index(name = "idx_token", columnList = "token", unique = true),
      @Index(name = "idx_user_id", columnList = "user_id")
    })
@Getter
@Builder
@NoArgsConstructor(access = AccessLevel.PROTECTED)
@AllArgsConstructor
@EntityListeners(AuditingEntityListener.class)
public class RefreshToken {

  @Id
  @GeneratedValue(strategy = GenerationType.IDENTITY)
  private Long id;

  @Column(nullable = false, name = "user_id")
  private Long userId;

  @Column(nullable = false, unique = true, length = 255)
  private String token;

  @Column(nullable = false)
  private LocalDateTime expiresAt;

  @CreatedDate
  @Column(nullable = false, updatable = false)
  private LocalDateTime createdAt;

  @Column(length = 200)
  private String deviceInfo;

  @Column(length = 50)
  private String ipAddress;

  // 만료 여부 확인 메서드
  public boolean isExpired() {
    return LocalDateTime.now().isAfter(expiresAt);
  }
}
```

### 주요 필드

- **token**: Refresh Token 값 (UUID), UNIQUE 인덱스
- **expiresAt**: 만료 시간
- **deviceInfo**: User-Agent (다중 기기 관리용)
- **ipAddress**: 보안 로그용

### 체크포인트
- [ ] token에 `unique = true`가 있나요?
- [ ] indexes에 token, user_id 인덱스가 있나요?

---

## 📝 4. RefreshTokenRepository.java

**위치**: `src/main/java/io/iotree/linkwave/infra/jpa/repository/RefreshTokenRepository.java`

### 전체 코드

```java
package io.iotree.linkwave.infra.jpa.repository;

import io.iotree.linkwave.domain.token.RefreshToken;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

@Repository
public interface RefreshTokenRepository extends JpaRepository<RefreshToken, Long> {

  Optional<RefreshToken> findByToken(String token);

  void deleteByToken(String token);

  void deleteByUserId(Long userId);

  @Query(
      "SELECT rt FROM RefreshToken rt WHERE rt.userId = :userId AND rt.expiresAt > :now")
  List<RefreshToken> findActiveTokensByUserId(
      @Param("userId") Long userId, @Param("now") LocalDateTime now);
}
```

### 주요 메서드

- **findByToken**: 토큰 조회
- **deleteByToken**: 로그아웃 시 사용
- **deleteByUserId**: 모든 기기 로그아웃
- **findActiveTokensByUserId**: 사용자의 유효한 토큰 목록

---

## 📝 5. CustomUserDetailsService.java

**위치**: `src/main/java/io/iotree/linkwave/config/CustomUserDetailsService.java`

### 설명
- Spring Security의 UserDetailsService 구현
- 이메일로 사용자 조회

### 전체 코드

```java
package io.iotree.linkwave.config;

import io.iotree.linkwave.infra.jpa.repository.UserRepository;
import io.iotree.linkwave.domain.user.User;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.security.core.userdetails.UsernameNotFoundException;
import org.springframework.stereotype.Service;

@Service
@RequiredArgsConstructor
public class CustomUserDetailsService implements UserDetailsService {

  private final UserRepository userRepository;

  @Override
  public UserDetails loadUserByUsername(String email) throws UsernameNotFoundException {
    User user =
        userRepository
            .findByEmail(email)
            .orElseThrow(() -> new UsernameNotFoundException("User not found: " + email));

    return org.springframework.security.core.userdetails.User.builder()
        .username(user.getEmail())
        .password(user.getPassword())
        .roles(user.getRole().name()) // ROLE_ 접두사 자동 추가
        .build();
  }
}
```

**참고**: UserRepository와 User Entity는 Phase 4에서 작성합니다. 지금은 컴파일 에러가 발생할 수 있습니다.

---

## 📝 6. JwtAuthenticationFilter.java

**위치**: `src/main/java/io/iotree/linkwave/config/JwtAuthenticationFilter.java`

### 역할
- 모든 HTTP 요청의 Authorization 헤더에서 JWT 추출
- JWT 검증 후 SecurityContext에 인증 정보 저장

### 전체 코드

```java
package io.iotree.linkwave.config;

import io.iotree.linkwave.common.exception.BusinessException;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.stereotype.Component;
import org.springframework.util.StringUtils;
import org.springframework.web.filter.OncePerRequestFilter;

@Slf4j
@Component
@RequiredArgsConstructor
public class JwtAuthenticationFilter extends OncePerRequestFilter {

  private final JwtTokenProvider jwtTokenProvider;
  private final UserDetailsService userDetailsService;

  @Override
  protected void doFilterInternal(
      HttpServletRequest request, HttpServletResponse response, FilterChain filterChain)
      throws ServletException, IOException {

    // 1. Authorization 헤더에서 토큰 추출
    String token = extractTokenFromRequest(request);

    if (token != null) {
      try {
        // 2. 토큰 검증
        if (jwtTokenProvider.validateToken(token)) {
          // 3. 토큰에서 이메일 추출
          String email = jwtTokenProvider.getEmailFromToken(token);

          // 4. UserDetails 로드
          UserDetails userDetails = userDetailsService.loadUserByUsername(email);

          // 5. Authentication 객체 생성
          UsernamePasswordAuthenticationToken authentication =
              new UsernamePasswordAuthenticationToken(
                  userDetails, null, userDetails.getAuthorities());

          // 6. SecurityContext에 인증 정보 저장
          SecurityContextHolder.getContext().setAuthentication(authentication);
        }
      } catch (BusinessException e) {
        // 토큰 검증 실패 시 로깅 (인증 실패로 처리)
        log.error("Token validation failed: {}", e.getMessage());
      }
    }

    filterChain.doFilter(request, response);
  }

  // Authorization 헤더에서 Bearer 토큰 추출
  private String extractTokenFromRequest(HttpServletRequest request) {
    String bearerToken = request.getHeader("Authorization");
    if (StringUtils.hasText(bearerToken) && bearerToken.startsWith("Bearer ")) {
      return bearerToken.substring(7);
    }
    return null;
  }
}
```

### 동작 흐름

```
HTTP Request
  ↓
1. Authorization: Bearer {token} 헤더 추출
  ↓
2. JWT 검증
  ↓
3. 토큰에서 이메일 추출
  ↓
4. UserDetailsService로 사용자 정보 로드
  ↓
5. Authentication 객체 생성
  ↓
6. SecurityContext에 저장
  ↓
다음 필터로 진행
```

### 체크포인트
- [ ] `OncePerRequestFilter` 상속했나요?
- [ ] Bearer 토큰을 정확히 추출했나요? (7번째 문자부터)
- [ ] 토큰 검증 실패해도 예외를 던지지 않고 계속 진행하나요?

---

## 📝 7. JwtAuthenticationEntryPoint.java

**위치**: `src/main/java/io/iotree/linkwave/config/JwtAuthenticationEntryPoint.java`

### 역할
- 인증 실패 시 401 Unauthorized 응답
- JSON 형식으로 에러 응답

### 전체 코드

```java
package io.iotree.linkwave.config;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.datatype.jsr310.JavaTimeModule;
import io.iotree.linkwave.common.exception.ErrorCode;
import io.iotree.linkwave.application.dto.response.ApiResponse;
import io.iotree.linkwave.application.dto.response.ErrorResponse;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import org.springframework.security.core.AuthenticationException;
import org.springframework.security.web.AuthenticationEntryPoint;
import org.springframework.stereotype.Component;

@Component
public class JwtAuthenticationEntryPoint implements AuthenticationEntryPoint {

  @Override
  public void commence(
      HttpServletRequest request,
      HttpServletResponse response,
      AuthenticationException authException)
      throws IOException {
    // 인증 실패 시 401 Unauthorized 응답
    response.setStatus(HttpServletResponse.SC_UNAUTHORIZED);
    response.setContentType("application/json;charset=UTF-8");

    ErrorResponse errorResponse =
        ErrorResponse.builder()
            .errorCode(ErrorCode.UNAUTHORIZED.getCode())
            .message(ErrorCode.UNAUTHORIZED.getMessage())
            .build();

    ApiResponse<Void> apiResponse = ApiResponse.error(errorResponse);

    ObjectMapper objectMapper = new ObjectMapper();
    objectMapper.registerModule(new JavaTimeModule());
    response.getWriter().write(objectMapper.writeValueAsString(apiResponse));
  }
}
```

---

## 📝 8. SecurityConfig.java

**위치**: `src/main/java/io/iotree/linkwave/config/SecurityConfig.java`

### 역할
- Spring Security 설정
- JWT 필터 등록
- URL별 인증 요구사항 설정

### 전체 코드

```java
package io.iotree.linkwave.config;

import java.util.Arrays;
import lombok.RequiredArgsConstructor;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.config.annotation.authentication.configuration.AuthenticationConfiguration;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.security.web.authentication.UsernamePasswordAuthenticationFilter;
import org.springframework.web.cors.CorsConfiguration;
import org.springframework.web.cors.CorsConfigurationSource;
import org.springframework.web.cors.UrlBasedCorsConfigurationSource;

@Configuration
@EnableWebSecurity
@RequiredArgsConstructor
public class SecurityConfig {

  private final JwtAuthenticationFilter jwtAuthenticationFilter;
  private final JwtAuthenticationEntryPoint jwtAuthenticationEntryPoint;

  @Bean
  public SecurityFilterChain filterChain(HttpSecurity http) throws Exception {
    http.csrf(csrf -> csrf.disable()) // JWT 사용 시 CSRF 불필요
        .cors(cors -> cors.configurationSource(corsConfigurationSource()))
        .sessionManagement(
            session ->
                session.sessionCreationPolicy(SessionCreationPolicy.STATELESS)) // 세션 사용 안 함
        .authorizeHttpRequests(
            auth ->
                auth.requestMatchers("/api/v1/auth/**")
                    .permitAll() // 인증 API 허용
                    .requestMatchers("/api/v1/companies")
                    .permitAll() // 회사 등록 허용
                    .requestMatchers("/actuator/health")
                    .permitAll() // Health check 허용
                    .anyRequest()
                    .authenticated()) // 나머지는 인증 필요
        .exceptionHandling(
            exception -> exception.authenticationEntryPoint(jwtAuthenticationEntryPoint))
        .addFilterBefore(
            jwtAuthenticationFilter,
            UsernamePasswordAuthenticationFilter.class); // JWT 필터 추가

    return http.build();
  }

  @Bean
  public PasswordEncoder passwordEncoder() {
    return new BCryptPasswordEncoder();
  }

  @Bean
  public AuthenticationManager authenticationManager(
      AuthenticationConfiguration authenticationConfiguration) throws Exception {
    return authenticationConfiguration.getAuthenticationManager();
  }

  @Bean
  public CorsConfigurationSource corsConfigurationSource() {
    CorsConfiguration configuration = new CorsConfiguration();
    configuration.setAllowedOrigins(Arrays.asList("http://localhost:3000")); // 프론트엔드 주소
    configuration.setAllowedMethods(Arrays.asList("GET", "POST", "PUT", "DELETE", "PATCH"));
    configuration.setAllowedHeaders(Arrays.asList("*"));
    configuration.setAllowCredentials(true);

    UrlBasedCorsConfigurationSource source = new UrlBasedCorsConfigurationSource();
    source.registerCorsConfiguration("/**", configuration);
    return source;
  }
}
```

### 주요 설정 설명

#### csrf().disable()
- JWT 사용 시 CSRF 공격 방어 불필요

#### SessionCreationPolicy.STATELESS
- 세션 사용하지 않음 (JWT로 인증)

#### authorizeHttpRequests
- `/api/v1/auth/**`: 로그인, 회원가입 등 인증 불필요
- `/api/v1/companies`: 회사 등록 허용
- 나머지: 인증 필요

#### addFilterBefore
- JWT 필터를 UsernamePasswordAuthenticationFilter 앞에 추가

---

## ✅ 완료 체크리스트

- [ ] build.gradle.kts에 JWT 의존성 추가
- [ ] application.yml에 JWT 설정 추가
- [ ] JwtTokenProvider.java 작성 완료
- [ ] RefreshToken.java 작성 완료
- [ ] RefreshTokenRepository.java 작성 완료
- [ ] CustomUserDetailsService.java 작성 완료 (컴파일 에러는 정상)
- [ ] JwtAuthenticationFilter.java 작성 완료
- [ ] JwtAuthenticationEntryPoint.java 작성 완료
- [ ] SecurityConfig.java 작성 완료
- [ ] `./gradlew spotlessApply` 실행

---

## 🧪 테스트 방법

**Phase 4 완료 후 테스트 가능합니다.**

---

## 🔍 자주하는 실수

### 1. secret이 너무 짧음
최소 256비트 (43자) 필요

### 2. Base64 디코딩 누락
secretKey를 그대로 사용하면 에러 발생

### 3. Filter 순서 잘못 설정
JWT 필터가 먼저 실행되어야 함

### 4. CSRF 비활성화 누락
JWT 사용 시 반드시 disable

---

**축하합니다! Phase 3 완료!** 🎉

다음 단계로 이동: 👉 [04-USER-AUTH.md](./04-USER-AUTH.md)
