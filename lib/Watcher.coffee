fs = require 'fs'
child_process = require 'child_process'
{loggerConf, log, warn} = require './logger'

# TODO Watch recursively, report creation of dirs, interpret rename event with a
# stat

class Watcher
  constructor: (conf, onChange) ->
    @delay        = conf.delay   # At most one batch is sent per delay
    @dir          = conf.root or '.' #
    @report       = conf.report      # {change: [/\.js$/, /\.css/]}
    @build        = conf.build       # 
    @onChange     = onChange or warn # Call this function when a change happens
    @batchWaiting = false
    @doBuild      = false
    @doReport     = false
    @reportBatch  = {}

    loggerConf conf

  start: ->
    @runBuild @build.command, (err) =>
      if err
        throw err
      log "Watching #{@dir}"
      fs.watch @dir, (event, fileName) =>
        matchReport = (@report[event] or []).some (rx) ->
          rx.test fileName
        matchBuild = (@build.deps or []).some (rx) ->
          rx.test fileName

        if matchReport or matchBuild
          if not @batchWaiting
            @batchWaiting = true
            setTimeout =>
              if @doBuild and @doReport
                @runBuild @build.command, @runReport.bind @
              else if @doBuild
                @runBuild @build.command, =>
                  @batchWaiting = false
              else if @doReport
                @runReport()
            ,
              @delay

          if matchBuild
            @doBuild = true

          if matchReport
            @doReport = true
            @reportBatch["#{event}-#{fileName}"] = [event, fileName]

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

