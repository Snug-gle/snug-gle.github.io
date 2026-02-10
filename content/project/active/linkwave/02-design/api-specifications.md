---
created: 2026-02-10
tags:
  - linkwave
  - api
  - specification
---

> 이 문서는 linkwave-docs의 API 스펙 3파일(Auth, Message, User)을 병합한 것입니다.

# LinkWave API Specifications

**Base URL**: `/api/v1`
**인증 방식**: JWT Bearer Token (`Authorization: Bearer {token}`)
**공통 응답 형식**: `{ "success": boolean, "data": T, "error": ErrorInfo | null }`

---

## 1. Auth API (`/api/v1/auth`)

### 1.1 아이디 중복 확인
| Method | Endpoint | 인증 | 상태 |
|--------|----------|------|------|
| GET | `/auth/check-username?username={id}` | ❌ | 구현 완료 |

Response: `data: true` (사용 가능) / `false` (중복)

### 1.2 회원가입
| Method | Endpoint | 인증 | 상태 |
|--------|----------|------|------|
| POST | `/auth/singup` | ❌ | 구현 완료 |

Request: `{ username, password, name, phone, email, userType }`
Response: `{ grantType, accessToken, accessTokenExpiresIn }` + Set-Cookie (refreshToken)

### 1.3 로그인
| Method | Endpoint | 인증 | 상태 |
|--------|----------|------|------|
| POST | `/auth/login` | ❌ | 구현 완료 |

Request: `{ username, password }`
Response: (회원가입과 동일 형식) + Set-Cookie (refreshToken)

### 1.4 토큰 재발급 (Silent Refresh)
| Method | Endpoint | 인증 | 상태 |
|--------|----------|------|------|
| POST | `/auth/refresh` | Cookie | 구현 완료 |

Cookie의 refreshToken으로 accessToken 재발급. RTR(Refresh Token Rotation) 정책 적용.

### 1.5 로그아웃
| Method | Endpoint | 인증 | 상태 |
|--------|----------|------|------|
| POST | `/auth/logout` | ✅ | 구현 완료 |

accessToken 만료(Redis), refreshToken 삭제, 쿠키 삭제.

---

## 2. Message API (`/api/v1/messages`)

### 2.1 메시지 발송
| Method | Endpoint | 인증 | 상태 |
|--------|----------|------|------|
| POST | `/messages` | ✅ | 구현 완료 |

Request:
```json
{
  "type": "SMS|LMS|MMS",
  "contentType": "COMM|AD",
  "countryCode": "82",
  "from": "01012345678",
  "to": "01098765432",
  "content": "메시지 내용",
  "subject": "제목 (LMS/MMS)",
  "files": []
}
```

Response (201):
```json
{
  "data": {
    "clientKey": "20260122103000_testuser_a1b2c3d4",
    "requestTime": "2026-01-22T10:30:00.123"
  }
}
```

### 2.2 메시지 목록 조회
| Method | Endpoint | 인증 | 상태 |
|--------|----------|------|------|
| GET | `/messages?startDate=&endDate=&status=&page=&size=` | ✅ | 구현 예정 |

### 2.3 메시지 상세 조회
| Method | Endpoint | 인증 | 상태 |
|--------|----------|------|------|
| GET | `/messages/{clientKey}` | ✅ | 구현 예정 |

---

## 3. User API (`/api/v1/users`)

### 3.1 프로필 조회
| Method | Endpoint | 인증 | 상태 |
|--------|----------|------|------|
| GET | `/users/profile` | ✅ | 구현 완료 |

### 3.2 프로필 수정
| Method | Endpoint | 인증 | 상태 |
|--------|----------|------|------|
| PUT | `/users/profile` | ✅ | 구현 완료 |

수정 가능 필드: name, email, phone, displayName, department

### 3.3 비밀번호 변경
| Method | Endpoint | 인증 | 상태 |
|--------|----------|------|------|
| PUT | `/users/password` | ✅ | 구현 완료 |

Request: `{ currentPassword, newPassword, newPasswordConfirm }`

---

## 4. SenderNumber API (`/api/v1/sender-numbers`)

### 4.1 발신번호 목록 조회
| Method | Endpoint | 인증 | 상태 |
|--------|----------|------|------|
| GET | `/sender-numbers` | ✅ | 구현 완료 |

### 4.2 발신번호 등록
| Method | Endpoint | 인증 | 상태 |
|--------|----------|------|------|
| POST | `/sender-numbers` | ✅ | 구현 완료 |

Request: `{ senderNumber, memo }` → 미인증 상태로 생성

### 4.3 발신번호 삭제
| Method | Endpoint | 인증 | 상태 |
|--------|----------|------|------|
| DELETE | `/sender-numbers/{senderNumber}` | ✅ | 구현 완료 |

### 4.4 발신번호 인증/기본 설정
| Endpoint | 상태 |
|----------|------|
| `POST /sender-numbers/{id}/request-verification` | 구현 예정 |
| `POST /sender-numbers/verify` | 구현 예정 |
| `PATCH /sender-numbers/{id}/default` | 구현 예정 |

---

## 5. 이메일/전화번호 인증 (구현 예정)

| Endpoint | 설명 |
|----------|------|
| `POST /users/email/request-verification` | 이메일 인증 메일 발송 |
| `GET /users/email/verify` | 이메일 인증 완료 |
| `POST /users/phone/request-verification` | 전화번호 인증번호 발송 |
| `POST /users/phone/verify` | 전화번호 인증 완료 |
