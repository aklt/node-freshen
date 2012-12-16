child_process = require 'child_process'
watchDirs     = require './watchDirs'

{loggerConf, note, log, warn, error} = require './logger'

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
        return next err
      note "Watching #{@dir}"
      onEvent = (event, relativeFile) =>
        relativeFile = relativeFile.replace /^\.\//, ''
        matchReport = (@report[event] or []).some (rx) ->
          rx.test relativeFile
        matchBuild = (@build.deps or []).some (rx) ->
          rx.test relativeFile

        if matchReport or matchBuild
          if not @batchWaiting
            @batchWaiting = true
            @timeoutId = setTimeout =>
              @timeoutId = null
              # Assume a build updates things to report
              if @doBuild
                @runBuild @build.command, @runReport
              else if @doReport
                @runReport()
            ,
              @delay

          if matchBuild
            @doBuild = true

          if matchReport
            @doReport = true
            @reportBatch["#{event}-#{relativeFile}"] = [event, relativeFile]

      watchDirs '.', @conf.exclude or /\/\/\//, onEvent, (err, watchers) =>
        @watchers = watchers
        next err

  stop: (next) =>
    if @timeoutId
      clearTimeout @timeoutId
      @timeoutId = null
    for watcher in @watchers
      watcher.close()
    @watchers = null

  runBuild: (command, next) =>
    [prog, args...] = command.split /\s+/
    child_process.exec prog, args, (err, stdout, stderr) =>
      if err
        return next error "#{err}" + stderr || ''
      if stdout
        log stdout
      if stderr
        warn stderr
      (next or ->)()
      @doBuild = false

  runReport: =>
    changes = {}
    changeCount = 0
    for key of @reportBatch
      changeCount += 1
      [event, relativeFile] = @reportBatch[key]
      if not changes.hasOwnProperty event
        changes[event] = []
      changes[event].push relativeFile
    if changeCount > 0
      @onChange changes
      @reportBatch = {}
    @doReport = false
    @batchWaiting = false
    note '___________________________________________'

module.exports = Watcher

