{Transform}     = require "stream"
class exports.Mangle extends Transform

  constructor: (mangler) ->
    super
    if mangler
      @['_transform'] =  mangler

  _transform: (data, enc, done) ->
    console.log "Override me to change this:" + data.toString()
    @push data
    done()
