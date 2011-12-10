express = require('express')
io = require('socket.io')
ringBuffer = require('../utils/ringbuffer').create(1000)
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
    app.use express.static(__dirname + '/../../weblogger/public')

  app.get '/', (req, res) ->
    index = require('fs').readFileSync(__dirname + '/../../weblogger/index.html')
    res.send index.toString(), 200

  app.get '/:key', (req, res) ->
    requestLog = ringBuffer.retrieve(req.params.key)
    if requestLog
      res.send JSON.stringify(longFormat.apply(this, requestLog), 200)
    else
      res.send "Not Found", 404

  io.sockets.on 'connection', (socket) ->
    currentSocket = socket

  app.listen(config.liveLoggerPort)

exports = module.exports = (filter) ->
  log.info ("Starting LiveLogger on #{config.liveLoggerPort}")
  createServer()

  return (req, res, next) ->
    end = res.end
    res.end = ->
      res.end = end;
      if sessionFilter.matches(filter, res)
        weblog(req, res)
      res.end()
    next()

weblog = (req, res) ->
  res._logKey = ringBuffer.add([req, res])
  if currentSocket
    currentSocket.emit 'request', { request: shortFormat(req, res) }
    currentSocket.broadcast.emit 'request', { request: shortFormat(req, res) }

shortFormat = (req, res) ->
  id: res._logKey
  status: res.statusCode
  url: req._url
  method: req.method
  length: res._length
  time: (res._endTime - req._startTime)

longFormat = (req, res) ->
  req_headers = for key, val of req.headers
    "#{key}: #{val}"
  res_headers = for key, val of res.headers
    "#{key}: #{val}"
  responseContent = ''
  requestContent = ''
  for buffer in req._content
    requestContent += buffer.toString('utf-8')
    break if requestContent.length > 100000
  unless res.headers['content-type'] && res.headers['content-type'].match(impracticalMimeTypes)
    responseContent = ''
    for buffer in res._content
      responseContent += buffer.toString('utf-8')
      break if responseContent.length > 100000
  request:
    method: req.method
    headers: req_headers
    content: requestContent
  response:
    status: res.statusCode
    headers: res_headers
    content: responseContent
  time: (res._endTime - req._startTime)

