---
created: 2025-11-28
tags:
  - moc
  - resource
  - infrastructure
  - devops
category: infrastructure
---

# 🔧 Infrastructure & DevOps MOC

> 인프라 및 데브옵스 학습 로드맵

## 📍 현재 위치
- 학습 단계: **초중급**
- 실전 적용: [[project/pending/rally-point/architecture|Rally-Point 프로젝트]] 인프라 구축

---

## 🌱 기초 개념

### Infrastructure as Code
- 인프라 자동화의 필요성
- IaC 도구 비교
- 선언적 vs 명령적 접근

### DevOps 철학
- DevOps란?
- CI/CD 개념
- 배포 전략 (Blue-Green, Canary, Rolling)

---

## 🐳 컨테이너화

### Docker
- Docker 기본 개념
- Dockerfile 작성
- Docker Compose
- 멀티 스테이지 빌드

### Kubernetes (K8s)
- Pod, Service, Deployment
- ConfigMap, Secret
- Ingress, LoadBalancer
- Helm Charts
- Kubernetes Operators

---

## 📊 모니터링 & 로깅

### Elastic Stack
- [[Elastic Stack]] - ELK Stack 개요
- **Elasticsearch** - 검색 및 분석 엔진
- **Logstash** - 로그 수집 및 처리
- **Kibana** - 데이터 시각화
- **Filebeat** - 로그 전송

### 모니터링 도구
- Prometheus - 메트릭 수집
- Grafana - 대시보드
- Jaeger - 분산 추적
- ELK Stack - 로그 분석

---

## 🔄 메시징 & 스트리밍

### Apache Kafka
- [[attiead-kafka-study|Attiead Kafka 스터디]] - 팀 스터디
- Kafka 아키텍처
- Producer, Consumer
- Topic, Partition
- Event-Driven Architecture
- 🔗 연결: [[resource/topics/architecture/_Architecture MOC|아키텍처 패턴]]

### Message Queue
- RabbitMQ
- Amazon SQS
- Redis Pub/Sub

---

## 💾 캐싱 & 데이터 스토어

### Redis
- Redis 개요
- 데이터 구조 (String, Hash, List, Set, Sorted Set)
- 캐싱 전략
- Redis Cluster
- Session 관리

### 기타 스토어
- Memcached
- Hazelcast

---

## ☁️ 클라우드 인프라

### AWS
- 🔗 [[resource/topics/aws/_AWS MOC|AWS MOC]]
- EC2, S3, RDS
- Lambda (Serverless)
- CloudWatch

### 기타 클라우드
- Google Cloud Platform (GCP)
- Microsoft Azure
- DigitalOcean

---

## 🔐 보안 & 네트워킹

### 네트워크 기초
- TCP/IP, HTTP/HTTPS
- DNS, Load Balancing
- Reverse Proxy (Nginx)
- API Gateway

### 보안
- SSL/TLS 인증서
- OAuth 2.0, JWT
- Secrets 관리
- 방화벽 설정

---

## 🚀 CI/CD

### 빌드 & 배포 자동화
- Jenkins
- GitHub Actions
- GitLab CI/CD
- ArgoCD (GitOps)

### 파이프라인 구성
```dataview
LIST
FROM #cicd OR #pipeline
```

---

## 🏗️ Infrastructure as Code

### 도구
- Terraform
- Ansible
- CloudFormation
- Pulumi

### Best Practices
- 버전 관리
- 모듈화
- 환경별 설정 분리

---

## 🚀 실전 프로젝트 적용

### Rally-Point 인프라
- [[project/pending/rally-point/architecture|인프라 아키텍처]]
- Docker Compose로 로컬 환경 구성
- Kafka를 통한 이벤트 처리
- Redis 캐싱 전략
- ELK Stack 로그 수집

### 학습 경험
```dataview
LIST
FROM #infrastructure AND #learning-log
SORT file.ctime DESC
```

---

## 📚 학습 자료

### 공식 문서
- [Docker Docs](https://docs.docker.com/)
- [Kubernetes Docs](https://kubernetes.io/docs/)
- [Kafka Documentation](https://kafka.apache.org/documentation/)

### 관련 노트
```dataview
LIST
FROM #infrastructure OR #devops
WHERE !contains(file.name, "MOC")
SORT file.mtime DESC
```

---

## 🔗 관련 MOC
- → [[resource/topics/aws/_AWS MOC|AWS MOC]]
- → [[resource/topics/architecture/_Architecture MOC|Architecture MOC]]
- → [[resource/topics/database/_Database MOC|Database MOC]]
- ← [[resource/topics/spring/_Spring MOC|Spring MOC]]

## 🎯 학습 목표
- [ ] Docker & Docker Compose 마스터
- [ ] Kubernetes 기본 개념 학습
- [ ] Kafka 실전 적용
- [ ] ELK Stack 구축 경험
- [ ] Redis 고급 기능 활용
- [ ] CI/CD 파이프라인 구축
- [ ] Terraform으로 IaC 실습

---
*Last updated: 2025-10-29*
