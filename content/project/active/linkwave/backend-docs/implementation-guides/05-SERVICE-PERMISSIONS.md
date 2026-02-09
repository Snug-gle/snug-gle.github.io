---
created: 2025-12-26
---
# 05. 서비스별 권한 및 우선순위 관리 시스템

## 📚 학습 목표

이 가이드를 통해 다음을 학습합니다:

1. **JSON 기반 권한 + 우선순위 통합 관리**
2. **Fallback 전송 로직** (서비스 실패 시 자동 대체)
3. **조직 vs 개인 권한 상속** 패턴
4. **Spring Security와 JWT 기반 권한 검증**
5. **React에서의 조건부 렌더링 및 라우팅 가드**
6. **대안 설계 비교** (비트마스크 vs JSON)

---

## 🎯 비즈니스 요구사항

### 서비스 종류
LinkWave는 다음 6가지 메시징 서비스를 제공합니다:
- **SMS**: 단문 메시지 (Short Message Service)
- **LMS**: 장문 메시지 (Long Message Service)
- **MMS**: 멀티미디어 메시지 (Multimedia Message Service)
- **KakaoTalk**: 카카오톡 알림톡/친구톡
- **Push**: 모바일 푸시 알림
- **RCS**: Rich Communication Services

### 핵심 요구사항

1. **권한 + 우선순위 통합 관리**:
   - 사용자마다 사용 가능한 서비스가 다름
   - 서비스 전송 시 **우선순위 적용** (예: 카카오톡 → SMS → LMS)
   - 1순위 실패 시 자동으로 다음 순위 서비스로 Fallback

2. **권한 단위**:
   - **조직(Business)**: 조직이 구독한 서비스를 조직 내 모든 사용자가 사용
   - **개인(Individual)**: 조직 없이 개인이 직접 서비스 구독

3. **권한 관리자**: `SUPER_ADMIN` 역할만 서비스 권한 및 우선순위 설정 가능

4. **프론트엔드 처리**: 권한 없는 서비스는 UI에서 **완전히 숨김** (disabled가 아님)

5. **백엔드 보안**: API 호출 시 서비스 권한 검증 (프론트엔드 숨김은 UX 목적일 뿐)

---

## 🔧 핵심 설계: JSON 배열 방식

### 왜 JSON 배열인가?

당초 비트마스크로 권한을 관리하는 방안을 검토했으나, **중대한 한계**를 발견했습니다:

#### 비트마스크의 한계:
```
enabled_services = 11  // KAKAO(8) + SMS(2) + LMS(1) 권한 보유

문제:
1. 어느 서비스가 1순위인지 알 수 없음
2. "KAKAO 실패 시 SMS로 fallback" 같은 로직 불가능
3. 순서 정보를 위해 별도 컬럼 필요 → 데이터 중복
```

#### JSON 배열 방식:
```json
service_priority = ["KAKAO", "SMS", "LMS"]

의미:
1. 사용 가능한 서비스: KAKAO, SMS, LMS ✅
2. 전송 우선순위: KAKAO(1순위) → SMS(2순위) → LMS(3순위) ✅
3. 단일 진실 공급원(Single Source of Truth) ✅
```

### 데이터 예시

```sql
-- 사용자 A: 카카오톡을 최우선으로, 실패 시 SMS, 최종적으로 LMS
user_id | service_priority
userA   | ["KAKAO", "SMS", "LMS"]

-- 사용자 B: SMS만 사용 (우선순위 불필요)
userB   | ["SMS"]

-- 사용자 C: 모든 서비스 사용, RCS부터 시도
userC   | ["RCS", "KAKAO", "PUSH", "SMS", "LMS", "MMS"]
```

### 장점 정리

| 항목 | 비트마스크 | JSON 배열 |
|------|-----------|-----------|
| 권한 표현 | ✅ 가능 | ✅ 가능 |
| 우선순위 표현 | ❌ 불가능 | ✅ 가능 |
| 데이터 중복 | 권한+우선순위 분리 필요 | 단일 컬럼 통합 |
| 가독성 | 숫자 (7 = ?) | 배열 명시적 |
| 쿼리 성능 | 빠름 (비트 AND) | 약간 느림 (JSON 함수) |
| 메모리 효율 | 4 bytes (INT) | ~50 bytes (JSON) |
| 확장성 | 32개 제한 | 제한 없음 |
| Fallback 로직 | 별도 구현 필요 | 배열 순회로 자연스럽게 구현 |

**결론**: 서비스가 6개이고 사용자 수가 수백만 이하라면 **JSON 배열이 압도적으로 실용적**입니다.

---

## 🏗️ 시스템 아키텍처

### 데이터 모델

#### DB 스키마

**1) `users` 테이블**
```sql
ALTER TABLE users
ADD COLUMN service_priority JSON
COMMENT '사용 가능한 서비스 및 전송 우선순위 (["KAKAO", "SMS", "LMS"])';

-- 예시 데이터
UPDATE users SET service_priority = '["SMS", "LMS"]' WHERE user_id = 'user1';
UPDATE users SET service_priority = '["KAKAO", "SMS", "LMS", "MMS"]' WHERE user_id = 'user2';
```

**학습 포인트**:
- JSON 타입은 MySQL 5.7.8+ 부터 지원
- 배열 순서 = 전송 시도 순서
- 빈 배열 `[]` = 모든 서비스 사용 불가

**2) `organizations` 테이블**
```sql
ALTER TABLE organizations
ADD COLUMN service_priority JSON
COMMENT '조직이 구독한 서비스 및 우선순위';

-- 예시 데이터
UPDATE organizations SET service_priority = '["KAKAO", "SMS", "LMS", "MMS", "PUSH", "RCS"]'
WHERE organization_id = 'org1';
```

**학습 포인트**:
- 비즈니스 사용자는 조직의 `service_priority` 상속
- 조직 설정 변경 시 전체 조직원에게 즉시 반영

---

## 💻 백엔드 구현 가이드

### 1단계: ServiceType Enum 작성

**파일**: `src/main/java/io/iotree/linkwave/domain/user/ServiceType.java`

```java
package io.iotree.linkwave.domain.user;

import lombok.Getter;

@Getter
public enum ServiceType {
  SMS("SMS", "단문 메시지"),
  LMS("LMS", "장문 메시지"),
  MMS("MMS", "멀티미디어 메시지"),
  KAKAO("KAKAO", "카카오톡"),
  PUSH("PUSH", "푸시 알림"),
  RCS("RCS", "RCS 메시지");

  private final String code;
  private final String displayName;

  ServiceType(String code, String displayName) {
    this.code = code;
    this.displayName = displayName;
  }
}
```

**학습 포인트**:
- 비트마스크 방식의 `value` 필드가 불필요해짐
- Enum 이름(SMS, LMS 등)이 JSON에 직접 저장됨
- Jackson이 자동으로 `"SMS"` 문자열 ↔ `ServiceType.SMS` 변환

---

### 2단계: JPA AttributeConverter 작성

**파일**: `src/main/java/io/iotree/linkwave/domain/user/ServicePriorityConverter.java`

```java
package io.iotree.linkwave.domain.user;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import jakarta.persistence.AttributeConverter;
import jakarta.persistence.Converter;
import java.util.ArrayList;
import java.util.List;

@Converter
public class ServicePriorityConverter
    implements AttributeConverter<List<ServiceType>, String> {

  private final ObjectMapper objectMapper = new ObjectMapper();

  @Override
  public String convertToDatabaseColumn(List<ServiceType> attribute) {
    if (attribute == null || attribute.isEmpty()) {
      return "[]";
    }
    try {
      return objectMapper.writeValueAsString(attribute);
    } catch (JsonProcessingException e) {
      throw new IllegalArgumentException("JSON 변환 실패: " + attribute, e);
    }
  }

  @Override
  public List<ServiceType> convertToEntityAttribute(String dbData) {
    if (dbData == null || dbData.trim().isEmpty()) {
      return new ArrayList<>();
    }
    try {
      return objectMapper.readValue(dbData,
          new TypeReference<List<ServiceType>>() {});
    } catch (JsonProcessingException e) {
      return new ArrayList<>();
    }
  }
}
```

**학습 포인트**:

1. **AttributeConverter 역할**:
   - JPA가 Entity ↔ DB 간 변환 시 자동 호출
   - `List<ServiceType>` → `String` (JSON): DB 저장 시
   - `String` (JSON) → `List<ServiceType>`: DB 조회 시

2. **Jackson ObjectMapper 사용**:
   ```java
   objectMapper.writeValueAsString(attribute)
   // ["SMS", "LMS"] → "[\"SMS\",\"LMS\"]" (JSON 문자열)

   objectMapper.readValue(dbData, new TypeReference<List<ServiceType>>() {})
   // "[\"SMS\",\"LMS\"]" → List.of(ServiceType.SMS, ServiceType.LMS)
   ```

3. **예외 처리**:
   - 저장 실패: `IllegalArgumentException` (데이터 무결성 보장)
   - 조회 실패: 빈 리스트 반환 (안전한 기본값)

---

### 3단계: User Entity 수정

**파일**: `src/main/java/io/iotree/linkwave/domain/user/User.java`

```java
package io.iotree.linkwave.domain.user;

import jakarta.persistence.*;
import java.util.*;
import lombok.Getter;
import lombok.Setter;

@Entity
@Table(name = "users")
@Getter
@Setter
public class User {
  // ... 기존 필드 ...

  @Column(name = "service_priority", columnDefinition = "JSON")
  @Convert(converter = ServicePriorityConverter.class)
  private List<ServiceType> servicePriority = new ArrayList<>();

  // 실제 사용 가능한 서비스 (우선순위 순서대로)
  public List<ServiceType> getAvailableServices() {
    if (userType == UserType.INDIVIDUAL) {
      // 개인 사용자: 본인의 service_priority 사용
      return new ArrayList<>(servicePriority);
    } else {
      // 비즈니스 사용자: 조직의 service_priority 상속
      if (organization == null) {
        return Collections.emptyList();
      }
      return new ArrayList<>(organization.getServicePriority());
    }
  }

  // 특정 서비스 사용 가능 여부 확인
  public boolean hasServicePermission(ServiceType serviceType) {
    return getAvailableServices().contains(serviceType);
  }

  // 서비스 우선순위 설정 (Admin용)
  public void setServicePriority(List<ServiceType> services) {
    this.servicePriority = new ArrayList<>(services);
  }

  // 전송 시 사용할 Fallback 순서
  public List<ServiceType> getServiceFallbackOrder() {
    return Collections.unmodifiableList(getAvailableServices());
  }
}
```

**학습 포인트**:

1. **@Convert 어노테이션**:
   ```java
   @Convert(converter = ServicePriorityConverter.class)
   ```
   - JPA가 자동으로 Converter 적용
   - Entity 필드는 `List<ServiceType>` 타입 유지 (개발자 편의)

2. **권한 상속 로직**:
   ```java
   if (userType == UserType.INDIVIDUAL) {
     return servicePriority;  // 개인: 자신의 설정
   } else {
     return organization.getServicePriority();  // 비즈니스: 조직 설정 상속
   }
   ```

3. **Fallback 순서 제공**:
   ```java
   public List<ServiceType> getServiceFallbackOrder() {
     return Collections.unmodifiableList(getAvailableServices());
   }
   ```
   - `unmodifiableList`: 외부에서 변경 불가 (불변성 보장)
   - 메시지 전송 Service에서 이 순서대로 시도

---

### 4단계: MessageService에 Fallback 로직 추가

**파일**: `src/main/java/io/iotree/linkwave/service/MessageService.java`

```java
package io.iotree.linkwave.service;

import io.iotree.linkwave.domain.user.ServiceType;
import io.iotree.linkwave.domain.user.User;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Slf4j
@Service
@RequiredArgsConstructor
public class MessageService {

  // Fallback 전송 로직
  @Transactional
  public void sendMessageWithFallback(User user, String phone, String content) {
    List<ServiceType> fallbackOrder = user.getServiceFallbackOrder();

    if (fallbackOrder.isEmpty()) {
      throw new BusinessException(ErrorCode.NO_AVAILABLE_SERVICE,
          "사용 가능한 서비스가 없습니다.");
    }

    Exception lastException = null;

    for (ServiceType serviceType : fallbackOrder) {
      try {
        log.info("메시지 전송 시도: service={}, phone={}", serviceType, phone);
        sendViaService(serviceType, phone, content);
        log.info("메시지 전송 성공: service={}", serviceType);
        return;  // 성공하면 즉시 종료
      } catch (Exception e) {
        log.warn("메시지 전송 실패: service={}, error={}",
            serviceType, e.getMessage());
        lastException = e;
        // 다음 서비스로 fallback 계속
      }
    }

    // 모든 서비스 실패
    throw new BusinessException(ErrorCode.ALL_SERVICES_FAILED,
        "모든 서비스 전송 실패", lastException);
  }

  private void sendViaService(ServiceType serviceType, String phone, String content) {
    switch (serviceType) {
      case SMS -> sendSms(phone, content);
      case LMS -> sendLms(phone, content);
      case MMS -> sendMms(phone, content);
      case KAKAO -> sendKakao(phone, content);
      case PUSH -> sendPush(phone, content);
      case RCS -> sendRcs(phone, content);
    }
  }

  // 각 서비스별 전송 로직 (예시)
  private void sendSms(String phone, String content) {
    // SMS 전송 구현
  }

  private void sendKakao(String phone, String content) {
    // 카카오톡 전송 구현
  }

  // ... 나머지 서비스 전송 메서드 ...
}
```

**학습 포인트**:

1. **Fallback 전략**:
   ```java
   for (ServiceType serviceType : fallbackOrder) {
     try {
       sendViaService(serviceType, phone, content);
       return;  // 성공하면 즉시 종료
     } catch (Exception e) {
       // 실패 시 다음 서비스로 계속
     }
   }
   ```
   - 배열 순서대로 시도
   - 하나라도 성공하면 즉시 종료
   - 모두 실패하면 예외 발생

2. **로깅**:
   - 시도: `log.info("메시지 전송 시도: service={}", serviceType)`
   - 실패: `log.warn("메시지 전송 실패")`
   - 성공: `log.info("메시지 전송 성공")`
   - 추후 통계 분석 및 디버깅에 활용

3. **예외 처리**:
   - 개별 서비스 실패는 catch로 처리
   - 마지막 예외를 저장하여 최종 실패 시 컨텍스트 제공

---

### 5단계: DTO 작성

**파일**: `src/main/java/io/iotree/linkwave/api/dto/request/UpdateServicePriorityRequest.java`

```java
package io.iotree.linkwave.api.dto.request;

import io.iotree.linkwave.domain.user.ServiceType;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import java.util.List;
import lombok.Data;

@Data
public class UpdateServicePriorityRequest {
  @NotNull(message = "서비스 목록은 필수입니다")
  @Size(min = 1, max = 6, message = "최소 1개, 최대 6개 서비스 지정 가능")
  private List<ServiceType> servicePriority;
}
```

**파일**: `src/main/java/io/iotree/linkwave/api/dto/response/ServicePriorityResponse.java`

```java
package io.iotree.linkwave.api.dto.response;

import io.iotree.linkwave.domain.user.ServiceType;
import java.util.List;
import lombok.Builder;
import lombok.Data;

@Data
@Builder
public class ServicePriorityResponse {
  private String userId;
  private String userType;
  private List<ServiceType> servicePriority;  // 우선순위 순서

  // 조직 사용자의 경우 조직 정보 포함
  private String organizationId;
  private List<ServiceType> organizationServicePriority;
}
```

**학습 포인트**:

1. **Validation**:
   ```java
   @Size(min = 1, max = 6, message = "최소 1개, 최대 6개 서비스 지정 가능")
   ```
   - 최소 1개: 서비스가 없으면 전송 불가
   - 최대 6개: 현재 지원 서비스 개수

2. **List vs Set**:
   - List 사용: 순서가 중요하므로 (우선순위)
   - Set은 순서 보장 안 함

---

### 6단계: AdminService 구현

**파일**: `src/main/java/io/iotree/linkwave/service/AdminService.java`

```java
package io.iotree.linkwave.service;

import io.iotree.linkwave.api.dto.response.ServicePriorityResponse;
import io.iotree.linkwave.common.exception.BusinessException;
import io.iotree.linkwave.common.exception.ErrorCode;
import io.iotree.linkwave.domain.organization.Organization;
import io.iotree.linkwave.domain.organization.OrganizationRepository;
import io.iotree.linkwave.domain.user.ServiceType;
import io.iotree.linkwave.domain.user.User;
import io.iotree.linkwave.domain.user.UserRepository;
import io.iotree.linkwave.domain.user.UserType;
import java.util.List;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
public class AdminService {

  private final UserRepository userRepository;
  private final OrganizationRepository organizationRepository;

  // 개인 사용자 서비스 우선순위 설정
  @Transactional
  public ServicePriorityResponse updateUserServicePriority(
      String userId, List<ServiceType> servicePriority) {

    User user = userRepository.findById(userId)
        .orElseThrow(() -> new BusinessException(ErrorCode.USER_NOT_FOUND));

    if (user.getUserType() == UserType.BUSINESS) {
      throw new BusinessException(ErrorCode.INVALID_OPERATION,
          "비즈니스 사용자는 조직 단위로 서비스 권한을 관리해야 합니다.");
    }

    user.setServicePriority(servicePriority);
    return buildResponse(user);
  }

  // 조직 서비스 우선순위 설정
  @Transactional
  public ServicePriorityResponse updateOrganizationServicePriority(
      String organizationId, List<ServiceType> servicePriority) {

    Organization organization = organizationRepository.findById(organizationId)
        .orElseThrow(() -> new BusinessException(ErrorCode.ORGANIZATION_NOT_FOUND));

    organization.setServicePriority(servicePriority);

    return ServicePriorityResponse.builder()
        .organizationId(organization.getOrganizationId())
        .servicePriority(servicePriority)
        .build();
  }

  // 사용자 서비스 우선순위 조회
  @Transactional(readOnly = true)
  public ServicePriorityResponse getUserServicePriority(String userId) {
    User user = userRepository.findById(userId)
        .orElseThrow(() -> new BusinessException(ErrorCode.USER_NOT_FOUND));
    return buildResponse(user);
  }

  private ServicePriorityResponse buildResponse(User user) {
    ServicePriorityResponse.ServicePriorityResponseBuilder builder =
        ServicePriorityResponse.builder()
            .userId(user.getUserId())
            .userType(user.getUserType().name())
            .servicePriority(user.getAvailableServices());

    if (user.getUserType() == UserType.BUSINESS && user.getOrganization() != null) {
      builder.organizationId(user.getOrganization().getOrganizationId())
          .organizationServicePriority(user.getOrganization().getServicePriority());
    }

    return builder.build();
  }
}
```

---

### 7단계: AdminController 구현

**파일**: `src/main/java/io/iotree/linkwave/api/controller/AdminController.java`

```java
package io.iotree.linkwave.api.controller;

import io.iotree.linkwave.api.dto.request.UpdateServicePriorityRequest;
import io.iotree.linkwave.api.dto.response.ApiResponse;
import io.iotree.linkwave.api.dto.response.ServicePriorityResponse;
import io.iotree.linkwave.service.AdminService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/v1/admin")
@RequiredArgsConstructor
public class AdminController {

  private final AdminService adminService;

  @PreAuthorize("hasRole('SUPER_ADMIN')")
  @PutMapping("/users/{userId}/service-priority")
  public ApiResponse<ServicePriorityResponse> updateUserServicePriority(
      @PathVariable String userId,
      @Valid @RequestBody UpdateServicePriorityRequest request) {

    ServicePriorityResponse response =
        adminService.updateUserServicePriority(userId, request.getServicePriority());

    return ApiResponse.success(response);
  }

  @PreAuthorize("hasRole('SUPER_ADMIN')")
  @PutMapping("/organizations/{orgId}/service-priority")
  public ApiResponse<ServicePriorityResponse> updateOrganizationServicePriority(
      @PathVariable String orgId,
      @Valid @RequestBody UpdateServicePriorityRequest request) {

    ServicePriorityResponse response =
        adminService.updateOrganizationServicePriority(orgId, request.getServicePriority());

    return ApiResponse.success(response);
  }

  @PreAuthorize("hasRole('SUPER_ADMIN')")
  @GetMapping("/users/{userId}/service-priority")
  public ApiResponse<ServicePriorityResponse> getUserServicePriority(
      @PathVariable String userId) {
    ServicePriorityResponse response = adminService.getUserServicePriority(userId);
    return ApiResponse.success(response);
  }
}
```

---

### 8단계: API 권한 검증 Interceptor

**파일**: `src/main/java/io/iotree/linkwave/config/ServicePermissionInterceptor.java`

```java
package io.iotree.linkwave.config;

import io.iotree.linkwave.common.exception.BusinessException;
import io.iotree.linkwave.common.exception.ErrorCode;
import io.iotree.linkwave.domain.user.ServiceType;
import io.iotree.linkwave.domain.user.User;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Component;
import org.springframework.web.servlet.HandlerInterceptor;

@Component
@RequiredArgsConstructor
public class ServicePermissionInterceptor implements HandlerInterceptor {

  @Override
  public boolean preHandle(
      HttpServletRequest request,
      HttpServletResponse response,
      Object handler) {

    String requestUri = request.getRequestURI();
    ServiceType requiredService = determineRequiredService(requestUri);

    if (requiredService != null) {
      Authentication auth = SecurityContextHolder.getContext().getAuthentication();

      if (auth == null || !auth.isAuthenticated()) {
        throw new BusinessException(ErrorCode.UNAUTHORIZED);
      }

      User user = (User) auth.getPrincipal();

      if (!user.hasServicePermission(requiredService)) {
        throw new BusinessException(ErrorCode.SERVICE_NOT_PERMITTED,
            requiredService.getDisplayName() + " 서비스 사용 권한이 없습니다.");
      }
    }

    return true;
  }

  private ServiceType determineRequiredService(String uri) {
    if (uri.contains("/api/v1/messages/sms")) return ServiceType.SMS;
    if (uri.contains("/api/v1/messages/lms")) return ServiceType.LMS;
    if (uri.contains("/api/v1/messages/mms")) return ServiceType.MMS;
    if (uri.contains("/api/v1/messages/kakao")) return ServiceType.KAKAO;
    if (uri.contains("/api/v1/messages/push")) return ServiceType.PUSH;
    if (uri.contains("/api/v1/messages/rcs")) return ServiceType.RCS;
    return null;
  }
}
```

**파일**: `src/main/java/io/iotree/linkwave/config/WebConfig.java`

```java
package io.iotree.linkwave.config;

import lombok.RequiredArgsConstructor;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.servlet.config.annotation.InterceptorRegistry;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;

@Configuration
@RequiredArgsConstructor
public class WebConfig implements WebMvcConfigurer {

  private final ServicePermissionInterceptor servicePermissionInterceptor;

  @Override
  public void addInterceptors(InterceptorRegistry registry) {
    registry.addInterceptor(servicePermissionInterceptor)
        .addPathPatterns("/api/v1/messages/**")
        .excludePathPatterns("/api/v1/auth/**", "/api/v1/admin/**");
  }
}
```

---

## 🎨 프론트엔드 구현 가이드

### 1단계: authStore 수정

**파일**: `linkwave-frontend/src/stores/authStore.js`

```javascript
import { create } from 'zustand';
import { persist } from 'zustand/middleware';

export const useAuthStore = create(
  persist(
    (set, get) => ({
      user: null,
      token: null,
      isAuthenticated: false,
      servicePriority: [], // ['KAKAO', 'SMS', 'LMS', ...]

      login: (user, token) => {
        localStorage.setItem('auth-token', token);
        set({
          user,
          token,
          isAuthenticated: true,
          servicePriority: user.servicePriority || [],
        });
      },

      logout: () => {
        localStorage.removeItem('auth-token');
        set({
          user: null,
          token: null,
          isAuthenticated: false,
          servicePriority: [],
        });
      },

      updateServicePriority: (services) => {
        set({ servicePriority: services });
      },

      hasService: (serviceType) => {
        const { servicePriority } = get();
        return servicePriority.includes(serviceType);
      },
    }),
    {
      name: 'auth-storage',
      partialize: (state) => ({
        user: state.user,
        isAuthenticated: state.isAuthenticated,
        servicePriority: state.servicePriority,
      }),
    }
  )
);
```

---

### 2단계: 권한 체크 Hook

**파일**: `linkwave-frontend/src/hooks/useServicePermission.jsx`

```javascript
import { useAuthStore } from '../stores/authStore';

export const useServicePermission = (serviceType) => {
  const servicePriority = useAuthStore((state) => state.servicePriority);
  return servicePriority.includes(serviceType);
};

export const useServicePriority = () => {
  return useAuthStore((state) => state.servicePriority);
};

export const useHasAnyService = (serviceTypes) => {
  const servicePriority = useAuthStore((state) => state.servicePriority);
  return serviceTypes.some((type) => servicePriority.includes(type));
};
```

---

### 3단계: ServiceGuard 컴포넌트

**파일**: `linkwave-frontend/src/components/common/ServiceGuard.jsx`

```javascript
import { useServicePermission } from '../../hooks/useServicePermission';
import { Navigate } from '@tanstack/react-router';

export const ServiceGuard = ({ serviceType, children, redirectTo = '/dashboard' }) => {
  const hasPermission = useServicePermission(serviceType);

  if (!hasPermission) {
    return <Navigate to={redirectTo} replace />;
  }

  return children;
};
```

---

### 4단계: Header 메뉴 필터링

**파일**: `linkwave-frontend/src/components/common/Header.jsx`

```javascript
import { useServicePriority } from '../../hooks/useServicePermission';
import { SERVICE_TYPES } from '../../utils/constants';
import { Link } from '@tanstack/react-router';

export const Header = () => {
  const servicePriority = useServicePriority();

  const menuItems = [
    { path: '/dashboard', label: '대시보드', service: null },
    { path: '/sms', label: 'SMS', service: SERVICE_TYPES.SMS },
    { path: '/lms', label: 'LMS', service: SERVICE_TYPES.LMS },
    { path: '/mms', label: 'MMS', service: SERVICE_TYPES.MMS },
    { path: '/kakao', label: '카카오톡', service: SERVICE_TYPES.KAKAO },
    { path: '/push', label: 'Push', service: SERVICE_TYPES.PUSH },
    { path: '/rcs', label: 'RCS', service: SERVICE_TYPES.RCS },
    { path: '/history', label: '전송이력', service: null },
    { path: '/address-book', label: '주소록', service: null },
  ];

  const visibleMenu = menuItems.filter((item) =>
    item.service === null || servicePriority.includes(item.service)
  );

  return (
    <nav>
      {visibleMenu.map((item) => (
        <Link key={item.path} to={item.path}>
          {item.label}
        </Link>
      ))}
    </nav>
  );
};
```

---

## 🧪 테스트 시나리오

### 백엔드 테스트

#### 1) 개인 사용자 권한 + Fallback 테스트

```sql
-- 사용자에게 KAKAO → SMS 우선순위 설정
UPDATE users SET service_priority = '["KAKAO", "SMS"]' WHERE user_id = 'user1';
```

```java
// MessageService 테스트
@Test
void testMessageFallback() {
  User user = userRepository.findById("user1").get();

  // KAKAO 실패 시 자동으로 SMS로 fallback
  messageService.sendMessageWithFallback(user, "01012345678", "테스트");

  // 로그 확인:
  // INFO  메시지 전송 시도: service=KAKAO, phone=01012345678
  // WARN  메시지 전송 실패: service=KAKAO, error=Connection timeout
  // INFO  메시지 전송 시도: service=SMS, phone=01012345678
  // INFO  메시지 전송 성공: service=SMS
}
```

#### 2) SUPER_ADMIN API 테스트

```bash
# 사용자 우선순위 설정
curl -X PUT http://localhost:8080/api/v1/admin/users/user1/service-priority \
  -H "Authorization: Bearer {super_admin_token}" \
  -H "Content-Type: application/json" \
  -d '{"servicePriority": ["KAKAO", "SMS", "LMS"]}'

# Response:
{
  "success": true,
  "data": {
    "userId": "user1",
    "userType": "INDIVIDUAL",
    "servicePriority": ["KAKAO", "SMS", "LMS"]
  }
}

# DB 확인:
# user1.service_priority = '["KAKAO","SMS","LMS"]'
```

---

## 🔒 보안 고려사항

1. **백엔드 검증 우선**: 프론트엔드 UI 제어는 UX 목적, 실제 보안은 백엔드에서

2. **JWT에 우선순위 포함 금지**: DB 실시간 조회로 즉시 반영

3. **Interceptor로 동적 권한 검증**: URL 경로 기반

---

## 📝 구현 체크리스트

### 백엔드
- [ ] DB 스키마: `users.service_priority JSON`, `organizations.service_priority JSON` 추가
- [ ] `ServiceType` Enum 작성 (비트마스크 값 제거)
- [ ] `ServicePriorityConverter` 작성 (JPA AttributeConverter)
- [ ] `User` Entity에 `servicePriority` 필드 및 Converter 적용
- [ ] `MessageService`에 Fallback 전송 로직 추가
- [ ] `AdminService`, `AdminController` 구현
- [ ] `ServicePermissionInterceptor` 구현 및 등록

### 프론트엔드
- [ ] `authStore`에 `servicePriority` 상태 추가
- [ ] `useServicePermission` Hook 작성
- [ ] `ServiceGuard` 컴포넌트 작성
- [ ] `Header` 메뉴 필터링

### 테스트
- [ ] Fallback 전송 로직 테스트
- [ ] 조직 권한 상속 테스트
- [ ] SUPER_ADMIN API 테스트
- [ ] 프론트엔드 메뉴 필터링 확인

---

## 📚 대안 접근법: 비트마스크 (교육용)

### 비트마스크란?

정수의 각 비트를 플래그로 사용하여 여러 on/off 상태를 하나의 숫자로 관리하는 기법입니다.

```
SMS  = 1  (0b000001)
LMS  = 2  (0b000010)
MMS  = 4  (0b000100)
KAKAO = 8  (0b001000)

SMS + MMS = 5 (0b000101)
```

### 비트마스크의 장점

1. **메모리 효율**: 4 bytes (INT) vs ~50 bytes (JSON)
2. **쿼리 성능**: 비트 AND 연산 vs JSON 함수
3. **빠른 권한 체크**: O(1) vs O(n)

### 비트마스크의 한계

1. **우선순위 불가**: 순서 정보 없음
2. **확장성 제한**: 최대 32개 (INT) 또는 64개 (BIGINT)
3. **가독성 부족**: 숫자만으로는 의미 파악 어려움

### 언제 비트마스크를 사용할까?

- **단순 권한만 필요한 경우** (우선순위 불필요)
- **사용자 수가 수백만 이상** (쿼리 성능 중요)
- **서비스 개수가 많지 않은 경우** (32개 이하)

**현재 프로젝트**: 우선순위 Fallback이 핵심 요구사항이므로 **JSON 배열이 적합**

---

## 🚀 확장 아이디어

### 1. 시간대별 우선순위

```json
{
  "default": ["KAKAO", "SMS", "LMS"],
  "night": ["SMS", "LMS"],
  "emergency": ["SMS"]
}
```

### 2. 서비스별 쿼터 관리

```java
@Column(name = "monthly_sms_quota")
private int monthlySmsQuota;

@Column(name = "sms_sent_this_month")
private int smsSentThisMonth;
```

### 3. 권한 변경 이력

```sql
CREATE TABLE service_priority_history (
  id BIGINT PRIMARY KEY AUTO_INCREMENT,
  user_id VARCHAR(50),
  old_priority JSON,
  new_priority JSON,
  changed_by VARCHAR(50),
  changed_at DATETIME
);
```

---

**이 가이드를 기반으로 직접 구현하면서 실무 권한 + 우선순위 관리 시스템의 설계 원리를 익혀보세요!** 🎯