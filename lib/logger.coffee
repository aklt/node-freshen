
esc = String.fromCharCode 27
colorInfo  = ''
colorLog   = ''
colorNote  = ''
colorWarn  = ''
colorError = ''
colorEnd   = ''
log = console.log

_logBuffer = []

msgFun = (msg, conf) ->
  stamp = "#{new Date().toLocaleTimeString()} "
  if conf and conf.prefix
    stamp += conf.prefix
  msg = msg.replace /[\r\n]+$/, ''
  _logBuffer.push [stamp, msg]
  return "#{msg.replace(/^/gm, conf.color)
               .replace(/$/gm, colorEnd)
               .replace(/^/gm, stamp)}"

module.exports =
  loggerConf: (conf) ->
    if conf.color
      colorInfo  = esc + '[0;33m'
      colorNote  = esc + '[0;32m'
      colorLog   = esc + '[0;36m'
      colorWarn  = esc + '[0;35m'
      colorError = esc + '[0;31m'
      colorEnd   = esc + '[0m'
    else
      colorInfo  = ''
      colorNote  = ''
      colorLog   = ''
      colorWarn  = ''
      colorError = ''
      colorEnd   = ''
  loggerBuffer: _logBuffer
  info: (msg, conf) ->
    conf or= {prefix: ''}
    conf.color = colorInfo
    log msgFun msg, conf
  note: (msg, conf) ->
    conf or= {prefix: ''}
    conf.color = colorNote
    log msgFun msg, conf
  log: (msg, conf) ->
    conf or= {prefix: ''}
    conf.color = colorLog
    log msgFun msg, conf
  warn: (msg, conf) ->
    conf or= {prefix: ''}
    conf.color = colorWarn
    conf.prefix = "WARNING #{conf.prefix}"
    log msgFun msg, conf
  error: (msg, conf) ->
    conf or= {prefix: ''}
    conf.color = colorError
    conf.prefix = "ERROR #{conf.prefix}"
    log msgFun msg, conf

