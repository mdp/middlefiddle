fakeServer = require './fake_server'

fakeServer.start (app)->
  fakePort = app.sslPort
  console.log app.sslPort
