net       = require('net')
{Buffer}  = require('buffer')
_         = require('underscore')
tls       = require('tls')
http      = require('http')
{proxyHandler} = require('./proxy_handler')
certGenerator = require('./cert_generator')
log = require("./logger")

STATES =
  UNCONNECTED: 0,
  CONNECTING : 1,
  CONNECTED : 2

exports.createServer = (middlewares) ->
  proxy = new Proxy(middlewares)
  return proxy


Proxy = (middlewares) ->
  self = this
  @httpServer = http.createServer(proxyHandler(middlewares))
  @server = net.createServer (c) ->
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
            self.hijackHttp(headers, c)

Proxy.prototype.listen = (port, callback) ->
  @server.listen(port, callback)


Proxy.prototype.hijackSsl = (headers, c) ->
  match = headers.match("CONNECT +([^:]+):([0-9]+).*")
  host = match[1]
  port = match[2]
  certGenerator.build host, (tlsContext) =>
    pair = tls.createSecurePair(tlsContext, true, false, false)
    @httpServer.httpAllowHalfOpen = false;
    http._connectionListener.call(@httpServer, pair.cleartext)
    pair.encrypted.pipe(c)
    c.pipe(pair.encrypted)
    c.write("HTTP/1.0 200 Connection established\r\nProxy-agent: MiddleFiddle\r\n\r\n")

Proxy.prototype.hijackHttp = (headers, c) ->
  @httpServer.httpAllowHalfOpen = false;
  http._connectionListener.call(@httpServer,c)
  buffer = new Buffer(headers)
  c.ondata buffer, 0, Buffer.byteLength(headers)


# TODO: Thing probably still needs to be used to prevent errors from bubling up
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
