<!-- One navigation item in a base nav -->

<template lang='pug'>
component(
	:is='element'
	@keydown='onKeydown'
	@click='onClick'
	@focusout='onBlur'
)
	smart-link.base-nav-item(
		:to='url'
		v-bind='props'
		ref='item'
	)
		slot(
			:active='index == activeSubnavIndex'
		)

</template>

<!-- ––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––– -->

<script lang='coffee'>
import emitter from 'tiny-emitter/instance'
import { isInternal } from 'vue-routing-anchor-parser'
HTMLElement = window?.HTMLElement || Object

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

		# Clicking this nav-item takes you to this URL.  If we have a URL, there's no subnav.
		url:
			type: String

		# Determines what DOM element should receive focus on keyboard navigation.  Defaults to this component's smart-link.
		focusElement:
			type: String

		# What element to wrap this component in.
		element:
			type: String
			default: 'div'

	computed:
		# Injected from base-nav
		id: -> @baseNavInject.id
		activeSubnavIndex: -> @baseNavInject.activeSubnavIndex
		focusedItemIndex: -> @baseNavInject.focusedItemIndex

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

		classes: -> [
			"#{@id}-item-link"
			if @index == @activeSubnavIndex then 'active' else 'not-active'
		]

		tabindex: ->
			if !@enableArrowKeys then return 0
			if (@index == @focusedItemIndex) then return 0 else return -1

		##################################################################
		## Keyboard Events
		
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


	mounted: ->
		# Listen for events
		emitter.on 'vue-nav', @onEvent
		# Emit event, so vue-nav knows how many items it has
		sendEvent('')

	beforeDestroy: ->
		# Unsubscribe from child events
		emitter.off 'vue-nav', @onEvent

	methods:
		onEvent: (args) ->
			# console.log 'onEvent', args
			{ id, type, index } = args
		
		sendEvent: (type) ->
			emitter.emit 'vue-nav', { id: @id, index: @index, type: type }

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
			# console.log 'onKeydown', @id, event.keyCode, @keyboardOrientation
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
