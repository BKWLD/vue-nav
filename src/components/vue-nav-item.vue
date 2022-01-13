<!-- One navigation item in a base nav -->

<template lang='pug'>
component(
	:is='element'
	@keydown='onKeydown'
	@click='onClick'
	@focusin='onFocus'
	@focusout='onBlur'
)
	component.vue-nav-item(
		:is='innerElement'
		v-bind='smartLinkProps'
		ref='smartLinkRef'
	)
		slot(
			:active='index == activeSubnavIndex'
			:has-subnav='hasSubnav'
		)

</template>

<!-- ––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––– -->

<script lang='coffee'>
import emitter from 'tiny-emitter/instance'
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
	# Inject the variables provided by the vue-nav.
	inject: ['vueNavInject']

	props:
		# Each vue-nav-item must have a unique index.  This determines the
		# keyboard navigation order, and connects each item to its subnav.
		index:
			type: Number

		# If provided, clicking this item takes you to this URL.  
		# If provided, there's no subnav.
		url:
			type: String

		# By default, the '.vue-nav-item' element receives keyboard focus.
		# If you want a different element to receive keyboard focus,
		# (for example, a button that you nested inside it), 
		# then pass in a querySelector string (for example, '.btn')
		focusElement:
			type: String

		# Determines this component's root element.  For example, if you're
		# doing a menu you may want to use 'li'.
		element:
			type: String
			default: 'div'

		# Tells the component that the slot contains a button element.
		# When true, .vue-nav-item won't wrap the slot in a button.  
		# This prevents having a button wrapped inside a button, which is 
		# invalid HTML.
		buttonInside:
			type: Boolean
			default: false

	computed:
		# Injected from vue-nav
		id: -> @vueNavInject.id
		parentId: -> @vueNavInject.parentId
		activeSubnavIndex: -> @vueNavInject.activeSubnavIndex
		focusedItemIndex: -> @vueNavInject.focusedItemIndex
		enableArrowKeys: -> @vueNavInject.enableArrowKeys
		keyboardOrientation: -> @vueNavInject.keyboardOrientation
		subnavFocusElements: -> @vueNavInject.subnavFocusElements

		# Other
		hasSubnav: -> 
			# if @id=='nav-mobile-2' then console.log 'hasSubnav', @subnavFocusElements[@index]
			if @subnavFocusElements?[@index] then true else false

		# Props for the smart-link component
		smartLinkProps: ->
			class: @classes
			role: 'menuitem'
			to: @url
			'data-vue-nav-item-index': @index
			tabindex: @tabindex
			'aria-haspopup': !!@url
			'aria-expanded': @index == @activeSubnavIndex
			# Disable this nav item if it has no url and no subnav.
			# disabled: if (!@url && !@hasSubnav) then true else false
		
		innerElement: ->
			if @url then return 'smart-link'
			if @buttonInside then return 'div'
			return 'button'

		classes: -> [
			if @index == @activeSubnavIndex then 'active' else 'not-active'
			if @hasSubnav then 'has-subnav' else ''
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
		
		# Send an event to the vue-nav
		sendEvent: (type) ->
			# console.log 'sendEvent', @id, type
			emitter.emit 'vue-nav-item', {
				type
				id: @id
				index: @index
				focusElement: @getFocusElement()
			}
		
		# Send an event to the parent vue-nav.
		sendParentEvent: (type) ->
			# console.log 'sendParentEvent', @parentId, type
			emitter.emit 'child-vue-nav-item', {
				type
				id: @parentId
			}

		# Pointer events
		onClick: (event) ->
			return if !!@url
			@sendEvent('click')
			event.stopPropagation()

		onBlur: (event) ->
			@sendEvent('blur')
			event.stopPropagation()

		onFocus: (event) -> 
			# console.log 'onFocus'
			event.stopPropagation()

		# Key events
		onKeydown: (event) ->
			# console.log 'onKeydown', @$el.innerText

			switch event.keyCode

				when keycodes.SPACE, keycodes.RETURN, @keycodeReturnArrow
					event.stopPropagation()
					# Don't prevent default, in case we hit return on a nav link.
					if @hasSubnav then event.preventDefault()
					@sendEvent('returnkey')

				when keycodes.ESC, @keycodeEscArrow
					# console.log 'onKeyDown esc'
					# Escape key is special becuase it emits using the parent vue-nav's ID.
					# Because we need to tell the parent vue-nav instance to close its subnav.
					@sendParentEvent('esckey')
					event.stopPropagation()
					event.preventDefault()

				when @keycodeNext
					event.stopPropagation()
					event.preventDefault()
					@sendEvent('nextkey')

				when @keycodePrev
					event.preventDefault()
					event.stopPropagation()
					@sendEvent('prevkey')

				when @keycodeNullArrow1, @keycodeNullArrow2
					# Stop propagation because these keys might be bound in a parent vue-nav and do unwanted things
					event.stopPropagation()
					event.preventDefault()

		# Get the DOM element that should receive keyboard focus.
		# This is a method instead of a computed prop so it's called just in time and returns accurate elements.
		getFocusElement: -> 

			return @$el.querySelector(@focusElement) if @focusElement
			return @$refs.smartLinkRef.$el || @$refs.smartLinkRef

		# Set focus to focusElement
		setFocusToUs: ->

			el = @getFocusElement()
			el.focus()
			# console.log 'setFocusToUs', el.innerText, el
			# Fix bug where .focus-visible is not added when we hit escape key.
			# el.classList.add('focus-visible')
			# el.setAttribute('data-focus-visible-added', true)

	watch:

		focusedItemIndex: ->
			if @focusedItemIndex == @index
				# console.log 'vue-nav-item', @id, 'focusedItemIndex', @index
				@setFocusToUs()

</script>

<!-- ––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––– -->

<style lang='stylus' scoped>



</style>
