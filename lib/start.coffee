pkg = require '../package'
http = require 'http'

next = (err) ->
  if err
    throw err

# {{{1 Maintain state
state =
  sigintCount: 0
  pauseBuilds: false

addSigIntHandler = (obj, done) ->
  obj.on 'SIGINT', ->
    state.sigintCount or= 0
    if state.sigintCount > 1
      done 0
    else
      console.warn 'Press CTRL-C a couple of times to close'
    timeoutFun = ->
      state.sigintToken = null
      delete state.sigintCount
    state.sigintCount += 1
    if not state.sigintToken
      state.sigintToken = setTimeout timeoutFun, 500

addOptionsHandler = (obj, done) ->
  obj.on 'options', (options) ->
    obj.options

# 1}}}

startWorker = (freshen, configFileName) ->
  addSigIntHandler process, ->
    console.warn "CTRL-C: exit"
    process.exit 0
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
    process.on 'message', (msg) ->
      switch msg
        when 'stop'
          server.stop()
          watcher.stop()
          process.exit 0
        when 'start'
          server.start()
          watcher.start()
    watcher.start next
    server.start next

send = (res, code, message) ->
  res.writeHead code, {'Content-Type': 'text/html', \
                       'Content-Length': message.length}
  res.end message

startDaemon = (freshen, daemonConfigFile) ->
  freshen.conf.readDaemonConfig daemonConfigFile, (err, conf) ->
    if err
      return next err
    children = []
    count = conf.dirs.length
    for dir in conf.dirs
      do (dir) ->
        ch = require('child_process').fork "#{__dirname}/../bin/freshen", \
          ["#{dir}/.freshenrc"], cwd: dir
        children.push ch
        count -= 1
        if count == 0
          httpServer = http.createServer (req, res, next) =>
            parts = req.url.split /\//
            if /^start|stop/.test parts[1]
              for child in children
                child.send parts[1]
              send res, 200, parts[1]
            else
              send res, 502, 'nope'

          httpServer.listen 5000, 'localhost'

start = (freshen) ->
  runAsDaemon = false
  showHelp = false
  for arg in process.argv.slice(2)
    if /^-h|--help/.test arg
      showHelp = true
      break
    if /^-d|--daemon/.test arg
      runAsDaemon = true
      break

  if showHelp
    require('util').puts """
    Usage: freshen [option] | [path/to/.freshenrc] | [command]

      -h | --help   Shows this help

      -d | --daemon Reads $HOME/.freshend and starts an instance
                    of freshen for each dir in this file

    Commands:

      stop, start, restart  Start/Stop/Restart freshend

    If no arguments are given the file .freshenrc in the current directory
    will read or created if it does not exist.

    """
    return 0

  if runAsDaemon
    startDaemon freshen, process.env.HOME + '/.freshend'
  else
    startWorker freshen, process.argv[2] or '.freshenrc'

module.exports = start
