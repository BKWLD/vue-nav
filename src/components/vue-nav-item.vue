<!-- One navigation item in a base nav -->

<template lang='pug'>
component(
	:is='element'
	@keydown='onKeydown'
	@click='onClick'
	@focusout='onBlur'
)
	smart-link.vue-nav-item(
		:to='url'
		v-bind='smartLinkProps'
		ref='smartLinkRef'
	)
		slot(
			:active='index == activeSubnavIndex'
		)

</template>

<!-- ––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––– -->

<script lang='coffee'>
import emitter from 'tiny-emitter/instance'
import { isInternal } from 'vue-routing-anchor-parser'
HTMLElement = window?.HTMLElement || Object # Define HTMLElement for SSG

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

		# By default, the smart-link receives keyboard focus.  If you want an element inside the slot
		# to receive keyboard focus, then pass in a querySelector string.
		focusElement:
			type: String

		# What element to wrap this component in.
		element:
			type: String
			default: 'div'

	computed:
		# Injected from vue-nav
		id: -> @baseNavInject.id
		activeSubnavIndex: -> @baseNavInject.activeSubnavIndex
		focusedItemIndex: -> @baseNavInject.focusedItemIndex
		enableArrowKeys: -> @baseNavInject.enableArrowKeys
		keyboardOrientation: -> @baseNavInject.keyboardOrientation

		# Other
		isInternalUrl: -> if @url? then isInternal(@url) else false

		# Props for the smart-link component
		smartLinkProps: ->
			class: @classes
			role: 'menuitem'
			'data-vue-nav-item-index': @index
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
		# console.log 'vue-nav-item mounted', @$el.innerText
		# Emit event, so vue-nav knows how many items it has
		@$nextTick -> @sendEvent('mounted')

	beforeDestroy: ->
		@sendEvent('destroyed')

	methods:
		
		sendEvent: (type) ->
			# console.log 'vue-nav-item', @id, 'sendEvent', type
			emitter.emit 'vue-nav-item', {
				type
				id: @id
				index: @index
				focusElement: @getFocusElement()
			}

		# Pointer events
		onClick: (event) ->
			return if !!@url
			@sendEvent('click')
			event.stopPropagation()

		onBlur: (event) ->
			@sendEvent('blur')
			event.stopPropagation()

		# Key events
		onKeydown: (event) ->
			# console.log 'onKeydown', @id, event.keyCode, @keyboardOrientation
			switch event.keyCode
				when keycodes.SPACE, keycodes.RETURN, @keycodeReturnArrow
					@sendEvent('returnkey')
					# Don't prevent default, in case we hit return on a nav link.
				when keycodes.ESC, @keycodeEscArrow
					@sendEvent('esckey')
					event.stopPropagation()
					event.preventDefault()
				when @keycodeNext
					@sendEvent('nextkey')
					event.stopPropagation()
					event.preventDefault()
				when @keycodePrev
					@sendEvent('prevkey')
					event.preventDefault()
					event.stopPropagation()
				when @keycodeNullArrow1, @keycodeNullArrow2
					# Stop propagation because these keys might be bound in a parent base-nav and do unwanted things
					event.stopPropagation()
					event.preventDefault()

		# Get the DOM element that should receive keyboard focus.
		# This is a method instead of a computed prop so it's called just in time and returns accurate elements.
		getFocusElement: -> 
			return @$el.querySelector(@focusElement) if @focusElement
			return @$refs.smartLinkRef.$el || @$refs.smartLinkRef

	watch:
		focusedItemIndex: ->
			if @focusedItemIndex == @index
				# console.log 'vue-nav-item', @id, @$el.innerText, 'focusing self'
				@getFocusElement().focus()


</script>

<!-- ––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––– -->

<style lang='stylus' scoped>



</style>
