exports.middleware = (Mf, args) ->
  Mf.config.transparent = true
  minLength = args.minLength || 100
  responseFilter = (res) ->
    contentType = res.headers['content-type']
    if contentType && contentType.search(/html/) < 0
      return false
    if res.statusCode != 200
      return false
    if res.length < Number(minLength)
      return false
    return true
  [Mf.logger(null, responseFilter)]

usage = ->
  console.error "Logs relevant tor traffice through a transparent proxy"
  console.error "minLength is the minumum length of the body, default 100"
  console.error "usage: tor [--minLength 1000]"
  process.exit -1

