---
tags:
  - resource
  - vue
  - frontend
  - event
category: frontend
topic: custom event
status: complete
created: 2024-01-01
updated: 2025-10-29
---

부모에게서 받아온 props data를 자식에서 수정할 수 없다. (Read-only)
custom event: 부모의 데이터를 바꾸고 싶을 때 메세지를 보냄
`$emit('작명', 데이터)` 함수: 부모에게 메세지 보낼 때 사용. (vue에서 사용하는 특별한 변수)
`$event`: 부모에게 데이터를 보낼 때 사용
1. 자식에서 `$emit`를 사용
``` vue
<template>
	<div>
		<img :src="원룸.image" class="room-img">
		<h4 @click="$emit('openModal', 원룸.id)">{{ 원룸.title }}</h4>
		<p>{{ 원룸.price }} 원</p>
</div>
</template>

```

2. 자식에서 정의한 이름을 부모에서 사용
``` vue
<product-card @openModal="모달창열렸니 = true; 누른거 = $event" :원룸="원룸들[i]" v-for="(작명, i) in 원룸들" :key="작명"/>
```

3. script - method를 통해 정리 가능
	- props든, data든, `$변수`든 밑에서 사용할 땐 this를 붙임
``` vue
<template>
	<div>
		<img :src="원룸.image" class="room-img">
		<h4 @click="모달창열기">{{ 원룸.title }}</h4>
		<p>{{ 원룸.price }} 원</p>
	</div>
</template>
<script>
export default {
	props :{
		원룸 : Object,
	},
	methods : {
		모달창열기() {
			this.$emit('openModal', this.원룸.id)
		}
	}
}
</script>
```
