
fs = require 'fs'

###*
  List directory contents and call the passed function with
  the result.  The properties of the objects are:

      name: file name
      size: size of file in bytes as a base 36 number
      time: modification time as a base36 number in seconds
###
list = (dir, cb) ->
  info = []

  fs.readdir dir, (err, files) ->
    if err
      return cb err
    last = files.length - 1
    files.forEach (file, idx) ->
      fs.stat "#{dir}/#{file}", (err, stats) ->
        if err
          return cb err
        info.push {
          name: if stats.isDirectory() then (file+'/') else file,
          size: stats.size
          time: (stats.mtime.getTime() / 1000)
        }
        if idx == last
          cb null, info.sort(pathCmp)

pathCmp = (a, b) ->
  an = a.name
  bn = b.name
  aisdir = an[an.length - 1] == '/'
  bisdir = bn[bn.length - 1] == '/'
  cmp = if an > bn then 1 else if bn > an then -1 else 0

  if aisdir and bisdir
    return cmp

  if not aisdir and not bisdir
    return cmp

  if bisdir
    return 1

  return -1

withRealPath = (stat, filePath, cb) ->
  if stat.isSymbolicLink()
    return fs.realpath filePath, cb
  cb null, filePath

pathBrowse = (filePath, cb) ->
  console.warn 'pathBrowse'
  fs.stat filePath, (err, stat) =>
    if err
      return cb err
    withRealPath stat, filePath, (err, realPath) =>
      if err
        return cb err

      if stat.isFile()
        stream = fs.createReadStream realPath
        suffix = ((/\.(\w{2,6})$/.exec realPath) or [])[1]
        return cb 0,
          type: suffix
          stream: stream

      if stat.isDirectory()
        return list realPath, (err, files) ->
          if err
            return cb err
          cb 0,
            data: files
            type: 'json'

      cb 0,
        type: 'unshowable'
        data: 'Boo'

module.exports = pathBrowse
