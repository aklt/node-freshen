
var fs = require('fs')

function findDirs (root, next) {
  var result = []
  var pending = [root]
  function dirRecurse (root) {
    if (!root) {
      return next(0, result)
    }
    return fs.readdir(root, function (err, dirs) {
      var count, dir, fn, i, len
      if (err) {
        return next(err)
      }
      count = dirs.length
      if (count === 0) {
        return dirRecurse(pending.shift())
      }
      fn = function (dir) {
        var fullDir
        fullDir = root + '/' + dir
        return fs.stat(fullDir, function (err, stat) {
          if (err && err.code !== 'ENOENT') {
            return next(err)
          }
          if (!err && stat.isDirectory()) {
            result.push(fullDir)
            pending.push(fullDir)
          }
          count -= 1
          if (count === 0) {
            return dirRecurse(pending.shift())
          }
        })
      }
      for (i = 0, len = dirs.length; i < len; i++) {
        dir = dirs[i]
        fn(dir)
      }
    })
  }
  return dirRecurse(pending.shift())
}

function watchDirs (rootDir, excludeFilter, onchange, next) {
  return findDirs(rootDir, function (err, dirs) {
    var dir, i, len, watchers
    if (err) {
      return next(err)
    }
    dirs = dirs.filter(function (dir) {
      return !excludeFilter.test(dir)
    })
    dirs.push(rootDir)
    watchers = []
    for (i = 0, len = dirs.length; i < len; i++) {
      dir = dirs[i]
      watchers.push(fs.watch(dir, (function (dir) {
        return function (event, filename) {
          if (!dir) {
            throw new Error('Seems like fs.watch on your platform does not return a' + ' filename, so this script will not work :-(')
          }
          return onchange(event, dir + '/' + filename)
        }
      })(dir)))
    }
    return next(0, watchers)
  })
}

module.exports = watchDirs
