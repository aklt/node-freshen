
fs = require 'fs'

{log} = require './logger'

findDirs = (root, next) ->

  result  = []
  pending = [root]

  dirRecurse = (root) ->
    if not root
      return next 0, result

    fs.readdir root, (err, dirs) ->
      if err
        dirRecurse = ->
        return next err

      count = dirs.length
      if count == 0
        return dirRecurse pending.shift()

      for dir in dirs
        do (dir) ->
          fullDir = "#{root}/#{dir}"
          fs.stat fullDir, (err, stat) ->
            if err and err.code != 'ENOENT' # Ignore invalid symlinks
              dirRecurse = ->
              return next err
            if not err and stat.isDirectory()
              result.push fullDir
              pending.push fullDir
            count -= 1
            if count == 0
              return dirRecurse pending.shift()
      return
  dirRecurse pending.shift()

watchDirs = (rootDir, excludeFilter, onchange, next) ->
    findDirs rootDir, (err, dirs) ->
      if err
        return next err

      dirs = dirs.filter (dir) ->
        ! excludeFilter.test dir

      dirs.push rootDir
      watchers = []

      for dir in dirs
        watchers.push fs.watch dir, do (dir) ->
          return (event, filename) ->
            # log "Watch Event, #{event} #{filename}"
            if not dir
              throw "Seems like fs.watch on your platform does not return a" + \
                    " filename, so this script will not work :-("
            onchange event, "#{dir}/#{filename}"
      next 0, watchers

module.exports = watchDirs
