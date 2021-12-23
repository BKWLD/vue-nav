<!--  -->

<template lang='pug'>
component.vue-nav(
	:is='element'
	:class='classes'
)
	slot

</template>

<!-- ––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––– -->

<script lang='coffee'>
import emitter from 'tiny-emitter/instance'
import { ReactiveProvideMixin } from 'vue-reactive-provide'
import PointerEvents from '../mixins/pointer-events.coffee'
import KeyboardEvents from '../mixins/keyboard-events.coffee'
import { disableBodyScroll, clearAllBodyScrollLocks } from 'body-scroll-lock'

export default
	name: 'VueNav'

	mixins: [
		PointerEvents
		KeyboardEvents
		ReactiveProvideMixin({
			name: 'baseNavInject',
			include: [
				'id'
				'parentId'
				'enterActiveClass'
				'leaveActiveClass'
				'activeSubnavIndex'
				'enableArrowKeys'
				'focusedItemIndex'
				'keyboardOrientation'
				'subnavWrapperElements'
			]
		})
	]

	props:
		# Unique ID that links vue-nav and vue-nav-items
		id:
			type: String
			required: true

		# ID of the parent vue-nav.
		# This is only required if you want to close the subnav 
		# when you hit the escape key.
		parentId:
			type: String
			default: ''

		# If true, the subnav closes when the route changes.
		closeOnRouteChange:
			type: Boolean
			default: true
				
		element:
			type: String
			default: 'div'
		
		# When subnav is open, engage body-scroll-lock
		lockScroll:
			type: Boolean
			default: false

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
			@id # Your custom wrapper class name.  We need this for keyboard-events mixin.
			if @subnavOpen then 'subnav-open'
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
		emitter.on 'child-vue-nav-item', @onChildNavItemEvent
		emitter.on 'vue-nav-subnav', @onSubnavEvent
		emitter.on 'vue-nav', @onNavEvent
		document.addEventListener 'click', @onDocClick

	beforeDestroy: ->
		# Unsubscribe from child events
		emitter.off 'vue-nav-item', @onNavItemEvent
		emitter.off 'child-vue-nav-item', @onChildNavItemEvent
		emitter.off 'vue-nav-subnav', @onSubnavEvent
		emitter.off 'vue-nav', @onNavEvent
		document.removeEventListener 'click', @onDocClick

	methods:

		# When we click outside the nav and subnav, close the subnav.
		onDocClick: (event) ->
			# console.log 'onDocClick', event.target
			return unless @subnavOpen
			return unless @clickOutsideToClose
			return if @$el.contains event.target
			@closeSubnav()
			@closeUs()

		setActiveSubnavIndex: (index, fromKeyboardEvent=false, closeIfAlreadyActive=true) ->
			# console.log 'vue-nav', @id, 'setActiveSubnavIndex', {index, fromKeyboardEvent}
			@prevActiveSubnavIndex = @activeSubnavIndex

			# If index is -1 then close subnav.  
			# Or if toggling the already active subnav then close subnav.
			if (index==@activeSubnavIndex and closeIfAlreadyActive) || (index == -1)
				# Close the subnav
				@activeSubnavIndex = -1

				# If this was from a keyboard event, then set focus to a menu item.
				# If this was from a pointer event don't set focus, because it would be unexpected
				# to see a nav item suddenly jump to a focus state.
				# console.log 'setting setFocusToIndex', @prevActiveSubnavIndex
				if fromKeyboardEvent then @setFocusToIndex @prevActiveSubnavIndex

			else
				# Open the new subnav
				@activeSubnavIndex = index
				# Set focusedItemIndex to -1, so that it can be activated later
				@focusedItemIndex = -1

		# Todo: If always true, we could remove this param.
		closeSubnav: (fromKeyboardEvent=true) -> 
			@setActiveSubnavIndex -1, fromKeyboardEvent

		closeUs: ->
			# When we think we'll be closed, set the focus index back to the start.
			@focusedItemIndex = 0

		# Handle events from a vue-nav-item
		onNavItemEvent: ({ type, id, index, focusElement }) ->
			# Do nothing if this event was emitted from a different nav.
			return unless id == @id

			# console.log 'onNavItemEvent', { type, id, index, focusElement, text: focusElement.innerText }
			# if @id=='nav-desktop-2' then console.log @id, 'onNavItemEvent', { type, id, index, focusElement, text: focusElement.innerText }
			# if @id=='nav-desktop-2' then console.log id, 'onNavItemEvent', type
			
			# Save ref
			if index? && focusElement? then @navFocusElements[index] = focusElement
			
			switch type
				when 'click'
					@setActiveSubnavIndex(index)
				# Todo: If blur always does nothing, then remove it.
				# Blur does nothing
				# when 'blur', 'subnav-blur'
					# @onBlur(index)
				when 'focus'
					@setFocusToIndex(index)
				when 'returnkey'
					@onReturnKey(event, index)
				when 'nextkey'
					@setFocustoNextItem(index)
				when 'prevkey'
					@setFocustoPrevItem(index)
				when 'destroyed'
					@navFocusElements.pop(index)

		# Handle events from a vue-nav-item in a child vue-nav
		onChildNavItemEvent: ({ type, id }) ->
			# Do nothing if this event was emitted from the wrong nav.
			return unless id == @id

			# When we press the escape key in our child vue-nav, close our subnav.
			if type == 'esckey' then @closeSubnav(true)
			# console.log 'onChildNavItemEvent', { type }

		# Handle events from a vue-nav-subnav
		onSubnavEvent: ({ type, id, index, subnavFocusElement, subnavWrapperElement }) ->
			# Do nothing if this event was emitted from a different nav.
			return unless id == @id

			# Save ref in reactive way (Doing `@subnavFocusElements[index]` is not reactive)
			@$set @subnavFocusElements, index, subnavFocusElement
			@$set @subnavWrapperElements, index, subnavWrapperElement
			
			switch type
				when 'blur'
					@closeSubnav()
				when 'close'
					@closeSubnav()

		# Handle events from another vue-nav, such as our parent.
		onNavEvent: ({ id, type }) ->
			# console.log 'onNavEvent', {type, id}
			# Listen for 'closesubnav' events emitted by our parent vue-nav.  
			# This is a special event emitted by our parent vue-nav instance 
			# when it commands all its children to close their subnavs.
			if id == @parentId and type=='closesubnav' then @closeSubnav()

	watch:
		# Trigger closeSubnav() on route change
		$route: -> if @closeOnRouteChange then @closeSubnav()

		activeSubnavIndex: ->
			# Emit events to parent via Vue events
			@$emit 'update:activeSubnavIndex', @activeSubnavIndex
			
			# Handle body-scroll-lock
			if @lockScroll
				if @subnavOpen then disableBodyScroll @$el
				else clearAllBodyScrollLocks()

			# @setFocusToSubnav(@activeSubnavIndex)

		subnavOpen: ->
			@$emit 'update:subnavOpen', @subnavOpen

			if !@subnavOpen
				# When we close our subnav, tell all direct child vue-navs
				# to close their subnavs, too.
				# This is handled by the 'onNavEvent' method of all the 
				# child vue-navs.
				emitter.emit 'vue-nav', {
					id: @id
					type: 'closesubnav'
				}

</script>

<!-- ––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––– -->

<style lang='stylus' scoped>

</style>
