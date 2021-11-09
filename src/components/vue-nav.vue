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
	name: 'BaseNav'

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
		# Render subnav behind item-head using z-index.
		renderSubnavBehind:
			type: Boolean
			default: true

		closeOnRouteChange:
			type: Boolean
			default: true
		
		# Unique string used to connect this nav's items and subnavs
		id:
			type: String
			default: 'vue-nav'

	data: ->
		# So we know how many items we have and can set/loop focus.
		navItems: []
		activeSubnavIndex: -1
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

	watch:
		# Trigger closeSubnav() on route change
		$route: -> if @closeOnRouteChange then @closeSubnav()

		# Emit events to parent
		activeSubnavIndex: ->
			@$emit 'update:activeSubnavIndex', @activeSubnavIndex
		subnavOpen: ->
			@$emit 'update:subnavOpen', @subnavOpen

	mounted: ->
		# Listen for events
		emitter.on 'vue-nav', @onEvent

	beforeDestroy: ->
		# Unsubscribe from child events
		emitter.off 'vue-nav', @onEvent

	methods:

		setActiveSubnavIndex: (index, closeIfAlreadyActive=true) ->
			@prevActiveSubnavIndex = @activeSubnavIndex
			if index==@activeSubnavIndex and closeIfAlreadyActive
				# Close the subnav
				@activeSubnavIndex = -1
			else
				# Open the new subnav
				@activeSubnavIndex = index

		closeSubnav: -> @setActiveSubnavIndex -1

		closeUs: ->
			# When we think we'll be closed, set the focus index back to the start.
			@focusedItemIndex = 0

		onEvent: (args) ->
			{ id, index, type } = args

			# Do nothing if this event was emitted from a different nav.
			return if id != @id

			console.log 'onEvent', args
			
			switch type
				when 'itemclick'
					@setActiveSubnavIndex(index)
				when 'itemblur', 'subnavblur'
					@onBlur(index)
				when 'returnkey'
					@onReturnKey(event, index)
				when 'nextkey'
					@setFocustoNextItem(index)
				when 'prevkey'
					@setFocustoPrevItem(index)
				when 'esckey'
					@closeSubnav()

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
