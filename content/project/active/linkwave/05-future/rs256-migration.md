---
created: 2026-02-10
tags:
  - linkwave
  - security
  - jwt
  - rs256
---

> 이 문서는 linkwave-docs의 RS256_MIGRATION.md 원본입니다.

# JWT 인증 RS256 마이그레이션 가이드

## 왜 RS256?

- **향상된 보안**: Private Key는 인증 서버에만 존재, Public Key로만 검증
- **MSA 친화적**: 서비스 간 비밀키 공유 불필요
- **업계 표준**: OAuth 2.0/OIDC 표준, Spring Security 공식 권장

---

## 마이그레이션 절차

### 1단계: RSA 키 페어 생성

```bash
# 2048비트 RSA 개인키 생성
openssl genpkey -algorithm RSA -out private_key.pem -pkeyopt rsa_keygen_bits:2048

# 개인키에서 공개키 추출
openssl rsa -pubout -in private_key.pem -out public_key.pem
```

저장 위치: `src/main/resources/keys/`
`.gitignore`에 `*.pem` 추가

### 2단계: application.yml 설정

```yaml
spring:
  security:
    oauth2:
      resourceserver:
        jwt:
          public-key-location: classpath:keys/public_key.pem

linkwave:
  jwt:
    private-key-path: classpath:keys/private_key.pem
    access-token-expiration: 3600000    # 1시간
    refresh-token-expiration: 604800000 # 7일
```

`public-key-location` 설정으로 Spring Boot가 `JwtDecoder` Bean 자동 구성.

### 3단계: SecurityConfig.java 수정

1. 기존 `jwtSecret` 필드 및 수동 `JwtDecoder` Bean **삭제**
2. `JwtEncoder` Bean을 RS256 방식으로 수정:

```java
@Value("${linkwave.jwt.private-key-path}")
private Resource privateKeyResource;

@Value("${spring.security.oauth2.resourceserver.jwt.public-key-location}")
private Resource publicKeyResource;

@Bean
public JwtEncoder jwtEncoder() throws Exception {
    RSAKey rsaKey = new RSAKey.Builder(readPublicKey(publicKeyResource))
                            .privateKey(readPrivateKey(privateKeyResource))
                            .build();
    return new NimbusJwtEncoder(new ImmutableJWKSet<>(new JWKSet(rsaKey)));
}
```

헬퍼 메서드: PEM 파일 → `RSAPrivateKey`/`RSAPublicKey` 변환

### 4단계: 테스트

1. 애플리케이션 재시작
2. 로그인 API → JWT 발급 확인 (JwtEncoder)
3. 인증 필요 API 호출 → 200 OK 확인 (자동 구성 JwtDecoder)

---

## Related Documents

- [[backend-architecture|Backend Architecture]]
- [[api-specifications|API Specifications]]
