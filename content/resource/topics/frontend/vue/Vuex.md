---
tags:
  - resource
  - vue
  - frontend
  - vuex
  - state-management
category: frontend
topic: Vuex
status: complete
created: 2024-01-01
modified: 2025-10-29
---
- Vue.js 애플리케이션에서 전역 상태 관리를 위한 라이브러리
- 모든 컴포넌트에서 공유할 수 있는 중앙 저장소 역할

### 핵심 요소
#### 상태(State)
- 공유 데이터
- 모든 컴포넌트가 store의 state를 읽거나 수정할 수 있음
``` javascript
const store = new Vuex.store({
	state: {
		count: 0, // 공유되는 상태
	}
})
```
- 컴포넌트에서 state를 읽는 방법
``` javascript
this.$store.state.count; // 0출력
```
#### 변이(Mutations)
- mutations는 State를 수정하는 유일한 방법
- 동기적으로 동작
```javascript
const store = new Vuex.Store({
	state: {
		count: 0,
	},
	mutations: {
		increment(state) {
			state.count++; // 수정
		}
	}
})
```
- 호출 방법
```javascript
this.$store.commit('increment'); //count가 1증가
```
#### 액션(Actions)
- 비동기 작업을 처리하거나, 여러 Mutations를 조합해 실행하는 역할
- 서버에서 데이터를 가져와서 state를 업데이트 해야 할 때 사용
```javascript
const store = new Vuex.Store({
	state: {
		count: 0,
	},
	mutations: {
		setCount(state, value) {
			state.count = value;
		}
	},
	actions: {
		async fetchCount({ commit }) {
			const value = await fetchSomeDate();
			commit('setCount', value); 
		}
	}	
})
```
- action 호출
``` javascript
this.$store.dispatch('fetchCount');
```
#### 게터(Getters)
- State를 기반으로 계산된 값(computed porperty)을 제공
- 컴포넌트에서 State를 가져오는 로직을 단순화할 때 유용
``` javascript
const store = new Vuex.store({
	state: {
		count: 5,
	},
	getters: {
		doubledCount: (state) => state.count * 2,
	},
})
```
- 호출
```javascript
this.$store.getters.doubledCount;
```
#### Vuex 동작 흐름
1. 컴포넌트에서 Action을 호출(dispatch 사용)
2. Action은 필요한 작업(비동기 요청 등)을 수행한 뒤, Mutation은 State를 수정
3. Mutation은 State를 수정
4. 수정된 State는 컴포넌트에서 반영