---
created: 2025-12-26
---
# LinkWave Frontend 구현 체크리스트

이 문서는 전체 구현 진행 상황을 추적하기 위한 체크리스트입니다.

---

## Phase 0: 프로젝트 구조 및 개발 환경

### 환경 설정
- [x] Node.js 20+ 설치
- [x] 프로젝트 의존성 설치 (`npm install`)
- [x] Vite + React + TypeScript 구성
- [x] TanStack Router 설정
- [x] TanStack Query 설정
- [x] Zustand 설치
- [x] Tailwind CSS v4 설정
- [x] shadcn/ui 컴포넌트 설치
- [x] 환경 변수 파일 생성 (`.env`)

### 개발 도구
- [x] VSCode TypeScript 설정
- [x] ESLint 설정
- [x] Prettier 설정
- [x] React DevTools 설치

### 확인 사항
- [ ] `npm run dev` 정상 실행
- [ ] `npx tsc --noEmit` 타입 에러 없음
- [ ] `npm run build` 빌드 성공

---

## Phase 1: 타입 시스템 및 API 클라이언트

### 타입 정의
- [ ] `src/types/api.ts` - ApiResponse, PaginatedResponse, ApiError
- [ ] `src/types/auth.ts` - Login, Signup, PhoneVerification 타입
- [x] `src/types/user.ts` - User, UserType, UserRole (이미 구현됨)
- [ ] `src/types/organization.ts` - Organization 타입
- [ ] `src/types/message.ts` - Message, MessageSendRequest 타입

### API 클라이언트
- [x] `src/api/client.ts` - Axios 인스턴스 + 인터셉터 (이미 구현됨)
- [ ] `src/api/authApi.ts` - 인증 API 함수
- [ ] `src/api/messageApi.ts` - 메시지 API 함수
- [ ] `src/api/addressBookApi.ts` - 주소록 API 함수
- [ ] `src/api/statisticsApi.ts` - 통계 API 함수
- [ ] `src/api/organizationApi.ts` - 조직 API 함수
- [ ] `src/api/adminApi.ts` - 관리자 API 함수

### 확인 사항
- [ ] TypeScript 컴파일 에러 없음
- [ ] import 경로 확인 (`@/types`, `@/api`)
- [ ] API Response Interceptor 동작 확인 (401 → 로그아웃)

---

## Phase 2: 인증 시스템 구현

### Zustand Stores
- [x] `src/stores/authStore.ts` - JWT 토큰 관리 (이미 구현됨)
- [x] `src/stores/userStore.ts` - 사용자 프로필 (이미 구현됨)
- [x] `src/stores/signupStore.ts` - 회원가입 상태 (이미 구현됨)

### 로그인/회원가입
- [ ] `src/pages/LoginPage.tsx` - API 연동
  - [ ] Mock 코드 제거
  - [ ] 실제 loginApi 호출
  - [ ] authStore + userStore 업데이트
  - [ ] 에러 처리 개선
- [ ] `src/pages/signup/Step1UserType.tsx` - 회원 유형 선택
- [ ] `src/pages/signup/Step2Phone.tsx` - 휴대폰 인증 API 연동
- [ ] `src/pages/signup/Step3Account.tsx` - 아이디/비밀번호 입력
- [ ] `src/pages/signup/Step4Info.tsx` - 이름/이메일 입력
- [ ] `src/pages/signup/Step5Organization.tsx` - 조직 정보 (법인만)
- [ ] `src/pages/signup/Step6Review.tsx` - 최종 확인 및 API 호출

### 보호된 라우트
- [x] `src/routes/_authenticated.tsx` - 인증 체크 (이미 구현됨)
- [x] `src/routes/_organization-admin.tsx` - 조직 관리자 체크 (이미 구현됨)
- [x] `src/routes/_super-admin.tsx` - Super Admin 체크 (이미 구현됨)

### 유틸리티
- [ ] `src/utils/validation.ts` - 유효성 검사 함수

### 확인 사항
- [ ] 로그인 성공 → 대시보드 이동
- [ ] 로그아웃 → authStore + userStore 클리어
- [ ] 새로고침 → 인증 상태 유지 (persist)
- [ ] 회원가입 성공 → 자동 로그인
- [ ] 휴대폰 인증 플로우 동작 확인

---

## Phase 3: 메시지 발송 시스템

### 메시지 API
- [ ] `src/api/messageApi.ts` 완성
  - [ ] sendMessage
  - [ ] cancelScheduledMessage
  - [ ] getMessageGroupStatus

### 메시지 폼 상태
- [ ] `src/stores/messageFormStore.ts` - 메시지 작성 상태

### 바이트 계산
- [ ] `src/utils/byteCalculator.ts` - 바이트 계산 유틸
  - [ ] calculateBytes 함수
  - [ ] getMessageType 함수 (SMS/LMS 판별)

### SMS 발송
- [ ] `src/pages/SmsPage.tsx` - API 연동
  - [ ] Mock 코드 제거
  - [ ] 실제 sendMessage API 호출
  - [ ] 바이트 계산 실시간 업데이트
  - [ ] 수신자 목록 관리

### LMS 발송
- [ ] `src/pages/LmsPage.tsx` - 장문 메시지
  - [ ] 제목 입력 필드 추가
  - [ ] 2000 bytes 제한

### MMS 발송
- [ ] `src/pages/MmsPage.tsx` - 멀티미디어 메시지
  - [ ] 파일 업로드 UI
  - [ ] 이미지 미리보기
  - [ ] FormData 전송

### 파일 업로드
- [ ] `src/hooks/useFileUpload.ts` - 파일 업로드 훅

### 확인 사항
- [ ] SMS 발송 성공 (90 bytes 이하)
- [ ] LMS 발송 성공 (2000 bytes 이하)
- [ ] MMS 파일 첨부 발송 성공
- [ ] 예약 발송 동작 확인
- [ ] 바이트 계산 정확도 검증

---

## Phase 4: 주소록 관리

### 주소록 타입 및 API
- [ ] `src/types/addressBook.ts` - Contact, ContactGroup 타입
- [ ] `src/api/addressBookApi.ts` - 주소록 API 함수

### 주소록 상태
- [ ] `src/stores/addressBookStore.ts` - 주소록 상태 관리

### 주소록 화면
- [ ] `src/pages/AddressBookPage.tsx` - 주소록 메인 화면
- [ ] `src/components/addressBook/ContactList.tsx` - 연락처 목록
- [ ] `src/components/addressBook/GroupManagement.tsx` - 그룹 관리
- [ ] `src/components/addressBook/ImportExport.tsx` - CSV 기능

### 확인 사항
- [ ] 연락처 CRUD 동작
- [ ] 그룹 생성 및 연락처 할당
- [ ] CSV import 동작 확인
- [ ] CSV export 동작 확인
- [ ] 중복 연락처 감지

---

## Phase 5: 발송 이력 및 통계

### 통계 타입 및 API
- [ ] `src/types/statistics.ts` - DashboardStatistics, DailyStatistics
- [ ] `src/api/statisticsApi.ts` - 통계 API 함수

### 무한 스크롤
- [ ] `src/hooks/useInfiniteScroll.ts` - 무한 스크롤 훅

### 발송 이력
- [ ] `src/pages/HistoryPage.tsx` - 발송 이력 화면 개선
  - [ ] 무한 스크롤 적용
  - [ ] 필터링 기능 (타입, 상태, 날짜)
- [ ] `src/components/history/MessageFilter.tsx` - 필터 컴포넌트

### 통계 대시보드
- [ ] `src/pages/DashboardPage.tsx` - 통계 대시보드 개선
  - [ ] 실제 API 연동
  - [ ] 통계 카드 표시
- [ ] `src/components/dashboard/StatisticsChart.tsx` - 차트 컴포넌트
  - [ ] Recharts 통합
  - [ ] 일별 통계 그래프

### 확인 사항
- [ ] 발송 이력 페이지네이션 동작
- [ ] 무한 스크롤 동작
- [ ] 필터링 동작 확인
- [ ] 통계 차트 렌더링
- [ ] 실시간 데이터 갱신 (Polling or WebSocket)

---

## Phase 6: 조직 관리 (Organization Admin)

### 멤버 관리
- [ ] `src/types/member.ts` - Member 타입
- [ ] `src/api/memberApi.ts` - 멤버 관리 API
- [ ] `src/pages/_organization-admin/members.tsx` - 멤버 관리 화면
- [ ] `src/components/organization/MemberTable.tsx` - 멤버 테이블

### 발신번호 관리
- [ ] `src/types/senderNumber.ts` - SenderNumber 타입
- [ ] `src/api/senderNumberApi.ts` - 발신번호 API
- [ ] `src/pages/_organization-admin/sender-numbers.tsx` - 발신번호 관리
- [ ] `src/components/organization/SenderNumberRegistration.tsx` - 발신번호 등록

### 조직 정보
- [ ] `src/pages/_organization-admin/organization.tsx` - 조직 정보 수정
- [ ] `src/pages/_organization-admin/settings.tsx` - 조직 설정

### 확인 사항
- [ ] 멤버 초대 및 역할 할당
- [ ] 발신번호 등록 신청
- [ ] 조직 정보 수정
- [ ] 멤버 목록 조회
- [ ] 조직 설정 변경

---

## Phase 7: Super Admin 시스템

### 관리자 API
- [ ] `src/api/adminApi.ts` - 관리자 API 함수

### 사용자 관리
- [ ] `src/pages/_super-admin/users.tsx` - 사용자 관리 개선
- [ ] `src/components/admin/UserManagement.tsx` - 사용자 관리 테이블

### 조직 관리
- [ ] `src/pages/_super-admin/organizations.tsx` - 조직 관리 개선
- [ ] `src/components/admin/OrganizationApproval.tsx` - 조직 승인 컴포넌트

### 전체 통계
- [ ] `src/pages/_super-admin/statistics.tsx` - 시스템 전체 통계

### 권한 관리
- [ ] `src/hooks/usePermissions.ts` - 권한 체크 훅

### 확인 사항
- [ ] 사용자 목록 조회 및 상태 관리
- [ ] 조직 승인/거부 동작
- [ ] 전체 시스템 통계 확인
- [ ] 권한 체크 동작
- [ ] Super Admin 전용 기능 접근 제한

---

## Phase 8: 고급 패턴 및 최적화

### Custom Hooks
- [ ] `src/hooks/useAuth.ts` - 인증 훅
- [ ] `src/hooks/useDebounce.ts` - 디바운스 훅

### 에러 처리
- [ ] `src/components/ErrorBoundary.tsx` - 에러 경계

### 로딩 상태
- [ ] `src/components/Loading/SkeletonLoader.tsx` - 스켈레톤 로더

### 성능 최적화
- [ ] Code splitting 설정 (vite.config.ts)
- [ ] Lazy loading 적용 (routes)
- [ ] React.memo 적용 (필요한 컴포넌트)
- [ ] useMemo/useCallback 최적화

### 접근성
- [ ] ARIA 속성 추가
- [ ] 키보드 네비게이션 테스트
- [ ] 스크린 리더 테스트

### 확인 사항
- [ ] Custom Hook 동작 확인
- [ ] Error Boundary로 에러 캐치
- [ ] Lazy loading 동작
- [ ] 번들 크기 확인 (`npm run build`)
- [ ] Lighthouse 성능 점수 90+
- [ ] Lighthouse 접근성 점수 90+

---

## 최종 점검

### 코드 품질
- [ ] ESLint 에러 없음
- [ ] TypeScript 타입 에러 없음
- [ ] 사용하지 않는 import 제거
- [ ] Console.log 제거

### 테스트
- [ ] 모든 페이지 접속 테스트
- [ ] 로그인/로그아웃 플로우 테스트
- [ ] 메시지 발송 플로우 테스트
- [ ] 주소록 CRUD 테스트
- [ ] 조직 관리 기능 테스트
- [ ] 권한별 접근 제한 테스트

### 배포 준비
- [ ] 환경 변수 프로덕션 설정
- [ ] 빌드 최적화 확인
- [ ] HTTPS 설정
- [ ] CORS 설정 확인
- [ ] 백엔드 API 연동 테스트

---

## 진행 상황 요약

### ✅ 완료 (Already Implemented)
- Phase 0: 프로젝트 구조 및 개발 환경
- Zustand Stores (authStore, userStore, signupStore)
- TanStack Router 설정
- 보호된 라우트 (_authenticated, _organization-admin, _super-admin)
- Axios 클라이언트 + 인터셉터
- 기본 UI 컴포넌트 (shadcn/ui)

### 🔄 진행 중 (To Implement)
- Phase 1: 타입 시스템 및 API 클라이언트
- Phase 2: 인증 시스템 API 연동
- Phase 3: 메시지 발송 시스템
- Phase 4: 주소록 관리
- Phase 5: 발송 이력 및 통계
- Phase 6: 조직 관리
- Phase 7: Super Admin 시스템
- Phase 8: 고급 패턴 및 최적화

---

**이 체크리스트를 참고하여 단계별로 구현을 진행하세요!** 🚀

각 Phase를 완료할 때마다 체크박스를 체크하면 진행 상황을 쉽게 추적할 수 있습니다.
