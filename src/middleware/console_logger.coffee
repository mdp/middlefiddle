exports = module.exports = (options) ->
  options ||= {}
  stream = options.stream || process.stdout

  return (req, res, next) ->
    req._startTime = new Date

    if (req._logging)
      return next()

    req._logging = true
    end = res.end
    res.end = (chunk, encoding) ->
      res.end = end;
      res.end(chunk, encoding)
      stream.write(fmt(req, res) + '\n', 'ascii')
    next()

fmt = (req, res) ->
  "#{res.statusCode} - #{req.href}"
