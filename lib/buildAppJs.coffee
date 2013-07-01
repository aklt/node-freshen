fs = require 'fs'
glob = require 'glob'
coffee = require 'coffee-script'

getCoffee = (filePath) ->
  cs = '' + fs.readFileSync filePath
  js = coffee.compile cs, bare: true
  return js

result = "// Made by buildAppJs.coffee #{Date()}. Do not edit.\n"
result += fs.readFileSync "#{__dirname}/../src/app.header.js"
result += getCoffee "#{__dirname}/../src/app.coffee"
files = glob.sync "#{__dirname}/../src/app[A-Z]*"
for pathname in files
  cs = '' + fs.readFileSync pathname
  result += cs = coffee.compile cs, bare: true

result += '' + fs.readFileSync "#{__dirname}/../src/app.footer.js"

fs.writeFileSync "#{__dirname}/../lib/app.js", result
