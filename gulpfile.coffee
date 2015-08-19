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
    gulp.src './angular-scrollable-feed.coffee'
    .pipe coffee bare: true
    gulp.src './angular-scrollable-feed.jade'
    .pipe jade pretty: true
    .pipe templateCache
      module: 'scrollableFeed'
      root: 'angular-scrollable-feed'
      transformUrl: (url) -> url.replace /\.jade$/, '.html')
  .pipe do sort
  .pipe concat 'angular-scrollable-feed.js'
  .pipe gulp.dest './dist'
  .on 'error', util.log

# Compile documents
gulp.task 'templates', ->
  gulp.src './index.jade'
  .pipe jade pretty: true
  .pipe gulp.dest './dist'
  .on 'error', util.log

# Compile stylesheets
gulp.task 'css', ->
  gulp.src './angular-scrollable-feed.styl'
  .pipe stylus()
  .pipe gulp.dest './dist'
  .on 'error', util.log

# Copy libs
gulp.task 'libs', ->
  gulp.src './bower_components/**/*.js'
  .pipe gulp.dest './dist/libs'
  .on 'error', util.log

# Create dist
gulp.task 'dist', ['coffee', 'css', 'templates', 'libs']

# clean up public directory
gulp.task 'clean', (cb) ->
  del ['public'], cb
