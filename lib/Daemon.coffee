
fs     = require 'fs'
url    = require 'url'
util   = require 'util'
http   = require 'http'
assert = require 'assert'
cp     = require 'child_process'
qs     = require 'querystring'

warn = console.warn

http.ServerResponse.prototype.sendJson = (code, json) ->
  warn "sendJson #{code}, #{util.inspect json, false, 200}"
  data = null
  try
    data = JSON.stringify json
  catch e
    data = util.inspect json
  if not data
    data = util.inspect json

  this.writeHead code, {'Content-Type': 'application/json', \
                        'Content-Length': data.length}
  this.write data
  this.end()

dirname  = (str) ->
  m = /^((?:\.|)\/?(?:\/+[^\/]*)+)\//.exec str
  if m
    return m[1]

class Daemon
  constructor: (@conf) ->
    @conf or= {}
    @conf.workers or= []
    @methods =
      GET:
        help:
          conf:    'Configuration'
          workers: 'Show worker info'

        conf: (req, next) =>
          next 0, @conf

        browse: (req, next) =>
          fileName = req.url.replace /\?.*/, ''
          if fileName[fileName.length - 1] == '/'
            fileName += 'index.html'
          req.fileName = fileName
          next 0, req

        workers: (req, next) =>
          result = []
          @conf.workers.forEach (worker) ->
            result.push {
              pid: worker.pid
              killed: worker.killed,
              rcFile: worker.rcFile
            }
          next 0, result

      POST:
        help:
          workers: 'POST /workers {' + \
              'rcfile: ~/project/.freshenrc,' + \
              'command: "start|stop|status"' + \
              'match: name =~ /foo/}'
        workers: (req, next) =>
          req.on 'readable', ->
            req.json = JSON.parse req.read().toString()
          req.on 'end', =>
            jsonRcfile = req.json and req.json.rcfile
            @loadWorker jsonRcfile, next

        stop: (req, next) =>
          @stop next

        restart: (req, next) =>
          next 0, todo: 'implement restart'

       DELETE:
         help:
           workers: 'DELETE /workers pid: Number'
         workers: (req, next) =>
           console.warn req.urlObject
           @closeWorker parseInt(req.urlObject.queryObject.pid, 10), (err) ->
             if err
               return next err
             next 0, closed: 1

  _requestMethod: (req, cb) ->
    if not req.urlObject
      urlObject = url.parse req.url
      urlObject.pathArray = urlObject.pathname.split /\/+/
      urlObject.queryObject = qs.decode urlObject.query
      req.urlObject = urlObject

    methodObj = @methods[req.method]
    if not methodObj
      return cb 400, methods
    func1 = methodObj[urlObject.pathArray[1]]
    if not func1
      return cb 404, methodObj
    return func1 req, cb

  loadWorker: (jsonRcfile, cb) ->
    if not jsonRcfile
      return cb "Bad request"
    cwd = dirname jsonRcfile
    ch = cp.fork "#{__dirname}/Worker.coffee", [jsonRcfile], cwd: cwd, silent: true
    warn "loadWorker ", ch
    ch.rcFile = jsonRcfile
    ch.on 'error', (err) ->
      cb err
      cb = ->
    ch.on 'exit', ->
      console.warn 'Child exited'
    @conf.workers.push ch
    cb(0, ch)

  loadWorkers: (freshenrcFiles, next) =>
    count = freshenrcFiles.length
    for freshenrc in freshenrcFiles
      do (freshenrc) =>
        @loadWorker freshenrc, (err) ->
          if err
            return next err
          count -= 1
          if count == 0
            return next 0

  closeWorker: (pid, cb) ->
    for worker, i in @conf.workers
      warn "Checking pid #{pid} == #{worker.pid}"
      if pid == worker.pid
        worker.send 'stop'
        worker.disconnect()
        @conf.workers.splice i, 1
        return cb()
    cb "404: Could not find pid #{pid}"

  start: (next) ->
    @loadWorkers @conf.load, (err) =>
      if err
        return next err
      @httpServer = http.createServer (req, res) =>
        urlObject = url.parse req.url
        @_requestMethod req, (err, result) ->
          if err
            return res.sendJson 404, error: err
          res.sendJson 200, result
      @httpServer.listen 2001, 'localhost'

  stop: (next) ->
    for worker in @conf.workers
      worker.send 'stop'
    @httpServer.close()
    next()


module.exports = Daemon
