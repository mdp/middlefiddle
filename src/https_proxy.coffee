STATES =
  CONNECTING : 0,
  CONNECTED : 1,

net = require('net')
tls = require('tls')
fs = require('fs')
tls_options =
  key: fs.readFileSync('middlefiddle.pem'),
  cert: fs.readFileSync('middlefiddle-cert.pem'),
  ca: fs.readFileSync('middlefiddle-cert.pem')

tls_context = require('crypto').createCredentials(tls_options)
tls_context.context.setCiphers('RC4-SHA:AES128-SHA:AES256-SHA')

hijack_ssl = (headers, c, listener) ->
  match = headers.match("CONNECT +([^:]+):([0-9]+).*")
  host = match[1]
  port = match[2]
  console.log("Hijacking HTTPS")
  console.log("Host:" + host + "\nPort:" + port)
  c.write("HTTP/1.0 200 Connection established\r\n\r\n")
  pair = require('tls').createSecurePair(tls_context, true, false, false)
  cleartext = pipe(pair, c)
  cleartext.addListener 'data', listener

exports.createProxy = (port, listener) ->
  tlsServer = net.createServer (c) ->
    headers = ''
    data = []
    c.addListener 'connect', ->
      console.log("Connecting")
      state = STATES.CONNECTING
    c.addListener 'data', (data) ->
      console.log("getting data chunk")
      if (state == STATES.CONNECTING)
        headers += data.toString()
        console.log(headers)
        if (headers.match("\r\n\r\n"))
          state = STATES.CONNECTED
          console.log("processing headers")
          if (headers.match(/^CONNECT/))
            hijack_ssl(headers, c, listener)
            c.removeListener(this)
          else
            console.log("Bad proxy call")
            console.log("Sent: #{headers}")
            c.end()
      else
        console.log("Proxying data")
  tlsServer.listen(port)


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
