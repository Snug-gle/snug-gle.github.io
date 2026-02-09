---
created: 2025-07-14
---
1. React 왜 쓰는가?
	- single page application을 만들기 위해 사용한다.
	- html을 함수나 Array Object에 담아 사용 가능해서 재사용이 편리하다
	- 같은 문법으로 reactive native를 활용해 모바일 앱도 만들 수 있다.
2. jsx 문법
	1. class 넣을 땐 className
	2. 변수 꽃을 땐 { 변수명 }
	3. style 넣을 땐 style={{이름 : '값'}}
3. 동적인 UI 만드는 step
	1. html css로 미리 디자인 완성
	2. UI의 현재 상태를 state로 저장
	3. state에 따라 UI가 어떻게 보일지 작성
4. 페이지 나누는 법(라우터)
	1. 컴포넌트 만들어서 상세페이지 내용 채움
	2. 누가 /detail 접속하면 그 컴포넌트 보여줌
5. Lifecycle
	- mount: 페이지가 로드 될 때
	- update:  업데이트 될 때
	- unmount: 필요 없으면 제거 (ex. 상세페이지에서 홈페이지로 이동시 상세페이지는 제거)
	- 왜 배우는가?
		- 중간중간 간섭(코드실행)을 할 수 있다.
	- useEffect
		- mount, update
		- html 렌더링 후에 동작함
			- 따라서 실행이 오래 걸리는 코드를 useEffect에 넣어서 클라이언트에게 화면을 먼저 보여준 후 코드를 실행할 수 있다.
			- 어려운 연산, 서버에서 데이터 가져오는 작업
			- 타이머 장착하는거
			- 왜 effect라는 용어를 사용했을까?
				- Side Effect
				- 함수의 핵심기능과 상관없는 부가기능
	- useEffect` 정리 요약
	1. `useEffect(() => { 실행코드 })`
		→ **매 렌더링마다 
		``` js
		useEffect(() => {
		  console.log('항상 실행됨'); 
		  // ❌ 실무에선 거의 안 씀
		});
		```
	2. `useEffect(() => { 실행코드 }, [])`
		→ **처음 렌더링 1회만 실행 (마운트 시)**
		``` js
		useEffect(() => {
		  console.log('처음에 한 번만 실행'); // ✅ 초기 로딩에 적합
		}, []);
		```
		- API 요청
		- 초기 세팅
		- 타이머 설정
		- 초기 콘솔 출력 등
	3. `useEffect(() => { 실행코드 }, [변수])`
		→ **해당 변수(state, props)가 바뀔 때만 실행**
		``` js
		useEffect(() => {
		  console.log('count가 바뀔 때만 실행됨');
		}, [count]);
		```
		- 특정 상태 감지
		- 값 바뀔 때마다 무언가 처리 (예: 저장, 애니메이션 등)
	4. `useEffect(() => { 실행코드; return () => 정리코드 }, [])`
		→ **처음 실행 + 언마운트 시 정리**
		``` js
		useEffect(() => {
		  const timer = setInterval(() => console.log("tick"), 1000);
		  return () => clearInterval(timer); // ❗️언마운트되면 타이머 정리
		}, []);
		```
		- setInterval, setTimeout, 이벤트 등록 → cleanup 필요할 때

6. AJax
	- 방법(GET, POST..)
	- URL
	- sample
		- https://codingapple1.github.io/shop/date2.json