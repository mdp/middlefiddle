exports = module.exports = (ua, matchRegex) ->
  matchRegex ||= //

  return (req, res, next) ->
    if req.fullUrl.match(matchRegex)
      req.headers['user-agent'] = ua
    next()

