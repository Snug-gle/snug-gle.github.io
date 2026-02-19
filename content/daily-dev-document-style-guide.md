---
tags: [vault, style-guide, documentation, obsidian]
category: vault
created: 2026-02-19
status: complete
description: resource/topics 하위 기술 문서의 통일 양식 정의서
---

# daily-dev 기술 문서 양식 가이드

> resource/topics 디렉토리에 생성되는 기술 문서의 구조, 포맷, 네이밍 규칙을 정의합니다. 새 문서 작성 시 이 가이드를 따릅니다.

---

## 개요
이 문서는 Obsidian vault의 `resource/topics/` 하위에 저장되는 기술 학습 문서의 표준 양식을 정의한다. 양식 통일의 목적은 일관된 탐색 경험, MOC 자동 연결의 용이성, 그리고 Quartz 퍼블리싱 시 균일한 렌더링을 확보하는 데 있다.

---

## 1. Frontmatter

모든 문서는 YAML frontmatter로 시작한다. 필드 순서를 반드시 지킨다.

```yaml
---
tags: [<category>, <tag2>, <tag3>, ...]
category: <category>
created: YYYY-MM-DD
status: complete
description: <한 줄 한국어 요약>
---
```

| 필드 | 설명 | 예시 |
|------|------|------|
| `tags` | 인라인 배열. 첫 번째 값은 `category`와 동일 | `[spring, jwt, redis]` |
| `category` | 디렉토리명과 일치하는 단일 문자열 | `spring`, `java`, `architecture` |
| `created` | ISO 날짜 | `2026-02-19` |
| `status` | 문서 상태 | `complete` 또는 `draft` |
| `description` | 한국어 한 문장 요약 | `JWT Refresh Token 구현 가이드` |

**주의사항:**
- `---` 뒤에 trailing space 금지 (YAML 파싱 오류 방지)
- `tags`는 block list가 아닌 인라인 배열 `[a, b, c]` 형식 사용

---

## 2. 문서 제목과 초록

Frontmatter 직후 구조:

```markdown
# <제목: 이모지 없이, 서술적으로>

> <1~2문장 한국어 초록. 문서의 범위와 목적을 요약>

---
```

- `#` 제목은 파일당 하나만 사용
- 제목에 이모지 사용 금지
- 초록(`>` blockquote) 뒤에 반드시 수평선(`---`) 삽입

---

## 3. 본문 구조

### 3.1 단일 주제 문서 (Single-Part)

하나의 세션이나 주제를 다루는 문서:

```markdown
## 개요
<바로 다음 줄에 본문 시작>

## <섹션 2>

### <하위 섹션>

...

## 정리 또는 배운 점

## References
```

### 3.2 멀티파트 문서 (Multi-Part)

여러 세션이나 날짜에 걸쳐 작성된 문서:

```markdown
## 개요
<통합 개요>

## Part 1: <파트 제목> (YYYY-MM-DD)

### 1. <하위 섹션>
...

## Part 2: <파트 제목> (YYYY-MM-DD)

### 1. <하위 섹션>
...

## 정리

## References
```

- 각 Part 내부에서 `#` 최상위 제목을 중복 사용하지 않는다
- Part 내부 구조는 `###` 이하로 구성

### 3.3 트러블슈팅 문서

문제 해결 과정을 다루는 문서의 권장 섹션 순서:

```
## 개요
## 문제 상황
## 원인 분석
## 해결 과정
## 설계 결정과 이유 (왜 이 방식을 선택했는가)
## 배운 점
## References
```

---

## 4. 마무리 섹션

모든 문서는 본문 끝에 다음 두 섹션을 포함해야 한다.

### 4.1 정리 (또는 배운 점)

```markdown
## 정리

- <핵심 인사이트 1>
- <핵심 인사이트 2>
- ...
```

- 트러블슈팅 문서는 `## 배운 점`을 대신 사용할 수 있다
- 글머리 기호(`-`) 목록으로 작성, 3~6개 항목 권장
- 각 항목은 하나의 완결된 문장

### 4.2 References

```markdown
## References

- [표시 텍스트](URL)
- [[Obsidian 내부 링크]]
```

- 외부 링크와 내부 wiki-link 모두 사용 가능
- 참조가 없는 경우: `[명시적인 참조가 없어 빈 섹션으로 유지합니다.]`

---

## 5. 서식 규칙

### 5.1 이모지

| 위치 | 허용 여부 |
|------|----------|
| `#`, `##`, `###` 등 헤더 | 금지 |
| 코드 블록 내 주석 (`// ✅ Good`) | 허용 |
| 테이블 셀 내 시각 표시 (`✅ 권장`) | 허용 |
| 본문 인라인 텍스트 | 최소화 권장 |

### 5.2 수평선 (`---`)

사용하는 위치:
1. 초록 blockquote 직후 (필수)
2. 주요 섹션 구분이 필요한 경우 (선택)
3. `## References` 직전 (선택)

### 5.3 코드 블록

언어 식별자를 반드시 명시한다:

```
` ` `java
` ` `sql
` ` `typescript
` ` `mermaid
` ` `yaml
` ` `xml
` ` `diff
```

### 5.4 테이블

GitHub-flavored Markdown 테이블 표준을 따른다:

```markdown
| 컬럼1 | 컬럼2 | 컬럼3 |
|-------|-------|-------|
| 값1   | 값2   | 값3   |
```

---

## 6. 파일 네이밍

| 규칙 | 예시 |
|------|------|
| 소문자 kebab-case | `spring-jwt-refresh-token.md` |
| 카테고리 접두사 권장 | `java-reflection.md`, `spring-rfc9457-error-handling.md` |
| 한글 파일명 허용 | `역할 기반 분리 CQRS.md` (기존 파일 호환) |

---

## 7. 전체 템플릿

```markdown
---
tags: [<category>, <tag2>, <tag3>]
category: <category>
created: YYYY-MM-DD
status: complete
description: <한 줄 한국어 요약>
---

# <문서 제목>

> <1~2문장 초록>

---

## 개요
<본문>

## <주요 섹션>

### <하위 섹션>

...

## 정리

- <핵심 인사이트 1>
- <핵심 인사이트 2>
- <핵심 인사이트 3>

## References

- [참조 제목](URL)
```

---

## References

- [[CLAUDE|CLAUDE.md]] — vault 전체 구조 및 운영 규칙
