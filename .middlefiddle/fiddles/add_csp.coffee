addCSP = (urlRegex) ->
  (req, res, next) ->
    if req.href.match(urlRegex)
      res.on 'headers', (headers) ->
        headers['x-content-security-policy'] = "allow 'self'"
    next()

exports.middleware = (Mf) ->
  addCSP(/\.com/)
