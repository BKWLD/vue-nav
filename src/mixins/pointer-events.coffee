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


	mounted: -> @addScrollListener()


	beforeDestroy: -> @removeScrollListener()


	watch:
		activeSubnavIndex: -> if @subnavOpen then @scrollYOnOpen = window?.scrollY


	methods:

		addScrollListener: -> 
			document.addEventListener 'scroll', @onScroll
		
		removeScrollListener: -> 
			document.removeEventListener 'scroll', @onScroll

		onScroll: ->
			return unless @closeOnScroll
			if Math.abs(window?.scrollY - @scrollYOnOpen) > @closeOnScrollThreshold
				# console.log 'closeOnScrollThreshold setActiveSubnavIndex', {id: @id}
				@setActiveSubnavIndex -1
