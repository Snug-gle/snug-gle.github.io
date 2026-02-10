---
created: 2025-04-15
---
## Intro
- 트랜스포머 아키텍처가 공개된 이후, 핵심적인 아키텍처를 공유함에도 구현방식에 차이가 있어 모델마다 활용법을 익혀야 하는 문제가 존재
- 허킹페이스팀이 개발한 트랜스포머 라이브러리는 공통된 인터페이스로 트랜스포머 모델을 활용할 수 있도록 지원함으로써 이런 문제를 해결
```
!pip install transformers==4.41.0 datasets==2.19.0 huggingface_hub==0.25.0 -qqq
```
## 허킹페이스 트랜스포머란
- 다양한 트랜스포머 모델을 통일된 인터페이스로 사용할 수 있도록 지언하는 오픈소스 라이브러리
## 허킹페이스 허브 탐색하기
- 다양한 사전 학습 모델과 데이터셋을 탐색하고 쉽게 불러와 사용할 수 있도록 제공하는 온라인 플랫폼
### 모델 활용하기
```python
from transformers import AutoModel
model_id = 'klue/roberta-base'
model = AutoModel.from_pretrained(model_id)

from transformers import AutoModelForSequenceClassification
model_id = 'SamLowe/roberta-base-go_embmotions'
classification_model = AutoModelForSequenceClassification.from_pretrained(model_id)

from transformers import AutoModelForSequenceClassification
model_id = 'klue/roberta-base'
classification_model = AutoModelForSequenceClassification.from_pretrained(model_id)
```
### 토크나이저 활용하기
- 토크나이저는 텍스트를 토큰 단위로 나누고 각 토큰을 대응하는 토큰 아이디로 변환함
- input_ids: 토큰아이디의 리스트(토큰이 토크나이저 사전의 몇 번째 항목인지)
- attention_mask: 실제 텍스트인지 아니면 길이를 맞추기 위해 추가한 패딩인지 알려줌(1이면 실제 토큰)
- token_type_ids: 토큰이 속한 문장의 아이디를 알려줌
```python
from transformers import AutoTokenizer
medel_id = 'klue/roberta-base'
tokenizer = AutoTokenizer.from_pretrained(model_id)

# 한 문장일 경우
tokenized = tokenizer("토크나이저는 텍스트를 토큰 단위로 나눈다")
print(tokenized)
print(tokenizer.convert_ids_to_tokens(tokenized['input_ids']))
print(tokenizer.decode(tokenized['input_ids']))
print(tokenizer.decode(tokenized['input_ids'], skip_special_tokens=True))

{'input_ids': [0, 9157, 7461, 2190, 2259, 8509, 2138, 1793, 2855, 5385, 2200, 20950, 2], 'token_type_ids': [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0], 'attention_mask': [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1]}
['[CLS]', '토크', '##나이', '##저', '##는', '텍스트', '##를', '토', '##큰', '단위', '##로', '나눈다', '[SEP]']
[CLS] 토크나이저는 텍스트를 토큰 단위로 나눈다 [SEP]
토크나이저는 텍스트를 토큰 단위로 나눈다

# 두 문장일 경우, 토큰 아이디를 문자열로 복원
first_tokenized_result = tokenizer(['첫 번째 문장', '두 번째 문장'])['input_ids']
print(tokenizer.batch_decode(first_tokenized_result))
['[CLS] 첫 번째 문장 [SEP]', '[CLS] 두 번째 문장 [SEP]'] 

second_tokenized_result = tokenizer([['첫 번째 문장','두 번째 문장']])['input_ids']
print(tokenizer.batch_decode(second_tokenized_result))
['[CLS] 첫 번째 문장 [SEP] 두 번째 문장 [SEP]']

# token_type_ids
bert_tokenizer = AutoTokenizer.from_pretrained('klue/bert-base')
print(bert_tokenizer([['첫 번째 문장', '두 번째 문장']]))
{'input_ids': [[2, 1656, 1141, 3135, 6265, 3, 864, 1141, 3135, 6265, 3]], 'token_type_ids': [[0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1]], 'attention_mask': [[1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1]]}

roberta_tokenizer = AutoTokenizer.from_pretrained('klue/roberta-base')
print(roberta_tokenizer([['첫 번째 문장', '두 번째 문장']]))
{'input_ids': [[0, 1656, 1141, 3135, 6265, 2, 864, 1141, 3135, 6265, 2]], 'token_type_ids': [[0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]], 'attention_mask': [[1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1]]}

en_roberta_tokenizer = AutoTokenizer.from_pretrained('roberta-base')
print(en_roberta_tokenizer([['첫 번째 문장', '두 번째 문장']]))
{'input_ids': [[0, 43998, 14292, 4958, 47672, 14292, 23133, 43998, 6248, 18537, 47672, 11582, 18537, 43998, 17772, 8210, 2, 2, 45209, 3602, 16948, 47672, 14292, 23133, 43998, 6248, 18537, 47672, 11582, 18537, 43998, 17772, 8210, 2]], 'attention_mask': [[1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1]]}

tokenizer(['첫 번째 문장은 짧다', '두 번째 문장은 첫 번째 문장보다 더 길다'], padding='longest')
{'input_ids': [[0, 1656, 1141, 3135, 6265, 2279, 1599, 2062, 2, 1, 1, 1, 1, 1, 1, 1], [0, 864, 1141, 3135, 6265, 2073, 1656, 1141, 3135, 6265, 2178, 2062, 831, 647, 2062, 2]], 'token_type_ids': [[0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0], [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]], 'attention_mask': [[1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0], [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1]]}

```
- CLS 토큰: "Classifier", 문장의 시작 부분에 추가. 모델이 전체 입력 문장을 요약하거나 분류하는 데 사용하는 표현을 학습하는데 도움
- SEP 토큰: "Separator", 문장의 끝을 나타내거나, 두 문장 또는 문장 구성 요소들을 구분하는데 사용
### 데이터셋 활용하기