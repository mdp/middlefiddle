STATES =
  UNCONNECTED: 0,
  CONNECTING : 1,
  CONNECTED : 2

net       = require('net')
tls       = require('tls')
http      = require('http')
HttpProxy = require('./http_proxy').HttpProxy
fs        = require('fs')
path      = require('path')
spawn     = require('child_process').spawn
chainGang = require('chain-gang')
chain     = chainGang.create({workers: 4})

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
    queueGenerateCerts host, (tlsContext) =>
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
              console.log("Bad proxy call")
              console.log("Sent: #{headers}")
              c.end()
        else
          # Proxying data
    tlsServer.listen(port)

generateCerts = (host, callback) ->
  # TODO: Make async
  currentCerts = getCerts(host)
  if currentCerts
    callback(currentCerts)
  else
    console.log("Generating certs for #{host}")
    prc = spawn "#{__dirname}/bin/certgen.sh", [host]
    prc.on 'exit', (code, err) ->
      if code == 0
        callback getCerts(host)
      else
        console.log(err)
        callback getCerts(host)

CERTS_DIR = "#{process.env['HOME']}/.middlefiddle/certs"
getCerts = (host) ->
  if path.existsSync("#{CERTS_DIR}/#{host}.key") && path.existsSync("#{CERTS_DIR}/#{host}.crt")
    tlsOptions =
      key: fs.readFileSync("#{CERTS_DIR}/#{host}.key"),
      cert: fs.readFileSync("#{CERTS_DIR}/#{host}.crt"),
      ca: fs.readFileSync("#{CERTS_DIR}/../ca.crt")
    tlsSettings = require('crypto').createCredentials(tlsOptions)
    tlsSettings.context.setCiphers('RC4-SHA:AES128-SHA:AES256-SHA')
    tlsSettings
  else
    return false

queueGenerateCerts = (host, tlsCallback) ->
  # Using Chaingang to prevent the forked
  # bash script from creating the same cert at the same time
  # Hacky, but it works
  # TODO: Gen and sign certs using native Node Openssl hooks
  if tlsSettings = getCerts(host)
    tlsCallback(tlsSettings)
  else
    console.log("Queuing up cert gen")
    callback = (err)->
      tlsCallback(getCerts(host))
    job = (host)->
      (worker) ->
        generateCerts host, ->
          worker.finish()
    chain.add job(host), host, callback

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
