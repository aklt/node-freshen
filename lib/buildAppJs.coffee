fs = require 'fs'
glob = require 'glob'
coffee = require 'coffee-script'

getCoffee = (filePath) ->
  cs = '' + fs.readFileSync filePath
  js = coffee.compile cs, bare: true
  return js

_result = null

module.exports.__defineGetter__ 'script', ->
  if not _result
    _result = appJs()
  return _result

appJs = ->
  _result = "// Made by buildAppJs.coffee #{Date()}. Do not edit.\n"
  _result += fs.readFileSync "#{__dirname}/../src/app.header.js"
  files = glob.sync "#{__dirname}/../src/app[A-Z0-9]*"
  for pathname in files
    cs = '' + fs.readFileSync pathname
    _result += cs = coffee.compile cs, bare: true
  _result += getCoffee "#{__dirname}/../src/app.coffee"
  _result += '' + fs.readFileSync "#{__dirname}/../src/app.footer.js"
  return _result
