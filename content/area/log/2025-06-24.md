---
created: 2025-06-24
---
- https://catalog.us-east-1.prod.workshops.aws/workshops/600420b7-5c4c-498f-9b80-bc7798963ba3/ko-KR/ec2/30-vpc
- https://kr-resources.awscloud.com/aws-techcamp
- bit.ly/3ZGffD8
# Day1 오후 14:00-17:00 KST

<aside>

# 서버리스로 가속하는 현대적 웹 애플리케이션 구현, 핸즈온 실습에 오신 것을 환영합니다.

---

이번 실습에서는 **AWS 의 다양한 서버리스 서비스**를 연결해 **직접적인 서버 할당 없이 웹 애플리케이션을 구현**해 볼 것입니다.

또한, **AI 어시스턴트의 보조**를 받아 앱 로직 개발을 가속화합니다. 이번 핸즈온을 통해 AI와 서버리스가 제공하는 향상된 개발 생산성을 경험해 보시기 바랍니다.

</aside>

## **목표 환경: Web Application with Serverless**

이번 세션을 따라오신다면 아래 그림과 같은 서버리스 웹 서비스 아키텍처를 AWS 환경에 만들게 됩니다. 서버 할당 없이도 확장 가능한 웹 서비스를 구축하는 방법을 학습할 수 있습니다.

**아키텍처**

![image.png](attachment:a5d59a7a-2329-4cd9-bac6-44dbebef3170:image.png)

**S3 정적 웹 사이트**

![image.png](attachment:df4e5ae0-e00a-4fb4-8a39-fe362100a571:image.png)

우리는 간단한 **멤버 관리 서비스**를 구현하게 될 것입니다. Lambda 함수로 멤버 데이터를 처리하고, DynamoDB에 저장하며, API Gateway를 통해 웹에 기능을 노출합니다. 최종적으로 S3 호스팅을 통해 웹 사이트를 서버 없이 배포하고 API 를 호출해 봅니다. Lambda 함수 개발에는 AI 기반 코드 자동완성 기능을 활용하여 개발 생산성을 높여 보겠습니다.

## **관련 서비스**

- [**AWS Lambda](https://aws.amazon.com/ko/lambda/faqs/)(람다)**: 서버리스 함수 실행
- [**Amazon DynamoDB](https://aws.amazon.com/ko/dynamodb/faqs/)(다이내모DB)**: 완전관리형 NoSQL 데이터베이스
- [**Amazon API Gateway**](https://aws.amazon.com/ko/api-gateway/faqs/): REST API 생성 및 관리
- [**Amazon S3**](https://aws.amazon.com/ko/s3/faqs/): 정적 웹사이트 호스팅
- [**Amazon Q Developer**](https://aws.amazon.com/q/?trk=4ca3bac1-348e-45e6-b2fc-95a7c76f8906&sc_channel=ps&ef_id=Cj0KCQjw097CBhDIARIsAJ3-nxc9iwmL3Lay4A0G70uLS0oOCw66bjd5F2baUti5yOzhD-1_1zYO2XcaAipZEALw_wcB:G:s&s_kwcid=AL!4422!3!692062155728!p!!g!!amazon%20q!21058131100!157173585537&gad_campaignid=21058131100&gbraid=0AAAAADjHtp_2e8aoI0VFqp6hpgSe95r5r&gclid=Cj0KCQjw097CBhDIARIsAJ3-nxc9iwmL3Lay4A0G70uLS0oOCw66bjd5F2baUti5yOzhD-1_1zYO2XcaAipZEALw_wcB): Lambda 함수 에디터에서 코드 자동완성 기능 제공 / [Using Amazon Q Developer with AWS Lambda](https://www.notion.so/Day1-14-00-17-00-KST-21a2bb5207f1808f9780c389533a95e8?pvs=21)

## **준비된 챕터**

|챕터 📖|주제 📋|시간 ⏰|
|---|---|---|
|**실습 안내**|실습 목표, 실습 진행 방법|15:00 - 15:10 (10분)|
|**Chapter1**|[**멤버 정보를 담는 DynamoDB 테이블 만들기**](https://www.notion.so/Day1-14-00-17-00-KST-21a2bb5207f1808f9780c389533a95e8?pvs=21)|15:10 - 15:30 (20분)|
|**Chapter2**|[**멤버 관리 로직을 Lambda 함수로 구현하기**](https://www.notion.so/Day1-14-00-17-00-KST-21a2bb5207f1808f9780c389533a95e8?pvs=21)|15:30 - 15:50 (20분)|
||(Break)|15:50 - 16:05 (15분)|
|**Chapter3**|[API Gateway 로 멤버 관리 기능 노출하기](https://www.notion.so/Day1-14-00-17-00-KST-21a2bb5207f1808f9780c389533a95e8?pvs=21)|16:05 - 16:25 (20분)|
|**Chapter4**|[**S3 정적 웹 사이트 호스팅하기**](https://www.notion.so/Day1-14-00-17-00-KST-21a2bb5207f1808f9780c389533a95e8?pvs=21)|16:25 - 16:45 (20분)|
||(Reserved)|16:45 - 17:00|

## Chapter1. 멤버 정보를 담는 DynamoDB 테이블 만들기

<aside>

### 확인 사항

---

- [ ] 사전 준비물
    - [ ] AWS 계정
    - [ ] IAM 유저
    - [ ] 언어 설정 (English(US))
- [ ] **hello-member** 테이블 생성
    - [ ] 파티션 Key: **groupId**
    - [ ] 정렬 Key: **name** </aside>

<aside> 📋

### 실습 가이드

[챕터1. DynamoDB](https://www.notion.so/21a2bb5207f180808220e86e2e72e868?pvs=21)

</aside>

## Chapter2. 멤버 관리 로직을 Lambda 함수로 구현하기

<aside>

### 확인 사항

---

- [ ] [PolySim](https://policysim.aws.amazon.com/home/index.jsp) 에서 Amazon Q 권한 확인 (**codewhisperer:GenerateRecommendations**)
- [ ] **member-service-api** 함수
    - [ ] Amazon Q 코드 추천 활용
    - [ ] Execution Role 보강 (**dynamodb:Query**)
    - [ ] 6가지 함수 테스트
- [ ] 공식문서 읽어 보기
    - [ ] [Lambda 함수 입력 이벤트 형식](https://docs.aws.amazon.com/apigateway/latest/developerguide/set-up-lambda-proxy-integrations.html#api-gateway-simple-proxy-for-lambda-input-format)
    - [ ] [Python Boto3 DynamoDB SDK](https://boto3.amazonaws.com/v1/documentation/api/latest/reference/services/dynamodb.html) </aside>

<aside> 📋

### 실습 가이드

[챕터2. Lambda](https://www.notion.so/21a2bb5207f1815cb5c1e8504cd3e38c?pvs=21)

</aside>

## **Chapter3. API Gateway 로 멤버 관리 기능 노출하기**

<aside>

### 확인 사항

---

- [ ] **my-api** 생성
- [ ] **{proxy+}** 자원
    - [ ] Proxy 모드 활성 → (ANY 메서드)
    - [ ] CORS 허용 → (OPTIONS 메서드)
- [ ] ANY 메서드 수정
    - [ ] Lambda 함수 연결
    - [ ] Proxy 통합 활성
- [ ] API 테스트
- [ ] API 배포 </aside>

<aside> 📋

### 실습 가이드

[챕터3. API Gateway](https://www.notion.so/21a2bb5207f181209e97d538207cfba0?pvs=21)

</aside>

## **Chapter4. S3 정적 웹 사이트 호스팅하기**

<aside>

### 확인 사항

---

- [ ] S3 버킷 생성
- [ ] 웹 사이트 문서 업로드 (**index.html**)
- [ ] 정적 웹사이트 호스팅
- [ ] S3 버킷 정책 수정
- [ ] 웹 사이트 테스트 </aside>

<aside> 📋

### 실습 가이드

[챕터4. S3](https://www.notion.so/21a2bb5207f181139ed4dd67c1bac9ed?pvs=21)

</aside>

---

<aside> 📖

### Appendix

[유용한 자료](https://www.notion.so/21a2bb5207f181a8a2bfd35095059b68?pvs=21)

</aside>

# Member Management Demo

API call was successful.

## Search Criteria

Group ID

Enter the ID of the group to query

Member Name

Used when querying specific members

Status

Select the activation status of members

## API Operations

## API Response

[ { "name": "sanghoon", "groupId": "aws", "status": null } ]

## User Guide

**1. Create Member (POST)**  
• Group ID and Member Name input required  
• Creates a new member

**2. Get All Members**  
• Group ID input required  
• Retrieves all members in the group

**3. Get Member by Name**  
• Group ID and Member Name input required  
• Retrieves a specific member within a specific group

**4. Get Members by Status**  
• Group ID and Status selection required  
• Retrieves members by status within a specific group (active/inactive)

![Powered by AWS](https://d0.awsstatic.com/logos/powered-by-aws.png)

### TechCamp Online 다음 어젠다

[AWS TechCamp](https://pages.awscloud.com/aws-techcamp.html)

![2e221d7e549543ed5f8610333ef6c882.6216faeefbd124eff81d8c0406e9e83dbeb7d16f.jpeg](attachment:6ad28b29-3907-482b-9ee1-644c67c4beb5:2e221d7e549543ed5f8610333ef6c882.6216faeefbd124eff81d8c0406e9e83dbeb7d16f.jpeg)