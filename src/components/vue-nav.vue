<!--  -->

<template lang='pug'>
.base-nav(
	:class='classes'
)
	.overlay(
		v-if='clickOutsideToClose'
		v-show='subnavOpen'
		@click='onOverlayClick'
	)
	slot

</template>

<!-- ––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––– -->

<script lang='coffee'>
import emitter from 'tiny-emitter/instance'
import { ReactiveProvideMixin } from 'vue-reactive-provide'
import PointerEvents from '../mixins/pointer-events.coffee'
import KeyboardEvents from '../mixins/keyboard-events.coffee'

export default
	name: 'VueNav'

	mixins: [
		PointerEvents
		KeyboardEvents
		ReactiveProvideMixin({
			name: 'baseNavInject',
			include: [
				'id'
				'enterActiveClass'
				'leaveActiveClass'
				'activeSubnavIndex'
				'enableArrowKeys'
				'focusedItemIndex'
				'keyboardOrientation'
			]
		})
	]

	props:
		# Unique ID that links vue-nav and vue-nav-items
		id:
			type: String
			required: true

		# ID of the direct child vue-nav.  
		# This is only required if you want to close the subnav 
		# when you hit the escape key.
		childId:
			type: String

		# Render subnav behind item-head using z-index.
		renderSubnavBehind:
			type: Boolean
			default: true

		# If true, the subnav closes when the route changes.
		closeOnRouteChange:
			type: Boolean
			default: true
		
	data: ->
		# DOM element in each vue-nav-item that should receive focus
		navFocusElements: []
		# DOM element in each vue-nav-subnav that should receive focus.
		subnavFocusElements: []
		# DOM element that wraps each vue-nav-subnav.
		subnavWrapperElements: []
		# Zero-based index of the vue-nav-subnav that is currently open/expanded.
		activeSubnavIndex: -1
		# Zero-based index of the vue-nav-subnav that was open before the current one.
		# Used only by @enterActiveClass, an animation helper.
		prevActiveSubnavIndex: -1

	computed:
		classes: -> [
			'base-nav' # Consistent wrapper class name.  Used by `keyboard-events` mixin.
			@id # Your custom wrapper class name.  We need this for keyboard-events mixin.
			if @renderSubnavBehind then 'subnav-behind' else 'subnav-in-front'
		]

		subnavOpen: -> @activeSubnavIndex != -1

		enterActiveClass: ->
			# Add "fast" class if the subnav was already open
			# If you feel your regular transitions are too much when you toggle quickly between subnavs,
			# add transitions to this classname.
			return "subnav-enter-active fast" if @prevActiveSubnavIndex != -1
			"subnav-enter-active"

		leaveActiveClass: ->
			# Add "fast" class if the subnav is still open (on another tab)
			# If you feel your regular transitions are too much when you toggle quickly between subnavs,
			# add transitions to this classname.
			return "subnav-leave-active fast" if @subnavOpen
			"subnav-leave-active"

	mounted: ->
		# Listen for events
		emitter.on 'vue-nav-item', @onNavItemEvent
		emitter.on 'vue-nav-subnav', @onSubnavEvent

	beforeDestroy: ->
		# Unsubscribe from child events
		emitter.off 'vue-nav-item', @onNavItemEvent
		emitter.off 'vue-nav-subnav', @onSubnavEvent

	methods:

		setActiveSubnavIndex: (index, closeIfAlreadyActive=true) ->
			# console.log 'vue-nav', @id, 'setActiveSubnavIndex', index
			@prevActiveSubnavIndex = @activeSubnavIndex
			# If index is -1 then close subnav.  If toggling the already active subnav, then close subnav.
			if (index==@activeSubnavIndex and closeIfAlreadyActive) || (index == -1)
				# Close the subnav
				@activeSubnavIndex = -1
				# Set focus to a menu item
				# console.log 'setting setFocusToIndex', @prevActiveSubnavIndex
				@setFocusToIndex @prevActiveSubnavIndex
			else
				# Open the new subnav
				@activeSubnavIndex = index
				# Set focusedItemIndex to -1, so that it can be activated later
				@focusedItemIndex = -1

		closeSubnav: -> 
			# console.log 'vue-nav', @id, 'closeSubnav'
			@setActiveSubnavIndex -1

		closeUs: ->
			# When we think we'll be closed, set the focus index back to the start.
			@focusedItemIndex = 0

		onNavItemEvent: ({ type, id, index, focusElement }) ->
			# console.log 'vue-nav', @id, 'onNavItemEvent', { type, id, index, focusElement, text: focusElement.innerText }
			
			if id == @childId and type == 'esckey'
				return @closeSubnav()
			
			# Do nothing if this event was emitted from a different nav.
			return if id != @id

			# Save ref
			@navFocusElements[index] = focusElement
			
			switch type
				when 'click'
					@setActiveSubnavIndex(index)
				when 'blur', 'subnav-blur'
					# TODO: remove this if we can.
					@onBlur(index)
				when 'returnkey'
					@onReturnKey(event, index)
				when 'nextkey'
					@setFocustoNextItem(index)
				when 'prevkey'
					@setFocustoPrevItem(index)
				when 'destroyed'
					@navFocusElements.pop(index)

		onSubnavEvent: ({ type, id, index, subnavFocusElement, subnavWrapperElement }) ->
			# console.log 'onSubnavEvent', { type, id, index, subnavFocusElement }
			# Do nothing if this event was emitted from a different nav.
			return if id != @id

			# Save ref
			@subnavFocusElements[index] = subnavFocusElement
			@subnavWrapperElements[index] = subnavWrapperElement
			
			switch type
				when 'blur'
					@closeSubnav()

	watch:
		# Trigger closeSubnav() on route change
		$route: -> if @closeOnRouteChange then @closeSubnav()

		# Emit events to parent via Vue events
		activeSubnavIndex: ->
			@$emit 'update:activeSubnavIndex', @activeSubnavIndex
			return if @activeSubnavIndex==-1
			@setFocusToSubnav(@activeSubnavIndex)

		subnavOpen: ->
			@$emit 'update:subnavOpen', @subnavOpen

</script>

<!-- ––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––– -->

<style lang='stylus' scoped>
.overlay
	position absolute
	width 200vw
	height 200vh
	left -50vw
	top -50vh

.items, .subnavs
	position relative

.base-nav-item
	cursor pointer

.subnav-behind
	.items
		z-index 1

.subnav-in-front
	.subnavs
		z-index 1

</style>
