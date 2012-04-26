express = require('express')
io = require('socket.io')
ringBuffer = require('../utils/ringbuffer').create(100)
log = require '../logger'
sessionFilter = require '../session_filter'
config = require '../config'
currentSocket = null 
# Things I don't want to dump into the content field
impracticalMimeTypes = /^(image|audio|video)\//

createServer = (callback) ->
  app = express.createServer()
  io = io.listen(app, {"log level": 0})
  app.configure ->
    app.use express.static(__dirname + '/../../logger/public')

  app.get '/', (req, res) ->
    index = require('fs').readFileSync(__dirname + '/../../logger/index.html')
    res.send index.toString(), 200

  app.get '/all', (req, res) ->
    requestLogs = ringBuffer.all(req.params.key)
    if requestLogs
      items = []
      for request in requestLogs
        items.push(shortFormat.apply(this, [request[0], request[1]]))
      res.send JSON.stringify(items, 200)
    else
      res.send JSON.stringify([], 200)

  app.get '/:key', (req, res) ->
    requestLog = ringBuffer.retrieve(req.params.key)
    if requestLog
      res.send JSON.stringify(longFormat.apply(this, requestLog), 200)
    else
      res.send "Not Found", 404

  io.sockets.on 'connection', (socket) ->
    currentSocket = socket

  app.listen(config.liveLoggerPort)

exports = module.exports = (requestFilter, responseFilter) ->
  log.info ("Starting LiveLogger on #{config.liveLoggerPort}")
  createServer()

  return (req, res, next) ->
    unless sessionFilter.matches(requestFilter, req)
      return next()
    # Wait till we have the body unzipped and processed
    res.on 'body', () ->
      if sessionFilter.matches(responseFilter, res)
        liveLog(req, res)
    next()

liveLog = (req, res) ->
  res.mf.logKey = ringBuffer.add([req, res])
  if currentSocket
    currentSocket.emit 'request', { request: shortFormat(req, res) }
    currentSocket.broadcast.emit 'request', { request: shortFormat(req, res) }

shortFormat = (req, res) ->
  id: res.mf.logKey
  status: res.statusCode
  url: req.href
  method: req.method
  length: res.length
  time: (res.endTime - req.startTime)

longFormat = (req, res) ->
  req_headers = for key, val of req.headers
    "#{key}: #{val}"
  res_headers = for key, val of res.headers
    "#{key}: #{val}"
  requestContent = req.body.toString('utf-8')
  unless res.headers['content-type'] && res.headers['content-type'].match(impracticalMimeTypes)
    responseContent = res.body.toString('utf-8')

  request:
    url: req.href
    method: req.method
    headers: req_headers
    content: requestContent
  response:
    status: res.statusCode
    headers: res_headers
    content: responseContent
  time: (res.endTime - req.startTime)

