fs              = require 'fs'
url             = require 'url'
path            = require 'path'
http            = require 'http'
assert          = require 'assert'
coffee          = require 'coffee-script'
socketIo        = require 'socket.io'

{loggerConf, info, log, warn} = require './logger'

class Server
  constructor: (@conf) ->
    assert @conf.url,  "Need conf.url"
    assert @conf.mime, "Need mime types"

    loggerConf @conf

    {@url, @mime}      = @conf
    {@hostname, @port} = url.parse @url

    @port or= 80

    if @conf.inject
      @injector = makeCoffeeInjector \
      (["../node_modules/socket.io/node_modules/socket.io-client/dist/" + \
        "socket.io.min.js", "script.coffee"] \
          .map (js) -> path.normalize("#{__dirname}/#{js}")), @url

    headers =
      'Cache-Control': 'private, max-age=0, must-revalidate'

    @httpServer = http.createServer (req, res, next) =>
      fileName = req.url.replace /\?.*/, ''
      if fileName[fileName.length - 1] == '/'
        fileName += 'index.html'
      log "#{req.method} #{fileName}"

      filePath = "#{@conf.root}/#{fileName.slice 1}"
      suffix = /(\w+)$/.exec(fileName)[1]
      fs.readFile filePath, (err, data) =>
        if err
          warn err + ''
          headers['Content-Type'] = 'text/plain'
          res.writeHead 400, headers
          return res.end err.toString()
        if /html?$/i.test(suffix) and @injector
          data = @injector data
        headers['Content-Type'] = @conf.mime[suffix] || 'text/plain'
        res.writeHead 200, headers
        res.end data

    @wsServer = socketIo.listen @httpServer, {
      log: true
      'log level': 1
      transports: ['websocket', 'xhr-polling', 'htmlfile']
    }

    @wsServer.on 'connection', (socket) ->
      log "Connection accepted"

  start: (next) ->
    @httpServer.listen @port, @hostname, 511, (err) =>
      if err
        return next err
      log "Listening to #{@url}"
      (next or ->) 0

  stop: (next) ->
    @httpServer.close =>
      @httpServer = null


  send: (data) ->
    info "Sending #{data} to client(s)"
    @wsServer.sockets.emit 'msg', data

  makeCoffeeInjector = (filesToInject, wsUrl) ->
    js = ''
    for fileToInject in filesToInject
      warn "Reading #{fileToInject}"
      cs = fs.readFileSync(fileToInject).toString().replace '<<URL>>', wsUrl
      if /\.coffee$/.test fileToInject
        cs = coffee.compile cs, bare: true
      js += """<script>\n#{cs}\n</script>\n"""
    return (data) ->
      lines = data.toString().split /[\r\n]+/
      lastBody = -1
      for line, i in lines
        if /<\/body>/i.test line
          lastBody= i
      if lastBody > -1
        lines[lastBody] = lines[lastBody].replace /<\/body>/i, "#{js}</body>"
      return lines.join '\n'

module.exports = Server
