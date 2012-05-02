addCSP = (urlRegex) ->
  (req, res, next) ->
    if req.href.match(urlRegex)
      res.addHeader 'x-content-security-policy', "allow 'self'"
    next()

exports.middleware = (Mf) ->
  addCSP(/\.com/)
