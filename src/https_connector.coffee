STATES =
  UNCONNECTED: 0
  CONNECTING : 1,
  CONNECTED : 2

net = require('net')
tls = require('tls')
http = require('http')
fs = require('fs')

tlsContext = (host) ->
  tlsOptions =
    key: fs.readFileSync('certs/server.key'),
    cert: fs.readFileSync('certs/server.crt'),
    ca: fs.readFileSync('certs/ca.crt')
  tlsSettings = require('crypto').createCredentials(tlsOptions)
  tlsSettings.context.setCiphers('RC4-SHA:AES128-SHA:AES256-SHA')
  tlsSettings

module.exports = class HttpsConnector extends tls.Server
  constructor: (@port, @listener) ->
    @createProxy(port, listener)

  createProxy: (port, listener) =>
    self = this
    tlsServer = net.createServer (c) ->
      headers = ''
      data = []
      state = STATES.UNCONNECTED
      c.addListener 'connect', ->
        state = STATES.CONNECTING
      c.addListener 'data', (data) =>
        if (state != STATES.CONNECTED)
          headers += data.toString()
          if headers.match("\r\n\r\n")
            state = STATES.CONNECTED
            if (headers.match(/^CONNECT/))
              self.hijackSsl(headers, c)
            else
              console.log("Bad proxy call")
              console.log("Sent: #{headers}")
              c.end()
        else
          # console.log("Proxying data")
    tlsServer.listen(port)

  hijackSsl: (headers, c) ->
    match = headers.match("CONNECT +([^:]+):([0-9]+).*")
    host = match[1]
    port = match[2]
    console.log("Hijacking HTTPS")
    console.log("Host:" + host + "\nPort:" + port)
    c.write("HTTP/1.0 200 Connection established\r\n\r\n")
    pair = require('tls').createSecurePair(tlsContext(), true, false, false)
    cleartext = pipe(pair, c)
    this.addListener 'request', @wrappedHandle
    http._connectionListener.call(this, cleartext)

  wrappedHandle: (req, res, out) ->
    # Ugh
    @listener.handle.call(@listener, req, res, out)


pipe = (pair, socket) ->
  pair.encrypted.pipe(socket)
  socket.pipe(pair.encrypted)

  pair.fd = socket.fd

  cleartext = pair.cleartext

  cleartext.socket = socket
  cleartext.encrypted = pair.encrypted

  onerror = (e) ->
    if (cleartext._controlReleased)
      cleartext.emit('error', e)


  onclose = ->
    socket.removeListener('error', onerror)
    socket.removeListener('close', onclose)

  socket.on('error', onerror)
  socket.on('close', onclose)

  return cleartext
