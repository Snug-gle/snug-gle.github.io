---
created: 2025-12-26
---
# LinkWave RESTful API 문서 규격

## 1. 개요

이 문서는 LinkWave 프로젝트의 RESTful API를 설계하고 문서화할 때 따라야 할 표준 규격을 정의합니다. 일관성 있고 예측 가능한 API를 제공하는 것을 목표로 합니다.

## 2. 엔드포인트 명명 규칙

- **URL 형식**: `/api/{version}/{resource}`
  - 예: `/api/v1/users`, `/api/v1/organizations`
- **리소스 이름**: 복수형 명사 사용 (예: `users`, `organizations`)
- **식별자**: Path Variable 사용 (예: `/api/v1/users/{userId}`)
- **동사**: HTTP Method (GET, POST, PUT, DELETE 등)로 표현하며 URL에 동사를 포함하지 않습니다.
  - **Bad**: `/api/v1/getUser`
  - **Good**: `GET /api/v1/users/{userId}`

## 3. 인증 (Authentication)

- **인증 방식**: JWT (JSON Web Token) 사용
- **토큰 전달**: 모든 인증된 요청은 `Authorization` 헤더에 Bearer 토큰을 포함해야 합니다.
  ```
  Authorization: Bearer <ACCESS_TOKEN>
  ```
- **토큰 종류**:
  - **Access Token**: API 요청 인증에 사용 (만료 시간: 1시간)
  - **Refresh Token**: Access Token 재발급에 사용 (만료 시간: 7일)
- **공개 엔드포인트**:
  - `POST /api/v1/auth/signup`
  - `POST /api/v1/auth/login`
  - `POST /api/v1/auth/refresh`
  - 그 외 `/api/v1/auth/**` 경로의 모든 API
- **인증 필요 엔드포인트**: 위 공개 엔드포인트를 제외한 모든 API

## 4. 요청 형식 (Request Format)

- **Content-Type**: `application/json`
- **Request Body**: JSON 형식
- **파라미터**:
  - **Path Parameters**: 리소스 식별에 사용 (예: `/users/{userId}`)
  - **Query Parameters**: 필터링, 정렬, 페이징에 사용 (예: `/users?role=ADMIN`)
  - **Request Body**: 복잡한 데이터나 리소스 생성/수정에 사용

## 5. 응답 형식 (Response Format)

모든 API 응답은 `ApiResponse<T>` 래퍼로 감싸서 반환합니다.

### 5.1. 성공 응답 (`2xx`)

- `success`: `true`
- `data`: 실제 응답 데이터 (제네릭 타입 `T`)
- `error`: `null`

**예시 (데이터 포함):**
```json
{
  "success": true,
  "data": {
    "id": 1,
    "email": "admin@iotree.com",
    "name": "관리자"
  },
  "error": null,
  "timestamp": "2025-12-16T10:00:00.123Z"
}
```

**예시 (데이터 미포함):**
```json
{
  "success": true,
  "data": null,
  "error": null,
  "timestamp": "2025-12-16T10:00:00.123Z"
}
```

### 5.2. 실패 응답 (`4xx`, `5xx`)

- `success`: `false`
- `data`: `null`
- `error`: `ErrorResponse` 객체

**`ErrorResponse` 구조:**
- `errorCode` (String): 애플리케이션 정의 에러 코드 (예: `U001`)
- `message` (String): 에러 메시지
- `fieldErrors` (Array, Optional): 유효성 검사 실패 시 필드별 에러 정보

**예시 (일반 에러):**
```json
{
  "success": false,
  "data": null,
  "error": {
    "errorCode": "U001",
    "message": "User not found",
    "fieldErrors": []
  },
  "timestamp": "2025-12-16T10:05:00.456Z"
}
```

**예시 (유효성 검사 에러):**
```json
{
  "success": false,
  "data": null,
  "error": {
    "errorCode": "C001",
    "message": "Invalid input value",
    "fieldErrors": [
      {
        "field": "email",
        "value": "invalid-email",
        "message": "이메일 형식이 올바르지 않습니다"
      }
    ]
  },
  "timestamp": "2025-12-16T10:05:00.456Z"
}
```

## 6. HTTP 상태 코드

- **`200 OK`**: 요청 성공 (주로 `GET` 응답)
- **`201 Created`**: 리소스 생성 성공 (주로 `POST` 응답)
- **`204 No Content`**: 요청은 성공했으나 반환할 콘텐츠 없음 (주로 `DELETE` 응답)
- **`400 Bad Request`**: 잘못된 요청 (예: 파라미터 오류, 유효성 검사 실패)
- **`401 Unauthorized`**: 인증 실패 (예: 유효하지 않은 토큰)
- **`403 Forbidden`**: 인가(권한) 실패 (예: ADMIN 전용 API에 USER가 접근)
- **`404 Not Found`**: 요청한 리소스를 찾을 수 없음
- **`409 Conflict`**: 리소스 충돌 (예: 중복된 이메일로 회원가입 시도)
- **`500 Internal Server Error`**: 서버 내부 오류

## 7. 에러 코드 (`ErrorCode`)

`ErrorCode` enum (`common/exception/ErrorCode.java`)에 정의된 코드를 사용합니다. 새로운 에러 발생 시 여기에 추가하여 관리합니다.

| 그룹 | 접두사 | 설명 |
|---|---|---|
| 공통 | C | `INVALID_INPUT_VALUE`, `INTERNAL_SERVER_ERROR` 등 |
| 인증 | A | `INVALID_CREDENTIALS`, `INVALID_TOKEN` 등 |
| 사용자 | U | `USER_NOT_FOUND`, `DUPLICATE_EMAIL` 등 |
| 조직/회사 | COM | `COMPANY_NOT_FOUND`, `DUPLICATE_BUSINESS_NUMBER` 등 |

## 8. API 엔드포인트 문서화 템플릿

새로운 API를 추가할 때, 아래의 Markdown 템플릿을 사용하여 문서를 작성합니다.

---

### **회원 정보 조회**

`GET /api/v1/users/{userId}`

#### **설명**

지정된 ID의 사용자 정보를 조회합니다.

#### **권한**

- `ADMIN`
- 본인 (`USER` 역할)

#### **Path Parameters**

| 이름 | 타입 | 필수 | 설명 |
|---|---|---|---|
| `userId` | `Long` | Y | 조회할 사용자의 ID |

#### **Request Body**

(없음)

#### **성공 응답 (200 OK)**

```json
{
  "success": true,
  "data": {
    "id": 1,
    "email": "user@example.com",
    "name": "홍길동",
    "phone": "010-1234-5678",
    "organizationId": "uuid-here",
    "role": "USER",
    "status": "ACTIVE",
    "createdAt": "2025-12-16T09:00:00"
  },
  "error": null,
  "timestamp": "2025-12-16T10:00:00.123Z"
}
```

#### **실패 응답**

- **404 Not Found**: 사용자를 찾을 수 없는 경우
  ```json
  {
    "success": false,
    "data": null,
    "error": {
      "errorCode": "U001",
      "message": "User not found",
      "fieldErrors": []
    },
    "timestamp": "2025-12-16T10:05:00.456Z"
  }
  ```

#### **cURL 예시**

```bash
curl -X GET 'http://localhost:8080/api/v1/users/1' \
-H 'Authorization: Bearer <ACCESS_TOKEN>'
```
---
