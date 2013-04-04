util   = require 'util'
freshen = require 'freshen'
pkg     = require '../package'

configFileName = process.argv[2]

next = (err) ->
  if err
    console.warn err
  process.emit 'message', '{error: "Worker dying"}'
  console.warn "last next"

freshen.conf.readConfig configFileName, (err, conf) ->
  if err
    return next err
  if not conf
    return next 'No configuration!'
  console.warn 'readConfig: ' + util.inspect conf
  freshen.logger.configure conf
  freshen.logger.info "Running #{pkg.name} version #{pkg.version}"
  server  = new freshen.Server conf
  watcher = new freshen.Watcher conf, (data) ->
    if configFileName in data.change
      server.stop()
      watcher.stop()
      return start freshen, configFileName
    server.send JSON.stringify data
  process.on 'message', (message) ->
    console.warn "Worker got message '#{message}'"
    switch message
      when 'stop'
        server.stop()
        watcher.stop()
        process.exit 0
      when 'start'
        server.start()
        watcher.start()
  watcher.start()
  server.start()
