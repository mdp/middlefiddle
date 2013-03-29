assert = require 'assert'
fake_server = require './helpers/fake_server'
stream = require 'stream'

# Ports
proxyPort = 15888
fakePort = 4040

Mf = require '../src/http_proxy'

request = require 'request'
req = request.defaults({'proxy':"http://localhost:#{proxyPort}"})

describe 'A basic HTTP Proxy', ->

  before (done) ->
    fake_server.listen port, ->
      done()

  describe "pass a request through", ->
    middlewares = []

    beforeEach (done) ->
      Mf.createProxy(middlewares).listen proxyPort, ->
        done()

    it 'should return 200 for a valid request', ()->
      req.get "http://localhost:#{fakePort}/status/200", (res) ->
        assert.equal res.statusCode, 200
