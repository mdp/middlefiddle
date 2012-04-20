util            = require 'util'
_               = require('underscore')
Stream          = require "stream"
fs              = require 'fs'
zlib            = require "zlib"
http            = require "http"
https           = require "https"
url             = require "url"
connect         = require "connect"
config          = require "./config"
log             = require "./logger"
sessionFilter   = require "./session_filter"

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

  constructor: (middlewares) ->
    if _.isArray middlewares
      @middlewares = middlewares
    else
      @middlewares = [middlewares]
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
    req.port = req.headers['host'].split(":")[1]

    if isSecure(req)
      # Helper property
      req.href = "https://" + req.headers['host'] + req.path
      req.ssl = true
      req.port ||= 443
    else
      req.port ||= 80

      # Act as a completely transparent proxy
      # This implies that the sender is unaware of the proxy,
      # and being forced here from a network level redirect
      # Therefore the request come in as a normal path
      # Id est: '/' vs '/http://google.com'
      if config.transparent
        # Helper property
        req.href = "http://" + req.headers['host'] + req.url

      # Proxy requests send the full URL, not just the path
      # Node HTTP sees this at '/http://google.com'
      else
        safeUrl = ''
        proxyUrl = url.parse(req.url.slice(1))
        safeUrl += proxyUrl.pathname
        safeUrl += proxyUrl.search if proxyUrl.search?
        req.url = safeUrl
        req.port = proxyUrl.port
        # Helper property
        req.href = proxyUrl.href

    res.addHeader = addHeader
    res.removeHeader = removeHeader
    res.modifyHeaders = modifyHeaders
    bodyLogger req
    next()

  outboundProxy: (req, res, next) ->
    req.startTime = new Date
    passed_opts = {method:req.method, path:req.url, host:req.host, headers:req.headers, port:req.port}
    upstream_processor = (upstream_res) ->
      # Helpers for easier logging upstream
      res.statusCode = upstream_res.statusCode
      res.headers = upstream_res.headers
      res.modifyHeaders()

      if res.headers && res.headers['content-type'] && res.headers['content-type'].search(/(text)|(application)/) >= 0
        res.isBinary = false
      else
        res.isBinary = true

      # Store body data with the response
      bodyLogger(res)

      res.writeHead(upstream_res.statusCode, upstream_res.headers)
      upstream_res.on 'data', (chunk) ->
        res.write(chunk, 'binary')
        res.emit 'data', chunk
      upstream_res.on 'end', (data)->
        res.endTime = new Date
        res.end(data)
        res.emit 'end'
      upstream_res.on 'close', ->
        res.emit 'close'
      upstream_res.on 'error', ->
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

addHeader = (header, value) ->
  @addedHeaders ||= []
  @addedHeaders.push([header, value])

removeHeader = (header) ->
  @removedHeaders ||= []
  @removedHeaders.push(header)

modifyHeaders = () ->
  if @addedHeaders
    for header in @addedHeaders
      @headers[header[0]] = header[1]
  if @removedHeaders
    for header in @removedHeaders
      delete @headers[header]

bodyLogger = (stream, callback) ->
  callback ||= () ->
    stream.emit 'body'
  stream.body = []
  stream.length = 0
  unzipper = zlib.createUnzip()
  unzipper.on 'data', (data) ->
    stream.length += data.length
    stream.body.push(data)
  unzipper.on 'end', ->
    callback()
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
        stream.body.push(data)
        stream.length += data.length
      stream.on 'end', ()->
        callback()
      break
