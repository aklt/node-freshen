var childProcess = require('child_process')

var m = (module.exports = {})
var slice = [].slice

m.start = function(/* ...args */) {
  var args = slice.call(arguments)
  var cb = args.pop()
  var i = -1
  ;(function loop(err) {
    if (err) return cb(err)
    i++
    if (args[i]) {
      childProcess.exec(`${__dirname}/dir/start.sh ${args[i]}`)
      loop()
    } else {
      // hack wait for the freshen processes to actually start
      setTimeout(cb, process.env.WAIT_FOR_FRESHEN || 300)
    }
  })(0)
}

m.stop = function(/* ...args */) {
  var args = slice.call(arguments)
  var cb = args.pop()
  var i = -1
  ;(function loop(err) {
    if (err) return cb(err)
    i++
    if (args[i]) {
      childProcess.exec(`${__dirname}/dir/stop-${args[i]}.sh`)
      loop()
    } else {
      cb()
    }
  })(0)
}

m.sh = function(/* ...args */) {
  var args = slice.call(arguments)
  var cb = args.pop()
  childProcess.exec(args.join(' '), (err, stdout, stderr) => {
    if (err) return cb(err)
    cb(null, stdout.toString(), stderr.toString())
  })
}
