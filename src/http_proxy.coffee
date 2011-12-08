Stream          = require "stream"
fs              = require 'fs'
zlib            = require "zlib"
http            = require "http"
https           = require "https"
url             = require "url"
connect         = require "connect"
log             = require "./logger"

safeParsePath = (req) ->

isSecure = (req) ->
  if req.client && req.client.pair
    true
  else if req.forceSsl
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
    if (req.realHost?)
      # Set request.realHost to alter the request destination destination
      log.debug("Overriding outbound host to:" + req.realHost)
      req._host = req.realHost
    else
      req._host = req.headers['host'].split(":")[0]

    # Dertermine outbound port
    # Sometime https proxy clients do not explicitly set the port to 443
    serverPort = req._host.split(":")[1]
    if serverPort?
      req._port = serverPort
    else if req.ssl
      req._port = 443
    else
      req._port = 80
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
    contentLogger(req)
    next()

  listenHTTPS: (port) ->
    httpsProxy = require './https_proxy'
    httpsProxy.createProxy(@middlewares).listen(port)

  listen: (port) ->
    super port
    return this

  outboundProxy: (req, res, next) ->
    passed_opts = {method:req.method, path:req.url, host:req._host, headers:req.headers, port:req._port}
    upstream_processor = (upstream_res) ->
      # Helpers for easier logging upstream
      res.statusCode = upstream_res.statusCode
      res.headers = upstream_res.headers
      contentLogger(res)

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
      log.error("ERROR: #{error}")
    if req.ssl
      upstream_request = https.request passed_opts, upstream_processor
    else
      upstream_request = http.request passed_opts, upstream_processor

    upstream_request.on 'error', (err)->
      log.error("Fail - #{req.method} - #{req.fullUrl}")
      log.error(err)
      res.end()
    upstream_request.end()


contentLogger = (stream) ->
  stream._content = []
  unzipper = zlib.createUnzip()
  unzipper.on 'data', (data) ->
    stream._content.push(data)
  switch (stream.headers['content-encoding'])
    when 'gzip'
      log.debug("Unzipping")
      stream.pipe(unzipper)
      break
    when 'deflate'
      log.debug("Deflating")
      stream.pipe(unzipper)
      break
    else
      stream.on 'data', (data)->
        stream._content.push(data)
      break
