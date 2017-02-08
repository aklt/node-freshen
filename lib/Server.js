var fs = require('fs')
var util = require('util')
var url = require('url')
var path = require('path')
var http = require('http')
var assert = require('assert')
var WebSocket = require('ws')
var logger = require('./logger')

var loggerConf = logger.loggerConf
var info = logger.info
var note = logger.note
var log = logger.log
var warn = logger.warn

require('./addHttpMethods')()

var Api = require('./Api')

function Server (conf) {
  this.conf = conf
  assert(this.conf.url, 'Need conf.url')
  assert(this.conf.mimeTypes, 'Need mime types')
  loggerConf(this.conf)
  var ref1 = this.conf
  this.url = ref1.url
  this.mimeTypes = ref1.mimeTypes
  this.mimeAdd = ref1.mimeAdd

  var ref2 = url.parse(this.url)
  this.hostname = ref2.hostname
  this.port = ref2.port

  this.port || (this.port = '80')
  this.port = parseInt(this.port, 10)
  var headers = {
    'Cache-Control': 'private, max-age=0, must-revalidate'
  }
  var self = this
  this.httpServer = http.createServer(function (req, res) {
    var fileName, filePath, suffix
    res.headers = headers
    if (Api.match(req.url)) {
      return Api.handle(req, res)
    }
    fileName = req.url.replace(/\?.*/, '')
    if (fileName[fileName.length - 1] === '/') {
      fileName += 'index.html'
    }
    note(req.method + ' ' + fileName)
    filePath = self.conf.root + '/' + (fileName.slice(1))
    suffix = /(\w*)$/.exec(fileName)[1]
    return fs.readFile(filePath, function (err, data) {
      var mimeType
      if (err) {
        warn(err + '')
        res.headers['Content-Type'] = 'text/plain'
        res.writeHead(400, res.headers)
        return res.end(err.toString())
      }
      mimeType = self.conf.mimeTypes[suffix]
      if (mimeType === 'text/html') {
        data = self.injector(data)
      }
      res.headers['Content-Type'] = mimeType || 'text/plain'
      res.writeHead(200, res.headers)
      res.end(data)
    })
  })
  this.wsServer = new WebSocket.Server({
    server: this.httpServer,
    path: '/'
  })
  this.wsServer.on('connection', function (ws) {
    var agent = ws.upgradeReq
    agent = agent && agent.headers
    agent = agent && agent['user-agent']
    agent = agent || 'WebSocket'
    info('Connection from ' + agent)
  })
}

Server.prototype.start = function (next) {
  var maxTries = 20
  var self = this

  function listen () {
    self.httpServer.listen(self.port, self.hostname, function (err) {
      if (err) next(err)
    })
  }
  this.httpServer.on('listening', function () {
    var msgListen, url2, urlObj
    msgListen = 'Listening to ' + self.url
    if (maxTries < 20) {
      urlObj = url.parse(self.url)
      url2 = urlObj.protocol + '//' + urlObj.hostname + ':' + self.port
      msgListen = 'Listening to ' + url2 + ' (changed from ' + self.url + ')'
      self.url = url2
    }
    self.injector = self.makeJsInjector([
      // TODO path access
      path.join(__dirname, '/../node_modules/ReconnectingWebSocket/reconnecting-websocket.min.js'),
      path.join(__dirname, '/../lib/script.js')
    ].map(path.normalize))
    info(msgListen);
    (next || function () {})(0)
  })
  this.httpServer.removeAllListeners('error')
  this.httpServer.on('error', function (err) {
    var error
    error = err.toString()
    if (error) {
      if (/EADDRINUSE/.test(error)) {
        warn(error)
        self.port += 1
        maxTries -= 1
        if (maxTries > 0) {
          return listen()
        }
      }
      return next(error)
    }
  })
  return listen()
}

Server.prototype.stop = function (next) {
  var self = this
  this.httpServer.close(function () {
    self.httpServer = null
  })
}

Server.prototype.send = function (data) {
  info('Sending ' + data + ' to client(s)')
  this.wsServer.clients.forEach(function (client) {
    if (client.readyState === WebSocket.OPEN) {
      client.send(data)
    }
  })
}

Server.prototype.makeJsInjector = function (filesToInject) {
  var cs, fileToInject, j, js, len
  js = ''
  for (j = 0, len = filesToInject.length; j < len; j++) {
    fileToInject = filesToInject[j]
    cs = fs.readFileSync(fileToInject).toString().replace('<<URL>>', this.url.replace(/^http/, 'ws'))
    js += '<script>\n' + cs + '\n</script>\n'
  }
  return function (data) {
    var i, k, lastBody, len1, line, lines
    lines = data.toString().split(/\r\n|\n/g)
    lastBody = -1
    for (i = k = 0, len1 = lines.length; k < len1; i = ++k) {
      line = lines[i]
      if (/<\/body>/i.test(line)) {
        lastBody = i
      }
    }
    if (lastBody > -1) {
      lines[lastBody] = lines[lastBody].replace(/<\/body>/i, js + '</body>')
    }
    return lines.join('\n')
  }
}

module.exports = Server
