---
created: 2025-04-15
---
### 2.1 수의 분류,  문자식,  2진법

- 수의 분류
	- 정수 : 소수점이 없는 수
	- 유리수 : "정수/정수"로 표현할 수 있는 수
	- 실수 : 수직선 위에 표현할 수 있는 모든 수
	=> 실수 > 유리수 > 정수

- 문자식
	- x, y, z, a, b 등의 문자를 사용해서 나타낸 식

- 2진법
	```java
	class sample {
		public static void main(String[] args) {
			Scanner sc = new Scanner(System.in);
			int n = sc.nextInt();
			String answer = "";
			while (n >= 1) {
				// n % 2는 N를 2로 나눈 나머지(예: n = 13의 경우 1)  
				// n / 2는 N를 2로 나눈 몫(예:n = 13의 경우 6)
				if (n%2 == 0) {
					answer = "0" + answer;
				}
				if (n%2 == 1) {
					answer = "1" + answer;
				}
				n = n / 2;
			}
			System.out.println(answer);
		}
	}
	```

- practice
- 

### 2.2 기본적인 연산과 기호

### 2.3 다양한 함수

### 2.4 계산 횟수 예측하기 : 전체 탐색과 이진 탐색

### 2.5 추가적인 기본 수학 지식
