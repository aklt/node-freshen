var childProcess = require('child_process')
var watchDirs = require('./watchDirs')

var logger = require('./logger')
var loggerConf = logger.loggerConf
var info = logger.info
// var note = logger.note
var log = logger.log
var warn = logger.warn

function Watcher(conf, onChange) {
  this.conf = conf
  this.runReport = this.runReport.bind(this)
  this.runBuild = this.runBuild.bind(this)
  this.stop = this.stop.bind(this)
  this.delay = this.conf.delay
  this.dir = this.conf.root || '.'
  this.report = this.conf.report
  this.build = this.conf.build
  this.onChange = onChange || warn
  this.batchWaiting = false
  this.doBuild = false
  this.doReport = false
  this.reportBatch = {}
  loggerConf(this.conf)
}

function formatDirs(dirs) {
  var str = dirs.join(', ')
  if (str.length > 400) {
    str = str.slice(0, 390) + '...(' + dirs.length + ' directories'
    if (dirs.length > 99) str += '!'
    str += ')'
  }
  return '{' + str + '}'
}

Watcher.prototype.start = function(next) {
  var self = this
  this.runBuild(this.build.command, function(err) {
    var onEvent
    if (err) {
      if (!err.cmd) return next(err)
      // error was reported
    }
    onEvent = function(event, relativeFile) {
      var matchBuild, matchReport
      relativeFile = relativeFile.replace(/^\.\//, '')
      matchReport = (self.report[event] || []).some(function(rx) {
        return rx.test(relativeFile)
      })
      matchBuild = (self.build.deps || []).some(function(rx) {
        return rx.test(relativeFile)
      })
      if (matchReport || matchBuild) {
        if (!self.batchWaiting) {
          self.batchWaiting = true
          self.timeoutId = setTimeout(function() {
            self.timeoutId = null
            if (self.doBuild) {
              return self.runBuild(self.build.command, self.runReport)
            } else if (self.doReport) {
              return self.runReport()
            }
          }, self.delay)
        }
        if (matchBuild) {
          self.doBuild = true
        }
        if (matchReport) {
          self.doReport = true
          self.reportBatch[event + '-' + relativeFile] = [event, relativeFile]
        }
      }
    }
    watchDirs('.', self.conf.exclude, onEvent, function(err, watchers, dirs) {
      info('Watching directories: ' + self.dir + '/' + formatDirs(dirs))
      if (err) return next(err)
      self.watchers = watchers
      next()
    })
  })
}

Watcher.prototype.stop = function(next) {
  if (this.timeoutId) {
    clearTimeout(this.timeoutId)
    this.timeoutId = null
  }
  var ref1 = this.watchers
  for (var i = 0, len = ref1.length; i < len; i++) {
    ref1[i].close()
  }
  this.watchers = null
}

Watcher.prototype.runBuild = function(command, next) {
  var self = this
  childProcess.exec(command, function(err, stdout, stderr) {
    if (stdout) {
      log(stdout)
    }
    if (stderr) {
      warn(stderr)
    }
    if (err) {
      return next(err)
    }
    ;(next || function() {})()
    self.doBuild = false
  })
}

Watcher.prototype.runReport = function() {
  var changes = {}
  var changeCount = 0
  for (var key in this.reportBatch) {
    changeCount += 1
    var ref1 = this.reportBatch[key]
    var event = ref1[0]
    var relativeFile = ref1[1]
    if (!changes.hasOwnProperty(event)) {
      changes[event] = []
    }
    changes[event].push(relativeFile)
  }
  if (changeCount > 0) {
    this.onChange(changes)
    this.reportBatch = {}
  }
  this.doReport = false
  this.batchWaiting = false
  info('___________________________________________')
}

module.exports = Watcher
