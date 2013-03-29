fs = require 'fs'

exports.createProxy =    require("./proxy").createProxy
exports.config =    require("./config")
#exports.log = require('./logger')
#exports.defaultFiddle = () ->
  #require('./fiddles/sites')

#fs.readdirSync(__dirname + '/middleware').forEach (filename) ->
  #if (/\.js$/.test(filename))
    #name = filename.substr(0, filename.lastIndexOf('.'))
    #exports.__defineGetter__ name, ->
      #return require('./middleware/' + name)

# HTTPS DNS lookup errors throw an exception which
# it difficult to catch
# process.on 'uncaughtException', (err)->
  # console.log(err)

