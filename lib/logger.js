var esc = String.fromCharCode(27)
var colorInfo = ''
var colorLog = ''
var colorNote = ''
var colorWarn = ''
var colorError = ''
var colorEnd = ''
var log = console.log
var _logBuffer = []

function msgFun(msg, conf) {
  var stamp
  // TODO Configurable, relative to previous time or not at all
  stamp = new Date().toLocaleTimeString() + ' '
  if (conf && conf.prefix) {
    stamp += conf.prefix
  }
  msg = msg.replace(/[\r\n]+$/, '')
  _logBuffer.push([stamp, msg])
  return (
    '' +
    msg
      .replace(/^/gm, conf.color)
      .replace(/$/gm, colorEnd)
      .replace(/^/gm, stamp)
  )
}

module.exports = {
  loggerConf: function(conf) {
    if (conf.color) {
      colorInfo = esc + '[0;33m'
      colorNote = esc + '[0;32m'
      colorLog = esc + '[0;36m'
      colorWarn = esc + '[0;35m'
      colorError = esc + '[0;31m'
      colorEnd = esc + '[0m'
    } else {
      colorInfo = ''
      colorNote = ''
      colorLog = ''
      colorWarn = ''
      colorError = ''
      colorEnd = ''
    }
  },
  loggerBuffer: _logBuffer,
  info: function(msg, conf) {
    conf ||
      (conf = {
        prefix: ''
      })
    conf.color = colorInfo
    return log(msgFun(msg, conf))
  },
  note: function(msg, conf) {
    conf ||
      (conf = {
        prefix: ''
      })
    conf.color = colorNote
    return log(msgFun(msg, conf))
  },
  log: function(msg, conf) {
    conf ||
      (conf = {
        prefix: ''
      })
    conf.color = colorLog
    return log(msgFun(msg, conf))
  },
  warn: function(msg, conf) {
    conf ||
      (conf = {
        prefix: ''
      })
    conf.color = colorWarn
    conf.prefix = 'WARNING ' + conf.prefix
    return log(msgFun(msg, conf))
  },
  error: function(msg, conf) {
    conf ||
      (conf = {
        prefix: ''
      })
    conf.color = colorError
    conf.prefix = 'ERROR ' + conf.prefix
    return log(msgFun(msg, conf))
  }
}
