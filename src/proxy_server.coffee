fs              = require "fs"
sys             = require "sys"
http            = require "http"
https           = require "./https"
url             = require "url"
connect         = require "connect"

safeParsePath = (proxyUrl) ->
  safeUrl = ''
  proxyUrl = url.parse(proxyUrl.slice(1))
  safeUrl += proxyUrl.pathname
  safeUrl += proxyUrl.search if proxyUrl.search?
  return safeUrl

module.exports = (middlewares...) ->
  proxy = new ProxyServer(middlewares)
  return proxy

class ProxyServer extends connect.HTTPServer

  # Shamelessly pilfered from POW
  o = (fn) -> (req, res, next)      -> fn req, res, next
  x = (fn) -> (err, req, res, next) -> fn err, req, res, next

  constructor: (middlewares) ->
    middlewares ?= []
    middlewares.unshift(@proxyHostCleanup)
    middlewares.push(@outboundProxy)
    super middlewares

  proxyHostCleanup: (req, res, next) ->
    req.url = safeParsePath(req.url)
    req.fullUrl = req.headers['host'] + req.url
    next()

  listenHTTPS: (port) ->
    https.createProxy(port, this._connectionListener)
    return this

  listen: (port) ->
    super port
    return this

  outboundProxy: (req, res, next) ->
    if (req.realHost?)
      server_host = req.realHost
    else
      server_host = req.headers['host']
    passed_opts = {method:req.method, path:req.url, host:server_host, headers:req.headers, port:req.port}
    upstream_request = http.request passed_opts, (upstream_res) ->
      upstream_res.on 'data', (chunk) ->
        res.write(chunk, 'binary')
      upstream_res.on 'end', ->
        res.end()
      res.writeHead(upstream_res.statusCode, upstream_res.headers)
    req.on 'data', (chunk) ->
      upstream_request.write(chunk)
    upstream_request.end()

