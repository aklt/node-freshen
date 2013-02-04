
puts = require('util').puts

esc = String.fromCharCode 27
colorInfo  = ''
colorLog   = ''
colorNote  = ''
colorWarn  = ''
colorError = ''
colorEnd   = ''

msgFun = (msg, conf) ->
  stamp = "#{new Date().toLocaleTimeString()} "
  if conf and conf.prefix
    stamp += conf.prefix
  return "#{msg.replace(/[\r\n]+$/, '')
               .replace(/^/gm, conf.color)
               .replace(/$/gm, colorEnd)
               .replace(/^/gm, stamp)}"

module.exports =
  configure: (conf) ->
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
  info: (msg, conf) ->
    conf or= {prefix: ''}
    conf.color = colorInfo
    puts msgFun msg, conf
  note: (msg, conf) ->
    conf or= {prefix: ''}
    conf.color = colorNote
    puts msgFun msg, conf
  log: (msg, conf) ->
    conf or= {prefix: ''}
    conf.color = colorLog
    puts msgFun msg, conf
  warn: (msg, conf) ->
    conf or= {prefix: ''}
    conf.color = colorWarn
    conf.prefix = "WARNING #{conf.prefix}"
    puts msgFun msg, conf
  error: (msg, conf) ->
    conf or= {prefix: ''}
    conf.color = colorError
    conf.prefix = "ERROR #{conf.prefix}"
    puts msgFun msg, conf

