
var fs = require('fs')
var path = require('path')
var assert = require('assert')
var ref = require('./logger')
var parseNested = require('./parseNested')

var log = ref.log
var projectRoot = path.normalize(path.join(__dirname, '/../'))
var defaultMime = projectRoot + 'mime.types'
var defaultConf = projectRoot + 'freshenrc-example'

function readMimeTypes (mimeTypesFileName, next) {
  return fs.readFile(mimeTypesFileName, function (err, data) {
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

function wsStringToArray (wsString) {
  if (typeof wsString === 'string') {
    return wsString.split(/\s+/)
  }
  return wsString
}

function strArrayToRegexArray (srArray) {
  var expr, i, len, ref1, result
  result = []
  ref1 = wsStringToArray(srArray)
  for (i = 0, len = ref1.length; i < len; i++) {
    expr = ref1[i]
    if (typeof expr === 'string') {
      result.push(new RegExp(expr + '$', 'i'))
    } else {
      result.push(expr)
    }
  }
  return result
}

module.exports = function readConfig (configFileName, next) {
  var ensureConfigFilePresence
  ensureConfigFilePresence = function (next) {
    return fs.exists(configFileName, function (exists) {
      if (!exists) {
        log('Creating ' + configFileName + ' from ' + defaultConf)
        return fs.readFile(defaultConf, function (err, data) {
          if (err) {
            return next(err)
          }
          return fs.writeFile(configFileName, data, function (err) {
            if (err) {
              return next(err)
            }
            return next(0)
          })
        })
      }
      return next(0)
    })
  }
  ensureConfigFilePresence(function (err) {
    if (err) {
      return next(err)
    }
    fs.readFile(configFileName, function (err, configData) {
      var configObj
      if (err) {
        return next(err)
      }
      configObj = parseNested(configData.toString()) || {}
      assert(configObj.report && configObj.report.change, 'Config: Need report.change in config file')
      assert(configObj.build && configObj.build.command && configObj.build.deps, 'Config: Need build.command and build.deps')
      assert(configObj.url, 'Config: Need url field in config file')
      readMimeTypes(configObj.mimeTypesFile || defaultMime, function (err, mimeTypes) {
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
          configObj.report[event] = strArrayToRegexArray(configObj.report[event])
        }
        configObj.report.change.push(new RegExp((configFileName.replace(/^\./g, '\\.')) + '$'))
        configObj.build.deps = strArrayToRegexArray(configObj.build.deps)
        configObj.load = configObj.load || {}

        fs.realpath(path.normalize(configObj.root), {}, function (err, realPath) {
          configObj.root = realPath
          if (err) {
            return next(err)
          }
          return next(0, configObj)
        })
      })
    })
  })
}
