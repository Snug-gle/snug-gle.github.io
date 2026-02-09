---
tags:
  - resource
  - spring
  - jpa
  - database
  - concept
category: backend
topic: Spring Data JPA
status: complete
created: 2024-04-25
updated: 2025-10-29
---

# Spring Data JPA

- MySQL에 접근해서 데이터를 읽기 위해 여러 레이어를 거친다
- JDBC는 직접적으로 SQL을 실행한다
- Hibernate는 ORM을 구현하고 있다.
- JPA는 어떻게 ORM을 구현할지 정의하고 있기 때문에, 실제로 코드상에서 Hibernate를 이용할 때 JPA에 속한 Interface를 사용하게 된다
- 그리로 JAP조차도 편하게 사용하기 위해 Spring Data JPA는  Repository를 제공한다.
- Repository를 이용하지 않고 바로 JPA를 사용할 수 있다.