---
created: 2025-04-07
---
### ✅ 왜 `$`를 사용하는가?

Sass에서는 `$`를 **변수(variable)** 선언에 사용해. 즉,

``` scss
`$dark: #333;`
```

이렇게 미리 값을 변수로 지정해두고,

```scss
`.target {   background-color: $dark; }`
```

처럼 사용하는 거야.

👉 그래서 `.target` 클래스의 `background-color`가 `#333`으로 설정되는 거지.

이게 CSS에서는 불가능한 Sass만의 기능

---

### ✅ Sass란?

Sass는 **CSS 전처리기(preprocessor)**야.  
기존 CSS의 한계를 보완해주고, **더 프로그래밍스럽게 스타일을 작성**할 수 있게 해줘.

---

### ✅ Sass의 주요 기능

|기능|설명|
|---|---|
|**변수** (`$`)|재사용 가능한 값 저장 (색상, 크기 등)|
|**중첩**|선택자를 구조적으로 작성 가능 (HTML 구조와 유사)|
|**Mixin**|재사용 가능한 스타일 블록. 파라미터도 받을 수 있음|
|**함수**|연산이나 동적 스타일 계산 가능|
|**상속**|스타일 속성을 다른 선택자가 상속 가능 (`@extend`)|
|**모듈화**|여러 `.scss` 파일로 나눠서 관리 가능 (`@use`, `@forward`)|

---

### ✅ Sass 예시

scss

복사편집

`// 변수 선언 $primary-color: #007bff; $padding-lg: 2rem;  // 믹스인 정의 @mixin flex-center {   display: flex;   justify-content: center;   align-items: center; }  // 사용 .card {   background-color: $primary-color;   padding: $padding-lg;    // 중첩   .title {     font-size: 1.5rem;     color: white;   }    // 믹스인 사용   @include flex-center; }`

컴파일되면 평범한 CSS로 변환돼. 이게 Sass가 **전처리기**인 이유야.

---

### ✅ SCSS vs SASS 문법?

- **SCSS**: CSS랑 비슷한 문법 (`{}`, `;` 사용)
    
- **SASS**: 들여쓰기 기반 문법 (Python 느낌)
    

요즘은 대부분 **SCSS 문법**을 써. 네 코드도 SCSS 스타일이야.


## inline element, block element
## ✅ Inline 요소 vs Block 요소 차이점

|구분|Inline 요소|Block 요소|
|---|---|---|
|**라인 배치**|같은 줄 안에서 옆으로 배치됨|무조건 줄 바꿈 후 배치됨|
|**width/height**|설정해도 무시됨 (콘텐츠 크기에 맞춰짐)|설정 가능함 (레아웃 제어 가능)|
|**padding/margin**|상하(padding-top/bottom, margin-top/bottom)는 거의 무시됨|모든 방향에서 잘 작동함|
|**대표 태그**|`<span>`, `<a>`, `<strong>`, `<em>` 등|`<div>`, `<p>`, `<section>`, `<article>` 등|

## ✅ 왜 inline 요소엔 `width`, `height`가 안 먹힐까?

`inline` 요소는 **텍스트처럼** 취급되기 때문이야.  
즉, 브라우저는 얘를 글자처럼 다루니까 텍스트 라인에 맞게 크기가 자동 조정돼.

html

복사편집

`<span style="width: 200px; height: 100px; background: red;">hello</span>`

이렇게 써도 `width`, `height`는 무시되고 텍스트만큼만 공간이 잡혀.  
배경색은 보이지만 크기 지정은 무시당해.

## ✅ 해결 방법: `inline-block`

css

복사편집

`display: inline-block;`

이렇게 설정하면 텍스트처럼 옆으로 흐르되, `width`/`height`가 적용돼.  
한마디로 **inline과 block의 장점을 합친 타입**이야.

---

## ✅ 예시로 정리

html

복사편집

`<!-- inline --> <span style="background: red; width: 100px; height: 50px;">TEXT</span>  <!-- inline-block --> <span style="display: inline-block; background: red; width: 100px; height: 50px;">TEXT</span>`

첫 번째 span은 텍스트만큼만 배경이 생기고, 두 번째 span은 100x50 크기로 정확히 만들어져.

---

## ✅ 정리

|속성/기능|inline|block|inline-block|
|---|---|---|---|
|줄 바꿈 여부|X|O|X|
|width/height 적용|X|O|O|
|텍스트와 함께 정렬|O|X|O|