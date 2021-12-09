<!-- Optional subnav that's shown when you click a vue-nav-item -->

<template lang='pug'>
transition(
	name='subnav'
	:enter-active-class='enterActiveClass'
	:leave-active-class='leaveActiveClass'
	:duration='transitionDuration'
)
	div.vue-nav-subnav(
		v-show='index == activeSubnavIndex'
		ref='subnavWrapperRef'
		@focusout='onBlur'
	)
		slot(
			:active='index == activeSubnavIndex'
			:closeSubnav='closeSubnav'
			v-show='index == activeSubnavIndex'
		)


</template>

<!-- ––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––– -->

<script lang='coffee'>
import emitter from 'tiny-emitter/instance'

export default
	inject: ['baseNavInject']

	props:
		index:
			type: Number

		# By default, the smart-link receives keyboard focus.  If you want an element inside the slot
		# to receive keyboard focus, then pass in a querySelector string.
		focusElement:
			type: String

		# Hardcode subnav transition duration, if necessary.
		transitionDuration:
			type: Number
			default: 800

	computed:
		# Injected from vue-nav
		id: -> @baseNavInject.id
		enterActiveClass: -> @baseNavInject.enterActiveClass
		leaveActiveClass: -> @baseNavInject.leaveActiveClass
		activeSubnavIndex: -> @baseNavInject.activeSubnavIndex
		classes: -> [
			'vue-nav-subnav' # Consistent wrapper class name.  Used by `keyboard-events` mixin.
			"#{@id}-subnav"
			if @index == @activeSubnavIndex then 'active' else 'not-active'
		]

	# On mounted, send an event so vue-nav has each subnav's index and ref
	mounted: -> @$nextTick ->
		@sendEvent('mounted')

	methods:
		sendEvent: (type) ->
			# console.log 'subnav sendEvent', type
			emitter.emit 'vue-nav-subnav', {
				type
				id: @id
				index: @index
				subnavFocusElement: @getSubnavFocusElement()
				subnavWrapperElement: @getSubnavWrapperElement()
			}

		onBlur: (event) ->
			@sendEvent('blur')
			event.stopPropagation()
		
		closeSubnav: (event) -> @sendEvent('close')

		# Get the DOM element that should receive keyboard focus.
		# This is a method instead of a computed prop so it's called just in time and returns accurate elements.
		getSubnavFocusElement: -> 
			return @$el.querySelector(@focusElement) if @focusElement
			return @getSubnavWrapperElement()

		getSubnavWrapperElement: -> return @$refs.subnavWrapperRef.$el || @$refs.subnavWrapperRef

	watch:
		# If focusElement changes after mount, communicate this change to vue-nav.
		focusElement: -> @sendEvent('focusElement changed')

</script>

<!-- ––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––– -->

<style lang='stylus' scoped>



</style>
