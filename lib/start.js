pkg = require '../package'

next = (err) ->
  if err
    throw err

start = (freshen, configFileName) ->
  freshen.readConfig configFileName, (err, conf) ->
    server  = new freshen.Server conf
    watcher = new freshen.Watcher conf, (data) ->
      if configFileName in data.change
        server.stop()
        watcher.stop()
        return start freshen, configFileName
      server.send JSON.stringify data
    freshen.logger.info "Running #{pkg.name} version #{pkg.version}"
    watcher.start next
    server.start next

module.exports = start
