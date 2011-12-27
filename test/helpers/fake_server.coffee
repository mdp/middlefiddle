# Test image server
fs = require 'fs'
express = require 'express'
app = express.createServer()
app.listen 4040

app.get '/status/:code', (req, res) ->
  res.send('Status code: ' + req.params.code, Number(req.params.code));

