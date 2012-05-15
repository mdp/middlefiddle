module.exports = (Mf) ->
  (req, res, next) ->
    res.on 'headers', (headers) ->
      headers['server'] = "IIS 1.0"
    next()
