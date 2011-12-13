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
    # Attach a namespace object to request and response for safer stashing of
    # properties and functions you'd like to have tag along
    req.mf ||= {}
    res.mf ||= {}
    # Request now has an explicit host which can be overridden later
    req.host = req.headers['host'].split(":")[0]

    # Dertermine outbound port
    # Sometime https proxy clients do not explicitly set the port to 443
    serverPort = req.host.split(":")[1]
    if serverPort?
      req.port = serverPort
    else if req.ssl
      req.port = 443
    else
      req.port = 80
    if isSecure(req)
      req.href = "https://" + req.headers['host'] + req.path
      req.ssl = true
    else
      # Proxy requests send the full URL, not just the path
      # Node HTTP sees this at '/http://google.com'
      safeUrl = ''
      proxyUrl = url.parse(req.url.slice(1))
      safeUrl += proxyUrl.pathname
      safeUrl += proxyUrl.search if proxyUrl.search?
      req.url = safeUrl
      req.href = "http://" + req.headers['host'] + req.url
    contentLogger(req)
    next()

  listenHTTPS: (port) ->
    httpsProxy = require './https_proxy'
    httpsProxy.createProxy(@middlewares).listen(port)

  listen: (port) ->
    super port
    return this

  outboundProxy: (req, res, next) ->
    req.startTime = new Date
    passed_opts = {method:req.method, path:req.url, host:req.host, headers:req.headers, port:req.port}
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
        res.endTime = new Date
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
  stream.content = []
  stream.length = 0
  unzipper = zlib.createUnzip()
  unzipper.on 'data', (data) ->
    stream.length += data.length
    stream.content.push(data)
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
        stream.content.push(data)
        stream.length += data.length
      break
