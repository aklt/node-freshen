var fs = require('fs')
var freshen = require('../')
var expect = require('unexpected')

describe('readConfig', () => {
  it('reads properties with parseNasted', done => {
    freshen.readConfig(`${__dirname}/dir/freshenrc-dev`, {}, function(
      err,
      conf,
      created
    ) {
      if (err) return done(err)
      expect(conf, 'to have properties', [
        'delay',
        'color',
        'retries',
        'exclude',
        'report',
        'build',
        'port',
        'mimeTypes',
        'root'
      ])
      expect(created, 'to be undefined')
      done()
    })
  })
  it('creates non-existing file', done => {
    var freshenrc = `${__dirname}/freshenrc-nothere`
    freshen.readConfig(freshenrc, {}, function(err, conf, created) {
      if (err) return done(err)
      expect(conf, 'to have properties', [
        'delay',
        'color',
        'retries',
        'exclude',
        'report',
        'build',
        'port',
        'mimeTypes',
        'root'
      ])
      expect(created, 'to be', freshenrc)
      fs.unlink(freshenrc, done)
    })
  })
})
