<!-- Optional subnav that's shown when you click a base-nav-item -->

<template lang='pug'>
transition(
	name='subnav'
	:enter-active-class='enterActiveClass'
	:leave-active-class='leaveActiveClass'
	:duration='transitionDuration'
)
	div(
		:class='classes'
		v-show='index == activeSubnavIndex'
		ref='subnav'
		@focusout='onBlur'
	)
		slot(
			:active='index == activeSubnavIndex'
			v-show='index == activeSubnavIndex'
		)


</template>

<!-- ––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––– -->

<script lang='coffee'>
export default
	inject: ['baseNavInject']

	props:
		index:
			type: Number

		# Hardcode subnav transition duration, if necessary.
		transitionDuration:
			type: [ Object, Number ]

	computed:
		# Injected from base-nav
		navId: -> @baseNavInject.navId
		enterActiveClass: -> @baseNavInject.enterActiveClass
		leaveActiveClass: -> @baseNavInject.leaveActiveClass
		activeSubnavIndex: -> @baseNavInject.activeSubnavIndex
		# Other
		subnavRef: -> @$refs.subnav.$el || @$refs.subnav
		classes: -> [
			'base-nav-subnav' # Consistent wrapper class name.  Used by `keyboard-events` mixin.
			"#{@navId}-subnav"
			if @index == @activeSubnavIndex then 'active' else 'not-active'
		]

	# On mounted, send an event so base-nav has each subnav's index and ref
	mounted: -> @$nextTick ->
		@sendEvent('subnav-mounted')

	methods:
		# Capture pointer and key events, and send custom events to base-nav.
		sendEvent: (type) ->
			customEvent = new CustomEvent 'basenav', {bubbles: true, detail: { navId:@navId, type:type, index:@index, ref:@subnavRef } }
			@subnavRef.dispatchEvent customEvent

		onBlur: (event) ->
			@sendEvent('subnavblur')
			event.stopPropagation()

</script>

<!-- ––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––– -->

<style lang='stylus' scoped>



</style>
