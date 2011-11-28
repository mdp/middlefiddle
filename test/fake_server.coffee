# Test image server
fs = require 'fs'
express = require 'express'

exports.startServer = (callback) ->
  app.listen 4040, ->
    socketDropper.listen(4041, callback)

app = express.createServer()

app.get '/wide.png', (req, res) ->
  fs.readFile 'test/images/wide-500x409.png', (err, data) ->
    console.log("Sending wide.png")
    res.writeHead(200, {"Content-Type": "image/png"})
    res.write(data, "binary")
    res.end()

app.get '/tall.jpg', (req, res) ->
  fs.readFile 'test/images/tall-354x640.jpg', (err, data) ->
    res.writeHead(200, {"Content-Type": "image/jpg"})
    res.write(data, "binary")
    res.end()

app.get '/square.jpg', (req, res) ->
  fs.readFile 'test/images/square-620x620.jpg', (err, data) ->
    res.writeHead(200, {"Content-Type": "image/jpg"})
    res.write(data, "binary")
    res.end()

app.get '/timeout.png', (req, res) ->
  res.writeHead(200, {"Content-Type": "image/jpg"})
  afterTime = ->
    res.end()
  setTimeout afterTime, 5000

app.get '/slow.png', (req, res) ->
  fs.readFile 'test/images/square-620x620.jpg', (err, data) ->
    res.writeHead(200, {"Content-Type": "image/jpg"})
    res.write(data, "binary")
    afterTime = ->
      res.end()
    setTimeout afterTime, 2000

# Returns a bad jpg. In this case HTML from google
app.get '/bad.jpg', (req, res) ->
  fs.readFile 'test/images/bad.jpg', (err, data) ->
    res.writeHead(200, {"Content-Type": "image/jpg"})
    res.write(data, "binary")
    res.end()

# Returns a bad jpg. In this case a pdf saying its a jpeg
app.get '/bad_pdf.jpg', (req, res) ->
  fs.readFile 'test/images/sample.pdf', (err, data) ->
    res.writeHead(200, {"Content-Type": "image/jpg"})
    res.write(data, "binary")
    res.end()

app.get '/redirect.png', (req, res) ->
  res.redirect('http://localhost:4040/wide.png');
  res.end()

app.get '/redirect_loop.png', (req, res) ->
  res.redirect('http://localhost:4040/redirect_loop.png');



# Create a bad server, just drops the connection
# unexpectedly.
net = require('net')
socketDropper = net.createServer (c) ->
  c.end('')
