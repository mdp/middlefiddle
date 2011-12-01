net       = require('net')
tls       = require('tls')
http      = require('http')
{HttpProxy} = require('./http_proxy')
certGenerator = require('./cert_generator')
log = require("./logger")

STATES =
  UNCONNECTED: 0,
  CONNECTING : 1,
  CONNECTED : 2

exports.createProxy = (middlewares) ->
  proxy = new HttpsProxy(middlewares)
  return proxy

exports.HttpsProxy = class HttpsProxy extends HttpProxy

  constructor: (middlewares) ->
    middlewares ?= []
    middlewares.unshift(@proxyCleanup)
    middlewares.push(@outboundProxy)
    super middlewares

  hijackSsl: (headers, c) ->
    match = headers.match("CONNECT +([^:]+):([0-9]+).*")
    host = match[1]
    port = match[2]
    certGenerator.build host, (tlsContext) =>
      pair = tls.createSecurePair(tlsContext, true, false, false)
      httpServer = new http.Server
      httpServer.addListener 'request', @handle
      cleartext = pipe(pair, c)
      http._connectionListener.call(this, cleartext)
      @httpAllowHalfOpen = false;
      c.write("HTTP/1.0 200 Connection established\r\nProxy-agent: MiddleFiddle\r\n\r\n")

  listen: (port) ->
    self = this
    tlsServer = net.createServer (c) ->
      headers = ''
      data = []
      state = STATES.UNCONNECTED
      c.addListener 'connect', ->
        state = STATES.CONNECTING
      c.addListener 'data', (data) ->
        if (state != STATES.CONNECTED)
          headers += data.toString()
          if headers.match("\r\n\r\n")
            state = STATES.CONNECTED
            if (headers.match(/^CONNECT/))
              self.hijackSsl(headers, c)
            else
              log.warn("Bad proxy call")
              log.debug("Sent: #{headers}")
              c.end()
        else
          # Proxying data
    tlsServer.listen(port)


pipe = (pair, socket) ->
  pair.encrypted.pipe(socket)
  socket.pipe(pair.encrypted)

  pair.fd = socket.fd
  cleartext = pair.cleartext
  cleartext.socket = socket
  cleartext.encrypted = pair.encrypted
  cleartext.authorized = false

  onerror = (e) ->
    if cleartext._controlReleased
      cleartext.emit('error', e)

  onclose = () ->
    socket.removeListener('error', onerror)
    socket.removeListener('close', onclose)
    socket.removeListener('timeout', ontimeout)

  ontimeout = () ->
    cleartext.emit('timeout')

  socket.on 'error', onerror
  socket.on 'close', onclose
  socket.on 'timeout', ontimeout

  return cleartext
