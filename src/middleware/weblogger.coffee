zlib = require 'zlib'
express = require('express')
io = require('socket.io')
ringBuffer = require('../utils/ringbuffer').create(1000)
log = require '../logger'
requestFilter = require '../request_filter'
config = require '../config'
currentSocket = null

logContentEnabled = (res) ->
  type = res.headers['content-type'].match(/^([^\;]+)/)[1]
  type.match(/^text/)

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
      res.send JSON.stringify(ringBuffer.retrieve(req.params.key)), 200
    else
      res.send "Not Found", 404

  io.sockets.on 'connection', (socket) ->
    currentSocket = socket

  app.listen(config.liveLoggerPort)

exports = module.exports = (filter) ->
  log.info ("Starting LiveLogger on #{config.liveLoggerPort}")
  createServer()

  return (req, res, next) ->
    if !requestFilter.matches(filter, req)
      return next()

    req._startTime = new Date
    res._length = 0
    res._content = ''

    if (req._logging)
      return next()

    req._logging = true
    end = res.end
    res.on 'data', (data) ->
      res._length += data.length
      res._content += data.toString('binary')
    res.end = ->
      res.end = end;
      weblog(req, res)
      res.end()
    next()

weblog = (req, res) ->
  logger = (req, res)->
    res._logKey = ringBuffer.add(longFormat(req, res))
    if currentSocket
      currentSocket.emit 'request', { request: shortFormat(req, res) }
      currentSocket.broadcast.emit 'request', { request: shortFormat(req, res) }
  if res.headers && res.headers['content-encoding'] && res.headers['content-encoding'].match(/gzip/)
    zlib.unzip new Buffer(res._content, 'binary'), (err, buffer)->
      res._content = buffer.toString('utf-8')
      logger(req, res)
  else
    res._content = res._content.toString('utf-8')
    logger(req, res)

shortFormat = (req, res) ->
  id: res._logKey
  status: res.statusCode
  url: req.fullUrl
  method: req.method
  length: res._length
  time: (new Date - req._startTime)

longFormat = (req, res) ->
  req_headers = for key, val of req.headers
    "#{key}: #{val}"
  res_headers = for key, val of res.headers
    "#{key}: #{val}"
  request:
    method: req.method
    headers: req_headers
  response:
    status: res.statusCode
    headers: res_headers
    content: res._content
  time: (new Date - req._startTime)

