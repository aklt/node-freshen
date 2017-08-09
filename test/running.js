/* global before after describe it */
var t = require('./testlib')
var expect = require('unexpected')

describe('running freshen', () => {
  before(done => {
    t.start('api', 'dev', done)
  })
  after(done => {
    t.stop('api', 'dev', done)
  })
  it('is running', done => {
    t.sh('ps aux | grep freshenrc- | grep -v grep', (err, stdout) => {
      if (err) return done(err)
      expect(stdout.split(/\n/).length, 'to be greater than or equal to', 2)
      done()
    })
  })
  it('sends index.html', done => {
    t.sh(
      'curl -D- http://localhost:1024/index.txt | grep HTTP',
      (err, stdout) => {
        if (err) return done(err)
        expect(stdout, 'to equal', 'HTTP/1.1 200 OK\r\n')
        done()
      }
    )
  })
  it('proxies a good request', done => {
    t.sh('curl -D- http://localhost:1024/api/index.txt', (err, stdout) => {
      if (err) return done(err)
      expect(stdout, 'to match', /200 OK/)
      done()
    })
  })
  it('proxies a bad request', done => {
    t.sh('curl -D- http://localhost:1024/api/not-found', (err, stdout) => {
      if (err) return done(err)
      expect(stdout, 'to match', /404 Not Found/)
      done()
    })
  })
})
