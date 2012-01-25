module.exports = (Mf) ->
  (req, res, next) ->
    res.removeHeader('server')
    next()
