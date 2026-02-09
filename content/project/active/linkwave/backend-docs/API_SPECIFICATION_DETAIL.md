---
created: 2025-12-26
---
# LinkWave API 명세서 (상세)

이 문서는 LinkWave 백엔드의 각 Controller에 포함될 API 엔드포인트의 상세 명세를 정의합니다.

---

## 1. AuthController

인증 및 사용자 계정 관련 API를 담당합니다.

- **Class**: `io.iotree.linkwave.api.AuthController`
- **Base URL**: `/api/v1/auth`

### 1.1. (신규) 휴대폰 인증번호 요청

- **HTTP Method**: `POST`
- **URL**: `/api/v1/auth/phone/request-verification`
- **Controller Method**: `requestPhoneVerification(RequestPhoneVerificationRequest request)`
- **설명**: 회원가입을 위해 휴대폰 인증번호(SMS)를 요청합니다. 요청 시 휴대폰 번호의 중복 여부를 먼저 확인합니다.
- **권한**: `permitAll` (인증 불필요)
- **Request Body**: `RequestPhoneVerificationRequest.java`
  ```java
  public class RequestPhoneVerificationRequest {
    @NotBlank @Pattern(regexp = "^010-?\\d{4}-?\\d{4}$")
    private String phone; // 인증할 휴대폰 번호
  }
  ```
- **성공 응답 (200 OK)**:
  - Body: `ApiResponse<Void>`
- **실패 응답 (409 Conflict)**:
  - 휴대폰 번호가 이미 등록된 경우 `DUPLICATE_PHONE` 에러 코드를 반환합니다.

### 1.2. (신규) 휴대폰 인증번호 확인

- **HTTP Method**: `POST`
- **URL**: `/api/v1/auth/phone/verify`
- **Controller Method**: `verifyPhone(VerifyPhoneRequest request)`
- **설명**: 발송된 SMS 인증번호를 확인합니다. 성공 시, 회원가입 단계에서 사용할 짧은 만료 시간(예: 5분)을 가진 `phoneVerificationToken`을 발급합니다.
- **권한**: `permitAll` (인증 불필요)
- **Request Body**: `VerifyPhoneRequest.java`
  ```java
  public class VerifyPhoneRequest {
    @NotBlank @Pattern(regexp = "^010-?\\d{4}-?\\d{4}$")
    private String phone;
    @NotBlank @Size(min = 6, max = 6)
    private String verificationCode; // 6자리 인증번호
  }
  ```
- **성공 응답 (200 OK)**:
  - Body: `ApiResponse<VerifyPhoneResponse>`
    ```json
    {
      "success": true,
      "data": {
        "phoneVerificationToken": "..." // 회원가입 시 사용할 토큰
      },
      "error": null,
      "timestamp": "..."
    }
    ```

### 1.3. 회원 가입

- **HTTP Method**: `POST`
- **URL**: `/api/v1/auth/signup`
- **Controller Method**: `signup(SignUpRequest request)`
- **설명**: 새로운 사용자를 등록합니다. username(로그인 아이디)과 비밀번호로 회원가입하며, 이메일은 선택 사항입니다. 개인/법인 회원 가입을 모두 처리하며, 가입 성공 시 로그인과 동일한 형식으로 토큰과 사용자 정보가 응답 Body에 포함됩니다.
- **권한**: `permitAll` (인증 불필요)
- **Request Body**: `SignUpRequest.java`
  ```java
  public record SignUpRequest(
      @NotBlank @Size(min = 4, max = 50)
      @Pattern(regexp = "^[a-zA-Z0-9_]+$")
      String username, // 로그인 아이디 (필수)
      @NotBlank @Pattern(regexp = "^(?=.*[A-Za-z])(?=.*\\d)(?=.*[@$!%*#?&])[A-Za-z\\d@$!%*#?&]{8,}$")
      String password, // 비밀번호 (필수)
      @NotBlank String name, // 이름 (필수)
      @NotBlank @Pattern(regexp = "^01[0-9]-?[0-9]{3,4}-?[0-9]{4}$")
      String phone, // 휴대폰 번호 (필수)
      @Email String email, // 이메일 (선택)
      String displayName, // 화면 표시명 (선택)
      @NotNull UserType userType, // INDIVIDUAL / BUSINESS
      UUID organizationId // Business 타입일 때만 필요
  ) {}
  ```
- **성공 응답 (201 Created)**:
  - Body: `ApiResponse<LoginResponse>` (로그인과 동일한 형식)
    ```json
    {
      "success": true,
      "data": {
        "accessToken": "...",
        "tokenType": "Bearer",
        "userId": "uuid-string",
        "username": "testuser",
        "role": "USER"
      },
      "error": null,
      "timestamp": "..."
    }
    ```

### 1.4. 로그인

- **HTTP Method**: `POST`
- **URL**: `/api/v1/auth/login`
- **Controller Method**: `login(LoginRequest request, HttpServletRequest httpRequest)`
- **설명**: username(로그인 아이디)과 비밀번호로 로그인하여 Access Token과 Refresh Token을 발급받습니다.
- **권한**: `permitAll` (인증 불필요)
- **Request Body**: `LoginRequest.java`
  ```java
  public class LoginRequest {
    @NotBlank @Size(max = 50) private String username; // 로그인 아이디
    @NotBlank private String password;
  }
  ```
- **성공 응답 (200 OK)**:
  - Body: `ApiResponse<LoginResponse>`
    ```json
    {
      "success": true,
      "data": {
        "accessToken": "...",
        "refreshToken": "...",
        "tokenType": "Bearer",
        "expiresIn": 3600, // Access Token 만료 시간(초)
        "user": {
          "id": 1,
          "username": "testuser",
          "name": "홍길동",
          "role": "USER"
        }
      },
      "error": null,
      "timestamp": "..."
    }
    ```

### 1.5. Access Token 재발급

- **HTTP Method**: `POST`
- **URL**: `/api/v1/auth/refresh`
- **Controller Method**: `refresh(RefreshTokenRequest request)`
- **설명**: 유효한 Refresh Token을 사용하여 만료된 Access Token을 재발급받습니다.
- **권한**: `permitAll` (인증 불필요)
- **Request Body**: `RefreshTokenRequest.java`
  ```java
  public class RefreshTokenRequest {
    @NotBlank private String refreshToken;
  }
  ```
- **성공 응답 (200 OK)**:
  - Body: `ApiResponse<RefreshTokenResponse>`
    ```json
    {
      "success": true,
      "data": {
        "accessToken": "...",
        "tokenType": "Bearer",
        "expiresIn": 3600
      },
      "error": null,
      "timestamp": "..."
    }
    ```

### 1.6. 로그아웃

- **HTTP Method**: `POST`
- **URL**: `/api/v1/auth/logout`
- **Controller Method**: `logout(RefreshTokenRequest request)`
- **설명**: 현재 사용중인 기기에서 로그아웃합니다. 서버에 저장된 Refresh Token을 삭제합니다.
- **권한**: `Authenticated` (인증 필요)
- **Request Body**: `RefreshTokenRequest.java`
  ```java
  public class RefreshTokenRequest {
    @NotBlank private String refreshToken;
  }
  ```
- **성공 응답 (200 OK)**:
  - Body: `ApiResponse<Void>`

### 1.7. 모든 기기에서 로그아웃

- **HTTP Method**: `POST`
- **URL**: `/api/v1/auth/logout-all`
- **Controller Method**: `logoutAll(UserDetails userDetails)`
- **설명**: 현재 사용자를 모든 기기에서 강제 로그아웃시킵니다. 해당 사용자의 모든 Refresh Token을 삭제합니다.
- **권한**: `Authenticated` (인증 필요)
- **Request Body**: (없음)
- **성공 응답 (200 OK)**:
  - Body: `ApiResponse<Void>`

### 1.8. 사용자 아이디 중복 확인

- **HTTP Method**: `GET`
- **URL**: `/api/v1/auth/check-username?username={username}`
- **Controller Method**: `checkUsername(@RequestParam String username)`
- **설명**: 특정 username(로그인 아이디)이 사용 가능한지 확인합니다. 회원가입 시 아이디 중복 체크를 위해 사용됩니다.
- **권한**: `permitAll` (인증 불필요)
- **Query Parameters**:
  - `username` (String, Required): 중복 확인할 로그인 아이디
- **성공 응답 (200 OK)**:
  - Body: `ApiResponse<Boolean>`
    ```json
    {
      "success": true,
      "data": true, // true: 사용 가능, false: 이미 사용 중
      "error": null,
      "timestamp": "..."
    }
    ```

---

## 2. AdminController

관리자 기능 관련 API를 담당합니다.

- **Class**: `io.iotree.linkwave.api.AdminController`
- **Base URL**: `/api/v1/admin`

### 2.1. 개인 사용자 서비스 우선순위 설정

- **HTTP Method**: `PUT`
- **URL**: `/api/v1/admin/users/{userId}/service-priority`
- **Controller Method**: `updateUserServicePriority(@PathVariable String userId, @RequestBody UpdateServicePriorityRequest request)`
- **설명**: 특정 개인 사용자(`INDIVIDUAL`)의 메시징 서비스 사용 권한 및 전송 우선순위를 설정합니다.
- **권한**: `SUPER_ADMIN`
- **Path Parameters**:
  - `userId` (String): 대상 사용자의 ID
- **Request Body**: `UpdateServicePriorityRequest.java`
  ```java
  public class UpdateServicePriorityRequest {
    @NotNull @Size(min = 1, max = 6)
    private List<ServiceType> servicePriority; // ["KAKAO", "SMS", "LMS"]
  }
  ```
- **성공 응답 (200 OK)**:
  - Body: `ApiResponse<ServicePriorityResponse>`

### 2.2. 조직 서비스 우선순위 설정

- **HTTP Method**: `PUT`
- **URL**: `/api/v1/admin/organizations/{orgId}/service-priority`
- **Controller Method**: `updateOrganizationServicePriority(@PathVariable String orgId, @RequestBody UpdateServicePriorityRequest request)`
- **설명**: 특정 조직(`ORGANIZATION`)의 메시징 서비스 사용 권한 및 전송 우선순위를 설정합니다. 해당 조직의 모든 사용자에게 적용됩니다.
- **권한**: `SUPER_ADMIN`
- **Path Parameters**:
  - `orgId` (String): 대상 조직의 ID
- **Request Body**: `UpdateServicePriorityRequest.java`
- **성공 응답 (200 OK)**:
  - Body: `ApiResponse<ServicePriorityResponse>`

### 2.3. 사용자 서비스 우선순위 조회

- **HTTP Method**: `GET`
- **URL**: `/api/v1/admin/users/{userId}/service-priority`
- **Controller Method**: `getUserServicePriority(@PathVariable String userId)`
- **설명**: 특정 사용자의 현재 적용된 서비스 우선순위를 조회합니다. 법인 회원의 경우 조직의 설정이 함께 조회됩니다.
- **권한**: `SUPER_ADMIN`
- **Path Parameters**:
  - `userId` (String): 대상 사용자의 ID
- **성공 응답 (200 OK)**:
  - Body: `ApiResponse<ServicePriorityResponse>`
    ```json
    {
        "success": true,
        "data": {
            "userId": "user1",
            "userType": "BUSINESS",
            "servicePriority": ["KAKAO", "SMS"], // 조직으로부터 상속받은 최종 우선순위
            "organizationId": "org1",
            "organizationServicePriority": ["KAKAO", "SMS"] // 조직 자체의 설정
        },
        "error": null,
        "timestamp": "..."
    }
    ```

---

## 3. MessageController

메시지 발송 관련 API를 담당합니다. (가상 컨트롤러)

- **Class**: `io.iotree.linkwave.api.MessageController` (예상)
- **Base URL**: `/api/v1/messages`

### 3.1. SMS 메시지 발송

- **HTTP Method**: `POST`
- **URL**: `/api/v1/messages/sms`
- **Controller Method**: `sendSms(SmsRequest request)`
- **설명**: 단문 메시지(SMS)를 발송합니다. 사용자가 `SMS` 서비스 사용 권한이 있는지 `ServicePermissionInterceptor`를 통해 검증됩니다.
- **권한**: `Authenticated` + `SMS` 서비스 권한
- **Request Body**: `SmsRequest.java` (예상)
  ```java
  public class SmsRequest {
    @NotBlank private String to; // 수신자 번호
    @NotBlank private String from; // 발신자 번호
    @NotBlank private String text; // 메시지 내용
  }
  ```
- **성공 응답 (200 OK)**:
  - Body: `ApiResponse<MessageSendResult>`

*(LMS, MMS, KAKAO, PUSH, RCS 등 다른 메시지 타입에 대해서도 위와 유사한 엔드포인트가 존재할 것으로 예상됩니다.)*
