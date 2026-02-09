---
created: 2025-12-26
---
# Phase 1: 예외 처리 및 공통 구조

## 📖 개념 설명

### 왜 공통 예외 처리가 필요한가?

1. **일관된 에러 응답**: 모든 API에서 동일한 형식의 에러 응답
2. **코드 중복 제거**: Controller마다 try-catch 작성 불필요
3. **유지보수성 향상**: 에러 처리 로직을 한 곳에서 관리

### 구조

```
common/exception/
├── ErrorCode.java              # 에러 코드 enum
├── BusinessException.java      # 비즈니스 예외
└── GlobalExceptionHandler.java # 전역 예외 처리기

model/dto/
├── ApiResponse.java            # 공통 응답 래퍼
└── ErrorResponse.java          # 에러 응답 DTO
```

## 🎯 구현 목표

- [ ] ErrorCode enum 작성
- [ ] BusinessException 작성
- [ ] ErrorResponse DTO 작성
- [ ] ApiResponse DTO 작성
- [ ] GlobalExceptionHandler 작성

---

## 📝 1. ErrorCode.java

**위치**: `src/main/java/io/iotree/linkwave/common/exception/ErrorCode.java`

### 설명
- HTTP 상태 코드와 별도로 애플리케이션 에러 코드 관리
- 클라이언트가 에러 타입을 구분할 수 있도록 명확한 코드 부여

### 필드 구조
- `status` (int): HTTP 상태 코드 (400, 401, 404 등)
- `code` (String): 애플리케이션 에러 코드 ("U001", "A002" 등)
- `message` (String): 에러 메시지

### 전체 코드

```java
package io.iotree.linkwave.common.exception;

import lombok.Getter;
import lombok.RequiredArgsConstructor;

@Getter
@RequiredArgsConstructor
public enum ErrorCode {
  // 공통
  INVALID_INPUT_VALUE(400, "C001", "Invalid input value"),
  INTERNAL_SERVER_ERROR(500, "C002", "Internal server error"),

  // 인증
  INVALID_CREDENTIALS(401, "A001", "Invalid email or password"),
  INVALID_TOKEN(401, "A002", "Invalid or expired token"),
  EXPIRED_TOKEN(401, "A003", "Token has expired"),
  REFRESH_TOKEN_NOT_FOUND(401, "A004", "Refresh token not found"),
  REFRESH_TOKEN_EXPIRED(401, "A005", "Refresh token has expired"),
  UNAUTHORIZED(401, "A006", "Unauthorized"),

  // 사용자
  USER_NOT_FOUND(404, "U001", "User not found"),
  DUPLICATE_EMAIL(409, "U002", "Email already exists"),
  USER_INACTIVE(403, "U003", "User account is inactive or locked"),

  // 조직
  ORGANIZATION_NOT_FOUND(404, "ORG001", "Organization not found"),
  DUPLICATE_BUSINESS_NUMBER(409, "ORG002", "Business number already exists");

  private final int status;
  private final String code;
  private final String message;
}
```

### 체크포인트
- [ ] enum 값들이 논리적으로 그룹화되어 있나요? (공통, 인증, 사용자, 회사 등)
- [ ] HTTP 상태 코드가 올바른가요?
- [ ] 에러 코드(code)가 중복되지 않나요?

---

## 📝 2. BusinessException.java

**위치**: `src/main/java/io/iotree/linkwave/common/exception/BusinessException.java`

### 설명
- 비즈니스 로직에서 발생하는 예외를 나타내는 커스텀 예외
- ErrorCode를 포함하여 어떤 에러인지 명확히 전달

### 전체 코드

```java
package io.iotree.linkwave.common.exception;

import lombok.Getter;

@Getter
public class BusinessException extends RuntimeException {
  private final ErrorCode errorCode;

  public BusinessException(ErrorCode errorCode) {
    super(errorCode.getMessage());
    this.errorCode = errorCode;
  }

  public BusinessException(ErrorCode errorCode, String message) {
    super(message);
    this.errorCode = errorCode;
  }

  public BusinessException(ErrorCode errorCode, String message, Throwable cause) {
    super(message, cause);
    this.errorCode = errorCode;
  }
}
```

### 사용 예시

```java
// Service에서 사용
if (userRepository.existsByEmail(email)) {
    throw new BusinessException(ErrorCode.DUPLICATE_EMAIL);
}
```

### 체크포인트
- [ ] RuntimeException을 상속하고 있나요? (Checked Exception이 아닌 Unchecked Exception)
- [ ] errorCode를 Getter로 접근할 수 있나요?

---

## 📝 3. ErrorResponse.java

**위치**: `src/main/java/io/iotree/linkwave/application/dto/response/ErrorResponse.java`

### 설명
- 에러 발생 시 클라이언트에게 전달할 에러 응답 DTO
- Validation 에러 시 어떤 필드에서 에러가 발생했는지 상세 정보 포함

### 전체 코드

```java
package io.iotree.linkwave.application.dto.response;

import java.util.ArrayList;
import java.util.List;
import lombok.Builder;
import lombok.Getter;

@Getter
@Builder
public class ErrorResponse {
  private String errorCode;
  private String message;

  @Builder.Default
  private List<FieldError> fieldErrors = new ArrayList<>();

  @Getter
  @Builder
  public static class FieldError {
    private String field;
    private String value;
    private String message;
  }
}
```

### 응답 예시

```json
{
  "errorCode": "U002",
  "message": "Email already exists",
  "fieldErrors": []
}
```

### Validation 에러 응답 예시

```json
{
  "errorCode": "C001",
  "message": "Invalid input value",
  "fieldErrors": [
    {
      "field": "email",
      "value": "invalid-email",
      "message": "이메일 형식이 올바르지 않습니다"
    }
  ]
}
```

### 체크포인트
- [ ] `@Builder.Default`로 fieldErrors 초기화했나요?
- [ ] 내부 클래스 FieldError도 @Builder가 있나요?

---

## 📝 4. ApiResponse.java

**위치**: `src/main/java/io/iotree/linkwave/application/dto/response/ApiResponse.java`

### 설명
- 모든 API 응답을 감싸는 공통 래퍼
- 성공/실패 여부, 데이터, 에러 정보, 타임스탬프 포함

### 전체 코드

```java
package io.iotree.linkwave.application.dto.response;

import com.fasterxml.jackson.annotation.JsonInclude;
import java.time.LocalDateTime;
import lombok.AllArgsConstructor;
import lombok.Getter;

@Getter
@AllArgsConstructor
@JsonInclude(JsonInclude.Include.NON_NULL)
public class ApiResponse<T> {
  private boolean success;
  private T data;
  private ErrorResponse error;
  private LocalDateTime timestamp;

  // 성공 응답 (데이터 있음)
  public static <T> ApiResponse<T> success(T data) {
    return new ApiResponse<>(true, data, null, LocalDateTime.now());
  }

  // 성공 응답 (데이터 없음)
  public static <T> ApiResponse<T> success() {
    return new ApiResponse<>(true, null, null, LocalDateTime.now());
  }

  // 에러 응답
  public static <T> ApiResponse<T> error(ErrorResponse error) {
    return new ApiResponse<>(false, null, error, LocalDateTime.now());
  }
}
```

### 성공 응답 예시

```json
{
  "success": true,
  "data": {
    "id": 1,
    "name": "홍길동"
  },
  "timestamp": "2025-12-10T15:30:00"
}
```

### 에러 응답 예시

```json
{
  "success": false,
  "error": {
    "errorCode": "U001",
    "message": "User not found"
  },
  "timestamp": "2025-12-10T15:30:00"
}
```

### 체크포인트
- [ ] 제네릭 `<T>`를 사용하여 다양한 타입의 데이터를 담을 수 있나요?
- [ ] `@JsonInclude(JsonInclude.Include.NON_NULL)`로 null 필드는 응답에서 제외되나요?
- [ ] 정적 팩토리 메서드 `success()`, `error()`를 제공하나요?

---

## 📝 5. GlobalExceptionHandler.java

**위치**: `src/main/java/io/iotree/linkwave/common/exception/GlobalExceptionHandler.java`

### 설명
- `@RestControllerAdvice`로 전역 예외를 한 곳에서 처리
- 다양한 예외 타입별로 적절한 응답 생성

### 전체 코드

```java
package io.iotree.linkwave.common.exception;

import io.iotree.linkwave.application.dto.response.ApiResponse;
import io.iotree.linkwave.application.dto.response.ErrorResponse;
import java.util.List;
import java.util.stream.Collectors;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.validation.BindException;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;

@Slf4j
@RestControllerAdvice
public class GlobalExceptionHandler {

  // BusinessException 처리
  @ExceptionHandler(BusinessException.class)
  public ResponseEntity<ApiResponse<Void>> handleBusinessException(BusinessException e) {
    log.error("BusinessException: {}", e.getMessage(), e);

    ErrorResponse errorResponse =
        ErrorResponse.builder()
            .errorCode(e.getErrorCode().getCode())
            .message(e.getMessage())
            .build();

    return ResponseEntity.status(e.getErrorCode().getStatus())
        .body(ApiResponse.error(errorResponse));
  }

  // @Valid 검증 실패 처리
  @ExceptionHandler(MethodArgumentNotValidException.class)
  public ResponseEntity<ApiResponse<Void>> handleMethodArgumentNotValidException(
      MethodArgumentNotValidException e) {
    log.error("MethodArgumentNotValidException: {}", e.getMessage());

    List<ErrorResponse.FieldError> fieldErrors =
        e.getBindingResult().getFieldErrors().stream()
            .map(
                error ->
                    ErrorResponse.FieldError.builder()
                        .field(error.getField())
                        .value(error.getRejectedValue() != null ? error.getRejectedValue().toString() : null)
                        .message(error.getDefaultMessage())
                        .build())
            .collect(Collectors.toList());

    ErrorResponse errorResponse =
        ErrorResponse.builder()
            .errorCode(ErrorCode.INVALID_INPUT_VALUE.getCode())
            .message(ErrorCode.INVALID_INPUT_VALUE.getMessage())
            .fieldErrors(fieldErrors)
            .build();

    return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(ApiResponse.error(errorResponse));
  }

  // BindException 처리
  @ExceptionHandler(BindException.class)
  public ResponseEntity<ApiResponse<Void>> handleBindException(BindException e) {
    log.error("BindException: {}", e.getMessage());

    List<ErrorResponse.FieldError> fieldErrors =
        e.getBindingResult().getFieldErrors().stream()
            .map(
                error ->
                    ErrorResponse.FieldError.builder()
                        .field(error.getField())
                        .value(error.getRejectedValue() != null ? error.getRejectedValue().toString() : null)
                        .message(error.getDefaultMessage())
                        .build())
            .collect(Collectors.toList());

    ErrorResponse errorResponse =
        ErrorResponse.builder()
            .errorCode(ErrorCode.INVALID_INPUT_VALUE.getCode())
            .message(ErrorCode.INVALID_INPUT_VALUE.getMessage())
            .fieldErrors(fieldErrors)
            .build();

    return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(ApiResponse.error(errorResponse));
  }

  // 예상하지 못한 예외 처리
  @ExceptionHandler(Exception.class)
  public ResponseEntity<ApiResponse<Void>> handleException(Exception e) {
    log.error("Unexpected Exception: {}", e.getMessage(), e);

    ErrorResponse errorResponse =
        ErrorResponse.builder()
            .errorCode(ErrorCode.INTERNAL_SERVER_ERROR.getCode())
            .message(ErrorCode.INTERNAL_SERVER_ERROR.getMessage())
            .build();

    return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
        .body(ApiResponse.error(errorResponse));
  }
}
```

### 주요 메서드 설명

#### 1. handleBusinessException
- 비즈니스 로직에서 발생한 예외 처리
- ErrorCode의 status를 HTTP 상태 코드로 사용

#### 2. handleMethodArgumentNotValidException
- `@Valid` 검증 실패 시 처리
- 어떤 필드가 왜 실패했는지 상세 정보 포함

#### 3. handleException
- 예상하지 못한 모든 예외를 500 에러로 처리
- 실제 에러 메시지는 로그에만 기록 (보안)

### 체크포인트
- [ ] `@RestControllerAdvice` 어노테이션이 있나요?
- [ ] 각 ExceptionHandler가 적절한 HTTP 상태 코드를 반환하나요?
- [ ] 로그에 에러 정보가 기록되나요?

---

## ✅ 완료 체크리스트

- [ ] ErrorCode.java 작성 완료
- [ ] BusinessException.java 작성 완료
- [ ] ErrorResponse.java 작성 완료
- [ ] ApiResponse.java 작성 완료
- [ ] GlobalExceptionHandler.java 작성 완료
- [ ] 모든 파일에 package 선언이 올바른가요?
- [ ] import 문이 정리되어 있나요?
- [ ] `./gradlew spotlessApply` 실행했나요?

---

## 🧪 테스트 방법

현재 단계에서는 직접 테스트하기 어렵습니다. Phase 2에서 Controller를 만든 후 테스트할 수 있습니다.

임시로 간단한 Controller를 만들어서 테스트해볼 수 있습니다:

```java
@RestController
@RequestMapping("/test")
public class TestController {

    @GetMapping("/error")
    public String testError() {
        throw new BusinessException(ErrorCode.USER_NOT_FOUND);
    }
}
```

---

## 🔍 자주하는 실수

### 1. ErrorCode enum에 괄호 없이 작성
❌ 잘못된 예:
```java
USER_NOT_FOUND; // 세미콜론만 있음
```

✅ 올바른 예:
```java
USER_NOT_FOUND(404, "U001", "User not found");
```

### 2. @RestControllerAdvice 누락
GlobalExceptionHandler에 반드시 `@RestControllerAdvice` 필요

### 3. static 팩토리 메서드를 static으로 선언 안 함
ApiResponse의 `success()`, `error()` 메서드는 반드시 `static`이어야 합니다.

---

**축하합니다! Phase 1 완료!** 🎉

다음 단계로 이동: 👉 [02-COMPANY-DOMAIN.md](./02-COMPANY-DOMAIN.md)
