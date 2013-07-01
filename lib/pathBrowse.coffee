
fs = require 'fs'

###*
  List a directories contents and call the passed function with
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

pathBrowse = (filePath, cb) ->
  fs.lstat filePath, (err, stat) =>
    if err
      return cb err

    if stat.isDirectory()
      return list filePath, (err, files) ->
        if err
          return cb err

        cb 0,
          data: files
          type: 'json'

    if stat.isFile()
      stream = fs.createReadStream filePath
      suffix = ((/\.(\w{2,6})$/.exec filePath) or [])[1]
      cb 0,
        type: suffix
        stream: stream

    cb 0,
      type: 'unshowable'
      data: 'Boo'

module.exports = pathBrowse
