---
created: 2023-11-06
---
- [x] enum에 대해 정리
- [x] 스터디 수정 반영
- [x] 강의 가능하면 듣기

### enum
- constant(상수) : 기본 자료형의 값을 고정 -> 어떤 클래스가 상수만으로 이루어져 있는 경우 굳이 class로 선언할 필요가 없음
- enum : "이 객체는 상수의 집합이다" 라는 것을 명시적으로 나타냄
- 가장 효과적으로 enum 클래스를 사용하는 방법은 switch문
```java
public class OverTimeManager {
	public int getOverTimeAmount(OverTimeValues value) {
		int amount = 0;
		System.out.prinln(value);
		switch(value) {
			case THREE_HOUR:
				amount=18000;
				break;
			...
			case WEEKEND_EIGHT_HOUR:
				amount=60000;
				break;
		}
		return amount;
	}
}

public static void main(String[] args) {
	OverTimeManager manager = new OverTimeManager();
	int myAmount = manager.getOvertimeAmount(OverTimeValues.THREE_HOUR);
	System.out.println(myAmount);
}
```

```java
public enum OverTimeValues2 {
	THREE_HOUR(18000),
	FIVE_HOUR(30000),
	WEEKENED_FOUR(40000),
	WEEKENED_EIGHT(60000);
	private final int amount;

	// enum 클래스의 생성자는 package-private, private만 접근 제어자로 사용 가능
	OverTimeValues2(int amount) {
		this.amount=amount;
	}

	// enum 클래스의 변수로 선언한 amount의 값을 리턴
	public int getAmount() {
		return amount;
	}

}

public class OverTimeManager2 {
	public static void main(String[] args) [
		OverTimeValues2 value2 = OverTimeValues2.FIVE_HOUR;
		System.out.println(value2);
		System.out.println(value2.getAmount());

		OverTimeValues2[] valueList = OverTimeValue2.values();
		for (OverTimeValues2 value : valueList) {
			Systme.out.println(value);
		}
	]
}
```

- enum 클래스의 부모는 무조건 java.lang.enum이어야 한다
	- extends java.lang.enum을 사용하지는 않으나 compiler가 알아서 추가해줌. 따라서 다른 클래스를 마음대로 extends 할 수 없음.
	- enum 클래스의 생성자
		```java
		// name은 enum 상수의 이름, ordinal은 enum의 순서(상수가 선언된 순서대로 0부터 증가
		protected Enum(String name, int ordinal)
```

- 