---
created: 2026-02-09
---
---
tags:
  - resource
  - database
  - mysql
  - join
  - sql
category: database
topic: JOIN
status: complete
created: 2024-01-01
modified: 2025-10-29
---
## 1. 테이블 간의 관계
### Foreign Key
- 두 테이블 간의 참조 무결성을 보장해주는 역할
- 보장을 통해 데이터의 품질을 확보할 수 있고, 품질이 확보된 데이터는 가치 있는 분석을 만들어 냄
- 무결성(integrity): "결함이 없는 성질", 데이터의 정확성, 일관성, 유효성을 유지하는 개념

## 2. INNER JOIN
### JOIN
#### 조인의종류
- INNER JOIN(흔히 불리는 JOIN)
- OUTER JOIN
- CROSS JOIN (Or 카테시안 조인)
#### 테이블을 연결하기 위한 기술로 UNION / UNION ALL도 있음
- 조인은 두 테이블을 좌우로 연결
- 반면에 UNION / UNION ALL은 두 테이블을 상하로 연결
#### 기초 문법
``` sql
SELECT 컬럼
FROM 테이블1 별칭1
	INNER JOIN 테이블2 별칭2 ON 별칭1.컬럼 = 별칭2.컬럼
WHERE 각 테이블의 필터 조건
```
### INNER JOIN 이해하기
- INNER JOIN에 실패한 데이터는 결과에 나오지 못함
- 한 건의 데이터가 여러 건과 조인하면, 한 건의 데이터가 여러 건으로 늘어난다.
### ANSI VS. ORACLE
- 

- mysql 책 끄적끄적 
	- join이 어떻게 인덱스를 사용하는지 쿼리 패턴 별로 확인