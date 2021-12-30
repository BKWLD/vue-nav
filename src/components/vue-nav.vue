<!--  -->

<template lang='pug'>
component.vue-nav(
	:is='element'
	:class='classes'
)
	slot(
		:subnav-open='subnavOpen'
		:active-subnav-index='activeSubnavIndex'
	)

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

	# If this vue-nav is nested inside another vue-nav, then inject the
	# variables provided by the parent vue-nav because we need the parentId.
	inject: 
		vueNavInject:
			default: {}

	mixins: [
		PointerEvents
		KeyboardEvents
		# Provide these properties to our vue-nav-items, vue-nav-subnavs, 
		# and any child vue-navs.
		ReactiveProvideMixin({
			name: 'vueNavInject'
			# ReactiveProvideMixin creates a computed prop by default with 
			# the same name as the `name` prop here.
			# Name the computed property something different so it doesn't
			# collide with one we're injecting from the parent vue-nav (if one exists).
			nameForComputed: 'vueNavInjectComputed'
			include: [
				'id'
				'parentId'
				'enterActiveClass'
				'leaveActiveClass'
				'activeSubnavIndex'
				'enableArrowKeys'
				'focusedItemIndex'
				'keyboardOrientation'
				'subnavFocusElements'
			]
		})
	]

	props:
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
		# Unique ID.  Randomly generated.
		id: ''
		# DOM element in each vue-nav-item that should receive focus.
		navFocusElements: []
		# DOM element in each vue-nav-subnav that should receive focus.
		subnavFocusElements: []
		# Zero-based index of the vue-nav-subnav that is currently open/expanded.
		activeSubnavIndex: -1
		# Zero-based index of the vue-nav-subnav that was open before the current one.
		# Used only by @enterActiveClass, an animation helper.
		prevActiveSubnavIndex: -1
		# Index of the focused vue-nav-item.
		focusedItemIndex: 0
		# Index of the previously focused vue-nav-item.  So we can restore focus after
		# the subnav has been opened and then closed.
		prevfocusedItemIndex: -1

	computed:
		# Injected from parent vue-nav, if one exists
		parentId: -> @vueNavInject?.id || ''

		classes: -> [
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

	created: -> 
		# Generate random ID for this vue-nav.
		@id = @getUid()

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

		# Generate a unique string comprised of numbers and lowercase letters.
		getUid: (strLength=8) -> Math.random().toString(36).substr(2, strLength)

		# When we click outside the nav and subnav, close the subnav.
		onDocClick: (event) ->
			# console.log 'onDocClick', event.target
			return unless @subnavOpen
			return unless @clickOutsideToClose
			return if @$el.contains event.target
			@closeSubnav()
			@closeUs()

		setActiveSubnavIndex: (index, fromKeyboardEvent=false, closeIfAlreadyActive=true) ->
			# Stop if there's no subnav at this index.
			return if index != -1 && !@subnavFocusElements?[index]

			# Stop if we're trying to close it when it's already closed.
			return if index == -1 && @activeSubnavIndex == -1

			# console.log 'setActiveSubnavIndex', {id: @id, index, fromKeyboardEvent}
			@prevActiveSubnavIndex = @activeSubnavIndex

			# If index is -1 then close subnav.  
			if index == -1
				# console.log "setActiveSubnavIndex #{@id}: received -1. closing subnav."
				# Close the subnav
				@activeSubnavIndex = -1
				# Restore focus to the item that was focused before we opened the subnav.
				@focusedItemIndex = @prevfocusedItemIndex
				return
			
			# If we toggled the already active subnav, close subnav.
			if (closeIfAlreadyActive and index == @activeSubnavIndex )
				# console.log "setActiveSubnavIndex #{@id}: closing the active subnav."
				# Close the subnav
				@activeSubnavIndex = -1
				# Restore focus to the item that was focused before we opened the subnav.
				@focusedItemIndex = @prevfocusedItemIndex
				return

			# Open the new subnav
			# console.log "setActiveSubnavIndex #{@id}: opening subnav', index"
			@activeSubnavIndex = index

			# We opened a subnav, and will set focus to it.  Now let's remove focus 
			# from this nav so that when we set focus to it later we'll get :focus-visible.
			@prevfocusedItemIndex = @focusedItemIndex
			@focusedItemIndex = -1

		# Todo: If always true, we could remove this param.
		closeSubnav: (fromKeyboardEvent=true) -> 
			# console.log 'closeSubnav', @id
			@setActiveSubnavIndex -1, fromKeyboardEvent

		closeUs: ->
			# When we think we'll be closed, set the focus index back to the start.
			@focusedItemIndex = 0

		# Handle events from a vue-nav-item
		onNavItemEvent: ({ type, id, index, focusElement }) ->
			# Do nothing if this event was emitted from a different nav.
			return unless id == @id

			# console.log 'onNavItemEvent', { type, id, index, focusElement, text: focusElement.innerText }
			
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
		onSubnavEvent: ({ type, id, index, subnavFocusElement }) ->
			# Do nothing if this event was emitted from a different nav.
			return unless id == @id
			# console.log 'onSubnavEvent', {type}

			# Save ref in reactive way (Doing `@subnavFocusElements[index]` is not reactive)
			@$set @subnavFocusElements, index, subnavFocusElement
			
			switch type
				when 'blur'
					@closeSubnav()
				when 'close'
					@closeSubnav()

		# Handle events from another vue-nav, such as our parent.
		onNavEvent: ({ id, type }) ->
			# Listen for 'closesubnav' events emitted by our parent vue-nav.  
			# This is a special event emitted by our parent vue-nav instance 
			# when it commands all its children to close their subnavs.
			if id == @parentId and type=='closesubnav'
				# console.log 'onNavEvent', {type, id: @id}
				@closeSubnav()

	watch:
		# Trigger closeSubnav() on route change
		$route: -> 
			if @closeOnRouteChange
				@closeSubnav()
				# console.log 'closing subnav on route change'

		activeSubnavIndex: ->
			# Emit events to parent via Vue events
			@$emit 'update:activeSubnavIndex', @activeSubnavIndex
			
			# Handle body-scroll-lock
			if @lockScroll
				if @subnavOpen then disableBodyScroll @$el
				else clearAllBodyScrollLocks()

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
