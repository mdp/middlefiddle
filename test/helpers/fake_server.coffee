# Test image server
fs = require 'fs'
express = require 'express'
app = express.createServer()
app.use express.bodyParser()

app.get '/status/:code', (req, res) ->
  json =
    headers: req.headers
  res.json(Number(req.params.code), json)

app.post '/status/:code', (req, res) ->
  res.json(Number(req.params.code), req.body)

module.exports = app
