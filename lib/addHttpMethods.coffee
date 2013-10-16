http = require 'http'
Stream = require 'stream'

module.exports = ->
  http.IncomingMessage.prototype.$json = (cb) ->
    jsonString = ''
    this.on 'readable', ->
      data = this.read()
      if data
        jsonString += data.toString()

    this.on 'end', ->
      return cb null, JSON.parse jsonString

  http.ServerResponse.prototype.$send or= (err, json, headers) ->
    headers or= {}
    if err
      this.writeHead err.statusCode or 502, headers
      return this.end JSON.stringify err
    if not json
      json =
        type: 'null'
    if json.stream
      json.stream.pipe this
    else
      if json.data
        output = json.data
      else
        output = JSON.stringify json
      headers['Content-Length'] = output.length
      this.writeHead json.statusCode or 200, headers
      this.write output
      this.end()

    this.writeHead json.statusCode or 200, headers
