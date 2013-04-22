assert = require 'assert'
{Mangle} = require "#{process.cwd()}/src/mangle"
fakeServer = require './helpers/fake_server'
proxy = require '../src/proxy'
fakePort = null; ProxyPort = 15888
request = require('request').defaults({proxy:"http://127.0.0.1:#{ProxyPort}", rejectUnauthorized: false, strictSSL: false})

describe 'A basic HTTPS Proxy', ->
  middlewares = []
  before (done) ->
    proxy.createServer(middlewares).listen ProxyPort, ->
      fakeServer.start (app)->
        fakePort = app.sslPort
        done()

  describe "pass a request through", ->
    it 'should return 200 for a valid request', (done)->
      request.get "https://127.0.0.1:#{fakePort}/status/200", (err, res, body) ->
        console.log err
        console.log err.message
        console.log err.stack
        assert.equal res.statusCode, 200
        assert.equal res.headers['x-powered-by'], "Express"
        done()
    it 'should return 404 for a 404 request', (done)->
      request.get "https://127.0.0.1:#{fakePort}/status/404", (err, res, body) ->
        assert.equal res.statusCode, 404
        done()
    it 'should post through params', (done)->
      request.post "https://127.0.0.1:#{fakePort}/status/200", {form:{key:'value'}, json:true}, (err, res, body) ->
        assert.equal body['key'], 'value'
        assert.equal res.statusCode, 200
        done()

