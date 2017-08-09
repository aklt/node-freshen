var args, command

module.exports = {
  match: function(aUrl) {
    aUrl = aUrl.replace(/\?.*/, '')
    var m = /^\/-\/([^/]+)\/?(.*)/.exec(aUrl)
    if (m) {
      command = m[1]
      args = m[2].split(/\//)
      return true
    }
    return false
  },
  handle: function(req, res) {
    return res.$send(null, [__filename, 'handle', command, args])
  }
}
