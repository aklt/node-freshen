var fs = require('fs')
var os = require('os')
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

function Server(conf) {
  this.conf = conf
  assert(conf.mimeTypes, 'Need mime types')
  loggerConf(this.conf)

  this.mimeTypes = conf.mimeTypes
  this.mimeAdd = conf.mimeAdd

  this.hostname = os.hostname()

  this.port = conf.port
  var headers = {
    'Cache-Control': 'private, max-age=0, must-revalidate'
  }
  var self = this
  if (conf.proxy) {
    var httpProxy
    try {
      httpProxy = require('http-proxy')
    } catch (e) {
      log('Please "npm install http-proxy" if you want to proxy requests')
      warn(e.stack)
      process.exit(1)
    }
    ;['from', 'to'].forEach(prop => {
      if (!conf.proxy[prop]) {
        log('Please specify proxy.' + prop + ' in config')
        process.exit(1)
      }
    })
    this.proxy = httpProxy.createProxyServer({
      proxyTimeout: 1000,
      preserveHeaderKeyCase: true,
      xfwd: true,
      prependPath: false,
      headers: {
        'X-Freshen': 'yes'
      }
    })

    var rxFrom = new RegExp(conf.proxy.from || '', 'i')

    this.matchProxyRequest = function(req) {
      return rxFrom.exec(req.url)
    }
  }
  this.httpServer = http.createServer(function(req, res) {
    var fileName, filePath, suffix
    res.headers = headers
    // TODO remmmove old api
    if (Api.match(req.url)) {
      return Api.handle(req, res)
    }
    // TODO we don't always want this
    fileName = req.url.replace(/\?.*/, '')
    if (fileName[fileName.length - 1] === '/') {
      fileName += 'index.html'
    }
    if (self.matchProxyRequest) {
      var m = self.matchProxyRequest(req)
      if (m) {
        var target = conf.proxy.to
        for (var i = 1; i < m.length; i += 1) {
          target = target.replace(new RegExp('\\$' + i, 'g'), m[i])
          note('proxy [' + req.method + ' ' + fileName + '] to ' + target)
        }
        // Funny this is needed
        req.url = target
        res.setHeader('X-Freshen-Proxied-To', target)
        return self.proxy.web(
          req,
          res,
          {
            target: target
          },
          function(err) {
            if (err) {
              warn('TODO retry Proxy error', err, err.stack)
            }
          }
        )
      }
    }
    note(req.method + ' ' + fileName)
    filePath = self.conf.root + '/' + fileName.slice(1)
    suffix = /(\w*)$/.exec(fileName)[1]
    return fs.readFile(filePath, function(err, data) {
      var mimeType
      if (err) {
        warn(err + '')
        var status = 400
        if (err.code === 'ENOENT') status = 404
        err = err.toString()
        res.headers['Content-Type'] = 'text/plain'
        res.headers['Content-Length'] = Buffer.byteLength(err)
        res.writeHead(status, res.headers)
        return res.end(err)
      }
      mimeType = self.conf.mimeTypes[suffix]
      if (mimeType === 'text/html') {
        data = self.injector(data)
      }
      res.headers['Content-Type'] = mimeType || 'text/plain'
      res.headers['Content-Length'] = Buffer.byteLength(data)
      res.writeHead(200, res.headers)
      res.end(data)
    })
  })
  this.wsServer = new WebSocket.Server({
    server: this.httpServer,
    path: '/'
  })
  this.wsServer.on('connection', function(ws, req) {
    req = req && req.headers
    req = req && req['user-agent']
    req = req || 'WebSocket'
    info('Connection from ' + req)
  })
}

Server.prototype.start = function(next) {
  var maxTries = 20
  var self = this

  function listen() {
    self.httpServer.listen(self.port, function(err) {
      if (err) next(err)
    })
  }
  this.httpServer.on('listening', function() {
    var msgListen = 'Listening to http://' + self.hostname + ':' + self.port
    var rcws =
      'node_modules/ReconnectingWebSocket/reconnecting-websocket.min.js'
    var script = ['..', '../..', '../../..']
      .map(dir => {
        return path.normalize(path.join(__dirname, dir, rcws))
      })
      .filter(fullPath => {
        return fs.existsSync(fullPath)
      })

    if (!script[0]) throw new Error('Could not find ReconnectingWebSocket')

    self.injector = self.makeJsInjector([
      script[0],
      path.normalize(path.join(__dirname, '/../lib/script.js'))
    ])

    info(msgListen)
    ;(next || function() {})(0)
  })
  this.httpServer.removeAllListeners('error')
  this.httpServer.on('error', function(err) {
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

Server.prototype.stop = function(next) {
  var self = this
  this.httpServer.close(function() {
    self.httpServer = null
  })
}

Server.prototype.send = function(data) {
  var numConnected = this.wsServer.clients.size
  var sdata = typeof data === 'string' ? data : JSON.stringify(data)
  if (numConnected === 0) {
    info('Not sending ' + sdata + ', no connected clients')
  } else {
    info(
      'Sending ' +
        sdata +
        ' to ' +
        numConnected +
        ' client' +
        (numConnected === 1 ? '' : 's')
    )
    this.wsServer.clients.forEach(function(client) {
      if (client.readyState === WebSocket.OPEN) {
        client.send(sdata)
      }
    })
  }
}

Server.prototype.makeJsInjector = function(filesToInject) {
  var browserConf = {}
  browserConf.root = this.conf.root
  browserConf.delay = this.conf.delay
  browserConf.load = this.conf.load
  browserConf.debug = this.conf.debug || 0
  browserConf.retries = this.conf.retries || 20
  browserConf = JSON.stringify(browserConf, 0, 2)
  var js = ''
  for (var j = 0, len = filesToInject.length; j < len; j++) {
    var fileToInject = filesToInject[j]
    var cs = fs
      .readFileSync(fileToInject)
      .toString()
      .replace('/* <<CONF>> */', ', ' + browserConf)
    js += '<script>\n' + cs + '\n</script>\n'
  }
  return function(data) {
    var i, lines
    lines = data.toString().split(/\r\n|\n/g)
    for (i = lines.length; i >= 0; i--) {
      var line = lines[i]
      if (/<\/body>/i.test(line)) break
    }
    if (i > -1) {
      lines[i] = lines[i].replace(/<\/body>/i, js + '</body>')
    } else {
      lines.push(js)
    }
    return lines.join('\n')
  }
}

module.exports = Server
