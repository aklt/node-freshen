pkg = require '../package'

next = (err) ->
  if err
    throw err

startWorker = (freshen, configFileName) ->
  freshen.conf.readConfig configFileName, (err, conf) ->
    freshen.logger.configure conf
    freshen.logger.info "Running #{pkg.name} version #{pkg.version}"
    server  = new freshen.Server conf
    watcher = new freshen.Watcher conf, (data) ->
      if configFileName in data.change
        server.stop()
        watcher.stop()
        return start freshen, configFileName
      server.send JSON.stringify data
    watcher.start next
    server.start next

startDaemon = (freshen, daemonConfigFile) ->
  freshen.conf.readDaemonConfig daemonConfigFile, (err, conf) ->
    if err
      return next err
    for dir in conf.dirs
      do (dir) ->
        require('child_process').fork "#{__dirname}/../bin/freshen", \
          ["#{dir}/.freshenrc"], cwd: dir

start = (freshen) ->
  runAsDaemon = false
  for arg in process.argv.slice(2)
    if /^-d|--daemon/.test arg
      runAsDaemon = true
      break

  if runAsDaemon
    startDaemon freshen, process.env.HOME + '/.freshend'
  else
    startWorker freshen, process.argv[2] or '.freshenrc'

module.exports = start
