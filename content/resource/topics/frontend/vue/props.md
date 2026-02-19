---
created: 2026-02-09
---
---
tags:
  - resource
  - vue
  - frontend
category: frontend
topic: props
status: complete
created: 2024-01-01
modified: 2025-10-29
---
1. 부모[[ app.vue ]]에서 props 등록
	``` vue
	<product-modal :원룸들="원룸들" :누른거="누른거" :모달창열렸니="모달창열렸니"/>
	<script>
	import ProductModal from './product-modal.vue'
	export default {
		name: 'App',
		data() {
			return {
					누른거 : 0,
					원룸들 : data,
					모달창열렸니 : false,
			}
		},
		components: {
			ProductModal : ProductModal,
	},
	</script>
	```
	==데이터는 자식이 아닌 부모 컴포넌트에 생성한다, 데이터를 자식에서 부모로 전송하는 건 지양==
2. 자식[[ product-modal]] 은  props로 받은 것을 등록
	``` vue
	<script>
	export default {
		name :'ProductModal',
		props : {
		원룸들 : Array,
		누른거 : Number,
		모달창열렸니 : Boolean,
		}
	}
	</script>
	```

