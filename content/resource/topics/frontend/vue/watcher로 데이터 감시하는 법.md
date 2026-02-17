---
tags:
  - resource
  - vue
  - frontend
  - watcher
category: frontend
topic: watcher로 데이터 감시하는 법
status: complete
created: 2024-01-01
modified: 2025-10-29
---
``` vue
<script>
export default {
	name : 'ProductModal',
	data() {
		return {
			month : 1,
		}
	},
	watch : {
		month(a) {
			사용자가 month를 글자로 입력하면 경고문 띄워주셈
			사용자가 monthdp 입력한 데이터가 13보다 크면 경고문 띄우기
			if (a > 13) {
				alert('13 이상 입력하지 마셈')
			}
		}
	},
	props : {
		원룸 : Object,
		모달창열렸니 : Boolean,
		누른거 : Number
	},
	methods : {
		closeProductModal() {
			console.log("[product-modal.vue]모달창열렸니: " + this.모달창열렸니)
			this.$emit('closeModal', this.원룸.id)
		}
	}
}
</script>
```
- input에 문자입력하면 경고문을 띄우고 싶은 경우 사용(data 감시하는 함수)
- 데이터 감시하려면 watch : { 감시할 데이터() {}}
- month라는 데이터가 변할 때마다 안에 있는 코드를 스윽 지나감.