angular.module('scrollableFeed', []).directive('scrollableFeed', [
  '$timeout', '$document', '$window', function($timeout, $document, $window) {
    return {
      compile: function(element) {
        var getBrowserScrollBarWidth;
        getBrowserScrollBarWidth = function() {
          var inner, offset, outer;
          outer = $document.find('body').prepend('<div/>').children().eq(0);
          outer.css({
            visibility: 'hidden',
            width: '100px',
            overflow: 'scroll'
          });
          inner = outer.append('<div/>').children();
          inner.css({
            width: '100%'
          });
          offset = inner.prop('offsetWidth') - outer.prop('offsetWidth');
          outer.remove();
          return offset;
        };
        if (element.css('position') !== 'absolute') {
          element.css({
            position: 'relative'
          });
        }
        element.children().eq(0).children().eq(0).css({
          right: getBrowserScrollBarWidth() + 'px'
        });
        return this.link;
      },
      controller: function($scope) {
        if (!angular.isDefined($scope.autoHide)) {
          $scope.autoHide = true;
        }
        if (!angular.isDefined($scope.autoScroll)) {
          $scope.autoScroll = true;
        }
        $scope.dragging = false;
        $scope.offset = 0;
        $scope.thumbSize = 20;
        $scope.thumbTop = 0;
        $scope.bottom = 1;
        $scope.visibleHeight = 0;
        $scope.position = 0;
        $scope.hidden = $scope.autoHide;
        $scope.locked = !$scope.autoScroll;
        $scope.resizeScrollBar = function() {
          var scaledHeight;
          scaledHeight = Math.round($scope.visibleHeight / $scope.bottom * $scope.visibleHeight);
          $scope.thumbSize = Math.max(scaledHeight, 20);
          return $scope.thumbTop = Math.round($scope.position / $scope.bottom * ($scope.visibleHeight - $scope.thumbSize + scaledHeight));
        };
        $scope.scrollToBottom = function() {
          return $scope.position = $scope.bottom - $scope.visibleHeight;
        };
        $scope.lock = function() {
          return $scope.locked = true;
        };
        $scope.unlock = function() {
          if ($scope.autoScroll) {
            $scope.locked = false;
            return $scope.position = $scope.bottom + $scope.visibleHeight;
          }
        };
        $scope.hideScrollBar = function() {
          if ($scope.autoHide) {
            return $scope.hidden = true;
          }
        };
        $scope.showScrollBar = function() {
          if ($scope.visibleHeight < $scope.bottom) {
            return $scope.hidden = false;
          }
        };
        return $scope.atBottom = function() {
          return $scope.position + $scope.visibleHeight >= $scope.bottom - 1;
        };
      },
      restrict: 'A',
      scope: {
        autoHide: '=?',
        autoScroll: '=?'
      },
      transclude: true,
      templateUrl: 'angular-scrollable-feed/angular-scrollable-feed.html',
      link: function(scope, element) {
        var clickScrollbar, clickViewport, content, debounce, deferred, dragStart, dragThumb, hideWithDelay, paginate, releaseOnPaste, releaseThumb, resetDimensions, scrollContent, scrollbar, selectContent, showWithDelay, thumb, thumbDown, timer, track, viewport;
        timer = null;
        deferred = null;
        dragStart = 0;
        viewport = element.children().eq(0);
        content = viewport.children().eq(0);
        scrollbar = viewport.children().eq(1);
        track = scrollbar.children().eq(0);
        thumb = track.children().eq(0);
        debounce = function(callback, delay) {
          var args, context;
          context = this;
          args = arguments;
          if (deferred) {
            $timeout.cancel(deferred);
          }
          return deferred = $timeout(function() {
            deferred = null;
            return callback.apply(context, args);
          }, delay);
        };
        resetDimensions = function() {
          scope.visibleHeight = Number(content.prop('clientHeight'));
          scope.bottom = Number(content.prop('scrollHeight'));
          if (!(scope.autoHide || element.css('paddingRight'))) {
            content.css({
              paddingRight: '8px'
            });
          }
          return scope.$apply(scope.resizeScrollBar);
        };
        releaseThumb = function($event) {
          if (scope.dragging && $event.button === 0) {
            $timeout(function() {
              return scope.dragging = false;
            });
            if (scope.atBottom()) {
              scope.unlock();
            }
            return hideWithDelay();
          }
        };
        dragThumb = function($event) {
          var delta, oldPosition;
          delta = Number($event.pageY) - dragStart;
          oldPosition = scope.position;
          if (scope.dragging) {
            scope.$apply(function() {
              return scope.position += Math.round(delta * Number(content.prop('scrollHeight')) / scope.visibleHeight);
            });
            if (oldPosition !== scope.position) {
              dragStart = Number($event.pageY);
            }
            $event.stopPropagation();
            return $event.preventDefault();
          }
        };
        scrollContent = function() {
          if (!scope.dragging) {
            return debounce(function() {
              return scope.position = content.prop('scrollTop');
            }, 20);
          }
        };
        clickViewport = function($event) {
          if ($event.button === 0 && !scope.dragging) {
            return $timeout(function() {
              if (!$window.getSelection().toString()) {
                scope.unlock();
                return scope.hideScrollBar();
              }
            });
          }
        };
        releaseOnPaste = function() {
          $window.getSelection().empty();
          return scope.$apply(function() {
            scope.unlock();
            return scope.hideScrollBar();
          });
        };
        showWithDelay = function() {
          if (timer) {
            $timeout.cancel(timer);
          }
          return timer = $timeout(function() {
            scope.showScrollBar();
            return timer = null;
          }, 200);
        };
        hideWithDelay = function() {
          if (timer) {
            $timeout.cancel(timer);
          }
          return timer = $timeout(function() {
            if (scope.atBottom() && !scope.dragging) {
              scope.hideScrollBar();
            }
            return timer = null;
          }, 500);
        };
        thumbDown = function($event) {
          if ($event.button === 0) {
            scope.$apply(function() {
              return scope.dragging = true;
            });
            dragStart = Number($event.pageY);
            scope.lock();
            $event.stopPropagation();
            return $event.preventDefault();
          }
        };
        paginate = function($event) {
          if ($event.button === 0) {
            scope.lock();
            scope.$apply(function() {
              if ($event.offsetY < scope.thumbTop) {
                return scope.position -= scope.visibleHeight;
              } else {
                return scope.position += scope.visibleHeight;
              }
            });
            if (scope.atBottom()) {
              scope.unlock();
            }
            return $event.stopPropagation();
          }
        };
        selectContent = function($event) {
          if ($event.button === 0) {
            return scope.lock();
          }
        };
        clickScrollbar = function($event) {
          if ($event.button === 0) {
            return $event.stopPropagation();
          }
        };
        scope.$watch('position', function() {
          scope.position = Math.max(Math.min(scope.position, Number(content.prop('scrollHeight')) - scope.visibleHeight), 0);
          content.prop('scrollTop', scope.position);
          if (!scope.dragging && scope.atBottom()) {
            return scope.hideScrollBar();
          } else {
            scope.showScrollBar();
            return scope.lock();
          }
        });
        scope.$watch(function() {
          scope.bottom = Number(content.prop('scrollHeight'));
          scope.visibleHeight = Number(content.prop('clientHeight'));
          scope.resizeScrollBar();
          return !scope.locked && !scope.dragging && !scope.atBottom();
        }, function() {
          return scope.unlock();
        });
        $document.on('paste', releaseOnPaste);
        $document.on('mouseup', releaseThumb);
        $document.on('mousemove', dragThumb);
        viewport.on('resize', resetDimensions);
        viewport.on('click', clickViewport);
        content.on('scroll', scrollContent);
        content.on('mousedown', selectContent);
        scrollbar.on('click', clickScrollbar);
        scrollbar.on('mouseover', showWithDelay);
        scrollbar.on('mouseleave', hideWithDelay);
        track.on('mousedown', paginate);
        thumb.on('mousedown', thumbDown);
        scope.$on('$destroy', function() {
          if (timer) {
            $timeout.cancel(timer);
          }
          $document.off('paste', releaseOnPaste);
          $document.off('mouseup', releaseThumb);
          $document.off('mousemove', dragThumb);
          viewport.off('resize', resetDimensions);
          viewport.off('click', clickViewport);
          content.off('scroll', scrollContent);
          content.off('mousedown', selectContent);
          scrollbar.off('click', clickScrollbar);
          scrollbar.off('mouseover', showWithDelay);
          scrollbar.off('mouseleave', hideWithDelay);
          track.off('mousedown', paginate);
          return thumb.off('mousedown', thumbDown);
        });
        return $timeout(function() {
          resetDimensions();
          scope.unlock();
          return scope.hideScrollBar();
        });
      }
    };
  }
]);

angular.module("scrollableFeed").run(["$templateCache", function($templateCache) {$templateCache.put("angular-scrollable-feed/angular-scrollable-feed.html","\n<div class=\"asf-viewport\"><span ng-transclude=\"ng-transclude\" class=\"asf-content\"></span><span class=\"asf-sb\">\n    <div ng-hide=\"hidden\" class=\"asf-sb-track\">\n      <div ng-hide=\"hidden\" ng-class=\"dragging ? &quot;asf-sb-thumb-active&quot; : &quot;&quot;\" ng-style=\"{ &quot;height&quot;: thumbSize + &quot;px&quot;, &quot;transform&quot;: &quot;translateY(&quot; + thumbTop + &quot;px)&quot; }\" class=\"asf-sb-thumb\"></div>\n    </div></span></div>");}]);