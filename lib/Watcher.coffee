path          = require 'path'
child_process = require 'child_process'
watchDirs     = require './watchDirs'

{note, log, warn, error} = require './logger'

# TODO Watch recursively, report creation of dirs, interpret rename event with a
# stat

class Watcher
  constructor: (@conf, onChange) ->
    @delay        = @conf.delay        # At most one batch is sent per delay
    @dir          = @conf.path.watch or path.resolve '.'
    @dirLength    = @dir.length
    @report       = @conf.report or {} # {change: [/\.js$/, /\.css/]}
    @build        = @conf.build
    @onChange     = onChange or console.warn # Call this when a change happens
    @batchWaiting = false
    @doBuild      = false
    @doReport     = false
    @buildPaused       = true
    @reportBatch  = {}

  start: (next) ->
    @buildPaused = false
    @runBuild @build.command, (err) =>
      if err
        return next err
      note "Watching #{@dir}"
      onEvent = (event, relativeFile) =>
        relativeFile = relativeFile.slice @dirLength
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

      watchDirs @dir, @conf.exclude or /\/\/\//, onEvent, (err, watchers) =>
        @watchers = watchers
        (next or ->) err

  stop: (next) =>
    @buildPaused = true
    if @timeoutId
      clearTimeout @timeoutId
      @timeoutId = null
    for watcher in @watchers
      watcher.close()
    @watchers = null

  pause: ->
    @buildPaused = true

  unpause: ->
    @buildPaused = false

  runBuild: (command, next) =>
    if not @buildPaused
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

