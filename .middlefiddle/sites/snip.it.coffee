module.exports = (Mf) ->
  (req, res, next) ->
    req.headers['user-agent'] = "iPhone"
    next()
