gulp = require 'gulp'
concat = require 'gulp-concat'
util = require 'gulp-util'
coffee = require 'gulp-coffee'
jade = require 'gulp-jade'
stylus = require 'gulp-stylus'
del = require 'del'
sort = require 'gulp-angular-filesort'
es = require 'event-stream'
templateCache = require 'gulp-angular-templatecache'

# Default: build entire app
gulp.task 'default', ['coffee', 'templates', 'css'], ->
  console.log 'Building Burning app in ./public'

# Brew some coffee
gulp.task 'coffee', ->
  es.merge(
    gulp.src 'src/angular-scrollable-feed.coffee'
    .pipe coffee bare: true
    gulp.src 'src/angular-scrollable-feed.jade'
    .pipe jade pretty: true
    .pipe templateCache
      module: 'scrollableFeed'
      root: 'angular-scrollable-feed'
      transformUrl: (url) -> url.replace /\.jade$/, '.html')
  .pipe do sort
  .pipe concat 'angular-scrollable-feed.js'
  .pipe gulp.dest '.'
  .on 'error', util.log

# Compile stylesheets
gulp.task 'css', ->
  gulp.src 'src/angular-scrollable-feed.styl'
  .pipe stylus()
  .pipe gulp.dest '.'
  .on 'error', util.log

# Compile documents
gulp.task 'templates', ->
  gulp.src 'src/index.jade'
  .pipe jade pretty: true
  .pipe gulp.dest './demo'
  .on 'error', util.log

gulp.task 'demo', ['coffee', 'css', 'templates'], ->
  gulp.src [
    'angular-scrollable-feed.css',
    'angular-scrollable-feed.js'
  ]
  .pipe gulp.dest './demo'
  .on 'error', util.log

# Create dist
gulp.task 'dist', ['coffee', 'css', 'templates']

# clean up public directory
gulp.task 'clean', (cb) ->
  del ['demo', 'angular-scrollable-feed.css', 'angular-scrollable-feed.js'], cb
