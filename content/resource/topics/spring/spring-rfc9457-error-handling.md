---
tags: [spring, error-handling, rfc9457, api, rest, design, frontend, backend]
category: spring
created: 2026-02-13
status: complete
description: RFC 9457 (Problem Details for HTTP APIs) 표준을 Spring Boot 백엔드 및 React 프론트엔드에 통합하여 일관되고 예측 가능한 에러 응답 시스템을 구축하는 상세 가이드
---

# Spring Boot에서 RFC 9457 기반 API 에러 처리 표준화: 백엔드 및 프론트엔드 구현 가이드

> HTTP API 에러 응답 표준인 RFC 9457을 Spring Boot 백엔드와 React 기반 프론트엔드에 도입하여, 일관되고 구조화된 에러 처리 시스템을 구축하고 개발 효율성을 높이는 방법을 단계별로 제시합니다.

---

## 개요
REST API에서 에러를 반환하는 방식은 팀마다 제각각이며, 이는 프론트엔드의 파싱 로직 복잡화, API 문서화의 어려움, 외부 도구/라이브러리 통합의 복잡성 등 다양한 문제를 야기합니다. 이 문서는 이러한 문제를 해결하기 위해 IETF에서 2023년에 발표한 HTTP API 에러 응답 표준인 **RFC 9457 (Problem Details for HTTP APIs)**을 LinkWave 프로젝트에 도입하기 위한 상세 가이드입니다. Spring Boot 백엔드와 React 기반 프론트엔드 양쪽에서 RFC 9457 표준을 통합하여, 일관되고 예측 가능한 에러 응답 시스템을 구축하고 개발 효율성을 높이는 방법을 단계별로 설명합니다.

## 본문

### 1. 배경 지식

#### 1.1 왜 에러 처리 표준이 필요한가?

REST API에서 에러를 반환하는 방식은 팀마다 제각각입니다:
```json
// 방식 A: 단순 메시지
{ "error": "User not found" }

// 방식 B: 코드 + 메시지
{ "code": "U001", "message": "User not found" }

// 방식 C: 래퍼 사용
{ "success": false, "error": { "code": "U001", "message": "User not found" } }
```
이런 불일치는 다음 문제를 야기합니다:
- 프론트엔드가 백엔드마다 다른 파싱 로직 필요
- API 문서화가 어려움
- 외부 도구/라이브러리 통합이 복잡

#### 1.2 RFC 9457이란?

IETF(인터넷 표준화 기구)에서 2023년에 발표한 **HTTP API 에러 응답 표준**입니다.

**핵심 아이디어**: 모든 API가 동일한 형식으로 에러를 반환하면 클라이언트가 예측 가능하게 처리할 수 있다.

---


### 2. 현재 구조 분석

#### 2.1 Backend 현재 구조

```
linkwave-backend/src/main/java/io/iotree.linkwave/
├── common/exception/
│   ├── ErrorCode.java          ← 에러 코드 Enum (C001, A001 등)
│   ├── BusinessException.java  ← 비즈니스 예외 클래스
│   └── GlobalExceptionHandler.java  ← 전역 예외 처리
└── application/dto/response/
    ├── ApiResponse.java        ← 응답 래퍼
    └── ErrorResponse.java      ← 에러 응답 DTO
```

**현재 ErrorCode.java 구조:**
```java
public enum ErrorCode {
  INVALID_CREDENTIALS(401, "A001", "Invalid email or password"),
  //                   ↑      ↑              ↑
  //              HTTP상태  비즈니스코드    메시지
}
```

**현재 응답 형식:**
```json
{
  "success": false,           ← HTTP 상태와 중복
  "data": null,
  "error": {
    "errorCode": "A001",      ← 프론트엔드와 불일치
    "message": "...",
    "fieldErrors": []
  },
  "timestamp": "..."
}
```

#### 2.2 Frontend 현재 구조

```
linkwave-frontend/src/
├── types/api.ts              ← ErrorCode 상수 (E000, U001 등)
├── api/client.ts             ← Axios 인터셉터
└── utils/toast.ts            ← 에러 표시 유틸
```

**문제점**: Backend는 `A001`, Frontend는 `U004`를 같은 에러에 사용 → **매핑 불일치**

---


### 3. RFC 9457 이해하기

#### 3.1 필수 필드

```json
{
  "type": "https://api.linkwave.io/errors/auth/invalid-credentials",
  "title": "Invalid Credentials",
  "status": 401,
  "detail": "The email or password you entered is incorrect.",
  "instance": "/api/v1/auth/login"
}
```

| 필드 | 설명 | 예시 |
|------|------|------|
| `type` | 에러 유형 URI (문서 링크 역할) | `https://api.linkwave.io/errors/auth/invalid-credentials` |
| `title` | 에러 유형의 짧은 제목 | `"Invalid Credentials"` |
| `status` | HTTP 상태 코드 | `401` |
| `detail` | 이 요청에서 발생한 구체적 설명 | `"The email or password..."` |
| `instance` | 문제가 발생한 요청 URI | `"/api/v1/auth/login"` |

#### 3.2 type URI 설계 원칙

```
https://api.linkwave.io/errors/{category}/{error-name}

예시:
- https://api.linkwave.io/errors/auth/invalid-credentials
- https://api.linkwave.io/errors/users/not-found
- https://api.linkwave.io/errors/messages/sender-not-verified
```

**왜 URI를 사용하나요?**
1. **고유성**: 전 세계적으로 유일한 에러 식별자
2. **문서화**: URI를 열면 에러 설명 페이지로 이동 가능 (선택적)
3. **네임스페이스**: 카테고리별 에러 분류 명확

#### 3.3 확장 필드 (Extensions)

RFC 9457은 추가 필드를 허용합니다:

```json
{
  "type": "https://api.linkwave.io/errors/invalid-input",
  "title": "Invalid Input",
  "status": 400,
  "detail": "Validation failed for 2 fields",
  "instance": "/api/v1/auth/signup",
  "errors": [
    { "field": "email", "message": "Invalid email format" },
    { "field": "password", "message": "Must be at least 8 characters" }
  ]
}
```

`errors` 필드는 표준이 아니지만, 표준이 허용하는 확장입니다.

#### 3.4 Content-Type

RFC 9457 응답은 특별한 Content-Type을 사용합니다:

```
Content-Type: application/problem+json
```

일반 JSON(`application/json`)과 구분하여 클라이언트가 에러 응답임을 즉시 알 수 있습니다.

---


### 4. 구현 Step 1: ErrorType Enum 생성

#### 4.1 새 파일 생성

**경로**: `linkwave-backend/src/main/java/io/iotree.linkwave/common/exception/ErrorType.java`

```java
package io.iotree.linkwave.common.exception;

import java.net.URI;
import lombok.Getter;
import lombok.RequiredArgsConstructor;

/**
 * RFC 9457 Problem Details를 위한 에러 타입 정의
 *
 * 각 에러 타입은 다음을 포함합니다:
 * - path: URI의 경로 부분 (예: "auth/invalid-credentials")
 * - title: 에러 유형의 짧은 제목
 * - status: HTTP 상태 코드
 *
 * type URI는 BASE_URI + path로 구성됩니다.
 * 예: https://api.linkwave.io/errors/auth/invalid-credentials
 */
@Getter
@RequiredArgsConstructor
public enum ErrorType {

  // ======================================== 
  // Common Errors (일반적인 에러)
  // ======================================== 

  /**
   * 유효성 검사 실패 (400 Bad Request)
   * - 요청 파라미터가 올바르지 않은 경우
   * - @Valid 검증 실패 시 사용
   */
  INVALID_INPUT("invalid-input", "Invalid Input", 400),

  /**
   * 예상치 못한 서버 에러 (500 Internal Server Error)
   * - 처리되지 않은 예외 발생 시 사용
   * - 로그에서 상세 원인 확인 필요
   */
  INTERNAL_SERVER_ERROR("internal-error", "Internal Server Error", 500),

  // ======================================== 
  // Authentication Errors (인증 관련)
  // ======================================== 

  /**
   * 로그인 실패 - 잘못된 이메일/비밀번호 (401 Unauthorized)
   */
  INVALID_CREDENTIALS("auth/invalid-credentials", "Invalid Credentials", 401),

  /**
   * 토큰 형식이 잘못되었거나 서명이 유효하지 않음 (401 Unauthorized)
   */
  INVALID_TOKEN("auth/invalid-token", "Invalid Token", 401),

  /**
   * Access Token 만료 (401 Unauthorized)
   * - 클라이언트는 refresh 엔드포인트 호출 필요
   */
  EXPIRED_TOKEN("auth/expired-token", "Token Expired", 401),

  /**
   * Refresh Token이 Redis에 없음 (401 Unauthorized)
   * - 로그아웃 후 재로그인 필요
   */
  REFRESH_TOKEN_NOT_FOUND("auth/refresh-token-not-found", "Refresh Token Not Found", 401),

  /**
   * Refresh Token 만료 (401 Unauthorized)
   * - 재로그인 필요
   */
  REFRESH_TOKEN_EXPIRED("auth/refresh-token-expired", "Refresh Token Expired", 401),

  /**
   * 인증되지 않은 요청 (401 Unauthorized)
   * - Authorization 헤더가 없거나 유효하지 않음
   */
  UNAUTHORIZED("auth/unauthorized", "Unauthorized", 401),

  // ======================================== 
  // User Errors (사용자 관련)
  // ======================================== 

  /**
   * 사용자를 찾을 수 없음 (404 Not Found)
   */
  USER_NOT_FOUND("users/not-found", "User Not Found", 404),

  /**
   * 이미 등록된 이메일 (409 Conflict)
   */
  DUPLICATE_EMAIL("users/duplicate-email", "Email Already Exists", 409),

  /**
   * 이미 등록된 전화번호 (409 Conflict)
   */
  DUPLICATE_PHONE("users/duplicate-phone", "Phone Already Exists", 409),

  /**
   * 비활성화된 계정 (403 Forbidden)
   */
  USER_INACTIVE("users/inactive", "User Inactive", 403),

  /**
   * 현재 비밀번호 불일치 (비밀번호 변경 시) (400 Bad Request)
   */
  PASSWORD_MISMATCH("users/password-mismatch", "Password Mismatch", 400),

  /**
   * 비밀번호 형식 오류 (400 Bad Request)
   */
  INVALID_PASSWORD("users/invalid-password", "Invalid Password", 400),

  // ======================================== 
  // Organization Errors (조직/회사 관련)
  // ======================================== 

  /**
   * 조직을 찾을 수 없음 (404 Not Found)
   */
  ORGANIZATION_NOT_FOUND("organizations/not-found", "Organization Not Found", 404),

  /**
   * 이미 등록된 사업자번호 (409 Conflict)
   */
  DUPLICATE_BUSINESS_NUMBER("organizations/duplicate-business-number", "Business Number Exists", 409),

  // ======================================== 
  // Message Errors (메시지 발송 관련)
  // ======================================== 

  /**
   * 메시지를 찾을 수 없음 (404 Not Found)
   */
  MESSAGE_NOT_FOUND("messages/not-found", "Message Not Found", 404),

  /**
   * 잘못된 메시지 타입 (SMS/LMS/MMS) (400 Bad Request)
   */
  INVALID_MESSAGE_TYPE("messages/invalid-type", "Invalid Message Type", 400),

  /**
   * 전화번호 형식 오류 (400 Bad Request)
   */
  INVALID_PHONE_NUMBER("messages/invalid-phone", "Invalid Phone Number", 400),

  /**
   * 메시지 내용 길이 초과 (400 Bad Request)
   */
  MESSAGE_CONTENT_TOO_LONG("messages/content-too-long", "Message Too Long", 400),

  /**
   * 수신자가 없음 (400 Bad Request)
   */
  NO_RECIPIENTS("messages/no-recipients", "No Recipients", 400),

  /**
   * 발신번호를 찾을 수 없음 (404 Not Found)
   */
  SENDER_NUMBER_NOT_FOUND("messages/sender-not-found", "Sender Number Not Found", 404),

  /**
   * 발신번호 미인증 (403 Forbidden)
   */
  SENDER_NUMBER_NOT_VERIFIED("messages/sender-not-verified", "Sender Not Verified", 403),

  /**
   * 본인 소유가 아닌 발신번호 (403 Forbidden)
   */
  SENDER_NUMBER_NOT_OWNED("messages/sender-not-owned", "Sender Not Owned", 403),

  /**
   * 이미 등록된 발신번호 (400 Bad Request)
   */
  SENDER_NUMBER_ALREADY_REGISTERED("messages/sender-already-registered", "Sender Already Registered", 400);

  // ======================================== 
  // 상수 및 필드
  // ======================================== 

  /**
   * 에러 타입 URI의 기본 경로
   * 실제 서비스에서는 도메인을 변경하세요.
   *
   * 이 URI는 실제로 접속 가능한 문서 페이지일 수 있습니다.
   * (선택사항이지만 권장됨)
   */
  private static final String BASE_URI = "https://api.linkwave.io/errors/";

  private final String path;    // URI 경로 (예: "auth/invalid-credentials")
  private final String title;   // 에러 제목 (예: "Invalid Credentials")
  private final int status;     // HTTP 상태 코드 (예: 401)

  /**
   * 전체 type URI를 반환합니다.
   *
   * @return 예: URI("https://api.linkwave.io/errors/auth/invalid-credentials")
   */
  public URI getTypeUri() {
    return URI.create(BASE_URI + path);
  }
}
```

#### 4.2 학습 포인트

1. **URI 설계**: `{category}/{error-name}` 패턴으로 계층 구조 표현
2. **Lombok 활용**: `@Getter`, `@RequiredArgsConstructor`로 보일러플레이트 제거
3. **문서화**: 각 에러에 Javadoc 주석으로 사용 시점 명시

---


### 5. 구현 Step 2: BusinessException 수정

#### 5.1 파일 수정

**경로**: `linkwave-backend/src/main/java/io/iotree.linkwave/common/exception/BusinessException.java`

```java
package io.iotree.linkwave.common.exception;

import lombok.Getter;

/**
 * 비즈니스 로직에서 발생하는 예외
 *
 * 사용 예시:
 * <pre>
 * // 기본 사용 (title이 detail로 사용됨)
 * throw new BusinessException(ErrorType.USER_NOT_FOUND);
 *
 * // 상세 메시지 지정
 * throw new BusinessException(ErrorType.USER_NOT_FOUND, "ID가 123인 사용자를 찾을 수 없습니다");
 * </pre>
 *
 * 이 예외는 GlobalExceptionHandler에서 캐치되어 RFC 9457 형식으로 변환됩니다.
 */
@Getter
public class BusinessException extends RuntimeException {

  /**
   * 에러 타입 (HTTP 상태, URI, 제목 포함)
   */
  private final ErrorType errorType;

  /**
   * 이 요청에서 발생한 구체적인 에러 설명
   * null이면 errorType.getTitle()이 사용됨
   */
  private final String detail;

  /**
   * 기본 생성자 - detail은 errorType의 title을 사용
   *
   * @param errorType 에러 타입
   */
  public BusinessException(ErrorType errorType) {
    super(errorType.getTitle());  // RuntimeException의 message로 title 사용
    this.errorType = errorType;
    this.detail = null;  // GlobalExceptionHandler에서 title을 사용
  }

  /**
   * 상세 메시지를 포함한 생성자
   *
   * @param errorType 에러 타입
   * @param detail 구체적인 에러 설명 (예: "ID가 123인 사용자를 찾을 수 없습니다")
   */
  public BusinessException(ErrorType errorType, String detail) {
    super(detail);  // RuntimeException의 message로 detail 사용
    this.errorType = errorType;
    this.detail = detail;
  }

  /**
   * 원인 예외를 포함한 생성자 (예외 체이닝)
   *
   * @param errorType 에러 타입
   * @param detail 구체적인 에러 설명
   * @param cause 원인 예외
   */
  public BusinessException(ErrorType errorType, String detail, Throwable cause) {
    super(detail, cause);
    this.errorType = errorType;
    this.detail = detail;
  }
}
```

#### 5.2 변경 전후 비교

```java
// Before (ErrorCode 사용)
throw new BusinessException(ErrorCode.USER_NOT_FOUND);
throw new BusinessException(ErrorCode.USER_NOT_FOUND, "커스텀 메시지");

// After (ErrorType 사용) - 사용법은 동일!
throw new BusinessException(ErrorType.USER_NOT_FOUND);
throw new BusinessException(ErrorType.USER_NOT_FOUND, "커스텀 메시지");
```

---


### 6. 구현 Step 3: GlobalExceptionHandler 수정

#### 6.1 파일 수정

**경로**: `linkwave-backend/src/main/java/io/iotree.linkwave/common/exception/GlobalExceptionHandler.java`

```java
package io.iotree.linkwave.common.exception;

import jakarta.servlet.http.HttpServletRequest;
import java.net.URI;
import java.util.List;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ProblemDetail;
import org.springframework.http.ResponseEntity;
import org.springframework.validation.FieldError;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;

/**
 * 전역 예외 처리기 - RFC 9457 Problem Details 형식으로 에러 응답
 *
 * Spring Boot 4.0의 ProblemDetail 클래스를 활용합니다.
 * 모든 에러 응답은 Content-Type: application/problem+json으로 반환됩니다.
 *
 * 처리 순서:
 * 1. BusinessException → 비즈니스 로직 에러
 * 2. MethodArgumentNotValidException → @Valid 검증 실패
 * 3. Exception → 예상치 못한 에러 (catch-all)
 */
@Slf4j
@RestControllerAdvice
public class GlobalExceptionHandler {

  /**
   * application/problem+json 미디어 타입
   * RFC 9457에서 정의한 에러 응답 전용 Content-Type
   */
  private static final MediaType PROBLEM_JSON = MediaType.APPLICATION_PROBLEM_JSON;

  // ======================================== 
  // BusinessException 처리
  // ======================================== 

  /**
   * 비즈니스 로직 예외 처리
   *
   * Service 레이어에서 던진 BusinessException을 RFC 9457 형식으로 변환합니다.
   *
   * @param ex 발생한 예외
   * @param request HTTP 요청 (instance URI 추출용)
   * @return ProblemDetail JSON 응답
   */
  @ExceptionHandler(BusinessException.class)
  public ResponseEntity<ProblemDetail> handleBusinessException(
      BusinessException ex,
      HttpServletRequest request) {

    // 로깅 - 에러 추적용
    log.error("BusinessException: type={}, detail={}",
        ex.getErrorType().name(),
        ex.getDetail(),
        ex);

    // ProblemDetail 생성 (Spring Boot 4.0 내장 클래스)
    ProblemDetail problem = ProblemDetail.forStatus(ex.getErrorType().getStatus());

    // RFC 9457 필수 필드 설정
    problem.setType(ex.getErrorType().getTypeUri());  // 에러 유형 URI
    problem.setTitle(ex.getErrorType().getTitle());    // 에러 제목

    // detail: 커스텀 메시지가 있으면 사용, 없으면 title 사용
    problem.setDetail(ex.getDetail() != null ? ex.getDetail() : ex.getErrorType().getTitle());

    // instance: 문제가 발생한 요청 URI
    problem.setInstance(URI.create(request.getRequestURI()));

    return ResponseEntity
        .status(ex.getErrorType().getStatus())
        .contentType(PROBLEM_JSON)  // Content-Type: application/problem+json
        .body(problem);
  }

  // ======================================== 
  // Validation 예외 처리
  // ======================================== 

  /**
   * @Valid 검증 실패 처리
   *
   * Controller에서 @Valid로 DTO를 검증할 때 실패하면 이 핸들러가 처리합니다.
   * 필드별 에러 목록을 extensions에 추가합니다.
   *
   * @param ex 검증 실패 예외
   * @param request HTTP 요청
   * @return 필드 에러가 포함된 ProblemDetail
   */
  @ExceptionHandler(MethodArgumentNotValidException.class)
  public ResponseEntity<ProblemDetail> handleValidationException(
      MethodArgumentNotValidException ex,
      HttpServletRequest request) {

    log.error("ValidationException: {}", ex.getMessage(), ex);

    // ProblemDetail 생성
    ProblemDetail problem = ProblemDetail.forStatus(HttpStatus.BAD_REQUEST);
    problem.setType(ErrorType.INVALID_INPUT.getTypeUri());
    problem.setTitle(ErrorType.INVALID_INPUT.getTitle());
    problem.setDetail("입력값 검증에 실패했습니다");
    problem.setInstance(URI.create(request.getRequestURI()));

    // 필드별 에러 목록 추출
    List<ValidationFieldError> fieldErrors = ex.getBindingResult()
        .getFieldErrors()
        .stream()
        .map(this::toValidationFieldError)
        .toList();

    // extensions에 errors 필드 추가 (RFC 9457 확장)
    problem.setProperty("errors", fieldErrors);

    return ResponseEntity
        .status(HttpStatus.BAD_REQUEST)
        .contentType(PROBLEM_JSON)
        .body(problem);
  }

  /**
   * Spring FieldError를 우리의 ValidationFieldError로 변환
   */
  private ValidationFieldError toValidationFieldError(FieldError error) {
    return new ValidationFieldError(
        error.getField(),
        error.getDefaultMessage(),
        error.getRejectedValue()
    );
  }

  /**
   * 검증 에러 상세 정보
   * JSON 직렬화를 위한 record
   */
  public record ValidationFieldError(
      String field,         // 필드명 (예: "email")
      String message,       // 에러 메시지 (예: "이메일 형식이 올바르지 않습니다")
      Object rejectedValue  // 거부된 값 (예: "invalid-email")
  ) {}

  // ======================================== 
  // Catch-All 예외 처리
  // ======================================== 

  /**
   * 예상치 못한 예외 처리 (최후의 방어선)
   *
   * BusinessException으로 처리되지 않은 모든 예외가 여기서 처리됩니다.
   * 보안을 위해 상세 에러 메시지는 클라이언트에 노출하지 않습니다.
   *
   * @param ex 예외
   * @param request HTTP 요청
   * @return 500 Internal Server Error
   */
  @ExceptionHandler(Exception.class)
  public ResponseEntity<ProblemDetail> handleException(
      Exception ex,
      HttpServletRequest request) {

    // 상세 로깅 (내부 디버깅용)
    log.error("Unexpected Exception at {}: {}",
        request.getRequestURI(),
        ex.getMessage(),
        ex);

    // ProblemDetail 생성 - 상세 메시지는 숨김
    ProblemDetail problem = ProblemDetail.forStatus(HttpStatus.INTERNAL_SERVER_ERROR);
    problem.setType(ErrorType.INTERNAL_SERVER_ERROR.getTypeUri());
    problem.setTitle(ErrorType.INTERNAL_SERVER_ERROR.getTitle());
    problem.setDetail("서버에서 예상치 못한 오류가 발생했습니다");  // 보안: 상세 메시지 숨김
    problem.setInstance(URI.create(request.getRequestURI()));

    return ResponseEntity
        .status(HttpStatus.INTERNAL_SERVER_ERROR)
        .contentType(PROBLEM_JSON)
        .body(problem);
  }
}
```

#### 6.2 응답 예시

**비즈니스 에러 (로그인 실패):**
```json
{
  "type": "https://api.linkwave.io/errors/auth/invalid-credentials",
  "title": "Invalid Credentials",
  "status": 401,
  "detail": "The email or password is incorrect",
  "instance": "/api/v1/auth/login"
}
```

**검증 에러 (회원가입):**
```json
{
  "type": "https://api.linkwave.io/errors/invalid-input",
  "title": "Invalid Input",
  "status": 400,
  "detail": "입력값 검증에 실패했습니다",
  "instance": "/api/v1/auth/signup",
  "errors": [
    { "field": "email", "message": "이메일 형식이 올바르지 않습니다", "rejectedValue": "invalid" },
    { "field": "password", "message": "8자 이상이어야 합니다", "rejectedValue": null }
  ]
}
```

---


### 7. 구현 Step 4: JwtAuthenticationEntryPoint 수정

#### 7.1 파일 수정

**경로**: `linkwave-backend/src/main/java/io/iotree.linkwave/common/security/JwtAuthenticationEntryPoint.java`

```java
package io.iotree.linkwave.common.security;

import com.fasterxml.jackson.databind.ObjectMapper;
import io.iotree.linkwave.common.exception.ErrorType;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.net.URI;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ProblemDetail;
import org.springframework.lang.NonNull;
import org.springframework.security.core.AuthenticationException;
import org.springframework.security.web.AuthenticationEntryPoint;
import org.springframework.stereotype.Component;

/**
 * 인증되지 않은 요청 처리
 *
 * Spring Security 필터 체인에서 인증 실패 시 호출됩니다.
 * GlobalExceptionHandler보다 먼저 실행되므로 직접 응답을 작성해야 합니다.
 *
 * 호출 시점:
 * - Authorization 헤더가 없는 경우
 * - 토큰이 유효하지 않은 경우 (JwtAuthenticationFilter에서 처리 후)
 */
@Component
@RequiredArgsConstructor
public class JwtAuthenticationEntryPoint implements AuthenticationEntryPoint {

  private final ObjectMapper objectMapper;

  @Override
  public void commence(
      @NonNull HttpServletRequest request,
      @NonNull HttpServletResponse response,
      @NonNull AuthenticationException authException)
      throws IOException, ServletException {

    // HTTP 응답 설정
    response.setStatus(HttpStatus.UNAUTHORIZED.value());
    response.setContentType(MediaType.APPLICATION_PROBLEM_JSON_VALUE);
    response.setCharacterEncoding("UTF-8");

    // ProblemDetail 생성
    ProblemDetail problem = ProblemDetail.forStatus(HttpStatus.UNAUTHORIZED);
    problem.setType(ErrorType.UNAUTHORIZED.getTypeUri());
    problem.setTitle(ErrorType.UNAUTHORIZED.getTitle());
    problem.setDetail("인증이 필요합니다. 로그인 후 다시 시도해주세요.");
    problem.setInstance(URI.create(request.getRequestURI()));

    // JSON으로 직렬화하여 응답
    response.getWriter().write(objectMapper.writeValueAsString(problem));
  }
}
```

---


### 8. 구현 Step 5: Service 클래스 마이그레이션

#### 8.1 변경 대상 파일 목록

다음 파일들에서 `ErrorCode` → `ErrorType`으로 변경합니다:

```
linkwave-backend/src/main/java/io/iotree.linkwave/
├── application/service/
│   ├── AuthService.java
│   ├── UserService.java
│   ├── MessageService.java
│   └── SenderNumberService.java
└── common/security/
    └── JwtTokenProvider.java
```

#### 8.2 변경 방법 (AuthService.java 예시)

**Before:**
```java
import io.iotree.linkwave.common.exception.ErrorCode;

// ...

UserLoginQueryDto user = userQueryMapper
    .findByUsername(request.username())
    .orElseThrow(() -> new BusinessException(ErrorCode.USER_NOT_FOUND));

if (!passwordEncoder.matches(request.password(), user.password())) {
  throw new BusinessException(ErrorCode.INVALID_CREDENTIALS);
}
```

**After:**
```java
import io.iotree.linkwave.common.exception.ErrorType;  // 변경된 import

// ...

UserLoginQueryDto user = userQueryMapper
    .findByUsername(request.username())
    .orElseThrow(() -> new BusinessException(ErrorType.USER_NOT_FOUND));  // ErrorCode → ErrorType

if (!passwordEncoder.matches(request.password(), user.password())) {
  throw new BusinessException(ErrorType.INVALID_CREDENTIALS);  // ErrorCode → ErrorType
}
```

#### 8.3 IDE 리팩토링 팁

IntelliJ IDEA에서:
1. `ErrorCode`에 커서를 놓고 `Shift + F6` (Rename)
2. 또는 `Ctrl + Shift + R` (Replace in Path)로 일괄 변경

---


### 9. 구현 Step 6: Frontend 타입 정의

#### 9.1 파일 수정

**경로**: `linkwave-frontend/src/types/api.ts`

```typescript
// ======================================== 
// RFC 9457 Problem Details 타입 정의
// ======================================== 

/**
 * RFC 9457 Problem Details 인터페이스
 *
 * 서버에서 에러 발생 시 반환되는 표준 형식입니다.
 * Content-Type: application/problem+json
 */
export interface ProblemDetail {
  /** 에러 유형 URI (예: "https://api.linkwave.io/errors/auth/invalid-credentials") */
  type: string

  /** 에러 제목 (예: "Invalid Credentials") */
  title: string

  /** HTTP 상태 코드 (예: 401) */
  status: number

  /** 이 요청에서 발생한 구체적인 에러 설명 */
  detail: string

  /** 문제가 발생한 요청 URI (예: "/api/v1/auth/login") */
  instance: string

  /**
   * 확장 필드: 검증 에러 목록 (optional)
   * @Valid 검증 실패 시 포함됩니다.
   */
  errors?: ValidationError[]

  /** 기타 확장 필드를 허용 */
  [key: string]: unknown
}

/**
 * 검증 에러 상세 (필드별)
 */
export interface ValidationError {
  /** 필드명 (예: "email") */
  field: string

  /** 에러 메시지 (예: "이메일 형식이 올바르지 않습니다") */
  message: string

  /** 거부된 값 (예: "invalid-email") */
  rejectedValue?: unknown
}

// ======================================== 
// Error Type 상수 (Backend와 동기화)
// ======================================== 

/**
 * 에러 타입 URI 상수
 *
 * Backend의 ErrorType enum과 1:1 매핑됩니다.
 * 에러 타입별 분기 처리에 사용합니다.
 *
 * 사용 예시:
 * ```typescript
 * if (error.problem.type === ErrorType.INVALID_CREDENTIALS) {
 *   // 로그인 실패 처리
 * }
 * ```
 */
export const ErrorType = {
  // Common
  INVALID_INPUT: 'https://api.linkwave.io/errors/invalid-input',
  INTERNAL_ERROR: 'https://api.linkwave.io/errors/internal-error',

  // Auth
  INVALID_CREDENTIALS: 'https://api.linkwave.io/errors/auth/invalid-credentials',
  INVALID_TOKEN: 'https://api.linkwave.io/errors/auth/invalid-token',
  EXPIRED_TOKEN: 'https://api.linkwave.io/errors/auth/expired-token',
  REFRESH_TOKEN_NOT_FOUND: 'https://api.linkwave.io/errors/auth/refresh-token-not-found',
  REFRESH_TOKEN_EXPIRED: 'https://api.linkwave.io/errors/auth/refresh-token-expired',
  UNAUTHORIZED: 'https://api.linkwave.io/errors/auth/unauthorized',

  // Users
  USER_NOT_FOUND: 'https://api.linkwave.io/errors/users/not-found',
  DUPLICATE_EMAIL: 'https://api.linkwave.io/errors/users/duplicate-email',
  DUPLICATE_PHONE: 'https://api.linkwave.io/errors/users/duplicate-phone',
  USER_INACTIVE: 'https://api.linkwave.io/errors/users/inactive',

  // Organizations
  ORGANIZATION_NOT_FOUND: 'https://api.linkwave.io/errors/organizations/not-found',

  // Messages
  MESSAGE_NOT_FOUND: 'https://api.linkwave.io/errors/messages/not-found',
  INVALID_PHONE_NUMBER: 'https://api.linkwave.io/errors/messages/invalid-phone',
  SENDER_NOT_FOUND: 'https://api.linkwave.io/errors/messages/sender-not-found',
  SENDER_NOT_VERIFIED: 'https://api.linkwave.io/errors/messages/sender-not-verified',
  SENDER_NOT_OWNED: 'https://api.linkwave.io/errors/messages/sender-not-owned',
} as const

/** ErrorType 값의 유니온 타입 */
export type ErrorTypeValue = (typeof ErrorType)[keyof typeof ErrorType]

// ======================================== 
// 헬퍼 함수
// ======================================== 

/**
 * ProblemDetail이 특정 에러 타입인지 확인
 *
 * @param problem ProblemDetail 객체
 * @param type 확인할 에러 타입
 * @returns 매칭 여부
 *
 * @example
 * ```typescript
 * if (isErrorType(error.problem, ErrorType.INVALID_CREDENTIALS)) {
 *   // 로그인 실패 처리
 * }
 * ```
 */
export function isErrorType(problem: ProblemDetail, type: ErrorTypeValue): boolean {
  return problem.type === type
}

/**
 * 인증 관련 에러인지 확인
 *
 * @param problem ProblemDetail 객체
 * @returns 인증 에러 여부
 */
export function isAuthError(problem: ProblemDetail): boolean {
  return problem.type.includes('/auth/')
}

// ======================================== 
// 기존 ApiResponse (성공 응답용으로 유지)
// ======================================== 

/**
 * 성공 응답 래퍼
 *
 * 에러 응답은 ProblemDetail을 직접 사용하므로,
 * 이 타입은 성공 응답에만 사용됩니다.
 */
export interface ApiResponse<T = unknown> {
  success: boolean
  data: T | null
  timestamp: string
}
```

---


### 10. 구현 Step 7: Axios Client 수정

#### 10.1 파일 수정

**경로**: `linkwave-frontend/src/api/client.ts`

```typescript
import { useAuthStore } from '@/stores/authStore'
import type { ProblemDetail } from '@/types/api'
import { ErrorType, isErrorType } from '@/types/api'
import axios, { AxiosError, AxiosInstance, AxiosResponse, InternalAxiosRequestConfig } from 'axios'

// ======================================== 
// ApiError 클래스 정의
// ======================================== 

/**
 * API 에러 클래스
 *
 * RFC 9457 ProblemDetail을 감싸는 커스텀 에러 클래스입니다.
 * catch 블록에서 instanceof로 타입 체크할 수 있습니다.
 *
 * @example
 * ```typescript
 * try {
 *   await authApi.login(credentials)
 * } catch (error) {
 *   if (error instanceof ApiError) {
 *     console.log(error.type)    // 에러 타입 URI
 *     console.log(error.status)  // HTTP 상태 코드
 *     console.log(error.detail)  // 상세 메시지
 *   }
 * }
 * ```
 */
export class ApiError extends Error {
  constructor(public readonly problem: ProblemDetail) {
    super(problem.detail || problem.title)
    this.name = 'ApiError'
  }

  /** 에러 타입 URI */
  get type(): string {
    return this.problem.type
  }

  /** HTTP 상태 코드 */
  get status(): number {
    return this.problem.status
  }

  /** 에러 제목 */
  get title(): string {
    return this.problem.title
  }

  /** 상세 메시지 */
  get detail(): string {
    return this.problem.detail
  }

  /** 검증 에러 목록 (있는 경우) */
  get validationErrors() {
    return this.problem.errors
  }

  /**
   * 특정 에러 타입인지 확인
   *
   * @example
   * ```typescript
   * if (error.isType(ErrorType.INVALID_CREDENTIALS)) {
   *   // 로그인 실패 처리
   * }
   * ```
   */
  isType(errorType: string): boolean {
    return this.problem.type === errorType
  }
}

// ======================================== 
// Silent Refresh 동시 요청 처리
// ======================================== 

/** 토큰 갱신 중 여부 */
let isRefreshing = false

/** 토큰 갱신 대기열 (동시 요청 처리용) */
let failedQueue: Array<{ 
  resolve: (token: string) => void
  reject: (error: Error) => void
}> = []

/**
 * 대기열 처리
 * 토큰 갱신 완료 후 대기 중인 요청들을 처리합니다.
 */
const processQueue = (error: Error | null, token: string | null = null) => {
  failedQueue.forEach((prom) => {
    if (error) {
      prom.reject(error)
    } else if (token) {
      prom.resolve(token)
    }
  })
  failedQueue = []
}

// ======================================== 
// Axios 인스턴스 생성
// ======================================== 

const client: AxiosInstance = axios.create({
  baseURL: import.meta.env.VITE_API_BASE_URL || '/api/v1',
  timeout: 30000,
  headers: { 'Content-Type': 'application/json' },
  withCredentials: true,  // 쿠키 포함 (refresh token)
})

// ======================================== 
// Request Interceptor
// ======================================== 

client.interceptors.request.use(
  (config: InternalAxiosRequestConfig) => {
    // Access Token을 Authorization 헤더에 추가
    const token = useAuthStore.getState().token
    if (token && config.headers) {
      config.headers.Authorization = `Bearer ${token}`
    }
    return config
  },
  (error: AxiosError) => Promise.reject(error)
)

// ======================================== 
// Response Interceptor
// ======================================== 

client.interceptors.response.use(
  // 성공 응답: data만 추출하여 반환
  (response: AxiosResponse) => response.data,

  // 에러 응답: ProblemDetail 처리
  async (error: AxiosError<ProblemDetail>) => {
    const originalRequest = error.config as InternalAxiosRequestConfig & { _retry?: boolean }

    // ProblemDetail 형식인지 확인
    const problem = error.response?.data
    const isProblemDetail = problem?.type && problem?.status

    // ---------------------------------------- 
    // 401 에러 + 토큰 만료: Silent Refresh 시도
    // ---------------------------------------- 
    if (
      error.response?.status === 401 &&
      !originalRequest._retry &&
      isProblemDetail &&
      isErrorType(problem, ErrorType.EXPIRED_TOKEN)
    ) {
      // 이미 갱신 중이면 대기열에 추가
      if (isRefreshing) {
        return new Promise<string>((resolve, reject) => {
          failedQueue.push({ resolve, reject })
        }).then((token) => {
          originalRequest.headers.Authorization = `Bearer ${token}`
          return client(originalRequest)
        })
      }

      originalRequest._retry = true
      isRefreshing = true

      try {
        // Refresh 엔드포인트 호출 (쿠키에서 refreshToken 자동 전송)
        const response = await axios.post(
          `${import.meta.env.VITE_API_BASE_URL || '/api/v1'}/auth/refresh`,
          {},
          { withCredentials: true }
        )

        const newAccessToken = response.data.data?.accessToken
        useAuthStore.getState().updateToken(newAccessToken)

        processQueue(null, newAccessToken)

        originalRequest.headers.Authorization = `Bearer ${newAccessToken}`
        return client(originalRequest)
      } catch (refreshError) {
        processQueue(refreshError as Error, null)

        // 로그아웃 처리
        useAuthStore.getState().logout()
        window.location.href = '/login'

        return Promise.reject(refreshError)
      } finally {
        isRefreshing = false
      }
    }

    // ---------------------------------------- 
    // ProblemDetail 형식이면 ApiError로 래핑
    // ---------------------------------------- 
    if (isProblemDetail) {
      throw new ApiError(problem)
    }

    // ---------------------------------------- 
    // 기타 에러는 그대로 throw
    // ---------------------------------------- 
    throw error
  }
)

export default client
```

---


### 11. 구현 Step 8: API 모듈 수정

#### 11.1 authApi.ts 수정 예시

**경로**: `linkwave-frontend/src/api/authApi.ts`

```typescript
import client, { ApiError } from './client'
import { ErrorType } from '@/types/api'
import type { LoginResponse } from '@/types/auth'

export const authApi = {
  /**
   * 로그인
   *
   * @throws {ApiError} 로그인 실패 시
   */
  login: async (credentials: { username: string; password: string }): Promise<LoginResponse> => {
    // 성공 시 response.data 반환 (interceptor에서 처리)
    return client.post('/auth/login', credentials)
  },
}

// ======================================== 
// 사용 예시 (컴포넌트에서)
// ======================================== 

/*
import { authApi } from '@/api/authApi'
import { ApiError } from '@/api/client'
import { ErrorType } from '@/types/api'
import { showError } from '@/utils/toast'

const handleLogin = async () => {
  try {
    const response = await authApi.login({ username, password })
    // 성공 처리
  } catch (error) {
    if (error instanceof ApiError) {
      // 에러 타입별 분기 처리
      if (error.isType(ErrorType.INVALID_CREDENTIALS)) {
        showError('이메일 또는 비밀번호가 올바르지 않습니다')
      } else if (error.isType(ErrorType.USER_INACTIVE)) {
        showError('비활성화된 계정입니다. 관리자에게 문의하세요.')
      } else {
        // 기타 에러: 서버에서 온 메시지 표시
        showError(error.detail)
      }
    } else {
      // 네트워크 에러 등
      showError('서버와 통신할 수 없습니다')
    }
  }
}
*/
```

#### 11.2 toast.ts 수정

**경로**: `linkwave-frontend/src/utils/toast.ts`

```typescript
import { ApiError } from '@/api/client'
import hotToast from 'react-hot-toast'

/**
 * 에러 토스트 표시
 *
 * ApiError, Error, 문자열 모두 처리합니다.
 *
 * @param message 기본 메시지
 * @param error 에러 객체 (optional)
 */
export const showError = (message: string, error?: Error | unknown) => {
  let errorMessage = message

  // ApiError: RFC 9457 ProblemDetail에서 메시지 추출
  if (error instanceof ApiError) {
    errorMessage = error.detail || error.title || message
  }
  // 일반 Error
  else if (error instanceof Error) {
    errorMessage = error.message || message
  }
  // Axios 에러 (ProblemDetail이 아닌 경우)
  else if (typeof error === 'object' && error !== null && 'response' in error) {
    const axiosError = error as { response?: { data?: { message?: string } } }
    errorMessage = axiosError.response?.data?.message || message
  }

  hotToast.error(errorMessage, {
    duration: 4000,
    position: 'top-right',
  })
}

export const showSuccess = (message: string) => {
  hotToast.success(message, {
    duration: 3000,
    position: 'top-right',
  })
}

export const showInfo = (message: string) => {
  hotToast(message, {
    duration: 3000,
    position: 'top-right',
  })
}

export const showWarning = (message: string) => {
  hotToast(message, {
    icon: '⚠️',
    duration: 3500,
    position: 'top-right',
  })
}
```

---


## 정리

### 12. 구현 Step 9: 정리 및 삭제 (Backend)

구현 완료 후 아래 파일들을 삭제합니다:

```bash
# 기존 ErrorCode enum 삭제
rm linkwave-backend/src/main/java/io/iotree.linkwave/common/exception/ErrorCode.java

# 기존 ErrorResponse DTO 삭제 (ProblemDetail로 대체)
rm linkwave-backend/src/main/java/io/iotree.linkwave/application/dto/response/ErrorResponse.java
```

### 12.3 정리 및 삭제 (Frontend)

`types/api.ts`에서 기존 ErrorCode 상수 삭제:

```typescript
// 삭제할 코드
export const ErrorCode = {
  INTERNAL_SERVER_ERROR: 'E000',
  INVALID_INPUT: 'E001',
  // ...
} as const
```

---


## 테스트 및 검증

### 13.1 Backend 테스트

```bash
# 전체 테스트
cd linkwave-backend
./gradlew test

# ExceptionHandler 관련 테스트만
./gradlew test --tests "*ExceptionHandler*"
```

### 13.2 수동 테스트 (curl)

```bash
# 로그인 실패 테스트
curl -X POST http://localhost:8080/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"wrong@email.com","password":"wrongpassword"}' \
  -v

# 예상 응답 헤더:
# Content-Type: application/problem+json

# 예상 응답 본문:
# {
#   "type": "https://api.linkwave.io/errors/auth/invalid-credentials",
#   "title": "Invalid Credentials",
#   "status": 401,
#   "detail": "...",
#   "instance": "/api/v1/auth/login"
# }
```

### 13.3 Frontend 빌드 확인

```bash
cd linkwave-frontend
npm run build

# 타입 에러가 없어야 합니다
```

### 13.4 E2E 체크리스트

| 시나리오 | 확인 사항 |
|----------|----------|
| 로그인 실패 | `type`이 `auth/invalid-credentials` 포함 |
| 회원가입 검증 실패 | `errors` 배열에 필드별 에러 포함 |
| 401 + EXPIRED_TOKEN | Silent Refresh 동작 |
| 401 + 기타 | 로그인 페이지로 리다이렉트 |

---


## 트러블슈팅

### 14.1 Content-Type이 application/json으로 반환됨

**원인**: `GlobalExceptionHandler`에서 `.contentType(PROBLEM_JSON)` 누락

**해결**:
```java
return ResponseEntity
    .status(...)
    .contentType(MediaType.APPLICATION_PROBLEM_JSON)  // 이 줄 확인
    .body(problem);
```

### 14.2 Frontend에서 error.problem이 undefined

**원인**: Axios interceptor에서 ProblemDetail 형식 체크 실패

**해결**: 응답 구조 확인
```typescript
const problem = error.response?.data
const isProblemDetail = problem?.type && problem?.status  // type과 status 필수
```

### 14.3 import 에러: ErrorCode를 찾을 수 없음

**원인**: 마이그레이션 중 일부 파일에서 ErrorCode 참조 남아있음

**해결**:
```bash
# 남은 ErrorCode 참조 검색
grep -r "ErrorCode" --include="*.java" linkwave-backend/src/main/
grep -r "ErrorCode" --include="*.ts" linkwave-frontend/src/
```

### 14.4 로그인 실패 시 Silent Refresh 무한 루프

**원인**: INVALID_CREDENTIALS와 EXPIRED_TOKEN 구분 실패

**해결**: interceptor에서 정확히 EXPIRED_TOKEN만 체크
```typescript
if (isErrorType(problem, ErrorType.EXPIRED_TOKEN)) {
  // Silent Refresh
} else {
  // 다른 401 에러는 그냥 throw
  throw new ApiError(problem)
}
```

---


## References

- [RFC 9457 - Problem Details for HTTP APIs](https://www.rfc-editor.org/rfc/rfc9457.html)
- [Spring Boot ProblemDetail 문서](https://docs.spring.io/spring-framework/reference/web/webmvc/mvc-ann-rest-exceptions.html)
- [Zalando Problem Library (참고용)](https://github.com/zalando/problem)