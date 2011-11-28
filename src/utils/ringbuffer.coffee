class Ringbuffer
  constructor: (@size)->
    @items = []

  add: (item) ->
    index = @items.length % @size
    item._timestamp = Number(new Date)
    @items[index] = item
    @buildKey(index, item)

  retrieve: (key) ->
    if !key.match(/^[0-9]+\-[0-9]+$/)
      return null
    index = Number(key.match(/^[0-9]+/)[0])
    ts = Number(key.match(/[0-9]+$/)[0])
    if index != undefined && ts
      item = @items[index]
      if item && item._timestamp == ts
        item
      else
        null

  buildKey: (index, item) ->
    "#{index}-#{item._timestamp}"


exports.create = (size) ->
  new Ringbuffer(size || 1000)
