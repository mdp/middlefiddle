STATES =
  UNCONNECTED: 0
  CONNECTING : 1,
  CONNECTED : 2

net = require('net')
tls = require('tls')
http = require('http')
fs = require('fs')
spawn = require('child_process').spawn


exports.createProxy =  (port, listener) =>
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
            new HijackSsl(headers, c, listener)
          else
            console.log("Bad proxy call")
            console.log("Sent: #{headers}")
            c.end()
      else
        console.log("Proxying data")
  tlsServer.listen(port)

generateCerts = (host, callback) ->
  prc = spawn "bin/certgen.sh", [host]
  prc.on 'exit', (code) ->
    console.log("Done with #{code}")
    if code == 0
      tlsOptions =
        key: fs.readFileSync("certs/#{host}.key"),
        cert: fs.readFileSync("certs/#{host}.crt"),
        ca: fs.readFileSync('certs/ca.crt')
      tlsSettings = require('crypto').createCredentials(tlsOptions)
      tlsSettings.context.setCiphers('RC4-SHA:AES128-SHA:AES256-SHA')
      callback(tlsSettings)

class HijackSsl extends http.Server
  constructor: (headers, c, @listener) ->
    match = headers.match("CONNECT +([^:]+):([0-9]+).*")
    host = match[1]
    port = match[2]
    generateCerts host, (tlsContext) =>
      c.write("HTTP/1.0 200 Connection established\r\nProxy-agent: MiddleFiddle\r\n\r\n")
      console.log("Sent 200 Proxy response")
      pair = require('tls').createSecurePair(tlsContext, true, false, false)
      cleartext = pipe(pair, c)
      cleartext.on 'data', (data) ->
        console.log data.toString()
      http._connectionListener.call(this, cleartext)
      this.addListener 'request', @wrappedHandle

  wrappedHandle: (req, res, out) ->
    # Ugh
    console.log("wrapping it")
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
