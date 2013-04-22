proxy = require '../src/proxy'
proxy.createServer([]).listen 15001, ->
  console.log "listening"
