fs     = require 'fs'
path   = require 'path'
assert = require 'assert'
coffee = require 'coffee-script'

{log, warn}   = require './logger'

projectRoot = path.normalize "#{__dirname}/../"
defaultMime = projectRoot + 'mime.types'
defaultConf = projectRoot + 'freshenrc-example'
userConf    = process.env.HOME + '/.freshenrc'

readMimeTypes = (mimeTypesFileName, next) ->
  fs.readFile mimeTypesFileName, (err, data) ->
    if err
      return next err
    result = {}
    for line in data.toString().split /[\r\n]+/
      if not line
        continue
      [type, suffixes] = line.split /\s{2,}/
      if not suffixes
        continue
      for suffix in suffixes.split /\s+/
        result[suffix] = type
    next 0, result

parseCSON = (str) ->
  return (new Function coffee.compile "return {\n#{str.replace /^/gm, '  '}}" \
  , bare: 1)()

wsStringToArray = (wsString) ->
  if typeof wsString == 'string'
    return wsString.split /\s+/
  return wsString

srArrayToRegexArray = (srArray) ->
  result = []
  for expr in wsStringToArray srArray
    if typeof expr == 'string'
      result.push new RegExp "#{expr}$", "i"
    else
      result.push expr
  return result

module.exports = readConfig = (configFileName, next) ->

  ensureConfigFilePresence = (next) ->
    fs.exists configFileName, (exists) ->
      if not exists
        conf = userConf
        return fs.exists conf, (exists) ->
          if not exists
            conf = defaultConf
          log "Creating #{configFileName} from #{conf}"
          fs.readFile conf, (err, data) ->
            if err
              return next err
            fs.writeFile configFileName, data, (err) ->
              if err
                return next err
              next 0
      next 0

  ensureConfigFilePresence (err) ->
    if err
      return next err

    fs.readFile configFileName, (err, configData) ->
      if err
        return next err
      configObj = (parseCSON configData.toString()) || {}

      assert configObj.report and configObj.report.change, \
        "Config: Need report.change in config file"
      assert configObj.build and configObj.build.command and \
        configObj.build.deps, "Config: Need build.command and build.deps"
      assert configObj.url, "Config: Need url field in config file"

      readMimeTypes configObj.mimeTypesFile or defaultMime, (err, mime) ->
        if err
          return next err
        configObj.mime = mime
        if not configObj.root
          configObj.root = './'
        if not configObj.hasOwnProperty 'inject'
          configObj.inject = true
        for event of configObj.report
          configObj.report[event] = srArrayToRegexArray configObj.report[event]
        configObj.report.change.push new RegExp "#{configFileName.replace \
                                                   /^\./g, '\\.'}$"
        configObj.build.deps = srArrayToRegexArray configObj.build.deps
        fs.realpath path.normalize(configObj.root), {}, (err, realPath) ->
          configObj.root = realPath
          if err
            return next err
          next 0, configObj
