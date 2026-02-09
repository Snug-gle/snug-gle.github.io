---
created: 2025-12-26
---
# Organization Domain Design

## 개요

LinkWave는 **개인 사용자**와 **법인 사용자(소상공인)**를 구분하여 서비스를 제공합니다.
- 개인 사용자: 단독으로 메시지 발송 서비스 이용
- 법인 사용자: 조직(organization) 단위로 팀원과 함께 서비스 이용

## 테이블 설계

### 1. organizations (조직 정보)

법인 사용자가 소속된 조직(회사, 단체) 정보를 관리합니다.

```sql
CREATE TABLE organizations (
    organization_id VARCHAR(50) PRIMARY KEY COMMENT '조직 고유 ID',
    organization_name VARCHAR(100) NOT NULL COMMENT '조직명',
    business_number VARCHAR(20) NOT NULL UNIQUE COMMENT '사업자등록번호 (국세청 API 검증)',
    business_status VARCHAR(20) DEFAULT 'PENDING' COMMENT '사업자 검증 상태: PENDING|VERIFIED|REJECTED',
    verification_date DATETIME COMMENT '사업자번호 검증 완료 일시',

    -- 연락처 정보
    contact_email VARCHAR(100) COMMENT '조직 대표 이메일',
    contact_phone VARCHAR(20) COMMENT '조직 대표 전화번호',
    address VARCHAR(255) COMMENT '사업장 주소',

    -- 사업자 정보
    industry VARCHAR(100) COMMENT '업종',
    representative_name VARCHAR(100) COMMENT '대표자명',

    -- 상태 관리
    status VARCHAR(20) NOT NULL DEFAULT 'ACTIVE' COMMENT 'ACTIVE|SUSPENDED|CLOSED',
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    INDEX idx_business_number (business_number),
    INDEX idx_status (status)
) COMMENT='조직(법인) 정보';
```

**주요 필드:**
- `organization_id`: UUID 또는 `org_{timestamp}_{random}` 형식
- `business_number`: 사업자등록번호 (하이픈 제거하여 저장)
- `business_status`: 국세청 API 검증 결과
  - `PENDING`: 검증 대기 중
  - `VERIFIED`: 검증 완료 (계속사업자)
  - `REJECTED`: 검증 실패 (폐업, 휴업 등)

---

### 2. users (사용자 - 개인/법인 통합)

개인 사용자와 법인 사용자를 하나의 테이블로 관리합니다.

```sql
CREATE TABLE users (
    user_id VARCHAR(50) PRIMARY KEY,
    user_type VARCHAR(20) NOT NULL COMMENT '사용자 유형: INDIVIDUAL|BUSINESS',
    organization_id VARCHAR(50) NULL COMMENT '법인 사용자인 경우 조직 ID',

    -- 인증 정보
    username VARCHAR(50) NOT NULL UNIQUE,
    password VARCHAR(255) NOT NULL COMMENT 'BCrypt 암호화',
    email VARCHAR(100) NOT NULL,
    email_verified BOOLEAN DEFAULT FALSE,
    phone VARCHAR(20) NOT NULL,
    phone_verified BOOLEAN DEFAULT FALSE COMMENT '휴대폰 문자 인증 완료 여부',

    -- 개인 정보
    name VARCHAR(100) NOT NULL COMMENT '개인: 본인 이름, 법인: 담당자 이름',
    department VARCHAR(100) COMMENT '법인 사용자의 부서',

    -- 권한 관리
    role VARCHAR(20) NOT NULL DEFAULT 'USER' COMMENT 'INDIVIDUAL_USER|ORGANIZATION_ADMIN|ORGANIZATION_MEMBER',
    status VARCHAR(20) NOT NULL DEFAULT 'ACTIVE' COMMENT 'ACTIVE|SUSPENDED|DELETED',

    -- 메타 정보
    last_login_at DATETIME,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    FOREIGN KEY (organization_id) REFERENCES organizations(organization_id) ON DELETE CASCADE,
    INDEX idx_user_type (user_type),
    INDEX idx_organization_id (organization_id),
    INDEX idx_phone (phone),
    INDEX idx_email (email),

    -- 제약 조건: 법인 사용자는 반드시 organization_id 필요
    CONSTRAINT chk_business_user CHECK (
        (user_type = 'INDIVIDUAL' AND organization_id IS NULL) OR
        (user_type = 'BUSINESS' AND organization_id IS NOT NULL)
    )
) COMMENT='사용자 테이블 (개인/법인 통합)';
```

**주요 필드:**
- `user_type`:
  - `INDIVIDUAL`: 개인 사용자 (organization_id = NULL)
  - `BUSINESS`: 법인 사용자 (organization_id NOT NULL)
- `role`:
  - `INDIVIDUAL_USER`: 개인 사용자
  - `ORGANIZATION_ADMIN`: 조직 관리자 (최초 가입자, 팀원 관리 권한)
  - `ORGANIZATION_MEMBER`: 조직 일반 멤버

---

### 3. phone_verifications (휴대폰 인증)

가입 시 휴대폰 문자 인증을 위한 테이블입니다.

```sql
CREATE TABLE phone_verifications (
    verification_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    phone VARCHAR(20) NOT NULL,
    verification_code VARCHAR(6) NOT NULL COMMENT '6자리 인증번호',
    purpose VARCHAR(20) NOT NULL COMMENT '인증 목적: SIGNUP|PASSWORD_RESET',
    is_verified BOOLEAN DEFAULT FALSE,
    expires_at DATETIME NOT NULL COMMENT '만료 시간 (발급 후 3분)',
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    verified_at DATETIME,

    INDEX idx_phone_code (phone, verification_code),
    INDEX idx_expires_at (expires_at)
) COMMENT='휴대폰 인증 코드';
```

**인증 플로우:**
1. 사용자가 휴대폰 번호 입력 → 6자리 랜덤 코드 생성 및 SMS 발송
2. 3분 이내에 사용자가 인증번호 입력
3. 검증 성공 시 `is_verified = TRUE`, 5분 유효한 verification_token 발급
4. 회원가입 시 verification_token으로 본인 인증 확인

---

### 4. business_verifications (사업자번호 검증 이력)

국세청 API를 통한 사업자등록번호 검증 이력을 저장합니다.

```sql
CREATE TABLE business_verifications (
    verification_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    business_number VARCHAR(20) NOT NULL,
    organization_name VARCHAR(100) NOT NULL,
    representative_name VARCHAR(100),
    nts_api_response TEXT COMMENT '국세청 API 응답 JSON',
    verification_status VARCHAR(20) NOT NULL COMMENT 'SUCCESS|FAIL|ERROR',
    verified_at DATETIME DEFAULT CURRENT_TIMESTAMP,

    INDEX idx_business_number (business_number)
) COMMENT='사업자번호 검증 이력 (국세청 API)';
```

**검증 절차:**
1. 사용자가 사업자번호, 상호명, 대표자명 입력
2. 국세청 사업자등록 진위확인 API 호출
3. 응답 결과 저장 (`nts_api_response`에 JSON 원본 보관)
4. 검증 성공 시 business_verification_token 발급 (10분 유효)

**국세청 API:**
- URL: `https://api.odcloud.kr/api/nts-businessman/v1/status`
- 응답 코드:
  - `01`: 계속사업자 (SUCCESS)
  - `02`: 휴업자 (FAIL)
  - `03`: 폐업자 (FAIL)

---

## 역할(Role) 정의

| Role | 설명 | user_type | 권한 |
|------|------|-----------|------|
| `INDIVIDUAL_USER` | 개인 사용자 | INDIVIDUAL | - 메시지 발송<br>- 개인 주소록 관리<br>- 개인 발신번호 관리<br>- 개인 통계 조회 |
| `ORGANIZATION_ADMIN` | 조직 관리자 | BUSINESS | - 모든 MEMBER 권한 포함<br>- 팀원 초대/관리<br>- 공유 주소록 관리<br>- 조직 전체 통계 조회<br>- 조직 설정 관리 |
| `ORGANIZATION_MEMBER` | 조직 일반 멤버 | BUSINESS | - 메시지 발송<br>- 공유 주소록 조회<br>- 조직 발신번호 사용<br>- 개인 통계 조회 |

---

## 가입 절차

### 개인 사용자 가입

```
Step 1: 휴대폰 인증 요청
POST /api/v1/auth/phone/request
{
  "phone": "01012345678",
  "purpose": "SIGNUP"
}
→ 6자리 인증번호 SMS 발송

Step 2: 휴대폰 인증 확인
POST /api/v1/auth/phone/verify
{
  "phone": "01012345678",
  "verificationCode": "123456"
}
→ 인증 성공 시 verification_token 발급 (5분 유효)

Step 3: 회원가입
POST /api/v1/auth/register/individual
{
  "verificationToken": "eyJhbGc...",
  "username": "hong_gildong",
  "password": "SecurePass123!",
  "email": "hong@example.com",
  "phone": "01012345678",
  "name": "홍길동"
}

처리:
1. verificationToken 검증
2. users 테이블 저장:
   - user_type = 'INDIVIDUAL'
   - organization_id = NULL
   - role = 'INDIVIDUAL_USER'
   - phone_verified = TRUE
3. JWT 토큰 발급
```

---

### 법인 사용자 가입

```
Step 1: 휴대폰 인증 (개인과 동일)
POST /api/v1/auth/phone/request
POST /api/v1/auth/phone/verify

Step 2: 사업자번호 검증
POST /api/v1/auth/business/verify
{
  "businessNumber": "123-45-67890",
  "organizationName": "ABC 소상공인",
  "representativeName": "김대표"
}
→ 국세청 API 호출 및 검증
→ 검증 성공 시 business_verification_token 발급 (10분 유효)

Step 3: 회원가입
POST /api/v1/auth/register/business
{
  "phoneVerificationToken": "eyJhbGc...",
  "businessVerificationToken": "eyJhbGc...",
  "organization": {
    "organizationName": "ABC 소상공인",
    "businessNumber": "123-45-67890",
    "representativeName": "김대표",
    "contactEmail": "contact@abc.com",
    "contactPhone": "0212345678",
    "address": "서울시 강남구...",
    "industry": "도소매업"
  },
  "user": {
    "username": "abc_admin",
    "password": "SecurePass123!",
    "email": "admin@abc.com",
    "phone": "01012345678",
    "name": "김대표",
    "department": "대표"
  }
}

처리:
1. phoneVerificationToken, businessVerificationToken 검증
2. organizations 테이블 저장:
   - business_status = 'VERIFIED'
   - verification_date = NOW()
3. users 테이블 저장:
   - user_type = 'BUSINESS'
   - organization_id = 생성된 organization_id
   - role = 'ORGANIZATION_ADMIN'
   - phone_verified = TRUE
4. JWT 토큰 발급
```

---

## 주요 비즈니스 로직

### 1. 발신번호 검증

```java
public void validateSenderNumber(String userId, String senderNumber) {
    User user = userRepository.findById(userId)
        .orElseThrow(() -> new BusinessException(ErrorCode.USER_NOT_FOUND));

    if (user.getUserType() == UserType.INDIVIDUAL) {
        // 개인: 본인 소유 발신번호만 사용 가능
        boolean exists = senderNumberRepository
            .existsByUserIdAndSenderNumber(userId, senderNumber);
        if (!exists) {
            throw new BusinessException(ErrorCode.SENDER_NUMBER_NOT_OWNED);
        }
    } else if (user.getUserType() == UserType.BUSINESS) {
        // 법인: 조직 소유 발신번호 사용 가능
        boolean exists = senderNumberRepository
            .existsByOrganizationIdAndSenderNumber(
                user.getOrganizationId(), senderNumber);
        if (!exists) {
            throw new BusinessException(ErrorCode.SENDER_NUMBER_NOT_OWNED);
        }
    }
}
```

---

### 2. 주소록 접근 권한

```java
public List<AddressBook> getAddressBook(String userId) {
    User user = userRepository.findById(userId).orElseThrow();

    List<AddressBook> result = new ArrayList<>();

    // 개인 주소록 (모든 사용자)
    result.addAll(personalAddressBookRepository.findByUserId(userId));

    // 공유 주소록 (법인 사용자만)
    if (user.getUserType() == UserType.BUSINESS) {
        result.addAll(sharedAddressBookRepository
            .findByOrganizationId(user.getOrganizationId()));
    }

    return result;
}
```

---

### 3. 통계 조회 권한

```java
public Statistics getStatistics(String userId, LocalDate startDate, LocalDate endDate) {
    User user = userRepository.findById(userId).orElseThrow();

    if (user.getUserType() == UserType.INDIVIDUAL) {
        // 개인: 본인 발송 통계만
        return statisticsService.getUserStatistics(userId, startDate, endDate);
    } else {
        // 법인: ADMIN은 조직 전체, MEMBER는 본인 통계만
        if (user.getRole() == Role.ORGANIZATION_ADMIN) {
            return statisticsService.getOrganizationStatistics(
                user.getOrganizationId(), startDate, endDate);
        } else {
            return statisticsService.getUserStatistics(userId, startDate, endDate);
        }
    }
}
```

---

## 테이블 관계도

```
┌──────────────────────┐
│  organizations       │
│  (법인 조직)         │
│──────────────────────│
│ organization_id (PK) │
│ organization_name    │
│ business_number (UK) │
│ business_status      │
└──────────────────────┘
           │
           │ 1:N
           ▼
┌──────────────────────┐
│  users               │
│  (개인 + 법인 통합)  │
│──────────────────────│
│ user_id (PK)         │
│ user_type            │◄───── INDIVIDUAL: organization_id = NULL
│ organization_id (FK) │◄───── BUSINESS: organization_id NOT NULL
│ username (UK)        │
│ role                 │
└──────────────────────┘
           │
           │ 1:N
           ▼
┌──────────────────────┐
│  sender_numbers      │
│──────────────────────│
│ sender_number_id (PK)│
│ user_id (FK)         │ ◄── 개인: user_id
│ organization_id (FK) │ ◄── 법인: organization_id
│ sender_number        │
└──────────────────────┘
           │
           │ 1:N
           ▼
┌──────────────────────┐
│  personal_address_book│
│──────────────────────│
│ address_id (PK)      │
│ user_id (FK)         │
│ name, phone          │
└──────────────────────┘

┌──────────────────────┐
│  shared_address_book │
│  (법인 공유 주소록)  │
│──────────────────────│
│ shared_address_id (PK)│
│ organization_id (FK) │
│ name, phone          │
│ created_by (FK users)│
└──────────────────────┘
```

---

## 주요 변경사항 요약

### 테이블명 변경
- `companies` → `organizations`

### 컬럼명 변경
- `company_id` → `organization_id`
- `company_name` → `organization_name`
- `business_number` 필드 추가 (사업자등록번호)
- `business_status` 필드 추가 (검증 상태)

### 사용자 타입 구분
- `users.user_type`: `INDIVIDUAL` | `BUSINESS`
- `users.organization_id`: nullable (개인은 NULL, 법인은 NOT NULL)

### 역할 세분화
- `INDIVIDUAL_USER`: 개인 사용자
- `ORGANIZATION_ADMIN`: 조직 관리자 (팀원 관리 가능)
- `ORGANIZATION_MEMBER`: 조직 일반 멤버

### 인증 강화
- 휴대폰 문자 인증 필수 (`phone_verifications`)
- 국세청 API 사업자번호 검증 (`business_verifications`)

---

## 향후 확장 고려사항

### 1. 팀원 초대 기능 (Phase 2)
```sql
CREATE TABLE organization_invitations (
    invitation_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    organization_id VARCHAR(50) NOT NULL,
    inviter_user_id VARCHAR(50) NOT NULL,
    invitee_email VARCHAR(100) NOT NULL,
    invitation_code VARCHAR(50) NOT NULL UNIQUE,
    role VARCHAR(20) NOT NULL DEFAULT 'ORGANIZATION_MEMBER',
    status VARCHAR(20) NOT NULL DEFAULT 'PENDING',
    expires_at DATETIME NOT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    accepted_at DATETIME,

    FOREIGN KEY (organization_id) REFERENCES organizations(organization_id),
    FOREIGN KEY (inviter_user_id) REFERENCES users(user_id),
    INDEX idx_invitation_code (invitation_code)
);
```

### 2. 조직 요금제 관리
```sql
CREATE TABLE organization_plans (
    plan_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    organization_id VARCHAR(50) NOT NULL,
    plan_type VARCHAR(20) NOT NULL COMMENT 'FREE|BASIC|PRO|ENTERPRISE',
    monthly_message_limit INT NOT NULL,
    max_members INT NOT NULL,
    started_at DATETIME NOT NULL,
    expires_at DATETIME,

    FOREIGN KEY (organization_id) REFERENCES organizations(organization_id)
);
```

### 3. 감사 로그 (조직 활동 추적)
```sql
ALTER TABLE audit_logs
ADD COLUMN organization_id VARCHAR(50),
ADD FOREIGN KEY (organization_id) REFERENCES organizations(organization_id);
```
