<!-- Optional subnav that's shown when you click a vue-nav-item -->

<template lang='pug'>
transition(
	name='subnav'
	:enter-active-class='enterActiveClass'
	:leave-active-class='leaveActiveClass'
	:duration='transitionDuration'
)
	div.vue-nav-subnav(
		:class='classes'
		v-show='index == activeSubnavIndex'
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
	inject: ['vueNavInject']

	props:

		# The index of this subnav must match the index of the 
		# vue-nav-item that opens it.
		index:
			type: Number

		# When this subnav opens, by default the first .vue-nav-item
		# receives keyboard focus. If you want a different element to 
		# receive focus, pass in a querySelector string.
		focusElement:
			type: String
			default: '.vue-nav-item'

		# Hardcode subnav transition duration, if necessary.
		transitionDuration:
			type: Number
			default: 800

		# When we lock scroll, what target element to persist scrolling for.
		# QuerySelector string.  If null, defaults to this vue-nav's @$el.
		scrollElement:
			type: String


	computed:
		# Injected from vue-nav
		id: -> @vueNavInject.id
		enterActiveClass: -> @vueNavInject.enterActiveClass
		leaveActiveClass: -> @vueNavInject.leaveActiveClass
		activeSubnavIndex: -> @vueNavInject.activeSubnavIndex
		classes: -> [
			if @index == @activeSubnavIndex then 'active' else 'not-active'
		]


	# On mounted, send an event so vue-nav has each subnav's index and ref
	mounted: -> @$nextTick ->
		@sendEvent('mounted')


	methods:
		sendEvent: (type) ->
			emitter.emit 'vue-nav-subnav', {
				type
				id: @id
				index: @index
				focusElement: @getFocusElement()
				scrollElement: @getScrollElement()
			}

		# Send a blur event when we tab away from this subnav.  This lets us
		# close the subnav and continue tabbing through the page.
		# Defer, or else 'document.activeElement' is always the body
		onBlur: (event) -> @$defer =>
			
			# Do nothing if focus changed between elements within this subnav.
			return if @$el.contains document.activeElement
			# console.log 'subnav onBlur', @$el.contains(document.activeElement), event.target, document.activeElement
			
			# Wait 100ms to ensure our blur event arrives after any click events.
			# This prevents a bug where clicking on this subnav's vue-nav-item
			# causes this subnav to close and re-open quickly, because this blur event
			# arrives first (closes the subnav), then the click event arrives (opens the subnav).
			# NextTick and Defer still arrive before click events.
			
			@$wait 100, => @sendEvent('blur')
			event.stopPropagation()
		
		closeSubnav: (event) -> @sendEvent('close')

		# Get the DOM element that should receive keyboard focus.
		# This is a method instead of a computed prop so it's called 
		# just in time and returns accurate elements.
		getFocusElement: -> 
			# Return focus element.  Fallback to the whole darn component.
			# We must return some element, or clicking the nav item won't
			# open the subnav at all.
			return @$el.querySelector(@focusElement) || @$el
		
		getScrollElement: -> 
			if typeof @scrollElement == 'string'
				return @$el.querySelector(@scrollElement) || @$el
			return @$el


	watch:		
		# When this subnav becomes active, set focus to the desired element.
		# Setting this too fast (ie @$nextTick=>) causes problems with
		# the vue transition, including flashing, wrong transform rendering, 
		# and not setting focus.  Waiting 100ms works better.
		# TODO: Check if this is bad.
		activeSubnavIndex: ->
			if @index == @activeSubnavIndex
				@$wait 100, () =>
					el = @getFocusElement()
					el.focus()
					# console.log 'watch activeSubnavIndex, set focus', el

</script>

<!-- ––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––– -->

<style lang='stylus' scoped>



</style>
