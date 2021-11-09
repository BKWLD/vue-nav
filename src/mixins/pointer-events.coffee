import dimensions from '/assets/vars/dimensions.json'

export default
	props:
		# When true, clicking outside the items and item subnavs will close all items.
		clickOutsideToClose:
			type: Boolean
			default: true

		closeOnScroll:
			type: Boolean
			default: true

	computed:
		closeOnScrollThreshold: -> parseInt(dimensions['header-close-on-scroll-threshold']) or 60

	mounted: ->
		document.addEventListener 'scroll', @onScroll

	beforeDestroy: ->
		document.removeEventListener 'scroll', @onScroll

	watch:
		activeSubnavIndex: -> if @subnavOpen then @scrollYOnOpen = window?.scrollY

	methods:
		onScroll: ->
			return unless @closeOnScroll
			if Math.abs(window?.scrollY - @scrollYOnOpen) > @closeOnScrollThreshold then @setActiveSubnavIndex -1

		onOverlayClick: (event) ->
			# console.log 'onOverlayClick', @navId
			return unless @clickOutsideToClose
			event.stopPropagation()
			@closeSubnav()
			@closeUs()
