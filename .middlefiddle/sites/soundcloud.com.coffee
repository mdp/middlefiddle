fs = require 'fs'
module.exports = (Mf) ->
  (req, res, next) ->
    res.on 'body', ->
      if res.headers["content-type"] == 'audio/mpeg'
        fileName = req.path.replace(/^[a-zA-Z]/, '').split('.')[0]
        path = "#{process.env["HOME"]}/Downloads/soundcloud#{fileName}.mp3"
        fs.writeFile path, res.body, ->
          console.log "Saved #{res.body.length} bytes to #{path}"
    next()
