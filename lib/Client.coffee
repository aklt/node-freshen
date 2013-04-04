#!/usr/bin/env coffee
# Created: Thu 04 Apr 2013 01:02:16 AM CEST

fs     = require 'fs'
util   = require 'util'
assert = require 'assert'
http   = require 'http'

warn = console.warn
pp   = (text...) -> text.forEach (arg) -> util.puts JSON.stringify arg, false, 2

next = (err) ->
  if err
    warn err
    throw err
  warn "last next"

class Client
  constructor: (@conf) ->

  listWorkers: (next) ->
    http.get 'http://localhost:2001/workers', (res) ->
      res.on 'readable', ->
        warn res.read().toString()

  addWorker: (rcfile, next) ->
    options =
      method: 'POST'
      hostname: 'localhost'
      port: 2001
      path: '/workers'

    req = http.request options, (res) ->
      res.on 'readable', ->
        warn 'READ', res.read().toString()

    req.on 'error', (err) ->
      warn 'error', err
      cb = next
      next = ->
      cb err

    req.write JSON.stringify rcfile: rcfile
    req.end()

  removeWorker: (pid, next) ->
    options =
      method: 'DELETE'
      hostname: 'localhost'
      port: 2001
      path: '/workers?pid=' + pid

    req = http.request options, (res) ->
      res.on 'readable', ->
        warn 'READ', res.read().toString()

    req.end()


module.exports = Client
