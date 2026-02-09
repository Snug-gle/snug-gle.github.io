---
created: 2025-12-26
---
# 02. 인증 API 연동

> **대상**: 로그인, 회원가입, 휴대폰 인증, 토큰 관리  
> **참고**: [백엔드 04-USER-AUTH.md](../../../linkwave-backend/docs/implementation-guides/04-USER-AUTH.md)

---

## 📌 개요

프론트엔드에서 백엔드 인증 API를 연동하는 방법을 설명합니다.

### API 엔드포인트

| Method | Endpoint                                  | 설명             | 권한 |
| ------ | ----------------------------------------- | ---------------- | ---- |
| POST   | `/api/v1/auth/login`                      | 로그인           | 공개 |
| POST   | `/api/v1/auth/signup`                     | 회원가입         | 공개 |
| GET    | `/api/v1/auth/check-username`             | 아이디 중복 확인 | 공개 |
| POST   | `/api/v1/auth/phone/request-verification` | 인증번호 요청    | 공개 |
| POST   | `/api/v1/auth/phone/verify`               | 인증번호 확인    | 공개 |
| POST   | `/api/v1/auth/refresh`                    | 토큰 재발급      | 공개 |
| POST   | `/api/v1/auth/logout`                     | 로그아웃         | 인증 |

---

## 1️⃣ 타입 정의

### 파일: `src/types/login.ts`

```typescript
// 로그인 응답 (회원가입 응답과 동일)
export interface LoginResponse {
  accessToken: string;
  tokenType: string; // "Bearer"
  userId: string;
  username: string;
  role: string; // "USER" | "ORGANIZATION_ADMIN"
}

// 아이디 중복 확인 응답
export interface CheckUsernameResponse {
  available: boolean;
  message: string;
}

// 휴대폰 인증 응답
export interface VerificationResponse {
  success: boolean;
  message: string;
}

export interface VerifyCodeResponse {
  verified: boolean;
  message: string;
  token?: string; // 휴대폰 인증 토큰 (회원가입 시 사용)
}
```

---

## 2️⃣ API 함수 구현

### 파일: `src/api/authApi.ts`

```typescript
import client from "./client";
import type { ApiResponse } from "@/types/api";
import type {
  LoginResponse,
  CheckUsernameResponse,
  VerificationResponse,
  VerifyCodeResponse,
} from "@/types/login";
import type { SignupFormData } from "@/types/signup";

export const authApi = {
  /**
   * 로그인
   */
  login: async (credentials: {
    username: string;
    password: string;
  }): Promise<LoginResponse> => {
    const response: ApiResponse<LoginResponse> = await client.post(
      "/auth/login",
      credentials
    );

    if (!response.success || !response.data) {
      throw new Error(response.error?.message || "로그인에 실패했습니다");
    }
    return response.data;
  },

  /**
   * 회원가입
   */
  signup: async (formData: SignupFormData): Promise<LoginResponse> => {
    const requestBody = {
      username: formData.username,
      password: formData.password,
      name: formData.name,
      phone: formData.phoneNumber.replace(/-/g, ""),
      email: formData.email || null,
      userType: formData.userType,
    };

    const response: ApiResponse<LoginResponse> = await client.post(
      "/auth/signup",
      requestBody
    );

    if (!response.success || !response.data) {
      throw new Error(response.error?.message || "회원가입에 실패했습니다");
    }
    return response.data;
  },

  /**
   * 아이디 중복 확인
   */
  checkUsername: async (username: string): Promise<CheckUsernameResponse> => {
    const response: ApiResponse<boolean> = await client.get(
      `/auth/check-username?username=${encodeURIComponent(username)}`
    );

    return {
      available: response.data === true,
      message: response.data
        ? "사용 가능한 아이디입니다"
        : "이미 사용 중인 아이디입니다",
    };
  },

  /**
   * 휴대폰 인증번호 요청
   */
  sendVerificationCode: async (
    phone: string
  ): Promise<VerificationResponse> => {
    const response: ApiResponse<void> = await client.post(
      "/auth/phone/request-verification",
      {
        phone: phone.replace(/-/g, ""),
      }
    );

    return {
      success: response.success,
      message: response.success
        ? "인증번호가 발송되었습니다"
        : "발송에 실패했습니다",
    };
  },

  /**
   * 휴대폰 인증번호 확인
   */
  verifyCode: async (
    phone: string,
    code: string
  ): Promise<VerifyCodeResponse> => {
    const response: ApiResponse<{ phoneVerificationToken: string }> =
      await client.post("/auth/phone/verify", {
        phone: phone.replace(/-/g, ""),
        verificationCode: code,
      });

    return {
      verified: response.success,
      message: response.success
        ? "인증이 완료되었습니다"
        : "인증번호가 일치하지 않습니다",
      token: response.data?.phoneVerificationToken,
    };
  },
};
```

---

## 3️⃣ 상태 관리 (Zustand)

### 파일: `src/stores/authStore.ts`

```typescript
import { create } from "zustand";
import { persist } from "zustand/middleware";
import type { LoginResponse } from "@/types/login";

interface AuthState {
  user: { userId: string; username: string; role: string } | null;
  token: string | null;
  isAuthenticated: boolean;

  loginWithResponse: (response: LoginResponse) => void;
  logout: () => void;
}

export const useAuthStore = create<AuthState>()(
  persist(
    (set) => ({
      user: null,
      token: null,
      isAuthenticated: false,

      loginWithResponse: (response) => {
        localStorage.setItem("auth-token", response.accessToken);
        set({
          token: response.accessToken,
          isAuthenticated: true,
          user: {
            userId: response.userId,
            username: response.username,
            role: response.role,
          },
        });
      },

      logout: () => {
        localStorage.removeItem("auth-token");
        set({ user: null, token: null, isAuthenticated: false });
      },
    }),
    { name: "auth-storage" }
  )
);
```

---

## 4️⃣ 컴포넌트에서 사용

### 로그인

```typescript
import { authApi } from "@/api/authApi";
import { useAuthStore } from "@/stores/authStore";

const handleLogin = async (username: string, password: string) => {
  try {
    const response = await authApi.login({ username, password });
    useAuthStore.getState().loginWithResponse(response);
    navigate({ to: "/dashboard" });
  } catch (error) {
    toast.error("아이디 또는 비밀번호가 일치하지 않습니다");
  }
};
```

### 회원가입

```typescript
const handleSignup = async (formData: SignupFormData) => {
  try {
    const response = await authApi.signup(formData);
    // 로그인과 동일한 응답 → 동일한 처리
    useAuthStore.getState().loginWithResponse(response);
    navigate({ to: "/dashboard" });
  } catch (error) {
    toast.error("회원가입에 실패했습니다");
  }
};
```

---

## 5️⃣ 휴대폰 번호 중복 체크

인증번호 발송 전 중복 체크를 수행합니다.

### API 추가: `authApi.ts`

```typescript
/**
 * 휴대폰 번호 중복 확인
 */
checkPhone: async (phone: string): Promise<{ available: boolean; message: string }> => {
  const response: ApiResponse<boolean> = await client.get(
    `/auth/check-phone?phone=${encodeURIComponent(phone.replace(/-/g, ''))}`
  );

  return {
    available: response.data === true,
    message: response.data ? '사용 가능한 번호입니다' : '이미 가입된 휴대폰 번호입니다'
  };
},
```

### 사용 예시: `SignupVerifyPage.tsx`

```typescript
const handleSendCode = async () => {
  setSending(true);
  try {
    // 1. 중복 체크
    const checkResult = await authApi.checkPhone(userInfo.phone);
    if (!checkResult.available) {
      toast.error(checkResult.message);
      navigate({ to: "/signup/info" });
      return;
    }

    // 2. 인증번호 발송
    await authApi.sendVerificationCode(userInfo.phone);
    toast.success("인증번호가 발송되었습니다");
  } catch {
    toast.error("인증번호 발송에 실패했습니다");
  } finally {
    setSending(false);
  }
};
```

---

## ✅ 체크리스트

- [ ] `src/types/login.ts` - 응답 타입 정의
- [ ] `src/api/authApi.ts` - API 함수 구현
  - [ ] login
  - [ ] signup
  - [ ] checkUsername
  - [ ] sendVerificationCode
  - [ ] verifyCode
  - [ ] checkPhone
- [ ] `src/stores/authStore.ts` - 인증 상태 관리
- [ ] 로그인 페이지 연동
- [ ] 회원가입 페이지 연동
- [ ] 휴대폰 인증 연동

---

## 🔗 참고 문서

- [백엔드 인증 가이드](../../../linkwave-backend/docs/implementation-guides/04-USER-AUTH.md)
- [API 명세](../../../linkwave-backend/docs/API_SPECIFICATION_DETAIL.md)
