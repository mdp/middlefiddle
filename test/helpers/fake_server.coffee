# Test image server
fs = require 'fs'
express = require 'express'
http = require 'http'
https = require 'https'
app = express()
app.use express.bodyParser()
fakePort = app.port = 15880
fakeSslPort = app.sslPort = 15881
started = false

app.get '/status/:code', (req, res) ->
  json =
    headers: req.headers
  res.json(Number(req.params.code), json)

app.post '/status/:code', (req, res) ->
  res.json(Number(req.params.code), req.body)

app.start = (callback) ->
  if started
    callback(app)
  else
    started = true
    console.log "start server"
    options =
      key: fs.readFileSync('test/fixtures/keys/ssl-key.private.pem'),
      cert: fs.readFileSync('test/fixtures/keys/ssl-cert.pem')
    http.createServer(app).listen fakePort, ->
      https.createServer(options, app).listen fakeSslPort, ->
        callback(app)

module.exports = app
