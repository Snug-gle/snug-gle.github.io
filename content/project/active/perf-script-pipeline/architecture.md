---
created: 2025-11-27
updated: 2025-11-27
tags:
  - project
  - architecture
  - spring-boot
  - react
  - performance-testing
  - jmeter
status: active
---

# Perf Script Pipeline - 프로젝트 아키텍처

> **Perf Script Pipeline (HAR-JMX Correlation Analysis Tool)** 전체 아키텍처 및 코드베이스 분석 문서

## 관련 문서
- [[Perf Script Pipeline 프로젝트 면접 준비]] - 프론트엔드 중심 면접 준비 자료

---

## 목차
1. [프로젝트 개요](#1-프로젝트-개요)
2. [전체 아키텍처](#2-전체-아키텍처)
3. [백엔드 아키텍처](#3-백엔드-아키텍처)
4. [핵심 비즈니스 로직](#4-핵심-비즈니스-로직)
5. [데이터 흐름](#5-데이터-흐름)
6. [주요 기술 포인트](#6-주요-기술-포인트)

---

## 1. 프로젝트 개요

### 1.1 프로젝트 목적

**Perf Script Pipeline - Correlation Analysis Tool**은 웹 애플리케이션의 성능 테스트 자동화를 지원하는 도구입니다.

**핵심 가치:**
- HAR(HTTP Archive) 파일과 JTL(JMeter Test Log) 파일을 분석하여 동적 파라미터 간 상관관계 자동 추출
- AI 기반 정규표현식 추출기(RegEx Extractor) 자동 추천
- JMeter 테스트 스크립트(JMX) 자동 생성 및 최적화

**비즈니스 임팩트:**
- 수동 작업 시간 80% 단축 (상관관계 분석 자동화)
- 성능 테스트 정확도 향상 (AI 기반 추천)
- 테스트 스크립트 품질 향상

### 1.2 주요 기능

1. **HAR/JTL 파일 업로드 및 분석**
   - 다중 HAR 파일 병합 및 검증
   - JTL 파일 파싱 및 인덱싱
   - 대용량 HTTP 요청/응답 데이터 처리

2. **상관관계 자동 추출**
   - 요청 파라미터와 응답 값 매칭
   - 동적 변수 자동 감지
   - 추출 규칙 자동 생성

3. **AI 기반 정규표현식 추천**
   - Spring AI (OpenAI) 연동
   - 컨텍스트 기반 RegEx 패턴 생성
   - 추출기 위치 및 매칭 전략 추천

4. **JMX 파일 생성 및 수정**
   - HAR → JMX 변환
   - RegexExtractor 자동 삽입
   - 변수 주입 및 검증

5. **예외 규칙 관리**
   - 사전 정의 규칙 (Pre-rules)
   - 사용자 정의 제외 규칙
   - AI 추천 제외 패턴

---

## 2. 전체 아키텍처

### 2.1 시스템 구성

```
┌─────────────────────────────────────────────────────┐
│                   Frontend (React)                   │
│  - React 19 + TypeScript                            │
│  - TanStack Router/Query/Table/Virtual              │
│  - Tailwind CSS + Radix UI                          │
└────────────────┬────────────────────────────────────┘
                 │ REST API (JSON)
┌────────────────┴────────────────────────────────────┐
│              Backend (Spring Boot)                   │
│  - Spring Boot 3.5.8 (Java 21)                      │
│  - Spring Security + LDAP                           │
│  - Spring AI (OpenAI)                               │
│  - JPA + H2 Database                                │
└────────────────┬────────────────────────────────────┘
                 │
┌────────────────┴────────────────────────────────────┐
│              Data Layer                              │
│  - File System (HAR/JMX/JTL)                        │
│  - H2 Database (메타데이터, 상관관계)                │
└─────────────────────────────────────────────────────┘
```

### 2.2 기술 스택 상세

#### Backend
- **Framework**: Spring Boot 3.5.8
- **Language**: Java 21
- **Security**: Spring Security + LDAP 인증
- **AI**: Spring AI 1.1.0 (OpenAI 모델 연동)
- **Database**: H2 (embedded, file mode)
- **ORM**: Spring Data JPA
- **Documentation**: SpringDoc OpenAPI (Swagger UI)
- **Utilities**:
  - ModelMapper (DTO ↔ Entity 변환)
  - Apache Commons Lang3
  - Lombok

#### Frontend
- **Framework**: React 19
- **Language**: TypeScript
- **Build**: Vite
- **Routing**: TanStack Router
- **State**: TanStack Query (React Query v5)
- **UI**: TanStack Table v8, TanStack Virtual
- **Styling**: Tailwind CSS
- **Components**: Radix UI (헤드리스 컴포넌트)

#### Build & Deploy
- **Build Tool**: Gradle 8.x
- **Version**: Git commit date/hash 기반 (예: `1.0.251127_0943_abc123`)
- **Packaging**: Spring Boot JAR (frontend 포함)

---

## 3. 백엔드 아키텍처

### 3.1 패키지 구조

```
com.jadecross.perftester.correl
├── aiagent/              # AI 에이전트 (정규식 추천)
├── api/                  # REST API 컨트롤러
│   ├── JmxCorrelationApiV1.java
│   ├── JmxListApiV2.java
│   ├── JtlListApiV2.java
│   ├── HarMergeToJmxJtlApiV2.java
│   └── PerfTestApiV1.java
├── common/               # 공통 유틸리티
│   ├── DateTimeEpoch.java
│   └── JtlConstants.java
├── config/               # 설정 클래스
│   ├── SecurityConfig.java
│   ├── AiAgentConfig.java
│   ├── WebConfig.java
│   └── ...
├── controller/           # 웹 컨트롤러 (Thymeleaf)
│   └── LoginController.java
├── domain/               # 도메인 모델
│   ├── entity/          # JPA 엔티티
│   │   ├── PerfTest.java
│   │   ├── JmxRequest.java
│   │   ├── JmxCorrelation.java
│   │   ├── JtlSample.java
│   │   └── JtlElement.java
│   ├── dto/             # 데이터 전송 객체
│   └── exception/       # 커스텀 예외
├── repository/           # JPA Repository
│   ├── PerfTestRepository.java
│   ├── JmxRequestRepository.java
│   ├── JmxCorrelationRepository.java
│   ├── JtlSampleRepository.java
│   └── ...
├── schedule/            # 스케줄 태스크
│   └── CacheClearScheduleTask.java
└── service/             # 비즈니스 로직
    ├── HarMergeOrchestratorService.java
    ├── HarMergeService.java
    ├── HarToJmxJtlTransService.java
    ├── JmxCorrelationService.java
    ├── JmxListService.java
    ├── JtlIndexService.java
    ├── RegexExtractorRecommendService.java
    └── ...
```

### 3.2 핵심 도메인 엔티티

#### 3.2.1 PerfTest
```java
@Entity
public class PerfTest {
    @Id
    private String id;           // 테스트 ID (사용자 정의)
    private String status;       // 테스트 상태
    private String errorMessage; // 에러 메시지 (최대 5000자)

    // 감사(Audit) 필드
    private String createdBy;
    private LocalDateTime createdDate;
    private String modifiedBy;
    private LocalDateTime modifiedDate;
}
```

**역할**: 성능 테스트 프로젝트의 메타데이터를 저장합니다.

**주요 특징**:
- `@EntityListeners(AuditingEntityListener.class)`: 생성/수정 정보 자동 기록
- ID는 사용자가 지정 (예: `test-2025-01`)
- 상태 관리: 처리 중, 완료, 에러 등

#### 3.2.2 JmxRequest
```java
@Entity
public class JmxRequest {
    @Id @GeneratedValue
    private Long id;

    private String perfId;       // PerfTest FK
    private String sid;          // Sampler ID (JMeter)
    private String name;         // 요청 이름
    private String method;       // HTTP 메서드
    private String path;         // URL 경로
    private String domain;       // 도메인

    // 요청/응답 데이터
    @Lob
    private String arguments;    // 요청 파라미터 (JSON)
    @Lob
    private String headers;      // 요청 헤더 (JSON)
}
```

**역할**: JMX 파일에서 추출한 HTTP 요청 정보를 저장합니다.

**주요 특징**:
- JMX 파일 파싱 후 DB에 인덱싱
- 상관관계 분석의 기준 데이터
- `@Lob`: 대용량 텍스트 저장 (arguments, headers)

#### 3.2.3 JmxCorrelation
```java
@Entity
@Table(uniqueConstraints = @UniqueConstraint(
    columnNames = {"jmx_request_id", "regex", "location"}
))
public class JmxCorrelation {
    @Id @GeneratedValue
    private Long id;

    private String perfId;       // PerfTest FK
    private Long requestId;      // JmxRequest FK

    // 상관관계 정보
    private String reqSid;       // 요청 SID
    private String resSid;       // 응답 SID (추출 위치)
    private String location;     // 추출 위치 (URL/Body/Header)

    // RegexExtractor 설정
    private String regex;        // 정규표현식
    private String refName;      // 변수 이름 (예: CORR_123)
    private String template;     // 추출 템플릿 (예: $1$)
    private Integer matchNumber; // 매칭 번호 (기본: 1)
    private Integer matchOffset; // 매칭 오프셋 (기본: 0)
    private String defaultValue; // 기본값

    // 메타데이터
    private String source;       // 출처: PRERULE/AIRECOMM/MANUAL
    private boolean selected;    // 사용자 선택 여부
    @Lob
    private String snippet;      // 코드 스니펫

    private Instant createdAt;
    private Instant updatedAt;
}
```

**역할**: 요청-응답 간 상관관계 및 RegexExtractor 설정을 저장합니다.

**주요 특징**:
- Unique Constraint: (requestId, regex, location) 중복 방지
- `source` 필드로 출처 구분:
  - `PRERULE`: 사전 정의 규칙
  - `AIRECOMM`: AI 추천
  - `MANUAL`: 사용자 수동 입력
- `selected=true`: 최종 JMX에 적용될 항목

#### 3.2.4 JtlSample & JtlElement
```java
@Entity
public class JtlSample {
    @Id @GeneratedValue
    private Long id;

    private String perfId;
    private Long timestamp;      // 요청 시작 시간 (epoch ms)
    private Long elapsed;        // 소요 시간 (ms)
    private String label;        // 샘플러 이름
    private Integer responseCode;
    private String responseMessage;
    private String threadName;
    private Boolean success;

    @Lob
    private String requestHeaders;
    @Lob
    private String responseData;
}

@Entity
public class JtlElement {
    @Id @GeneratedValue
    private Long id;

    private String perfId;
    private Long sampleId;       // JtlSample FK
    private String location;     // URL/Body/Header
    private String name;         // 파라미터 이름
    private String value;        // 파라미터 값
}
```

**역할**: JTL 파일 파싱 결과를 저장합니다.

**주요 특징**:
- `JtlSample`: 각 HTTP 요청-응답 쌍
- `JtlElement`: 요청/응답에서 추출한 개별 파라미터
- 상관관계 분석 시 응답 값 매칭에 사용

### 3.3 주요 서비스 계층

#### 3.3.1 HarMergeOrchestratorService

**역할**: HAR 병합 → JMX/JTL 변환 전체 공정을 오케스트레이션

**핵심 메서드**:
```java
public ResponseEntity<Map<String, Object>> runMergeAndConvert(
    String perfId,
    String prefix,
    String order,        // 병합 순서: filename/timeline
    String dedupe,       // 중복 제거 정책
    boolean saveFile,    // HAR 저장 여부
    boolean includeWarnings,  // 경고 주석 반영
    // ... 기타 파라미터
    Supplier<List<MultipartFile>> fileSupplier
)
```

**처리 단계**:
1. 출력 디렉토리 준비 (`./data/perfTests/{perfId}/`)
2. 이전 산출물 삭제 (HAR/JMX/JTL)
3. JMX 인덱스 DB 초기화
4. HAR 파일 병합 (`HarMergeService`)
5. JMX/JTL 변환 (`HarToJmxJtlTransService`)
6. JTL SID 보정 (`JtlSidRewriteService`)
7. `_cvDiag` 경고 주석 반영 (`CvDiagAnnotatorService`)
8. 파일 출처 기록 (`FileSourceTrackingService`)

**중요 포인트**:
- **Supplier 패턴**: 파일 공급 방식을 추상화 (업로드/디스크)
- **단계별 검증**: 각 단계 완료 후 산출물 존재 확인
- **에러 처리**: 단계별 실패 시 명확한 에러 메시지 반환
- **파일 추적**: 생성된 모든 산출물을 "GENERATED" 상태로 기록

#### 3.3.2 JmxCorrelationService

**역할**: JMX에 상관관계(RegexExtractor) 적용

**핵심 메서드**:

```java
// 1. 선택된 상관관계 저장
@Transactional
public List<JmxCorrelation> saveChoices(CorrelationChoiceRequest req) {
    // 1) 기존 선택 삭제 (requestId 단위)
    // 2) 신규 선택 저장
    // 3) refName 자동 생성 (미지정 시: CORR_{resSid})
}

// 2. JMX에 RegexExtractor 적용
@Transactional(readOnly = true)
public byte[] applyCorrelationsJmxOut(String perfId, InputStream jmxInput) {
    // 1) JMX XML 파싱
    // 2) DB에서 선택된 상관관계 조회
    // 3) 각 resSid에 대해:
    //    - 해당 샘플러 찾기 (JmxRequest.name → JMX testname)
    //    - RegexExtractor 생성/갱신
    //    - 다음 요청에 ${refName} 주입
    // 4) 수정된 JMX 반환 (pretty print)
}
```

**중요 포인트**:
- **삭제 후 저장 패턴**: 동일 requestId 범위의 기존 선택을 먼저 삭제
- **안전한 XML 파싱**: DOCTYPE 비활성화 (XXE 공격 방지)
- **XPath 탐색**: resSid@testname → 샘플러 노드 찾기
- **변수 주입**: reqSid와 일치하는 샘플러의 Arguments만 수정

#### 3.3.3 RegexExtractorRecommendService

**역할**: AI 기반 정규표현식 추출기 추천

**핵심 메서드**:
```java
public List<RegexExtractor> recommendExtractors(
    String perfId,
    String resSid,
    String location,
    String responseData,
    String targetValue
) {
    // 1) Spring AI ChatClient 준비
    // 2) 프롬프트 구성:
    //    - 응답 데이터 샘플
    //    - 추출 대상 값
    //    - 위치 (Body/Header/URL)
    // 3) AI 호출 및 응답 파싱
    // 4) RegexExtractor DTO 리스트 반환
}
```

**AI 프롬프트 예시**:
```
You are a JMeter RegexExtractor expert.
Given the following HTTP response data:

[Response Data]
...

Extract the value: "abc123"

Generate a regex pattern with:
- Pattern: the regex to extract the value
- Template: the extraction template (e.g., $1$)
- MatchNumber: which occurrence to extract
- DefaultValue: fallback value if not found
```

**중요 포인트**:
- **컨텍스트 제공**: 응답 데이터 전체를 AI에 제공
- **구조화된 출력**: JSON 형식으로 응답 요청
- **검증**: AI 응답을 파싱하여 DTO로 변환
- **폴백**: AI 실패 시 기본 패턴 제공

### 3.4 주요 API 엔드포인트

#### 3.4.1 HAR/JMX/JTL 변환 API

```java
@RestController
@RequestMapping("/api/v2/har")
public class HarMergeToJmxJtlApiV2 {

    // HAR 업로드 → JMX/JTL 생성
    @PostMapping("/merge-and-convert")
    public ResponseEntity<Map<String, Object>> mergeAndConvert(
        @RequestParam("files") List<MultipartFile> files,
        @RequestParam String perfId,
        @RequestParam(defaultValue = "filename") String order,
        @RequestParam(defaultValue = "none") String dedupe,
        // ... 기타 파라미터
    ) {
        return orchestrator.runMergeAndConvert(
            perfId, prefix, order, dedupe, saveFile, includeWarnings,
            // ...
            () -> files  // Supplier<List<MultipartFile>>
        );
    }
}
```

**요청 예시**:
```bash
POST /api/v2/har/merge-and-convert
Content-Type: multipart/form-data

files: [file1.har, file2.har]
perfId: test-2025-01
order: timeline
dedupe: exact
saveFile: true
```

**응답 예시**:
```json
{
  "ok": true,
  "perfId": "test-2025-01",
  "merged_har": "./data/perfTests/test-2025-01/test-2025-01.har",
  "jmx_out": "./data/perfTests/test-2025-01/test-2025-01.jmx",
  "jtl_out": "./data/perfTests/test-2025-01/test-2025-01.jtl",
  "jmeterOk": true,
  "jmeterExitCode": 0,
  "merge_info": {
    "totalRequests": 150,
    "duplicatesRemoved": 12,
    "warnings": []
  }
}
```

#### 3.4.2 상관관계 분석 API

```java
@RestController
@RequestMapping("/api/v1/expression")
public class JmxCorrelationApiV1 {

    // 선택한 상관관계 저장
    @PostMapping("/choice")
    public ResponseEntity<?> saveCorrelationChoice(
        @RequestBody CorrelationChoiceRequest request
    ) {
        List<JmxCorrelation> saved = correlationService.saveChoices(request);
        return ResponseEntity.ok(Map.of(
            "msg", "success",
            "count", saved.size(),
            "items", saved
        ));
    }

    // Correlation 적용된 JMX 다운로드
    @PostMapping("/apply")
    public ResponseEntity<ByteArrayResource> applyAndDownload(
        @RequestParam String perfId
    ) {
        Path src = Path.of("./data/perfTests/" + perfId + "/" + perfId + ".jmx");
        byte[] bytes = correlationService.applyCorrelationsJmxOut(perfId, Files.newInputStream(src));
        return ResponseEntity.ok()
            .header(HttpHeaders.CONTENT_DISPOSITION, "attachment; filename=" + perfId + "_correlated.jmx")
            .body(new ByteArrayResource(bytes));
    }
}
```

**요청 예시 (저장)**:
```json
POST /api/v1/expression/choice

{
  "perfId": "test-2025-01",
  "sid": "1-1",
  "requestId": 123,
  "response": [
    {
      "resSid": "2-1",
      "location": "Body",
      "regex": "\"token\":\"([^\"]+)\"",
      "refName": "AUTH_TOKEN",
      "template": "$1$",
      "matchNumber": 1,
      "defaultValue": "ERROR",
      "source": "AIRECOMM"
    }
  ]
}
```

#### 3.4.3 JMX/JTL 리스트 API

```java
@RestController
@RequestMapping("/api/v2/jmx")
public class JmxListApiV2 {

    // JMX 요청 목록 조회 (페이징)
    @GetMapping("/list")
    public ResponseEntity<?> getJmxList(
        @RequestParam String perfId,
        @RequestParam(defaultValue = "0") int page,
        @RequestParam(defaultValue = "1000") int size
    ) {
        Page<JmxRequest> result = jmxListService.findByPerfId(perfId, PageRequest.of(page, size));
        return ResponseEntity.ok(Map.of(
            "data", result.getContent(),
            "meta", Map.of(
                "total", result.getTotalElements(),
                "page", page,
                "size", size
            )
        ));
    }

    // 전체 페이지 SID 목록 조회
    @GetMapping("/page-sids")
    public ResponseEntity<?> getPageSids(@RequestParam String perfId) {
        List<String> sids = jmxListService.findAllPageSids(perfId);
        return ResponseEntity.ok(Map.of("pageSids", sids));
    }
}
```

---

## 4. 핵심 비즈니스 로직

### 4.1 HAR 병합 로직

**목적**: 여러 HAR 파일을 하나로 병합하여 일관된 테스트 시나리오 생성

**주요 단계**:

1. **HAR 파일 검증**
   ```java
   // HarMergeService.java
   private void validateHar(JsonNode harNode) {
       if (!harNode.has("log")) throw new IllegalArgumentException("Invalid HAR: missing 'log'");
       if (!harNode.get("log").has("entries")) throw new IllegalArgumentException("Invalid HAR: missing 'entries'");
   }
   ```

2. **병합 순서 결정**
   - `filename`: 파일명 기준 정렬
   - `timeline`: 타임스탬프 기준 정렬 (시간순)

3. **중복 제거 (Dedupe)**
   - `none`: 중복 제거 안 함
   - `exact`: 완전 일치 제거 (URL + Method + Body)
   - `url`: URL만 일치하면 제거

4. **병합 실행**
   ```java
   JsonNode mergedLog = mergeEntries(harFiles, order, dedupe);
   ```

5. **산출물 저장**
   - `{perfId}.har`: 병합된 HAR 파일
   - 원본 파일별 경고 정보 (`_cvDiag`)

### 4.2 JMX/JTL 변환 로직

**목적**: HAR 파일을 JMeter 스크립트(JMX) 및 예상 결과(JTL)로 변환

**주요 단계**:

1. **HAR to JMX 변환**
   - 외부 라이브러리 사용: `har-to-jmeter-convertor`
   - HTTP Sampler 생성
   - Arguments, Headers 추출

2. **JMX 파싱 및 인덱싱**
   ```java
   // JmxListService.java
   public void indexJmxFile(String perfId, Path jmxPath) {
       Document doc = parseXml(jmxPath);
       NodeList samplers = doc.getElementsByTagName("HTTPSamplerProxy");

       for (int i = 0; i < samplers.getLength(); i++) {
           Element sampler = (Element) samplers.item(i);
           JmxRequest request = extractRequestInfo(sampler);
           request.setPerfId(perfId);
           jmxRequestRepository.save(request);
       }
   }
   ```

3. **JTL 생성**
   - JMeter 실행 (선택적)
   - 또는 HAR 기반 모의 JTL 생성

4. **JTL 파싱 및 인덱싱**
   ```java
   // JtlIndexService.java
   public void indexJtlFile(String perfId, Path jtlPath) {
       // XML 또는 CSV 형식 파싱
       List<JtlSample> samples = parseJtl(jtlPath);

       for (JtlSample sample : samples) {
           sample.setPerfId(perfId);
           jtlSampleRepository.save(sample);

           // 요청/응답 파라미터 추출
           List<JtlElement> elements = extractElements(sample);
           jtlElementRepository.saveAll(elements);
       }
   }
   ```

### 4.3 Correlation 분석 로직

**목적**: 요청 파라미터와 응답 값 간 상관관계 자동 감지

**알고리즘**:

1. **후보 매칭**
   ```java
   // CorrelReqVarRecommendService.java
   public List<CorrelationCandidate> findCandidates(String perfId, String reqSid) {
       // 1) 현재 요청의 파라미터 추출 (JmxRequest)
       JmxRequest currentReq = jmxRequestRepository.findBySid(perfId, reqSid);
       List<String> reqParams = extractParameters(currentReq.getArguments());

       // 2) 이전 응답들에서 일치하는 값 탐색 (JtlElement)
       List<CorrelationCandidate> candidates = new ArrayList<>();
       for (String paramValue : reqParams) {
           List<JtlElement> matchingElements = jtlElementRepository
               .findByPerfIdAndValue(perfId, paramValue);

           for (JtlElement element : matchingElements) {
               // 시간순으로 이전 응답인지 확인
               if (element.getTimestamp() < currentReq.getTimestamp()) {
                   candidates.add(new CorrelationCandidate(
                       element.getSampleId(),  // resSid
                       element.getLocation(),  // Body/Header/URL
                       element.getName(),      // 파라미터 이름
                       paramValue
                   ));
               }
           }
       }
       return candidates;
   }
   ```

2. **AI 기반 정규식 생성**
   ```java
   // RegexExtractorRecommendService.java
   public RegexExtractor generateRegex(String responseData, String targetValue) {
       String prompt = String.format("""
           Extract the value '%s' from the following response:
           %s

           Provide a regex pattern, template, and match number.
           """, targetValue, responseData);

       ChatResponse response = chatClient.call(new Prompt(prompt));
       return parseAiResponse(response.getResult().getOutput().getContent());
   }
   ```

3. **Pre-rules 적용**
   ```java
   // CorrelPreRulesService.java
   public List<JmxCorrelation> applyPreRules(String perfId) {
       // 사전 정의된 규칙 로드 (config/correl-pre-rules.json)
       List<PreRule> rules = loadPreRules();

       List<JmxCorrelation> applied = new ArrayList<>();
       for (PreRule rule : rules) {
           if (rule.matches(perfId)) {
               JmxCorrelation corr = JmxCorrelation.builder()
                   .perfId(perfId)
                   .regex(rule.getRegex())
                   .refName(rule.getRefName())
                   .source("PRERULE")
                   .selected(false)  // 기본값: 미선택
                   .build();
               applied.add(correlationRepository.save(corr));
           }
       }
       return applied;
   }
   ```

### 4.4 JMX에 RegexExtractor 삽입 로직

**목적**: 선택된 상관관계를 JMX 파일에 실제로 적용

**주요 단계**:

1. **대상 샘플러 찾기**
   ```java
   // JmxCorrelationService.java
   private Element findSamplerByResSid(Document doc, String resSid) {
       // XPath: //HTTPSamplerProxy[@testname='{resSid}']
       XPath xpath = XPathFactory.newInstance().newXPath();
       String expression = String.format("//HTTPSamplerProxy[@testname='%s']", resSid);
       return (Element) xpath.evaluate(expression, doc, XPathConstants.NODE);
   }
   ```

2. **RegexExtractor 생성**
   ```java
   private Element createRegexExtractor(Document doc, JmxCorrelation corr) {
       Element extractor = doc.createElement("RegexExtractor");
       extractor.setAttribute("guiclass", "RegexExtractorGui");
       extractor.setAttribute("testclass", "RegexExtractor");
       extractor.setAttribute("testname", "Extract " + corr.getRefName());

       // 속성 추가
       addProperty(extractor, "RegexExtractor.refname", corr.getRefName());
       addProperty(extractor, "RegexExtractor.regex", corr.getRegex());
       addProperty(extractor, "RegexExtractor.template", corr.getTemplate());
       addProperty(extractor, "RegexExtractor.match_number", corr.getMatchNumber());
       addProperty(extractor, "RegexExtractor.default", corr.getDefaultValue());

       return extractor;
   }
   ```

3. **변수 주입**
   ```java
   private void injectVariable(Element sampler, String refName, String reqSid) {
       // Arguments 노드 찾기
       NodeList argNodes = sampler.getElementsByTagName("Arguments");
       if (argNodes.getLength() == 0) return;

       Element args = (Element) argNodes.item(0);
       NodeList argList = args.getElementsByTagName("elementProp");

       for (int i = 0; i < argList.getLength(); i++) {
           Element arg = (Element) argList.item(i);
           Element valueNode = (Element) arg.getElementsByTagName("stringProp").item(1);

           // 정적 값을 변수로 대체: abc123 → ${AUTH_TOKEN}
           String currentValue = valueNode.getTextContent();
           if (shouldReplace(currentValue, reqSid)) {
               valueNode.setTextContent("${" + refName + "}");
           }
       }
   }
   ```

4. **XML 저장**
   ```java
   private byte[] saveXml(Document doc) {
       TransformerFactory tf = TransformerFactory.newInstance();
       tf.setAttribute("indent-number", 2);
       Transformer transformer = tf.newTransformer();
       transformer.setOutputProperty(OutputKeys.INDENT, "yes");
       transformer.setOutputProperty(OutputKeys.ENCODING, "UTF-8");

       ByteArrayOutputStream out = new ByteArrayOutputStream();
       transformer.transform(new DOMSource(doc), new StreamResult(out));
       return out.toByteArray();
   }
   ```

---

## 5. 데이터 흐름

### 5.1 전체 데이터 파이프라인

```
┌─────────────────────────────────────────────────────────────────┐
│                         1. 파일 업로드                            │
│  User → Frontend → POST /api/v2/har/merge-and-convert          │
│  Input: HAR files (multipart/form-data)                        │
└────────────────┬────────────────────────────────────────────────┘
                 ↓
┌─────────────────────────────────────────────────────────────────┐
│                     2. HAR 병합 및 검증                           │
│  HarMergeService.mergeHar()                                    │
│  - 파일 검증 (valid HAR format)                                 │
│  - 병합 (order: filename/timeline, dedupe: none/exact/url)     │
│  Output: {perfId}.har                                          │
└────────────────┬────────────────────────────────────────────────┘
                 ↓
┌─────────────────────────────────────────────────────────────────┐
│                    3. JMX/JTL 변환                               │
│  HarToJmxJtlTransService.convertToJmxAndMaybeRunJMeter()       │
│  - HAR → JMX (har-to-jmeter-convertor)                         │
│  - JMeter 실행 (optional) → JTL 생성                            │
│  Output: {perfId}.jmx, {perfId}.jtl                            │
└────────────────┬────────────────────────────────────────────────┘
                 ↓
┌─────────────────────────────────────────────────────────────────┐
│                   4. JMX/JTL 인덱싱                              │
│  JmxListService.indexJmxFile()                                 │
│  JtlIndexService.indexJtlFile()                                │
│  - JMX 파싱 → JmxRequest 엔티티 저장 (H2 DB)                    │
│  - JTL 파싱 → JtlSample/JtlElement 엔티티 저장                  │
│  Output: DB 인덱스 (빠른 조회용)                                 │
└────────────────┬────────────────────────────────────────────────┘
                 ↓
┌─────────────────────────────────────────────────────────────────┐
│                  5. Correlation 후보 추출                         │
│  CorrelReqVarRecommendService.findCandidates()                 │
│  - 요청 파라미터 ↔ 응답 값 매칭                                   │
│  - Pre-rules 적용 (CorrelPreRulesService)                       │
│  Output: Correlation 후보 리스트 (Frontend 표시)                │
└────────────────┬────────────────────────────────────────────────┘
                 ↓
┌─────────────────────────────────────────────────────────────────┐
│                    6. AI 정규식 추천                              │
│  RegexExtractorRecommendService.recommendExtractors()          │
│  - Spring AI (OpenAI) 호출                                      │
│  - 프롬프트: 응답 데이터 + 추출 대상 값                            │
│  Output: RegexExtractor 추천 (regex, template, matchNumber)    │
└────────────────┬────────────────────────────────────────────────┘
                 ↓
┌─────────────────────────────────────────────────────────────────┐
│                  7. 사용자 선택 및 저장                            │
│  User → Frontend → POST /api/v1/expression/choice              │
│  JmxCorrelationService.saveChoices()                           │
│  - 선택된 상관관계를 JmxCorrelation 엔티티로 저장 (selected=true)│
└────────────────┬────────────────────────────────────────────────┘
                 ↓
┌─────────────────────────────────────────────────────────────────┐
│               8. JMX에 RegexExtractor 적용                       │
│  User → Frontend → POST /api/v1/expression/apply               │
│  JmxCorrelationService.applyCorrelationsJmxOut()               │
│  - JMX XML 파싱                                                 │
│  - 선택된 상관관계 기반으로:                                       │
│    1) resSid 샘플러에 RegexExtractor 추가                        │
│    2) reqSid 샘플러의 Arguments에 ${refName} 주입                │
│  Output: {perfId}_correlated.jmx (다운로드)                     │
└─────────────────────────────────────────────────────────────────┘
```

### 5.2 계층 간 데이터 흐름

```
┌──────────────┐
│  Frontend    │  React + TanStack Query
└──────┬───────┘
       │ JSON (REST API)
       ↓
┌──────────────┐
│  Controller  │  @RestController
└──────┬───────┘
       │ DTO (Request/Response)
       ↓
┌──────────────┐
│   Service    │  비즈니스 로직
└──────┬───────┘
       │ Entity
       ↓
┌──────────────┐
│  Repository  │  Spring Data JPA
└──────┬───────┘
       │ SQL
       ↓
┌──────────────┐
│   Database   │  H2 (file mode)
└──────────────┘

       +

┌──────────────┐
│ File System  │  HAR/JMX/JTL 파일
└──────────────┘  ./data/perfTests/{perfId}/
```

---

## 6. 주요 기술 포인트

### 6.1 보안 (Security)

#### 6.1.1 LDAP 인증

**설정**:
```java
@Configuration
@EnableWebSecurity
public class SecurityConfig {

    @Autowired
    private SecurityLdapProp ldapProp;

    @Bean
    public SecurityFilterChain filterChain(HttpSecurity http) throws Exception {
        http
            .authorizeHttpRequests(auth -> auth
                .requestMatchers("/api/**").authenticated()
                .anyRequest().permitAll()
            )
            .formLogin(form -> form
                .loginPage("/login")
                .defaultSuccessUrl("/")
            )
            .logout(logout -> logout
                .logoutUrl("/logout")
                .logoutSuccessUrl("/login")
            );

        return http.build();
    }

    @Bean
    public AuthenticationManager authenticationManager(BaseLdapPathContextSource contextSource) {
        LdapBindAuthenticationManagerFactory factory =
            new LdapBindAuthenticationManagerFactory(contextSource);
        factory.setUserDnPatterns("uid={0},ou=users");
        return factory.createAuthenticationManager();
    }
}
```

**주요 특징**:
- LDAP 서버 연동 (Active Directory/OpenLDAP)
- 폼 기반 로그인
- 세션 기반 인증

#### 6.1.2 로컬 사용자 지원

```java
@ConfigurationProperties(prefix = "app.security.local-users")
public class LocalUsersProp {
    private boolean enabled;
    private List<LocalUser> users;

    @Data
    public static class LocalUser {
        private String username;
        private String password;  // BCrypt 해시
        private List<String> roles;
    }
}
```

**목적**: 개발 환경 또는 LDAP 없는 환경에서 테스트용 계정 제공

#### 6.1.3 XXE 공격 방지

```java
// JmxCorrelationService.java
DocumentBuilderFactory dbf = DocumentBuilderFactory.newInstance();
dbf.setFeature("http://apache.org/xml/features/disallow-doctype-decl", true);
dbf.setFeature("http://xml.org/sax/features/external-general-entities", false);
dbf.setFeature("http://xml.org/sax/features/external-parameter-entities", false);
```

**목적**: XML 파싱 시 외부 엔티티 참조 차단

### 6.2 성능 최적화

#### 6.2.1 캐싱 전략

**Spring Cache 활용**:
```java
@Configuration
@EnableCaching
public class AppConfig {

    @Bean
    public CacheManager cacheManager() {
        SimpleCacheManager cacheManager = new SimpleCacheManager();
        cacheManager.setCaches(Arrays.asList(
            new ConcurrentMapCache("jmx-requests"),
            new ConcurrentMapCache("jtl-samples"),
            new ConcurrentMapCache("correlations")
        ));
        return cacheManager;
    }
}

// 사용 예시
@Service
public class JmxListService {

    @Cacheable(value = "jmx-requests", key = "#perfId + '-' + #page + '-' + #size")
    public Page<JmxRequest> findByPerfId(String perfId, Pageable pageable) {
        return jmxRequestRepository.findByPerfId(perfId, pageable);
    }

    @CacheEvict(value = "jmx-requests", allEntries = true)
    public void deletedb(String perfId) {
        jmxRequestRepository.deleteByPerfId(perfId);
    }
}
```

**스케줄 기반 캐시 클리어**:
```java
@Component
public class CacheClearScheduleTask {

    @Autowired
    private CacheManager cacheManager;

    @Scheduled(cron = "0 0 2 * * ?")  // 매일 새벽 2시
    public void clearAllCaches() {
        cacheManager.getCacheNames().forEach(cacheName -> {
            Cache cache = cacheManager.getCache(cacheName);
            if (cache != null) {
                cache.clear();
                log.info("Cleared cache: {}", cacheName);
            }
        });
    }
}
```

#### 6.2.2 페이징 및 가상화

**Backend 페이징**:
```java
@GetMapping("/list")
public ResponseEntity<?> getJmxList(
    @RequestParam String perfId,
    @RequestParam(defaultValue = "0") int page,
    @RequestParam(defaultValue = "1000") int size  // 최적화된 페이지 크기
) {
    Page<JmxRequest> result = jmxListService.findByPerfId(
        perfId,
        PageRequest.of(page, size)
    );
    return ResponseEntity.ok(Map.of(
        "data", result.getContent(),
        "meta", Map.of("total", result.getTotalElements(), "page", page)
    ));
}
```

**Frontend 가상화**: TanStack Virtual 사용 (프론트엔드 문서 참조)

#### 6.2.3 비동기 처리

**태스크 관리**:
```java
@Entity
public class Task {
    @Id @GeneratedValue
    private Long id;

    private String perfId;
    private String taskType;     // MERGE_HAR, CONVERT_JMX, INDEX_JTL
    private String status;       // PENDING, RUNNING, COMPLETED, FAILED
    private String progress;     // 0-100%
    private String errorMessage;

    private LocalDateTime startedAt;
    private LocalDateTime completedAt;
}
```

**비동기 실행 (미래 개선)**:
```java
// 현재는 동기 처리, 향후 @Async로 개선 가능
@Async
public CompletableFuture<Map<String, Object>> mergeAndConvertAsync(String perfId, ...) {
    // 1) Task 엔티티 생성 (status=RUNNING)
    // 2) 오케스트레이션 실행
    // 3) Task 업데이트 (status=COMPLETED/FAILED)
    return CompletableFuture.completedFuture(result);
}
```

### 6.3 Spring AI 활용

#### 6.3.1 AI 에이전트 설정

```java
@Configuration
public class AiAgentConfig {

    @Bean
    public ChatClient chatClient(ChatClient.Builder builder) {
        return builder
            .defaultOptions(ChatOptions.builder()
                .withModel("gpt-4o-mini")
                .withTemperature(0.3)  // 낮은 온도: 일관된 출력
                .withMaxTokens(1000)
                .build())
            .build();
    }
}
```

**application.yml**:
```yaml
spring:
  ai:
    openai:
      api-key: ${OPENAI_API_KEY}
      chat:
        options:
          model: gpt-4o-mini
          temperature: 0.3
```

#### 6.3.2 정규식 추천 프롬프트

```java
public RegexExtractor recommendExtractor(String responseData, String targetValue, String location) {
    String prompt = String.format("""
        You are a JMeter RegexExtractor expert.

        **Task**: Extract the value '%s' from the HTTP response %s.

        **Response Data**:
        ```
        %s
        ```

        **Requirements**:
        1. Provide a regex pattern to extract the value
        2. Use capture groups: (...)
        3. Consider edge cases (quotes, special characters)
        4. Provide the extraction template (e.g., $1$)
        5. Specify match number (1 for first occurrence)
        6. Provide a default value if not found

        **Output Format** (JSON):
        {
          "regex": "your regex pattern",
          "template": "$1$",
          "matchNumber": 1,
          "defaultValue": "ERROR",
          "explanation": "brief explanation"
        }
        """, targetValue, location, responseData);

    ChatResponse response = chatClient.call(new Prompt(prompt));
    String jsonOutput = response.getResult().getOutput().getContent();

    // JSON 파싱
    ObjectMapper mapper = new ObjectMapper();
    return mapper.readValue(jsonOutput, RegexExtractor.class);
}
```

**실제 예시**:

**입력**:
```json
{
  "responseData": "{\"token\":\"abc123xyz\",\"userId\":456}",
  "targetValue": "abc123xyz",
  "location": "Body"
}
```

**AI 응답**:
```json
{
  "regex": "\"token\":\"([^\"]+)\"",
  "template": "$1$",
  "matchNumber": 1,
  "defaultValue": "TOKEN_NOT_FOUND",
  "explanation": "Extract the token value from JSON response using a non-greedy match for quoted strings"
}
```

### 6.4 에러 처리

#### 6.4.1 커스텀 예외 계층

```java
// 기본 애플리케이션 예외
public class AppException extends RuntimeException {
    private final String code;
    private final HttpStatus status;

    public AppException(String code, String message, HttpStatus status) {
        super(message);
        this.code = code;
        this.status = status;
    }
}

// 구체적인 예외들
public class NotFoundException extends AppException {
    public NotFoundException(String resource, String id) {
        super("NOT_FOUND",
              String.format("%s not found: %s", resource, id),
              HttpStatus.NOT_FOUND);
    }
}

public class AlreadyExistsException extends AppException {
    public AlreadyExistsException(String resource, String id) {
        super("ALREADY_EXISTS",
              String.format("%s already exists: %s", resource, id),
              HttpStatus.CONFLICT);
    }
}

public class PerfTestException extends AppException {
    public PerfTestException(String message) {
        super("PERFTEST_ERROR", message, HttpStatus.BAD_REQUEST);
    }
}
```

#### 6.4.2 전역 예외 핸들러

```java
@RestControllerAdvice
public class ApiExceptionAdvice {

    @ExceptionHandler(AppException.class)
    public ResponseEntity<AppExceptionRes> handleAppException(AppException ex) {
        AppExceptionRes response = new AppExceptionRes(
            ex.getCode(),
            ex.getMessage(),
            LocalDateTime.now()
        );
        return ResponseEntity.status(ex.getStatus()).body(response);
    }

    @ExceptionHandler(MethodArgumentNotValidException.class)
    public ResponseEntity<AppExceptionRes> handleValidationException(MethodArgumentNotValidException ex) {
        String message = ex.getBindingResult().getAllErrors().stream()
            .map(ObjectError::getDefaultMessage)
            .collect(Collectors.joining(", "));

        AppExceptionRes response = new AppExceptionRes(
            "VALIDATION_ERROR",
            message,
            LocalDateTime.now()
        );
        return ResponseEntity.badRequest().body(response);
    }

    @ExceptionHandler(Exception.class)
    public ResponseEntity<AppExceptionRes> handleGeneralException(Exception ex) {
        log.error("Unexpected error", ex);
        AppExceptionRes response = new AppExceptionRes(
            "INTERNAL_ERROR",
            "An unexpected error occurred",
            LocalDateTime.now()
        );
        return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(response);
    }
}
```

### 6.5 데이터베이스 설계

#### 6.5.1 H2 Database 설정

**application.yml**:
```yaml
spring:
  datasource:
    url: jdbc:h2:file:./data/perftest;AUTO_SERVER=TRUE
    driver-class-name: org.h2.Driver
    username: sa
    password:

  h2:
    console:
      enabled: true
      path: /h2-console

  jpa:
    hibernate:
      ddl-auto: update  # 스키마 자동 생성/업데이트
    show-sql: false
    properties:
      hibernate:
        format_sql: true
        use_sql_comments: true
```

**특징**:
- File mode: `./data/perftest.mv.db` 파일로 저장
- AUTO_SERVER: 다중 프로세스 동시 접근 가능
- H2 Console: 개발/디버깅용 웹 콘솔

#### 6.5.2 인덱스 전략

```java
@Entity
@Table(indexes = {
    @Index(name = "idx_perfid", columnList = "perfId"),
    @Index(name = "idx_perfid_sid", columnList = "perfId,sid")
})
public class JmxRequest {
    // ...
}

@Entity
@Table(indexes = {
    @Index(name = "idx_perfid_selected", columnList = "perfId,selected"),
    @Index(name = "idx_perfid_requestid", columnList = "perfId,requestId")
})
public class JmxCorrelation {
    // ...
}
```

**목적**:
- 빠른 perfId 기반 조회
- 복합 인덱스로 필터링 성능 향상

---

## 7. 프로젝트 구조 및 빌드

### 7.1 디렉토리 구조

```
perftester-correl/
├── src/
│   ├── main/
│   │   ├── java/
│   │   │   └── com/jadecross/perftester/correl/
│   │   └── resources/
│   │       ├── application.yml
│   │       ├── static/           # 프론트엔드 빌드 결과물
│   │       └── templates/        # Thymeleaf 템플릿
│   └── test/
├── frontend/                     # React 프론트엔드
│   ├── src/
│   ├── package.json
│   └── vite.config.ts
├── config/                       # 설정 파일
│   ├── correl-pre-rules.json    # 상관관계 사전 규칙
│   └── ...
├── data/                         # 런타임 데이터
│   ├── perftest.mv.db           # H2 데이터베이스
│   └── perfTests/               # HAR/JMX/JTL 파일
│       └── {perfId}/
│           ├── {perfId}.har
│           ├── {perfId}.jmx
│           └── {perfId}.jtl
├── libs/                         # 외부 JAR
│   └── har-to-jmeter-convertor-7.1-jar-with-dependencies.jar
├── log/                          # 애플리케이션 로그
├── build.gradle
└── README.md
```

### 7.2 빌드 프로세스

**Gradle 태스크**:

1. **npm install** (조건부)
   ```bash
   ./gradlew npmInstall
   ```
   - `package.json` 변경 시에만 실행
   - `node_modules` 없으면 실행

2. **프론트엔드 빌드**
   ```bash
   ./gradlew buildFrontend
   ```
   - `npm run build` 실행
   - 결과물: `frontend/dist/`

3. **프론트엔드 복사**
   ```bash
   ./gradlew copyFrontend
   ```
   - `frontend/dist/` → `src/main/resources/static/`

4. **백엔드 빌드**
   ```bash
   ./gradlew build
   ```
   - Java 컴파일
   - 테스트 실행
   - JAR 생성

5. **통합 빌드**
   ```bash
   ./gradlew bootJar
   ```
   - 프론트엔드 + 백엔드를 하나의 JAR로 패키징
   - 결과물: `build/libs/perftester-correl-{version}.jar`

**실행**:
```bash
java -jar build/libs/perftester-correl-1.0.251127_0943.jar
```

### 7.3 버전 관리

**Git 기반 버전**:
```gradle
version = '1.0.' + getGitHeadCommitDateHash()

def getGitHeadCommitDateHash() {
    def commitDateHash = 'git show -s --format=%cd_%h --date=format:%y%m%d_%H%M HEAD'
        .execute()
        .text
        .trim()
    return commitDateHash ?: new Date().format('yyMMdd_HHmm')
}
```

**예시**: `1.0.251127_0943_abc123`
- `1.0`: 메이저.마이너 버전
- `251127_0943`: 2025년 11월 27일 09:43
- `abc123`: Git commit hash (short)

---

## 8. 배포 및 운영

### 8.1 시작 스크립트

**pt-cor-start.sh**:
```bash
#!/bin/bash

# 환경 변수 로드
export OPENAI_API_KEY="sk-..."
export LDAP_URL="ldap://ldap.example.com:389"

# JVM 옵션
JAVA_OPTS="-Xmx2g -Xms512m"
JAVA_OPTS="$JAVA_OPTS -Dspring.profiles.active=prod"

# 애플리케이션 실행
nohup java $JAVA_OPTS \
  -jar perftester-correl-1.0.*.jar \
  > ./log/app.log 2>&1 &

echo $! > ./perftester.pid
echo "Started with PID: $(cat ./perftester.pid)"
```

**pt-cor-stop.sh**:
```bash
#!/bin/bash

if [ -f ./perftester.pid ]; then
  PID=$(cat ./perftester.pid)
  kill $PID
  rm ./perftester.pid
  echo "Stopped PID: $PID"
else
  echo "PID file not found"
fi
```

### 8.2 모니터링

**Spring Boot Actuator**:
```yaml
management:
  endpoints:
    web:
      exposure:
        include: health,info,metrics,loggers
  endpoint:
    health:
      show-details: always
```

**엔드포인트**:
- `/actuator/health`: 헬스 체크
- `/actuator/info`: 빌드 정보
- `/actuator/metrics`: JVM, HTTP 메트릭
- `/actuator/loggers`: 로그 레벨 동적 변경

### 8.3 로깅

**logback-spring.xml**:
```xml
<configuration>
  <appender name="FILE" class="ch.qos.logback.core.rolling.RollingFileAppender">
    <file>./log/app.log</file>
    <rollingPolicy class="ch.qos.logback.core.rolling.TimeBasedRollingPolicy">
      <fileNamePattern>./log/app-%d{yyyy-MM-dd}.log</fileNamePattern>
      <maxHistory>30</maxHistory>
    </rollingPolicy>
    <encoder>
      <pattern>%d{yyyy-MM-dd HH:mm:ss} [%thread] %-5level %logger{36} - %msg%n</pattern>
    </encoder>
  </appender>

  <root level="INFO">
    <appender-ref ref="FILE" />
  </root>

  <logger name="com.jadecross.perftester" level="DEBUG" />
</configuration>
```

---

## 9. 향후 개선 방향

### 9.1 성능

- [ ] **비동기 처리**: HAR 병합/변환을 @Async로 전환
- [ ] **Redis 캐싱**: 분산 환경 대비 Redis 캐시 도입
- [ ] **스트리밍 파싱**: 대용량 HAR/JTL 파일 스트리밍 처리
- [ ] **병렬 처리**: 다중 HAR 파일 병렬 처리

### 9.2 기능

- [ ] **JMX 템플릿**: 자주 사용하는 패턴을 템플릿화
- [ ] **상관관계 검증**: 추출기 동작 자동 검증
- [ ] **다중 JMeter 버전 지원**: JMeter 5.x, 6.x 호환
- [ ] **협업 기능**: 팀원 간 상관관계 공유

### 9.3 운영

- [ ] **Docker 컨테이너화**: Dockerfile 및 docker-compose
- [ ] **CI/CD 파이프라인**: GitHub Actions/Jenkins
- [ ] **로그 집계**: ELK Stack 연동
- [ ] **메트릭 대시보드**: Grafana + Prometheus

### 9.4 테스트

- [ ] **단위 테스트**: Service 계층 테스트 커버리지 70% 이상
- [ ] **통합 테스트**: API 엔드포인트 테스트
- [ ] **E2E 테스트**: 전체 워크플로우 자동 테스트

---

## 관련 자료

### 내부 문서
- [[Perf Script Pipeline 프로젝트 면접 준비]] - 프론트엔드 중심 면접 준비
- [[Spring Boot]] - Spring Boot 학습 노트
- [[JPA]] - JPA 관련 노트
- [[Spring AI]] - Spring AI 활용 (생성 예정)

### 외부 문서
- [Spring Boot Documentation](https://spring.io/projects/spring-boot)
- [Spring AI Documentation](https://docs.spring.io/spring-ai/reference/)
- [JMeter User Manual](https://jmeter.apache.org/usermanual/)
- [HAR Spec 1.2](http://www.softwareishard.com/blog/har-12-spec/)

---

**마지막 업데이트**: 2025-11-27
**작성자**: Claude (코드베이스 분석)
**프로젝트 기간**: 2025-10-01 ~ 2025-11-05 (약 5주)
