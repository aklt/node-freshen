
var indexOf = [].indexOf
var pkg = require('../package')
var next = function (err) {
  if (err) {
    throw err
  }
}

function start (freshen, configFileName) {
  freshen.readConfig(configFileName, function (err, conf, created) {
    if (err) return next(err)
    var server = new freshen.Server(conf)
    var watcher = new freshen.Watcher(conf, function (data) {
      if (indexOf.call(data.change, configFileName) >= 0) {
        server.send({reload: true})
        server.stop()
        watcher.stop()
        return start(freshen, configFileName)
      }
      return server.send(data)
    })
    freshen.logger.info('Running ' + pkg.name + ' version ' + pkg.version)
    // TODO fixup the logger
    if (!created) console.log('Reading options from ' + configFileName)
    watcher.start(next)
    server.start(next)
  })
}

module.exports = start
