assert = require 'assert'
fake_server = require './helpers/fake_server'
http = require 'http'
Mf = require '../src/index'
Port = 15888
Mf.createProxy().listen(Port)

describe 'A basic HTTP Proxy', ->

  describe "pass a request through", ->
    it 'should return 200 for a valid request', ()->
      options =
        host: '127.0.0.1'
        port: Port
        path: '/http://127.0.0.1:4040/status/200'
      req = http.get options, (res) ->
        assert.equal res.statusCode, 200
    it 'should return 404 for a 404 request', ()->
      options =
        host: '127.0.0.1'
        port: Port
        path: '/http://127.0.0.1:4040/status/404'
      req = http.get options, (res) ->
        assert.equal res.statusCode, 404

describe 'A basic transparent HTTP Proxy', ->
  beforeEach (done) ->
    Mf.config.transparent = true
    done()

  describe "pass a request through", ->
    it 'should return 200 for a valid request', ()->
      options =
        host: 'localhost'
        port: Port
        path: '/status/200'
        headers: {
          host: "test.dev" # Need local server running on port 80 and forwarding to 4040/Fakeserver to work
        }
      req = http.get options, (res) ->
        assert.equal res.statusCode, 200

