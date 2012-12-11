child_process = require 'child_process'
watchDirs     = require './watchDirs'

{loggerConf, log, warn} = require './logger'

# TODO Watch recursively, report creation of dirs, interpret rename event with a
# stat

class Watcher
  constructor: (@conf, onChange) ->
    @delay        = @conf.delay   # At most one batch is sent per delay
    @dir          = @conf.root or '.' #
    @report       = @conf.report      # {change: [/\.js$/, /\.css/]}
    @build        = @conf.build       #
    @onChange     = onChange or warn # Call this function when a change happens
    @batchWaiting = false
    @doBuild      = false
    @doReport     = false
    @reportBatch  = {}

    loggerConf @conf

  start: (next) ->
    @runBuild @build.command, (err) =>
      if err
        throw err
      log "Watching #{@dir}"
      onEvent = (event, fileName) =>
        matchReport = (@report[event] or []).some (rx) ->
          rx.test fileName
        matchBuild = (@build.deps or []).some (rx) ->
          rx.test fileName

        if matchReport or matchBuild
          if not @batchWaiting
            @batchWaiting = true
            setTimeout =>
              # Assume a build updates things to report
              if @doBuild
                @runBuild @build.command, @runReport.bind @
              else if @doReport
                @runReport()
            ,
              @delay

          if matchBuild
            @doBuild = true

          if matchReport
            @doReport = true
            @reportBatch["#{event}-#{fileName}"] = [event, \
                                  fileName.replace /^\.\//, '']

      watchDirs '.', @conf.exclude or /\/\/\//, onEvent, next

  runBuild: (command, next) ->
    [prog, args...] = command.split /\s+/
    child_process.exec prog, args, (err, stdout, stderr) =>
      if err
        return warn "#{err}"
      log stdout, prefix: 'Build: '
      (next or ->)()
      @doBuild = false

  runReport: ->
    changes = {}
    for key of @reportBatch
      [event, fileName] = @reportBatch[key]
      if not changes.hasOwnProperty event
        changes[event] = []
      changes[event].push fileName
    @onChange changes
    @reportBatch = {}
    @doReport = false
    @batchWaiting = false

module.exports = Watcher

