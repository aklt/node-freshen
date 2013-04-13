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

parseCSON = (str) ->
  return (new Function coffee.compile "return {\n#{str.replace /^/gm, '  '}}" \
  , bare: 1)()

readCSON = (filename, next) ->
  fs.readFile filename, (err, configData) ->
    if err
      return next err
    next 0, (parseCSON configData.toString()) or {}

readConfig = (configFileName, next) ->

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

    readCSON configFileName, (err, configObj) ->
      if err
        return next err

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
          m = /^(.*?)\/[^\/]+$/.exec configFileName
          if m
            configObj.root = m[1]
          else
            configObj.root = './'

        if not configObj.path
          configObj.path = {}

        if not configObj.hasOwnProperty 'inject'
          configObj.inject = true

        for event of configObj.report
          configObj.report[event] = srArrayToRegexArray configObj.report[event]

        configObj.report.change.push new RegExp "#{configFileName.replace \
                                                   /^\./g, '\\.'}$"
        configObj.build.deps = srArrayToRegexArray configObj.build.deps
        fs.realpath path.normalize(configObj.root), {}, (err, realPath) ->
          configObj.root = path.resolve realPath
          if err
            return next err

          if not configObj.path.watch
            configObj.path.watch = configObj.root

          if not configObj.path.serve
            configObj.path.serve = configObj.root

          configObj.path.watchFull = path.resolve configObj.path.watch
          configObj.path.serveFull = path.resolve configObj.path.serve

          next 0, configObj

readDaemonConfig = (daemonConfigFile, next) ->
  readCSON daemonConfigFile, (err, confObj) ->
    if err
      return next err
    assert confObj.dirs and confObj.dirs.length > 0, \
      "Expected a list of dirs in the .freshend file"
    count = confObj.dirs.length
    noFreshenRc = []
    for dir in confObj.dirs
      do (dir) ->
        filename = "#{dir}/.freshenrc"
        fs.exists filename, (exists) ->
          if not exists
            noFreshenRc.push dir
          count -= 1
          if count == 0
            if noFreshenRc.length > 0
              return next "No .freshenrc file in:\n  #{noFreshenRc.join '\n  '}\n"
            next 0, confObj

module.exports = {readConfig, readDaemonConfig}
