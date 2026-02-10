---
created: 2023-11-13
---
##### There is no rule has no exception
- 자바에서는 예상을 했든, 예상을 하지 않았건 예외적인 일이 발생하게 되면 "예외"를 던져버림

```java
package c.exception;  
  
public class ExceptionSample {  
  
  public static void main(String[] args) {  
    ExceptionSample sample = new ExceptionSample();  
    sample.arrayOutOfBounds();  
  }  
  
  private void arrayOutOfBounds() {  
    try {  
      int[] intArray = new int[5];  
      System.out.println(intArray[5]);  
      System.out.println("This code should run.");  
    } catch (Exception e) {  
      System.err.println("Exception occured"); // err를 사용 시, IDE에서는 출력결과가 다른 색으로 표시됨
    }  
    System.out.println("This code must run.");  
  }  
}
```
##### try-catch 블록 내 변수선언
- try 블록은 중괄호로 쌓여 있는 블록 -> 블록 내에 선언한 변수를 catch에서 사용할 수 없음
- catch 문장에서 사용할 변수에 대해서는 try 앞에 미리 선언해 놓는다.
##### 두 개 이상의 catch
- try 다음에 오는 catch 블록은 1개 이상 올 수 있다.
- 먼저 선언한 catch 블록의 예외 클래스가 다음에 선언한 catch 블록의 부모에 속하면, 자식에 속하는 catch 블록은 절대 실행이 될 일이 없으므로 컴파일이 되지 않는다.
- 하나의 try 블록에서 예외가 발생하면 그 예외와 관련이 있는 catch 블록을 찾아서 실행한다.
- catch 블록 중 발생한 예외와 관련있는 블록이 없으면, 예외가 발생되면서 해당 쓰레드는 끝난다.
	-> 마지막 catch 블록에는 Exception 클래스로 묶어주는 습관 필요
##### 예외의 종류는 세 가지
###### 1. checked exception
- Exception을 바로 확장한 클래스들
###### 2. error
- 자바 프로그램 밖에서 발생한 예외. ex. 서버의 디스크가 고장, 메인보드 맛이감
- 에러를 예외의 종류로 보기는 힘드나 오라클에서 분류를 하고 있음
- 에러는 프로세스에 영향을 주고, exception은 쓰레드에만 영향을 줌
###### 3. runtime exception 혹은 unchecked exception
- RuntimeException을 확장한 예외들.
- 컴파일 시 예외 발생 하지 않고, 실행 시 예외 발생

##### Throwable 클래스
- getMessage()
	- 예외 메세지를 String 형태로 제공 받음
- toString()
	- getMessage() 메서드보다는 약간 더 자세하게, 예외 클래스 이름도 같이 제공
- printStackTrace()
	- 가장 첫 줄에는 예외 메세지를 출력, 두 번째 줄부터는 예외가 발생하게 된 메서들의 호출 관계(스택 트레이스)를 출력

##### 자바 예외  처리 전략
- 나만의 예외 클래스 작성 시, 이 예외가 항상 발생하지 않고, 실행시에 발생할 확률이 매우 높은 경우에는 RuntimeException으로 선언하는 것이 나을 수 있다. 
	-> throw 하더라도 try-catch로 묶지 않아도 컴파일 시에 예외가 발생하지 않음.
	-> 임의의 클래스를 만들 때에는, 반드시 try-catch로 묶어줄 필요가 있을 경우에만 Exception를 확장하고 일반적으로 실행시 예외를 처리할 수 있는 경우에는 RuntimeException 클래스를 확장하는 것을 권장
- catch문 내에 아무런 작업 없이 공백을 놔두면 예외 분석이 어려워지므로 꼭 로그 처리와 같은 예외 처리를 해줘야만 한다.
- 추가자료 : "자바 예외 전략" 혹은 "Java Exception Strategy"
