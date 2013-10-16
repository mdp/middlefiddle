assert = require 'assert'
{Mangle} = require "#{process.cwd()}/src/mangle"
fakeServer = require './helpers/fake_server'
proxy = require '../src/proxy'
fakePort = null; ProxyPort = 15888
{fetch} = require('./helpers/curl')
curl = (url, callback) ->
  fetch(url, "-i -k -x 'http://127.0.0.1:#{ProxyPort}'", callback)


describe 'A basic HTTPS Proxy', ->
  middlewares = []
  before (done) ->
    proxy.createServer(middlewares).listen ProxyPort, ->
      fakeServer.start (app)->
        fakePort = app.sslPort
        done()

  describe "pass a request through", ->
    it 'should return 200 for a valid request', (done)->
      curl "https://127.0.0.1:#{fakePort}/status/200", (err, res) ->
        assert.equal res.statusCode, 200
        assert.equal res.headers['x-powered-by'], "Express"
        done()
    it 'should return 404 for a 404 request', (done)->
      curl "https://127.0.0.1:#{fakePort}/status/404", (err, res, body) ->
        assert.equal res.statusCode, 404
        done()

