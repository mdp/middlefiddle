{Transform}     = require "stream"
class exports.Mangle extends Transform

  constructor: (@writeHeadFn, @transformFn, @flushFn) ->
    @count = 0
    @id = Math.floor(10000 * Math.random())
    super
    @on 'pipe', (readStream) =>
      console.log "#{@id}: Listening to events from #{readStream.id}"
      readStream.on 'writeHead', =>
        console.log "Readstream #{readStream.id} emitted writeHead, #{@id} received"
        @writeHead(arguments)

  writeHead: (statusCode, headers) ->
    if @writeHeadFn
      console.log "WriteHeadFn on #{@id}"
      @writeHeadFn.call(this, statusCode, headers)
    else
      console.log("End #{@id}")
      @socket.writeHead(statusCode, headers)

  _transform: (data, enc, done) ->
    if @transformFn
      @transformFn.call(this, data, enc, done)
    else
      @push data
      done()

  _flush: (done) ->
    if @flushFn
      @flushFn.call(this, done)
    else
      done()
