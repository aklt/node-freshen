
{info, log, warn} = console

esc = String.fromCharCode 27
colorInfo  = ''
colorLog  = ''
colorWarn = ''
colorEnd  = ''

msgFun = (msg, conf) ->
  stamp = "[#{new Date().toJSON().replace /\..*/, ''}] "
  if conf and conf.prefix
    stamp += conf.prefix
  return "#{msg.replace(/[\r\n]+$/, '')
               .replace(/^/gm, conf.color)
               .replace(/$/gm, colorEnd)
               .replace(/^/gm, stamp)}"

module.exports =
  loggerConf: (conf) ->
    if conf.color
      colorInfo = esc + '[0;33m'
      colorLog  = esc + '[0;36m'
      colorWarn = esc + '[0;31m'
      colorEnd  = esc + '[0m'
    else
      colorInfo = ''
      colorLog  = ''
      colorWarn = ''
      colorEnd  = ''
  info: (msg, conf) ->
    conf or= {prefix: ''}
    conf.color = colorInfo
    info msgFun msg, conf
  log: (msg, conf) ->
    conf or= {prefix: ''}
    conf.color = colorLog
    log msgFun msg, conf
  warn: (msg, conf) ->
    conf or= {prefix: ''}
    conf.color = colorWarn
    conf.prefix = "WARNING #{conf.prefix}"
    warn msgFun msg, conf

