util            = require 'util'
url             = require 'url'
_               = require('underscore')
{Mangle}        = require "./mangle"
log             = require "./logger"
{request}       = require 'http'


exports.proxyHandler = (middlewares) ->
  app = (req, res, next) ->
    app.handle(req, res, next)
  _.extend app, proto
  app.stack = []
  app.use inbound
  for arg in middlewares
    app.use(arg)
  app.use outbound
  app

proto =
  use: (fn) ->
    @stack.push(fn)
  handle: (req, res, next) ->
    index = 0
    stack = @stack
    next = ->
      if layer = stack[index++]
        layer(req, res, next)
    next()

inbound = (req, res, next) ->
  res.downstream = res
  res.transform = (stream) ->
    stream.pipe(res.downstream)
    res.downstream = stream
  req.upstream = req
  req.transform = (stream) ->
    req.upstream = req.upstream.pipe(stream)
  next()

outbound = (req, res) ->
  destUrl = url.parse(req.url)
  options =
    port: destUrl.port
    hostname: destUrl.hostname
    path: destUrl.path
    headers: req.headers
    method: req.method
  upstream = request options
  req.upstream.pipe(upstream)
  upstream.on 'response', (uRes) ->
    res.emit 'response', uRes
    res.writeHead(uRes.statusCode, uRes.headers)
    uRes.pipe(res.downstream)

