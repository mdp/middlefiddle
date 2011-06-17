fs              = require "fs"
sys             = require "sys"
http            = require "http"
url             = require "url"

safeParsePath = (proxy_url) ->
  if (proxy_url.match(/\/http\:\/\//))
    parseUrl = '/'
  parsedUrl = url.parse(proxy_url)
  return parsedUrl.pathname + parsedUrl.search

module.exports = proxy = (req, res, next) ->
  console.log(req.url)
  if (req.realHost?)
    server_host = req.realHost
  else
    server_host = req.headers['host']
  passed_opts = {method:req.method, path:safeParsePath(req.url), host:server_host, headers:req.headers, port:80}
  console.log(passed_opts)
  upstream_request = http.request passed_opts, (upstream_res) ->
    console.log(upstream_res.statusCode)
    upstream_res.on 'data', (chunk) ->
      res.write(chunk, 'binary')
    upstream_res.on 'end', ->
      res.end()
    res.writeHead(upstream_res.statusCode, upstream_res.headers)
  upstream_request.end()


