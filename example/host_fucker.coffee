Mf = require '../lib/index'
Connect = require 'connect'

hostFucker = (origHost,host) ->
  (req, res, next) ->
    if origHost == req.headers['host']
      req.realHost = origHost
      req.headers['host'] = host
    return next()


Mf.createProxy(Connect.logger()).listen(8088).listenHTTPS(8089)
