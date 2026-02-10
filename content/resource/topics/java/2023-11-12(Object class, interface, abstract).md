---
created: 2023-11-12
---
### Object
#### 왜 모든 클래스는 Object 클래스의 상속을 받을까?
- Object 클래스에 있는 메소드를 통해서 클래스의 기본적인 행동을 정의할 수 있기 때문.
#### Object 클래스에 선언되어 있는 메서드는 객체를 처리하기 위한 메서드와 쓰레드를 위한 메서드로 나뉜다.
- 객체 처리 관련 
	- clone, equals, finalize, Class < ? > getClass, hashCode, toString
- 스레드 처리 관련
	- notify : 이 객체의 모니터에 대기하고 있는 단일 쓰레드를 깨운다
	- notifyAll : 이 객체의 모니터에 대기하고 있는 모든 쓰레드를 깨운다
	- wait : 다른 쓰레드가 현재 객체에 대한 notify나 notifyAll 메소드를 호출할 때까지 현재 스레드가 대기하고 있도록 한다.
	- wait(long timeout) : 매개 변수에 지정한 밀리초 만큼만 대기
	- wait(long timeout, int nanos) : 밀리초 + 나노초 만큼만 대기
```java
  public class MemberDTO {  
    public String name;  
    public String phone;  
    public String email;  
  
    public MemberDTO(String name) {  
        this.name = name;  
    }  
  
    @Override  
    public String toString() {  
        return "MemberDTO{" +  
                "name='" + name + '\'' +  
                ", phone='" + phone + '\'' +  
                ", email='" + email + '\'' +  
                '}';  
    }  
  
    @Override  
    public boolean equals(Object obj) {  
        if (this == obj) return true; // 주소가 같으므로 당연히 true  
        if (obj == null) return false; // obj가 null이므로 당연히 false  
        if (getClass() != obj.getClass()) return false; // 클래스의 종류가 다르므로 false  
  
        MemberDTO other = (MemberDTO) obj; // 같은 클래스이므로 형변환 실행  
  
        // 이제부터는 각 인스턴스 변수가 같은지 비교하는 작업 수행  
        if (name == null) { // name이 null일때  
            if (other.name != null) return false; // 비교 대상의 name이 null 아니면 false  
        } else if (!name.equals(other.name)) return false; // 두 개의 name 값이 다르면 false  
  
        if (email == null) {  
            if (other.email != null) return false;  
        } else if (!email.equals(other.email)) return false;  
  
        if (phone == null) {  
            if (other.phone != null) return false;  
        } else if (!phone.equals(other.phone)) return false;  
  
        // 위 사항 모두 체크하여 false를 리턴하지 않은 객체는 같은 값을 가지는 객체로 생각해서 true  
        return true;  
    }  
  
    // equals() 메서드를 오버라이딩할 때에는 hashCode 메서드도 같이 오버라이딩해야함  
    // equals 객체의 값이 같음을 판단하나 객체의 주소까지 같지는 않음  
  
    @Override  
    public int hashCode() {  
        final int prime = 31;  
        int result = 1;  
        result = prime * result + ((name == null) ? 0 : name.hashCode());  
        result = prime * result + ((email == null) ? 0 : email.hashCode());  
        result = prime * result + ((phone == null) ? 0 : phone.hashCode());  
        return result;  
    }  
}
```

### interface
```java
public interface MemberManager {  
    public boolean addMember(MemberDTO member);  
    public boolean removeMember(String name, String phone);  
    public boolean updateMember(MemberDTO member);  
}
```


### abstract
#### 왜 abstract 클래스를 만들었을까?
- 아주 공통적인 기능을 미리 구현
#### 인터페이스, abstract 클래스, 클래스
|                                  | 인터페이스 | abstract 클래스 |   클래스   |
|:-------------------------------- |:----------:|:---------------:|:----------:|
| 선언 시 사용하는 예약어          | interface  | abstract class  |   class    |
| 구현 안 된 메서드 포함 가능 여부 | 가능(필수) |      가능       |    불가    |
| 구현된 메서드 포함 가능 여부     |    불가    |      가능       | 가능(필수) |
| static 메서드 사용 가능 여부    |    불가    |      가능       |    가능    |
| final 메서드 선언 가능 여부     |    불가    |      가능       |    가능    |
| 상속(extends) 가능               |    불가    |      가능       |    가능    |
| 구현(implements) 가능            |    가능    |      불가       |    불가    |

```java
public abstract class MemberManagerAbstract {  
    public abstract boolean addMember(MemberDTO member);  
    public abstract boolean removeMember(String name, String phone);  
    public abstract boolean updateMember(MemberDTO member);  
  
    public void printLog(String data) {  
        System.out.println("Data = "+data);  
    }  
}
```

#### final
- 클래스, 메서드, 변수에 선언 가능
- 클래스
	- 클래스가 final로 선언되어 있으면 상속을 해 줄 수 없음.
	- 클래스에 사용하는 이유 : 더 이상 확장해서는 안 되는 클래스, 내용을 변경해서는 안 되는 클래스를 선언 시 ex. String
- 메서드
	- 메서드에 사용하면 : 더 이상 오버라이딩 안 됨.
- 변수
	- 변수에 사용하면 : 그 변수는 더 이상 바꿀 수 없다 -> 인스턴스 변수나 static으로 선언된 클래스 변수는 선언과 함께 값을 지정해야만 한다.
	- 변하지 않는 값을 사용하는 경우
	- 참조 자료형도 적용이 될까?
```java
public class FinalReferenceType {  
    final MemberDTO dto = new MemberDTO();  
    public static void main(String[] args) {  
        FinalReferenceType referenceType = new FinalReferenceType();  
        referenceType.checkDTO();  
    }  
  
    private void checkDTO() {  
        System.out.println(dto);  
        // dto = new MemberDTO(); // 컴파일X  
        dto.name = "Sangmin"; // 컴파일O.. --> dto 객체는 두 번 이상 생성할 수 없음, 객체 안에 있는 객체들은 final로 선언되지 않음  
        System.out.println(dto);  
    }  
}
```