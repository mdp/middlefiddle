Mf = require '../lib/index'

hostFucker = (origHost,host) ->
  (req, res, next) ->
    if origHost == req.headers['host']
      req.realHost = origHost
      req.headers['host'] = host
    return next()


Mf.createProxy(Mf.logger()).listen(8080).listenHTTPS(8081)
