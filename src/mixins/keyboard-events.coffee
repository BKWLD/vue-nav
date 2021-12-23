# Enable keyboard navigation for base-menu.
# Based off this accessible nav example: https://www.w3.org/TR/wai-aria-practices/examples/menubar/menubar-1/menubar-1.html

export default
	props:
		# Binds the arrow keys to match the visual layout
		keyboardOrientation:
			type: String
			default: 'horizontal'
			validator: (val) -> val in ['horizontal', 'vertical']

		# If true, use arrow keys to move between nav items, and only the focused item is tabbable.
		# If false, use regular tab navigation.
		enableArrowKeys:
			type: Boolean
			default: true

	data: ->
		focusedItemIndex: 0

	methods:

		##################################################################
		## EVENT HANDLERS

		# onBlur: (index) -> @$defer =>
		# 	return

		onReturnKey: (event, index) ->
			return if @activeSubnavIndex == index
			# console.log 'onReturnKey', {id: @id, index}
			# If no subnav, then assume it's a link.  Stop propagation but don't prevent default.
			if !@subnavFocusElements[index]
				# console.log 'onReturnKey 1'
				return event.stopPropagation()
			event.stopPropagation()
			event.preventDefault()
			# Else, open the subnav.
			# console.log 'onReturnKey 2'
			@setActiveSubnavIndex index
			@setFocusToSubnav(index)

		##################################################################
		## FOCUS MOVERS

		setFocustoNextItem: (oldIndex) ->
			index = oldIndex + 1
			index = (index + @navFocusElements.length) % @navFocusElements.length
			# console.log @id, 'setFocustoNextItem', {oldIndex, index}
			@setFocusToIndex index

		setFocustoPrevItem: (oldIndex) ->
			index = oldIndex - 1
			index = (index + @navFocusElements.length) % @navFocusElements.length
			@setFocusToIndex index

		setFocusToIndex: (index) ->
			# console.log @id, 'setFocusToIndex', index, el.innerText, el
			@focusedItemIndex = index

		setFocusToSubnav: (index) -> @$nextTick => @$nextTick =>
			# console.log 'vue-nav', @id, 'setFocusToSubnav', index, @subnavFocusElements[index]
			if @subnavFocusElements[index]?.focus?
				@subnavFocusElements[index]?.focus()