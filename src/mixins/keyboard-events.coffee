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
		keyboardFocusIndex: 0

	methods:

		##################################################################
		## EVENT HANDLERS

		onBlur: (index) -> @$defer =>
			# console.log 'onBlur', document.activeElement
			# Must $defer.  ActiveElement will be `body` if you run immediately or on $nextTick.

			# If activeElement is the body, this usually means we clicked on something (eg .overlay).
			# In this case, do nothing and let the click event do the work.
			return if document.activeElement == document.body

			# If no subnav, then stop.
			subnav = @subnavRefs[index]
			return unless subnav
			focusWithinSubnav = subnav.contains document.activeElement
			return if focusWithinSubnav
			# If focus has left both us and the subnav, then close the subnav.
			@closeSubnav()
			@closeUs()
			# console.log @navId, 'onBlur', {subnav, activeElement: document.activeElement, focusWithinSubnav}

		onReturnKey: (event, index) ->
			# console.log @navId, 'onReturnKey', index
			# If no subnav, then assume it's a link.  Stop propagation but don't prevent default.
			if !@subnavRefs[index]
				console.log 'onReturnKey 1'
				return event.stopPropagation()
			# Else, open the subnav.
			console.log 'onReturnKey 2'
			@setActiveSubnavIndex index, true
			@setFocusToSubnav(index)
			event.stopPropagation()
			event.preventDefault()

		##################################################################
		## FOCUS MOVERS

		setFocustoNextItem: (oldIndex) ->
			index = oldIndex + 1
			index = (index + @navItemRefs.length) % @navItemRefs.length
			@setFocusToIndex index

		setFocustoPrevItem: (oldIndex) ->
			index = oldIndex - 1
			index = (index + @navItemRefs.length) % @navItemRefs.length
			@setFocusToIndex index

		setFocusToIndex: (index) ->
			console.log @navId, 'setFocusToIndex', index
			el = @navItemRefs[index]
			if !el then console.warn("base-nav setFocusToIndex: can't set focus because navItemRefs[#{index}] doesn't exist.")
			@navItemRefs[index]?.focus?()
			@keyboardFocusIndex = index
			# If subnav is open, then close the subnav.
			if @subnavOpen then @closeSubnav()

		setFocusToSubnav: (index) -> @$nextTick =>
			subnavWrap = @subnavRefs[index]

			# Select tabbable elements inside our subnavWrap
			selector = "[data-base-nav-item-index='0']"
			subnavItemSelector = selector
			# ...but don't select elements inside hidden subnavs
			subnavItemSelector += ":not( .base-nav-subnav.not-active #{selector} )"
			# ...and don't select elements nested inside two or more base-navs
			subnavItemSelector += ":not(.#{@navId} .base-nav .base-nav #{selector} )"
			subnavItems = subnavWrap.querySelectorAll(subnavItemSelector)
			# console.log @navId, 'setFocusToSubnav', subnavItems
			return unless subnavItems?.length
			# WIP: Select specific subnavIndex
			# index = (subnavIndex + subnavItems.length) % subnavItems.length
			subnavItems[0].focus()
