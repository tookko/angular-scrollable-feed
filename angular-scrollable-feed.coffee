angular.module 'scrollableFeed', []

.directive 'scrollableFeed', ['$timeout', '$document', '$window', ($timeout, $document, $window) ->

  compile: (element) ->

    getBrowserScrollBarWidth = ->
      outer = $document.find('body').prepend('<div/>').children().eq(0)
      outer.css visibility: 'hidden', width: '100px', overflow: 'scroll'
      inner = outer.append('<div/>').children()
      inner.css width: '100%'
      offset = inner.prop('offsetWidth') - outer.prop('offsetWidth')
      do outer.remove
      return offset

    unless element.css('position') == 'absolute' then element.css position: 'relative'
    element.children().eq(0).children().eq(0).css right: do getBrowserScrollBarWidth + 'px'
    return this.link

  controller: ($scope) ->
    unless angular.isDefined $scope.autoHide then $scope.autoHide = true
    unless angular.isDefined $scope.autoScroll then $scope.autoScroll = true
    $scope.dragging = false
    $scope.offset = 0
    $scope.thumbSize = 20
    $scope.thumbTop = 0
    $scope.bottom = 1
    $scope.visibleHeight = 0
    $scope.position = 0
    $scope.hidden = $scope.autoHide
    $scope.frozen = not $scope.autoScroll

    $scope.resizeScrollBar = ->
      scaledHeight = Math.round $scope.visibleHeight / $scope.bottom * $scope.visibleHeight
      $scope.thumbSize = Math.max scaledHeight, 20
      $scope.thumbTop = Math.round $scope.position / $scope.bottom * ($scope.visibleHeight - $scope.thumbSize + scaledHeight)

    $scope.scrollToBottom = ->
      $scope.position = $scope.bottom - $scope.visibleHeight

    $scope.freeze = ->
      $scope.frozen = true

    $scope.unfreeze = ->
      if $scope.autoScroll
        $scope.frozen = false
        $scope.position = $scope.bottom - $scope.visibleHeight

    $scope.hideScrollBar = ->
      if $scope.autoHide then $scope.hidden = true

    $scope.showScrollBar = ->
      if $scope.visibleHeight < $scope.bottom then $scope.hidden = false

    $scope.atBottom = () ->
      return $scope.position + $scope.visibleHeight == $scope.bottom

  restrict: 'A'
  scope:
    autoHide: '=?'
    autoScroll: '=?'
  transclude: true
  templateUrl: 'angular-scrollable-feed/angular-scrollable-feed.html'
  link: (scope, element) ->
    timer = null
    dragStart = 0
    viewport = element.children().eq 0
    content = viewport.children().eq 0
    scrollbar = viewport.children().eq 1
    track = scrollbar.children().eq 0
    thumb = track.children().eq 0

    resetDimensions = ->
      scope.visibleHeight = Number(content.prop 'clientHeight')
      scope.bottom = Number(content.prop 'scrollHeight')
      unless scope.autoHide or element.css 'paddingRight'
        content.css paddingRight: '8px'
      scope.$apply scope.resizeScrollBar

    releaseThumb = ($event) ->
      if scope.dragging and $event.button == 0
        $timeout ->
          scope.dragging = false
        if do scope.atBottom then do scope.unfreeze
        do hideWithDelay

    dragThumb = ($event) ->
      delta = Number($event.pageY) - dragStart
      oldPosition = scope.position
      if scope.dragging
        scope.$apply ->
          scope.position += Math.round delta * Number(content.prop 'scrollHeight') / scope.visibleHeight
        if oldPosition != scope.position then dragStart = Number $event.pageY
        do $event.stopPropagation
        do $event.preventDefault

    scrollContent = ->
      unless scope.dragging then scope.$apply ->
        scope.position = content.prop 'scrollTop'
        unless do scope.atBottom then do scope.freeze

    clickViewport = ($event) ->
      if $event.button == 0 and not scope.dragging then $timeout ->
        unless do $window.getSelection().toString
          do scope.unfreeze
          do scope.hideScrollBar

    releaseOnPaste = ->
      do $window.getSelection().empty
      scope.$apply ->
        do scope.unfreeze
        do scope.hideScrollBar

    showWithDelay = ->
      if timer then $timeout.cancel timer
      timer = $timeout ->
        do scope.showScrollBar
        timer = null
      , 200

    hideWithDelay = ->
      if timer then $timeout.cancel timer
      timer = $timeout ->
        if do scope.atBottom and not scope.dragging then do scope.hideScrollBar
        timer = null
      , 500

    thumbDown = ($event) ->
      if $event.button == 0
        scope.$apply ->
          scope.dragging = true
        dragStart = Number $event.pageY
        do scope.freeze
        do $event.stopPropagation

    paginate = ($event) ->
      if $event.button == 0
        do scope.freeze
        scope.$apply ->
          if $event.offsetY < scope.thumbTop
            scope.position -= scope.visibleHeight
          else
            scope.position += scope.visibleHeight
        if do scope.atBottom then do scope.unfreeze
        do $event.stopPropagation

    selectContent = ($event) ->
      if $event.button == 0
        do scope.freeze

    clickScrollbar = ($event) ->
      if $event.button == 0 then do $event.stopPropagation

    scope.$watch 'position', ->
      scope.position = Math.max (Math.min scope.position, Number(content.prop 'scrollHeight') - scope.visibleHeight), 0
      content.prop 'scrollTop', scope.position
      do scope.resizeScrollBar
      if not scope.dragging and do scope.atBottom
        do scope.hideScrollBar
      else
        do scope.showScrollBar

    scope.$watch ->
      scope.bottom = Number(content.prop 'scrollHeight')
      scope.visibleHeight = Number(content.prop 'clientHeight')
      do scope.resizeScrollBar
      not scope.frozen and not scope.dragging and not do scope.atBottom
    , ->
      do scope.unfreeze

    $document.on 'paste', releaseOnPaste
    $document.on 'mouseup', releaseThumb
    $document.on 'mousemove', dragThumb
    viewport.on 'resize', resetDimensions
    viewport.on 'click', clickViewport
    content.on 'scroll', scrollContent
    content.on 'mousedown', selectContent
    scrollbar.on 'click', clickScrollbar
    scrollbar.on 'mouseover', showWithDelay
    scrollbar.on 'mouseleave', hideWithDelay
    track.on 'mousedown', paginate
    thumb.on 'mousedown', thumbDown

    scope.$on '$destroy', ->
      if timer then $timeout.cancel timer
      $document.off 'paste', releaseOnPaste
      $document.off 'mouseup', releaseThumb
      $document.off 'mousemove', dragThumb
      viewport.off 'resize', resetDimensions
      viewport.off 'click', clickViewport
      content.off 'scroll', scrollContent
      content.off 'mousedown', selectContent
      scrollbar.off 'click', clickScrollbar
      scrollbar.off 'mouseover', showWithDelay
      scrollbar.off 'mouseleave', hideWithDelay
      track.off 'mousedown', paginate
      thumb.off 'mousedown', thumbDown

    $timeout ->
      do resetDimensions
      do scope.unfreeze
      do scope.hideScrollBar
]
