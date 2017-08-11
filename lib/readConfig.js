var fs = require('fs')
var path = require('path')
var assert = require('assert')
var ref = require('./logger')
var parseNested = require('./parseNested')

var log = ref.log
var projectRoot = path.normalize(path.join(__dirname, '/../'))
var defaultMime = projectRoot + 'mime.types'
var defaultConf = projectRoot + 'freshenrc-example'

function readMimeTypes(mimeTypesFileName, next) {
  return fs.readFile(mimeTypesFileName, function(err, data) {
    if (err) {
      return next(err)
    }
    var result = {}
    var ref1 = data.toString().split(/[\r\n]+/)
    for (var i = 0, len = ref1.length; i < len; i++) {
      var line = ref1[i]
      if (!line) {
        continue
      }
      var ref2 = line.split(/\s{2,}/)
      var type = ref2[0]
      var suffixes = ref2[1]
      if (!suffixes) {
        continue
      }
      var ref3 = suffixes.split(/\s+/)
      for (var j = 0, len1 = ref3.length; j < len1; j++) {
        result[ref3[j]] = type
      }
    }
    return next(0, result)
  })
}

function wsStringToArray(wsString) {
  if (typeof wsString === 'string') {
    return wsString.split(/\s+/)
  }
  return wsString
}

function strArrayToRegexArray(srArray, suffix) {
  suffix = suffix || ''
  var expr, i, len, ref1, result
  result = []
  ref1 = wsStringToArray(srArray)
  if (ref1.length === 0) return [/.*/]
  for (i = 0, len = ref1.length; i < len; i++) {
    expr = ref1[i]
    if (typeof expr === 'string') {
      result.push(new RegExp(expr + suffix, 'i'))
    } else {
      result.push(expr)
    }
  }
  return result
}

module.exports = function readConfig(configFileName, next) {
  var ensureConfigPresent
  ensureConfigPresent = function(next) {
    return fs.stat(configFileName, function(err) {
      if (err) {
        if (err.code !== 'ENOENT') return next(err)
        log('Creating ' + configFileName + ' from ' + defaultConf)
        return fs.readFile(defaultConf, function(err, data) {
          if (err) {
            return next(err)
          }
          return fs.writeFile(configFileName, data, function(err) {
            if (err) {
              return next(err)
            }
            return next(0, 1)
          })
        })
      }
      return next(0)
    })
  }
  ensureConfigPresent(function(err, created) {
    if (err) {
      return next(err)
    }
    fs.readFile(configFileName, function(err, configData) {
      if (err) {
        return next(err)
      }
      var configObj
      configObj = parseNested(configData.toString()) || {}
      assert(
        configObj.report && configObj.report.change,
        'Config: Need report.change in config file'
      )
      assert(
        configObj.build && configObj.build.command && configObj.build.deps,
        'Config: Need build.command and build.deps'
      )
      if (!configObj.port) {
        log('Using default port 2000')
        configObj.port = 2000
      }
      configObj.port = parseInt(configObj.port, 10)
      readMimeTypes(configObj.mimeTypesFile || defaultMime, function(
        err,
        mimeTypes
      ) {
        var event, extension
        if (err) {
          return next(err)
        }
        configObj.mimeTypes = mimeTypes
        configObj.mimeAdd || (configObj.mimeAdd = {})
        for (extension in configObj.mimeAdd) {
          configObj.mimeTypes[extension] = configObj.mimeAdd[extension]
        }
        if (!configObj.root) {
          configObj.root = './'
        }

        for (event in configObj.report) {
          configObj.report[event] = strArrayToRegexArray(
            configObj.report[event],
            '$'
          )
        }
        configObj.report.change.push(
          new RegExp(configFileName.replace(/^\./g, '\\.') + '$')
        )
        configObj.build.deps = strArrayToRegexArray(configObj.build.deps, '$')
        configObj.exclude = strArrayToRegexArray(configObj.exclude)

        // defaults
        configObj.load = configObj.load || {}
        if (typeof configObj.delay === 'undefined') configObj.delay = 150
        if (typeof configObj.color === 'undefined') configObj.color = true
        if (typeof configObj.retries === 'undefined') configObj.retries = 20

        fs.realpath(path.normalize(configObj.root), {}, function(
          err,
          realPath
        ) {
          configObj.root = realPath
          if (err) {
            return next(err)
          }
          return next(0, configObj, created)
        })
      })
    })
  })
}
