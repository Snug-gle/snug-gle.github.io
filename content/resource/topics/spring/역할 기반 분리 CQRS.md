---
tags: [spring, cqrs, architecture, jpa, mybatis]
created: 2026-02-04
modified: 2026-02-04
---
# 역할 기반 분리 (Role-Based CQRS)

## 개요

CQRS(Command Query Responsibility Segregation)의 핵심은 "명령(Command)"과 "조회(Query)"의 책임을 분리하는 것입니다. 하지만 실무에서는 단순히 CUD와 R로 나누는 것보다 **"이 조회 결과로 무엇을 하는가?"**라는 질문이 더 중요합니다.

## 핵심 원칙

### 조회의 목적에 따른 기술 스택 분리

```
조회 결과의 사용 목적
├── 상태 변경을 위한 조회 → Command Layer (JPA)
│   ├── findById() - 엔티티 수정 목적
│   ├── existsBy() - 유효성 검증 목적
│   └── findOneBy() - 비즈니스 로직 실행 목적
│
└── 사용자에게 보여주기 위한 조회 → Query Layer (MyBatis)
    ├── 목록 조회 (페이징, 정렬)
    ├── 검색 (복잡한 조건)
    ├── 상세 보기 (Join 필요)
    └── 통계/집계
```

## 실무 적용 예시

### 1. Command Layer - JPA Repository

**목적**: 엔티티의 상태 변경, 비즈니스 로직 실행

```java
// UserRepository.java
public interface UserRepository extends JpaRepository<User, Long> {

    // ✅ 수정을 위한 조회
    Optional<User> findById(Long id);

    // ✅ 검증을 위한 조회
    boolean existsByEmail(String email);

    // ✅ 비즈니스 로직 실행을 위한 조회
    Optional<User> findByEmail(String email);
}

// UserService.java
@Transactional
public void updateUserProfile(Long userId, UpdateProfileDto dto) {
    User user = userRepository.findById(userId)
        .orElseThrow(() -> new UserNotFoundException());

    // 엔티티 메서드로 상태 변경
    user.updateProfile(dto.getName(), dto.getBio());
    // JPA Dirty Checking으로 자동 저장
}
```

### 2. Query Layer - MyBatis Mapper

**목적**: 사용자에게 데이터 제공 (읽기 전용)

```java
// UserQueryMapper.java (MyBatis Interface)
@Mapper
public interface UserQueryMapper {

    // ✅ 목록 조회 (페이징)
    List<UserListDto> findUserList(UserSearchCondition condition);

    // ✅ 상세 보기 (Join)
    UserDetailDto findUserDetail(Long userId);

    // ✅ 검색 (복잡한 조건)
    List<UserSearchResultDto> searchUsers(UserSearchCriteria criteria);

    // ✅ 통계
    UserStatisticsDto getUserStatistics(Long userId);
}
```

```xml
<!-- UserQueryMapper.xml -->
<mapper namespace="com.example.mapper.UserQueryMapper">
    <select id="findUserDetail" resultType="UserDetailDto">
        SELECT
            u.id,
            u.name,
            u.email,
            u.created_at as createdAt,
            COUNT(p.id) as postCount,
            COUNT(c.id) as commentCount
        FROM users u
        LEFT JOIN posts p ON u.id = p.user_id
        LEFT JOIN comments c ON u.id = c.user_id
        WHERE u.id = #{userId}
        GROUP BY u.id
    </select>
</mapper>
```

### 3. 네이밍 컨벤션

| 계층 | 역할 | 네이밍 | 기술 스택 |
|------|------|--------|-----------|
| Command | 상태 변경 | `{Entity}Repository` | JPA |
| Query | 데이터 제공 | `{Entity}QueryMapper` | MyBatis |

```java
// 예시
UserRepository          // JPA - Command
UserQueryMapper         // MyBatis - Query

OrderRepository         // JPA - Command
OrderQueryMapper        // MyBatis - Query
```

## 의사결정 플로우차트

```
조회 쿼리를 작성해야 할 때
        ↓
"이 조회 결과로 무엇을 하는가?"
        ↓
    ┌───┴───┐
    │       │
엔티티 수정?   화면 표시?
영속성 필요?   DTO 반환?
    │           │
    ↓           ↓
JPA Repository  MyBatis Mapper
(Command)       (Query)
```

### 판단 기준

#### JPA를 사용해야 하는 경우 ✅
- 조회 후 엔티티의 상태를 변경해야 함
- 영속성 컨텍스트 관리가 필요함
- 비즈니스 로직을 엔티티 메서드로 실행해야 함
- 트랜잭션 내에서 Dirty Checking 활용

#### MyBatis를 사용해야 하는 경우 ✅
- 조회 결과를 화면에 바로 표시
- 복잡한 Join이 필요한 상세 조회
- 동적 검색 조건이 많은 목록 조회
- 통계/집계 쿼리
- 성능 최적화가 필요한 대량 조회

## QueryDSL 대신 MyBatis를 선택한 이유

### 1. 학습 곡선
- **QueryDSL**: Q클래스 생성, 복잡한 API, 타입 안전성 학습 필요
- **MyBatis**: SQL 작성 능력만 있으면 즉시 사용 가능

### 2. 유지보수성
```java
// QueryDSL - 복잡한 Join
JPAQueryFactory queryFactory;
List<UserDto> users = queryFactory
    .select(Projections.constructor(UserDto.class,
        user.id, user.name, user.email,
        post.count(), comment.count()))
    .from(user)
    .leftJoin(post).on(post.user.eq(user))
    .leftJoin(comment).on(comment.user.eq(user))
    .where(user.status.eq(UserStatus.ACTIVE))
    .groupBy(user.id)
    .fetch();
```

```xml
<!-- MyBatis - 명확한 SQL -->
<select id="findActiveUsers" resultType="UserDto">
    SELECT
        u.id, u.name, u.email,
        COUNT(p.id) as postCount,
        COUNT(c.id) as commentCount
    FROM users u
    LEFT JOIN posts p ON u.id = p.user_id
    LEFT JOIN comments c ON u.id = c.user_id
    WHERE u.status = 'ACTIVE'
    GROUP BY u.id
</select>
```

### 3. 성능 튜닝
- MyBatis는 SQL을 직접 작성하므로 실행 계획 확인 및 최적화가 용이
- 복잡한 쿼리의 경우 DBMS의 힌트나 최적화 구문을 바로 적용 가능

### 4. 팀 협업
- SQL을 알고 있는 개발자라면 누구나 XML을 읽고 수정 가능
- DBA와의 협업 시 QueryDSL보다 SQL이 직관적

## 실무 예시 비교

### 상황: 사용자 정보 수정

```java
// ❌ 잘못된 접근 - MyBatis로 엔티티 수정
@Transactional
public void updateUser(Long userId, String newName) {
    userQueryMapper.updateUserName(userId, newName);
    // 문제: 엔티티 생명주기 무시, 비즈니스 로직 누락 가능
}

// ✅ 올바른 접근 - JPA로 엔티티 수정
@Transactional
public void updateUser(Long userId, String newName) {
    User user = userRepository.findById(userId)
        .orElseThrow();
    user.changeName(newName); // 엔티티 메서드로 비즈니스 규칙 적용
    // JPA Dirty Checking 자동 반영
}
```

### 상황: 사용자 목록 조회

```java
// ❌ 비효율적인 접근 - JPA로 복잡한 Join
public List<UserListDto> getUserList() {
    List<User> users = userRepository.findAll();
    return users.stream()
        .map(user -> new UserListDto(
            user.getId(),
            user.getName(),
            user.getPosts().size(),  // N+1 문제 발생
            user.getComments().size()
        ))
        .collect(Collectors.toList());
}

// ✅ 효율적인 접근 - MyBatis로 필요한 데이터만 Join
public List<UserListDto> getUserList() {
    return userQueryMapper.findUserList();
    // 단일 쿼리로 필요한 데이터만 조회
}
```

## 주의사항

> [!warning] 경계를 명확히
> - Command와 Query를 섞어 사용하지 말 것
> - Service 계층에서 역할에 맞는 레이어를 호출

> [!tip] 일관성 유지
> - 프로젝트 전체에서 동일한 네이밍 규칙 사용
> - 새로운 팀원도 쉽게 이해할 수 있도록 문서화

## 관련 개념
- [[CQRS 패턴]]
- [[JPA vs MyBatis 비교]]
- [[영속성 컨텍스트]]
- [[N+1 문제 해결]]

## 참고 자료
- Martin Fowler - CQRS Pattern
- Spring Data JPA Documentation
- MyBatis Documentation
