pkg = require '../package'
http = require 'http'

Client = require '../lib/Client'
Daemon = require '../lib/Daemon'
conf = require '../lib/conf'

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

send = (res, code, message) ->
  res.writeHead code, {'Content-Type': 'text/html', \
                       'Content-Length': message.length}
  res.end message

start = (freshen) ->
  startDaemon = false
  showHelp = false
  c1 = new Client
  for arg, i in process.argv.slice(2)
    if /^-h|--help/.test arg
      showHelp = true
      break
    if /^start/.test arg
      startDaemon = true
      break
    if /^list/.test arg
      return c1.listWorkers (err, data) ->
        console.log err, data
        process.exit 0
    if /^add|load/.test arg and process.argv[i]
      return c1.addWorker process.argv[i + 2], (err, childp) ->
        console.log err
    if /^del|^rem/.test(arg)
      console.log process.argv
      return c1.removeWorker parseInt(process.argv[3], 10), (err, data) ->
        console.log err, data
    if /^clo|^sto/.test arg
      return c1.stop (err, data) ->
        console.log 'closed'
    if /^start-children/.test arg
      return c1.restart (err, data) ->
        console.log 'restarted', data

  if showHelp
    require('util').puts """
    Usage: freshen [-h|--help] | [command] | [path/to/.freshenrc]

      -h | --help   Shows this help

    Commands:

      start    Start a freshen instance for each of the directories
               mentioned in $HOME/.freshend

    If no arguments are given the file .freshenrc in the current directory
    will read or created if it does not exist.
    """
    return 0

  if startDaemon
    conf.readConfig process.env.HOME + '/.freshenrc', (err, config) ->
      d1 = new Daemon(config)
      console.warn d1
      d1.start()

  else
    startWorker freshen, process.argv[2] or '.freshenrc'

module.exports = start
