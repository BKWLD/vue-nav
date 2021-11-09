<!-- One navigation item in a base nav -->

<template lang='pug'>
//- `data-base-nav-item-index` is used by setFocusToSubnav()

//- If internalUrl, then use .native events because it's a `smart-link`.
smart-link.base-nav-item(
	v-if='isInternalUrl'
	:to='url'
	v-bind='props'
	ref='item'
	@keydown.native='onKeydown'
	@click.native='onClick'
	@focusout.native='onBlur'
)
	slot(
		:active='index == activeSubnavIndex'
	)

//- If not internalUrl, it's a `a` or `span`
smart-link.base-nav-item(
	v-else
	v-bind='props'
	ref='item'
	@keydown='onKeydown'
	@click='onClick'
	@focusout='onBlur'
)
	slot(
		:active='index == activeSubnavIndex'
	)

</template>

<!-- ––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––– -->

<script lang='coffee'>
import { isInternal } from 'vue-routing-anchor-parser'

keycodes = Object.freeze
	'TAB': 9
	'RETURN': 13
	'ESC': 27
	'SPACE': 32
	'PAGEUP': 33
	'PAGEDOWN': 34
	'END': 35
	'HOME': 36
	'LEFT': 37
	'UP': 38
	'RIGHT': 39
	'DOWN': 40

export default
	inject: ['baseNavInject']

	props:
		# Determines tabbing order, and connects nav-items with corresponding subnavs.
		index:
			type: Number

		# Clicking this nav-item takes you to this URL.  If url is provided, then this nav-item has no subnav.
		url:
			type: String

		# Determines what DOM element should receive focus on keyboard navigation.  Defaults to @$el.
		focusRef:
			type: HTMLElement

	computed:
		# Injected from base-nav
		navId: -> @baseNavInject.navId
		activeSubnavIndex: -> @baseNavInject.activeSubnavIndex
		enableArrowKeys: -> @baseNavInject.enableArrowKeys
		keyboardFocusIndex: -> @baseNavInject.keyboardFocusIndex
		keyboardOrientation: -> @baseNavInject.keyboardOrientation
		# Other
		isInternalUrl: -> if @url? then isInternal(@url) else false

		# Props
		props: ->
			class: @classes
			role: 'menuitem'
			'data-base-nav-item-index': @index
			tabindex: @tabindex
			'aria-haspopup': !!@url
			'aria-expanded': @index == @activeSubnavIndex

		# This DOM element dispatches our events, and is attached to our event's `detail` prop.
		itemRef: -> @focusRef || @$refs.item.$el || @$refs.item

		classes: -> [
			"#{@navId}-item-link"
			if @index == @activeSubnavIndex then 'active' else 'not-active'
		]
		tabindex: ->
			if !@enableArrowKeys then return 0
			if (@index == @keyboardFocusIndex) then return 0 else return -1

		# Keyboard Events
		# Get the next/prev arrow keycodes depending on keyboardOrientation.
		keycodeNext: ->
			return null unless @enableArrowKeys
			if @keyboardOrientation=='horizontal' then keycodes.RIGHT else keycodes.DOWN
		keycodePrev: ->
			return null unless @enableArrowKeys
			if @keyboardOrientation=='horizontal' then keycodes.LEFT else keycodes.UP
		# Get the other two arrow keycodes so we can preventDefault
		keycodeNullArrow1: ->
			return null unless @enableArrowKeys
			if @keyboardOrientation=='horizontal' then keycodes.DOWN else keycodes.RIGHT
		keycodeNullArrow2: ->
			return null unless @enableArrowKeys
			if @keyboardOrientation=='horizontal' then keycodes.UP else keycodes.LEFT
		# Allow using the arrow keys as if they were return and escape.  Assume child menus are positioned
		# below and to the right of parent menus, respectively.
		# keycodeReturnArrow: ->
		# 	return null unless @enableArrowKeys
		# 	return null unless @subnavKeyboardOrientation?
		# 	if @keyboardOrientation=='horizontal' then keycodes.DOWN else keycodes.RIGHT
		# keycodeEscArrow: ->
		# 	return null unless @enableArrowKeys
		# 	return null unless @subnavKeyboardOrientation?
		# 	if @subnavKeyboardOrientation=='horizontal' then keycodes.UP else keycodes.LEFT


	# On mounted, send an event so base-nav has each nav-item's index and ref
	mounted: -> @$nextTick ->
		@sendEvent('navitem-mounted')

	methods:
		# Capture pointer and key events, and send custom events to base-nav.
		sendEvent: (type) ->
			customEvent = new CustomEvent 'basenav', {bubbles: true, detail: { navId:@navId, type:type, index:@index, ref:@itemRef } }
			@itemRef.dispatchEvent customEvent

		# Pointer events
		onClick: (event) ->
			return if !!@url
			@sendEvent('itemclick')
			event.stopPropagation()

		onBlur: (event) ->
			@sendEvent('itemblur')
			event.stopPropagation()

		# Key events
		onKeydown: (event) ->
			# console.log 'onKeydown', @navId, event.keyCode, @keyboardOrientation
			key = event.keyCode
			if key==keycodes.SPACE or key==keycodes.RETURN or key==@keycodeReturnArrow
				@sendEvent('returnkey')
				event.stopPropagation()
				# Don't prevent default, in case we hit return on a nav link.
			if key==keycodes.ESC or key==@keycodeEscArrow
				@sendEvent('esckey')
				event.stopPropagation()
				event.preventDefault()
			if key==@keycodeNext
				@sendEvent('nextkey')
				event.stopPropagation()
				event.preventDefault()
			if key==@keycodePrev
				@sendEvent('prevkey')
				event.preventDefault()
				event.stopPropagation()
			if key==@keycodeNullArrow1 or key==@keycodeNullArrow2
				# Stop propagation because these keys might be bound in a parent base-nav and do unwanted things
				event.stopPropagation()
				event.preventDefault()

	watch:
		# If focusRef changes after mount, update the ref in base-nav
		focusRef: -> @sendEvent('navitem-mounted')


</script>

<!-- ––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––– -->

<style lang='stylus' scoped>



</style>
