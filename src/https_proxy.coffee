STATES =
  UNCONNECTED: 0
  CONNECTING : 1,
  CONNECTED : 2

net = require('net')
tls = require('tls')
http = require('http')
HttpProxy = require('./http_proxy').HttpProxy
fs = require('fs')
path = require('path')
spawn = require('child_process').spawn

exports.createProxy = (middlewares...) ->
  proxy = new HttpsProxy(middlewares)
  return proxy

exports.HttpsProxy = class HttpsProxy extends HttpProxy

  constructor: (middlewares) ->
    middlewares ?= []
    middlewares.unshift(@proxyCleanup)
    middlewares.push(@outboundProxy)
    super middlewares

  hijackSsl: (headers, c) ->
    self = this
    match = headers.match("CONNECT +([^:]+):([0-9]+).*")
    host = match[1]
    port = match[2]
    generateCerts host, (tlsContext) =>
      pair = tls.createSecurePair(tlsContext, true, false, false)
      cleartext = pipe(pair, c)
      cleartext.on 'data', (data) ->
        console.log data.toString()
      httpServer = new http.Server
      httpServer.addListener.call this, 'request', self.handle
      http._connectionListener.call(httpServer, cleartext)
      c.write("HTTP/1.0 200 Connection established\r\nProxy-agent: MiddleFiddle\r\n\r\n")
      console.log("Sent 200 Proxy response")

  listen: (port) ->
    self = this
    tlsServer = net.createServer (c) ->
      headers = ''
      data = []
      state = STATES.UNCONNECTED
      c.addListener 'connect', ->
        console.log("Connected to proxy")
        state = STATES.CONNECTING
      c.addListener 'data', (data) ->
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
          # Proxying data
    tlsServer.listen(port)

badCerts = () ->
  tlsOptions =
    key: fs.readFileSync("certs/default.key"),
    cert: fs.readFileSync("certs/default.crt"),
    ca: fs.readFileSync('certs/ca.crt')

  tlsSettings = require('crypto').createCredentials(tlsOptions)
  tlsSettings.context.setCiphers('RC4-SHA:AES128-SHA:AES256-SHA')

generateCerts = (host, callback) ->
  if path.existsSync("certs/#{host}.key") && path.existsSync("certs/#{host}.crt")
    tlsOptions =
      key: fs.readFileSync("certs/#{host}.key"),
      cert: fs.readFileSync("certs/#{host}.crt"),
      ca: fs.readFileSync('certs/ca.crt')
    tlsSettings = require('crypto').createCredentials(tlsOptions)
    tlsSettings.context.setCiphers('RC4-SHA:AES128-SHA:AES256-SHA')
    callback(tlsSettings)
  else
    prc = spawn "bin/certgen.sh", [host]
    prc.on 'exit', (code, err) ->
      if code == 0
        console.log("Generated new certs for #{host}")
      else
        console.log(err)
    callback(badCerts())

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
