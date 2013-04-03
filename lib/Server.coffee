fs              = require 'fs'
url             = require 'url'
util            = require 'util'
path            = require 'path'
http            = require 'http'
assert          = require 'assert'
coffee          = require 'coffee-script'
socketIo        = require 'socket.io'

{info, note, log, warn} = require './logger'

http.ServerResponse.prototype.sendJson = (code, data) ->
  warn "sendJson #{code}, #{util.inspect data, false, 200}"
  data = JSON.stringify data
  this.writeHead code, {'Content-Type': 'application/json', \
                        'Content-Length': data.length}
  this.write data
  this.end()


class Server
  constructor: (@conf) ->
    assert @conf.url,  "Need conf.url"
    assert @conf.mime, "Need mime types"

    {@url, @mime}      = @conf
    {@hostname, @port} = url.parse @url

    @port or= '80'
    @port = parseInt @port, 10

    headers =
      'Cache-Control': 'private, max-age=0, must-revalidate'

    @httpServer = http.createServer (req, res) =>
      fileName = req.url.replace /\?.*/, ''
      if fileName[fileName.length - 1] == '/'
        fileName += 'index.html'
      log "#{req.method} #{fileName}"

      filePath = "#{@conf.root}/#{fileName.slice 1}"
      suffix = /(\w+)$/.exec(fileName)[1]
      fs.lstat filePath, (err, stat) =>
        if err
          return res.sendJson 200, err

        if stat.isDirectory()
          filePath += '/index.html'

        fs.readFile filePath, (err, data) =>
          if err
            warn err + ''
            headers['Content-Type'] = 'text/html'
            res.writeHead 400, headers
            return res.end err.toString()
          if /html?$/i.test(suffix) and @injector
            data = @injector data
          headers['Content-Type'] = @conf.mime[suffix] || 'text/html'
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
    maxTries = 20
    listen = =>
      @httpServer.listen @port, @hostname, (err) =>
        if err
          return next err

    @httpServer.on 'listening', =>
      msgListen = "Listening to #{@url}"
      if maxTries < 20
        urlObj = url.parse @url
        url2 = "#{urlObj.protocol}//#{urlObj.hostname}:#{@port}"
        msgListen = "Listening to #{url2} (changed from #{@url})"
        @url = url2

      if @conf.inject
        @injector = @makeCoffeeInjector \
        (["../node_modules/socket.io/node_modules/socket.io-client/dist/" + \
          "socket.io.min.js", "script.coffee"] \
            .map (js) -> path.normalize("#{__dirname}/#{js}"))
      note msgListen
      (next or ->) 0

    @httpServer.removeAllListeners 'error'
    @httpServer.on 'error', (err) =>
      error = err.toString()
      if error
        if /EADDRINUSE/.test error
          warn error
          @port += 1
          maxTries -= 1
          if maxTries > 0
            return listen()
        return next error

    listen()

  stop: (next) ->
    @httpServer.close =>
      @httpServer = null


  send: (data) ->
    info "Sending #{data} to client(s)"
    @wsServer.sockets.emit 'msg', data

  makeCoffeeInjector: (filesToInject) ->
    js = ''
    for fileToInject in filesToInject
      # info "Reading #{fileToInject}"
      cs = fs.readFileSync(fileToInject).toString().replace '<<URL>>', @url
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
