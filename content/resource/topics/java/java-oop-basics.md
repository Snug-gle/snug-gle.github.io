---
created: 2023-11-12
tags:
  - resource
  - java
  - OOP
  - lambda
  - functional-programming
category: java
up: "[[resource/topics/java/_Java MOC|Java MOC]]"
---

## OOP 4대 특성

- **캡슐화** - 속성을 변수에, 행위를 메소드에 담아 클래스로 묶고 정보를 은닉
- **추상화** - 복잡한 시스템에서 핵심 개념/기능을 간추려내는 것 (예: 핸들=방향전환, 엑셀=가속)
- **상속** - 한 객체를 또 다른 객체가 이어받아 부모 코드를 재사용
- **다형성** - 오버로딩(이름은 같으나 파라미터가 다름), 오버라이딩(상속받아 메소드를 재정의)

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

---

## 제네릭 (Generics)
- 클래스나 메소드에서 사용할 자료형을 컴파일 타임에 미리 지정하는 방식
- 런타임이 아닌 컴파일 시점에 타입 검사 → 버그를 미리 수정
- 다이아몬드 연산자로 간결하게 사용: `Map<String, Integer> mapNames = new HashMap<>();`

---

## 람다 표현식 (Lambda)
- 함수형 인터페이스를 간결하게 구현: `(파라미터) -> 내용`
- 함수형 인터페이스란 추상 메소드를 하나만 갖는 인터페이스

```java
@FunctionalInterface
interface MathInterface {
    double getPiValue();
}

// 기존 익명 클래스
MathInterface math = new MathInterface() {
    @Override
    public double getPiValue() {
        return 3.141592;
    }
};

// 람다 표현식
MathInterface math = () -> 3.141592;

// 정렬 - 익명 클래스 vs 람다
Collections.sort(members, new Comparator<Member>() {
    @Override
    public int compare(Member o1, Member o2) {
        return o2.age - o1.age;
    }
});
members.sort((o1, o2) -> o2.age - o1.age);
```

### java.util.function 함수형 인터페이스
- **Function** - 인자 있고, 리턴값 있음. 매개값 연산 후 결과 리턴. `T -> R`
- **Consumer** - 인자 있고, 리턴값 없음. `T -> void`
- **Supplier** - 인자 없고, 리턴값 있음. `() -> R`
- **Operator** - 인자 있고, 리턴값 있음. 매개값 연산 후 결과 리턴. `T -> R`
- **Predicate** - 인자 있고, 리턴값은 boolean. 매개값 조사 후 true/false 리턴

---

## 스트림 API (Stream)
- 컬렉션을 스트림 파이프라인으로 처리

```java
// 기존 방식
List<String> chosenMembers = new ArrayList<>();
for (Member member : members) {
    if (member.age == 24) {
        chosenMembers.add(member.name);
    }
}
Collections.sort(chosenMembers);
for (String name : chosenMembers) {
    System.out.println(name);
}

// 스트림 API
members.stream()
    .filter(m -> m.age == 24)
    .map(m -> m.name)
    .sorted()
    .collect(Collectors.toList())
    .forEach(System.out::println);
```