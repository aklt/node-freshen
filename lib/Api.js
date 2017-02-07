
command = ''
args = ''

module.exports =
  match: (aUrl) ->
    aUrl = aUrl.replace /\?.*/, ''
    m = /^\/-\/([^\/]+)\/?(.*)/.exec aUrl
    if m
      command = m[1]
      args = m[2].split /\//
      return true
    return false

  handle: (req, res) ->
    # switch command
      # when 'stop'
    res.$send null, [__filename, "handle", command, args]

