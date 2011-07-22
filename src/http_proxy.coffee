fs              = require "fs"
sys             = require "sys"
http            = require "http"
https           = require "https"
url             = require "url"
connect         = require "connect"

safeParsePath = (req) ->

isSecure = (req) ->
  if req.client && req.client.pair
    true
  else
    false

exports.createProxy = (middlewares...) ->
  proxy = new HttpProxy(middlewares)
  return proxy

exports.HttpProxy = class HttpProxy extends connect.HTTPServer

  constructor: (@middlewares) ->
    @middlewares ?= []
    super @bookendedMiddleware()

  bookendedMiddleware: ->
    @middlewares.unshift(@proxyCleanup)
    @middlewares.push(@outboundProxy)
    @middlewares

  proxyCleanup: (req, res, next) ->
    if isSecure(req)
      req.fullUrl = "https://" + req.headers['host'] + req.url
      req.ssl = true
    else
      safeUrl = ''
      proxyUrl = url.parse(req.url.slice(1))
      safeUrl += proxyUrl.pathname
      safeUrl += proxyUrl.search if proxyUrl.search?
      req.url = safeUrl
      req.fullUrl = "http://" + req.headers['host'] + req.url
    next()

  listenHTTPS: (port) ->
    httpsProxy = require './https_proxy'
    httpsProxy.createProxy(@middlewares).listen(port)

  listen: (port) ->
    super port
    return this

  outboundProxy: (req, res, next) ->
    if (req.realHost?)
      server_host_port = req.realHost
    else
      server_host_port = req.headers['host']
    tmp = server_host_port.split(':')
    server_host = tmp[0]
    server_port = if tmp.length > 1 then tmp[1] else 80
    passed_opts = {method:req.method, path:req.url, host:server_host, headers:req.headers, port:server_port}
    upstream_processor = (upstream_res) ->
      # Helpers for easier logging upstream
      res.statusCode = upstream_res.statusCode
      res.headers = upstream_res.headers

      res.writeHead(upstream_res.statusCode, upstream_res.headers)
      upstream_res.on 'data', (chunk) ->
        res.emit 'data', chunk
        res.write(chunk, 'binary')
      upstream_res.on 'end', (data)->
        res.emit 'end', data
        res.end(data)
      upstream_res.on 'close', ->
        res.emit 'close'
      upstream_res.on 'error', ->
        res.emit 'end'
        res.abort()
    req.on 'data', (chunk) ->
      upstream_request.write(chunk)
    req.on 'error', (error) ->
      console.log("ERROR: #{error}")
    if req.ssl
      upstream_request = https.request passed_opts, upstream_processor
    else
      upstream_request = http.request passed_opts, upstream_processor
    upstream_request.on 'error', ->
      console.log("Fail")
      res.end()
    upstream_request.end()

