---
created: 2025-12-26
---
# LinkWave Frontend 구현 가이드

이 가이드는 LinkWave 프론트엔드 애플리케이션을 단계별로 구현하기 위한 학습 자료입니다. 각 Phase는 백엔드 API와 연동되며, TypeScript와 React의 모던 패턴을 학습할 수 있도록 구성되어 있습니다.

## 📚 학습 목표

- **TypeScript**: Generic, Union Types, Type Guards, Utility Types 활용
- **React 19**: Server Components, Suspense, Transitions, Custom Hooks
- **TanStack Router**: File-based Routing, Type-safe Navigation, Layout 기반 권한 관리
- **TanStack Query**: Server State Management, Infinite Queries, Optimistic Updates
- **Zustand**: Client State Management, Persist Middleware
- **React Hook Form + Zod**: 타입 안전한 폼 검증
- **Tailwind CSS v4**: Modern CSS-first Configuration
- **shadcn/ui**: Accessible Component System

## 🗺️ 구현 순서

### Phase 0: 프로젝트 구조 및 개발 환경
**학습 시간**: 30분
**파일**: [`00-GETTING-STARTED.md`](./00-GETTING-STARTED.md)

- Vite + React + TypeScript 프로젝트 구조 이해
- TanStack Router 파일 기반 라우팅 설정
- TanStack Query 설정
- Zustand 상태 관리 소개
- Tailwind CSS v4 + shadcn/ui 테마 설정
- 환경 변수 관리

**완료 체크**:
- [ ] 개발 서버 실행 (`npm run dev`)
- [ ] 타입 체크 통과 (`npm run typecheck`)
- [ ] 빌드 성공 (`npm run build`)

---

### Phase 1: 타입 시스템 및 API 클라이언트
**학습 시간**: 2-3시간
**파일**: [`01-TYPE-SYSTEM-AND-API-CLIENT.md`](./01-TYPE-SYSTEM-AND-API-CLIENT.md)

백엔드 API와 통신하기 위한 타입 안전한 API 레이어를 구축합니다.

**구현할 파일**:
- `src/types/api.ts` - ApiResponse, PaginatedResponse, ApiError
- `src/types/auth.ts` - Login, Signup, Token 타입
- `src/types/user.ts` - User, UserType, UserRole
- `src/types/organization.ts` - Organization 관련 타입
- `src/types/message.ts` - Message, SendRequest 타입
- `src/api/client.ts` - Axios 인스턴스 + 인터셉터
- `src/api/authApi.ts` - 인증 API 함수들

**학습 포인트**:
- TypeScript Generic을 활용한 재사용 가능한 타입
- Axios 인터셉터로 401 자동 처리
- 백엔드 ErrorCode와 매핑되는 에러 처리

**완료 체크**:
- [ ] 모든 타입 파일 작성 완료
- [ ] API 클라이언트 인터셉터 동작 확인
- [ ] 타입 안전성 검증 (no `any` types)

---

### Phase 2: 인증 시스템 구현
**학습 시간**: 3-4시간
**파일**: [`02-AUTHENTICATION-SYSTEM.md`](./02-AUTHENTICATION-SYSTEM.md)

JWT 기반 로그인/회원가입 플로우를 완성하고, 보호된 라우트를 구현합니다.

**구현할 파일**:
- `src/stores/authStore.ts` - JWT 토큰 관리 (✅ 이미 구현됨)
- `src/stores/userStore.ts` - 사용자 프로필 (✅ 이미 구현됨)
- `src/stores/signupStore.ts` - 다단계 회원가입 상태 (✅ 이미 구현됨)
- `src/pages/LoginPage.tsx` - 로그인 화면 (✅ 이미 구현됨)
- `src/pages/signup/*` - 회원가입 6단계 화면 (✅ 이미 구현됨)
- `src/routes/_authenticated.tsx` - 보호 라우트 (✅ 이미 구현됨)
- `src/utils/validation.ts` - 유효성 검사 유틸

**학습 포인트**:
- Zustand persist middleware로 인증 상태 유지
- React Hook Form + Zod를 활용한 폼 검증
- 다단계 폼의 상태 관리 패턴
- TanStack Router의 beforeLoad를 활용한 권한 체크
- 휴대폰 인증 플로우 (SMS 인증)

**완료 체크**:
- [ ] 로그인 성공 시 토큰 저장 및 대시보드 이동
- [ ] 로그아웃 시 상태 초기화
- [ ] 회원가입 6단계 완료 후 로그인
- [ ] 보호된 라우트 접근 시 리다이렉트

---

### Phase 3: 메시지 발송 시스템
**학습 시간**: 4-5시간
**파일**: [`03-MESSAGE-SENDING.md`](./03-MESSAGE-SENDING.md)

SMS/LMS/MMS 메시지 발송 기능을 구현합니다.

**구현할 파일**:
- `src/api/messageApi.ts` - 메시지 발송 API
- `src/stores/messageFormStore.ts` - 메시지 작성 상태
- `src/pages/SmsPage.tsx` - SMS 발송 화면 (✅ 이미 구현됨)
- `src/pages/LmsPage.tsx` - LMS 발송 화면 (TODO)
- `src/pages/MmsPage.tsx` - MMS 발송 화면 (TODO)
- `src/components/sms/ByteVisualizer.tsx` - 바이트 계산 (✅ 이미 구현됨)
- `src/components/sms/MessageTemplates.tsx` - 템플릿 선택 (✅ 이미 구현됨)
- `src/hooks/useFileUpload.ts` - 파일 업로드 훅 (NEW)

**학습 포인트**:
- FormData를 활용한 멀티미디어 파일 업로드
- 바이트 계산 로직 (한글 3byte, 영문 1byte)
- 예약 발송 처리 (ISO 8601 형식)
- 중복 발송 방지 (Debounce + Loading 상태)
- 수신자 목록 관리 (Excel/CSV 업로드)

**완료 체크**:
- [ ] SMS 단문 발송 성공 (90byte 이하)
- [ ] LMS 장문 발송 성공 (2000byte 이하)
- [ ] MMS 파일 첨부 발송 성공
- [ ] 예약 발송 설정 및 확인
- [ ] 바이트 계산 정확도 검증

---

### Phase 4: 주소록 관리
**학습 시간**: 3-4시간
**파일**: [`04-ADDRESS-BOOK.md`](./04-ADDRESS-BOOK.md)

주소록 CRUD 및 그룹 관리 기능을 구현합니다.

**구현할 파일** (NEW):
- `src/api/addressBookApi.ts` - 주소록 API
- `src/types/addressBook.ts` - Contact, Group 타입
- `src/stores/addressBookStore.ts` - 주소록 상태
- `src/pages/AddressBookPage.tsx` - 주소록 화면
- `src/components/addressBook/ContactList.tsx` - 연락처 목록
- `src/components/addressBook/GroupManagement.tsx` - 그룹 관리
- `src/components/addressBook/ImportExport.tsx` - CSV 가져오기/내보내기

**학습 포인트**:
- CSV 파싱 및 생성 (Papa Parse 라이브러리)
- 대량 데이터 처리 (Virtual Scrolling)
- 검색/필터링 UI (Debounced Search)
- 그룹 관리 (Drag & Drop)
- 중복 연락처 병합

**완료 체크**:
- [ ] 연락처 CRUD 동작
- [ ] 그룹 생성 및 연락처 할당
- [ ] CSV 파일 import/export
- [ ] 검색 및 필터링 동작
- [ ] 중복 연락처 감지

---

### Phase 5: 발송 이력 및 통계
**학습 시간**: 3-4시간
**파일**: [`05-HISTORY-AND-STATISTICS.md`](./05-HISTORY-AND-STATISTICS.md)

메시지 발송 이력 조회 및 통계 대시보드를 구현합니다.

**구현할 파일**:
- `src/api/statisticsApi.ts` - 통계 API (NEW)
- `src/types/statistics.ts` - 통계 타입 (NEW)
- `src/pages/HistoryPage.tsx` - 이력 조회 (개선 필요)
- `src/pages/DashboardPage.tsx` - 통계 대시보드 (개선 필요)
- `src/components/dashboard/StatisticsChart.tsx` - 차트 컴포넌트 (NEW)
- `src/components/history/MessageFilter.tsx` - 필터 컴포넌트 (NEW)
- `src/hooks/useInfiniteScroll.ts` - 무한 스크롤 훅 (NEW)

**학습 포인트**:
- TanStack Query의 useInfiniteQuery
- Intersection Observer를 활용한 무한 스크롤
- Chart 라이브러리 통합 (Recharts)
- 날짜 범위 필터링 (date-fns)
- 실시간 통계 업데이트 (Polling)

**완료 체크**:
- [ ] 발송 이력 페이지네이션
- [ ] 무한 스크롤 동작
- [ ] 날짜/상태/타입 필터링
- [ ] 통계 차트 렌더링
- [ ] 실시간 데이터 갱신

---

### Phase 6: 조직 관리 (Organization Admin)
**학습 시간**: 3-4시간
**파일**: [`06-ORGANIZATION-MANAGEMENT.md`](./06-ORGANIZATION-MANAGEMENT.md)

조직 관리자 기능을 구현합니다 (법인 사용자용).

**구현할 파일**:
- `src/api/memberApi.ts` - 멤버 관리 API (NEW)
- `src/api/senderNumberApi.ts` - 발신번호 API (NEW)
- `src/types/member.ts` - Member 타입 (NEW)
- `src/types/senderNumber.ts` - SenderNumber 타입 (NEW)
- `src/pages/_organization-admin/members.tsx` - 멤버 관리 (개선)
- `src/pages/_organization-admin/organization.tsx` - 조직 정보 (개선)
- `src/pages/_organization-admin/sender-numbers.tsx` - 발신번호 관리 (NEW)
- `src/pages/_organization-admin/settings.tsx` - 조직 설정 (NEW)
- `src/components/organization/MemberTable.tsx` - 멤버 테이블 (NEW)
- `src/components/organization/SenderNumberRegistration.tsx` - 발신번호 등록 (NEW)

**학습 포인트**:
- 멀티테넌시 패턴 (organizationId 기반)
- 멤버 초대 플로우 (이메일 인증)
- 발신번호 등록 및 승인 프로세스
- 조직 설정 관리
- 권한 기반 UI 렌더링

**완료 체크**:
- [ ] 멤버 초대 및 역할 할당
- [ ] 발신번호 등록 신청
- [ ] 조직 정보 수정
- [ ] 멤버 목록 조회 및 관리
- [ ] 조직 설정 변경

---

### Phase 7: Super Admin 시스템
**학습 시간**: 2-3시간
**파일**: [`07-SUPER-ADMIN.md`](./07-SUPER-ADMIN.md)

시스템 관리자 기능을 구현합니다.

**구현할 파일**:
- `src/api/adminApi.ts` - 관리자 API (NEW)
- `src/pages/_super-admin/users.tsx` - 사용자 관리 (개선)
- `src/pages/_super-admin/organizations.tsx` - 조직 관리 (개선)
- `src/pages/_super-admin/statistics.tsx` - 전체 통계 (NEW)
- `src/components/admin/UserManagement.tsx` - 사용자 관리 테이블 (NEW)
- `src/components/admin/OrganizationApproval.tsx` - 조직 승인 (NEW)
- `src/hooks/usePermissions.ts` - 권한 체크 훅 (NEW)

**학습 포인트**:
- Role-based Access Control (RBAC)
- 권한 기반 UI 렌더링 패턴
- 시스템 전체 통계 조회
- 사용자/조직 관리 워크플로우
- 승인 프로세스 구현

**완료 체크**:
- [ ] 사용자 목록 조회 및 상태 관리
- [ ] 조직 승인/거부
- [ ] 전체 시스템 통계 확인
- [ ] 권한 체크 동작
- [ ] Super Admin 전용 기능 접근 제한

---

### Phase 8: 고급 패턴 및 최적화
**학습 시간**: 3-4시간
**파일**: [`08-ADVANCED-PATTERNS.md`](./08-ADVANCED-PATTERNS.md)

성능 최적화 및 UX 개선을 위한 고급 패턴을 학습합니다.

**구현할 파일** (NEW):
- `src/hooks/useAuth.ts` - 인증 훅
- `src/hooks/useDebounce.ts` - 디바운스 훅
- `src/components/ErrorBoundary.tsx` - 에러 경계
- `src/components/Loading/SkeletonLoader.tsx` - 스켈레톤 로더
- Code splitting 설정 (vite.config.ts)
- Lazy loading 적용 (routes)

**학습 포인트**:
- Custom Hook 작성 패턴
- Error Boundary로 에러 격리
- React Suspense + Lazy loading
- Code splitting으로 번들 최적화
- 접근성 개선 (ARIA, 키보드 네비게이션)
- 성능 모니터링 (React DevTools Profiler)

**완료 체크**:
- [ ] Custom Hook 동작 확인
- [ ] Error Boundary로 에러 캐치
- [ ] Lazy loading 적용
- [ ] 번들 크기 최적화 확인
- [ ] Lighthouse 접근성 점수 90+

---

## 📋 구현 체크리스트

전체 구현 진행 상황을 추적하려면 [`IMPLEMENTATION-CHECKLIST.md`](./IMPLEMENTATION-CHECKLIST.md)를 참조하세요.

---

## 🎯 학습 전략

### 1. 순차적 학습
Phase 0부터 순서대로 진행하는 것을 권장합니다. 각 Phase는 이전 Phase의 개념을 기반으로 합니다.

### 2. 코드 작성 우선
가이드의 코드를 복사하지 말고, 직접 타이핑하면서 이해하세요. TypeScript 타입 에러를 직접 해결하는 과정에서 많이 배울 수 있습니다.

### 3. 백엔드 API 문서 참조
각 Phase는 백엔드 API와 연동됩니다. 백엔드 API 문서를 함께 참조하세요:
- `/home/sanghoon/project/iotree-linkwave/linkwave-backend/docs/API_SPECIFICATION_DETAIL.md`
- `/home/sanghoon/project/iotree-linkwave/linkwave-backend/docs/implementation-guides/`

### 4. 실험과 디버깅
코드가 동작하지 않을 때는:
1. TypeScript 에러 메시지를 주의 깊게 읽기
2. React DevTools로 컴포넌트 상태 확인
3. Network 탭에서 API 요청/응답 확인
4. Console에서 에러 스택 트레이스 분석

### 5. 테스트 주도 학습
각 Phase의 "완료 체크" 항목을 하나씩 확인하면서 진행하세요.

---

## 🔧 개발 환경 요구사항

- **Node.js**: v20 이상
- **npm**: v10 이상
- **에디터**: VSCode (TypeScript 지원)
- **브라우저**: Chrome/Edge (React DevTools 설치)

---

## 📚 참고 자료

### 공식 문서
- [TypeScript Handbook](https://www.typescriptlang.org/docs/)
- [React 19 Docs](https://react.dev/)
- [TanStack Router](https://tanstack.com/router/latest)
- [TanStack Query](https://tanstack.com/query/latest)
- [Zustand](https://zustand.docs.pmnd.rs/)
- [Tailwind CSS v4](https://tailwindcss.com/docs)
- [shadcn/ui](https://ui.shadcn.com/)
- [React Hook Form](https://react-hook-form.com/)
- [Zod](https://zod.dev/)

### 학습 리소스
- [Total TypeScript](https://www.totaltypescript.com/) - TypeScript 심화 학습
- [React TypeScript Cheatsheet](https://react-typescript-cheatsheet.netlify.app/)
- [Patterns.dev](https://www.patterns.dev/) - React 디자인 패턴

---

## 💬 도움이 필요하신가요?

각 가이드 문서의 "자주하는 실수" 섹션을 참조하거나, 백엔드 API 문서와 비교하여 타입 및 응답 형식을 확인하세요.

Happy coding! 🚀
