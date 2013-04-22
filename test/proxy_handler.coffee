assert = require 'assert'
{Mangle} = require "#{process.cwd()}/src/mangle"
fakeServer = require './helpers/fake_server'
http = require 'http'
{proxyHandler} = require '../src/proxy_handler'
fakePort = null; ProxyPort = 15888
request = require('request').defaults({proxy:"http://127.0.0.1:#{ProxyPort}"})

describe 'A basic HTTP Proxy', ->
  middlewares = []
  middlewares.push (req, res, next) ->
    transform = (data, enc, done) ->
      @push data
      done()
    req.transform new Mangle(transform)
    res.transform new Mangle(transform)
    next()
  middlewares.push (req, res, next) ->
    transform = (data, enc, done) ->
      @push data
      done()
    req.transform new Mangle(transform)
    res.on 'response', (response) ->
      res.transform new Mangle(transform)
    next()
  before (done) ->
    http.createServer(proxyHandler(middlewares)).listen ProxyPort, ->
      fakeServer.start (app)->
        fakePort = app.port
        done()

  describe "pass a request through", ->
    it 'should return 200 for a valid request', (done)->
      request.get "http://127.0.0.1:#{fakePort}/status/200", (err, res, body) ->
        assert.equal res.statusCode, 200
        assert.equal res.headers['x-powered-by'], "Express"
        done()
    it 'should return 404 for a 404 request', (done)->
      request.get "http://127.0.0.1:#{fakePort}/status/404", (err, res, body) ->
        assert.equal res.statusCode, 404
        done()
    it 'should post through params', (done)->
      request.post "http://127.0.0.1:#{fakePort}/status/200", {form:{key:'value'}, json:true}, (err, res, body) ->
        assert.equal body['key'], 'value'
        assert.equal res.statusCode, 200
        done()

