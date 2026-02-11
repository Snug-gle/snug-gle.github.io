---
created: 2025-11-28
tags:
  - moc
  - resource
  - aws
  - cloud
category: cloud
---

# ☁️ AWS MOC

> AWS 클라우드 서비스 학습 로드맵

## 📍 현재 위치
- 학습 단계: **준비 중**
- 목표: AWS 기반 인프라 구축 능력 확보

---

## 🌱 기초 개념

### AWS 시작하기
- AWS란?
- 클라우드 컴퓨팅 기본 개념
- AWS 계정 및 IAM 설정
- AWS 요금 체계 이해

### 핵심 서비스 개요
- Compute (EC2, Lambda)
- Storage (S3, EBS)
- Database (RDS, DynamoDB)
- Network (VPC, Route53)

---

## 💻 Compute Services

### EC2 (Elastic Compute Cloud)
- 인스턴스 타입 선택
- AMI (Amazon Machine Image)
- Auto Scaling
- Load Balancer (ALB, NLB)

### Serverless
- AWS Lambda
- API Gateway
- Step Functions
- EventBridge

---

## 🗄️ Storage & Database

### Storage Services
- **S3** - 객체 스토리지
- EBS - 블록 스토리지
- EFS - 파일 스토리지
- Glacier - 아카이브 스토리지

### Database Services
- **RDS** - 관계형 데이터베이스
- DynamoDB - NoSQL
- ElastiCache - Redis/Memcached
- Aurora - 고성능 RDS

---

## 🌐 Networking

### VPC (Virtual Private Cloud)
- 서브넷 설계
- 라우팅 테이블
- Security Groups
- NACL (Network ACL)

### 트래픽 관리
- Route53 - DNS
- CloudFront - CDN
- Direct Connect
- VPN Gateway

---

## 🔧 DevOps & CI/CD

### 배포 자동화
- CodePipeline
- CodeBuild
- CodeDeploy
- Elastic Beanstalk

### 컨테이너 서비스
- **ECS** - Elastic Container Service
- **EKS** - Elastic Kubernetes Service
- ECR - Container Registry
- Fargate - Serverless Container

---

## 📊 모니터링 & 보안

### 모니터링
- CloudWatch - 로그 및 메트릭
- X-Ray - 분산 추적
- CloudTrail - API 감사

### 보안
- IAM - 권한 관리
- KMS - 암호화 키 관리
- Secrets Manager
- WAF - 웹 방화벽

---

## 🚀 실전 프로젝트 적용

### 아키텍처 패턴
- 3-Tier 웹 애플리케이션
- Serverless 아키텍처
- Microservices on ECS/EKS
- Event-Driven Architecture

### 예정 프로젝트
- [[project/pending/rally-point/architecture|Rally-Point]] AWS 배포
- CI/CD 파이프라인 구축
- 모니터링 대시보드 구성

---

## 📚 학습 자료

### 공식 문서
- [AWS 공식 문서](https://docs.aws.amazon.com/)
- [AWS Well-Architected Framework](https://aws.amazon.com/architecture/well-architected/)

### 자격증 로드맵
- ☁️ AWS Certified Cloud Practitioner
- 👨‍💻 AWS Certified Solutions Architect - Associate
- 🔧 AWS Certified Developer - Associate

### 관련 노트
```dataview
LIST
FROM #aws OR #cloud
WHERE !contains(file.name, "MOC")
SORT file.mtime DESC
```

---

## 🔗 관련 MOC
- → [[resource/topics/infrastructure/_Infrastructure MOC|Infrastructure MOC]]
- → [[resource/topics/spring/_Spring MOC|Spring MOC]]
- → [[resource/topics/database/_Database MOC|Database MOC]]

## 🎯 학습 목표
- [ ] AWS 기초 서비스 실습 (EC2, S3, RDS)
- [ ] VPC 네트워크 설계 실습
- [ ] Lambda + API Gateway 서버리스 앱
- [ ] ECS/Docker 컨테이너 배포
- [ ] CloudWatch 모니터링 구성
- [ ] AWS Solutions Architect Associate 취득

---
*Last updated: 2025-10-29*
