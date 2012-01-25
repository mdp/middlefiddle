sessionFilter = require '../session_filter'
exports = module.exports = (ua, requestFilter) ->
  return (req, res, next) ->
    if sessionFilter.matches(requestFilter,req)
      req.headers['user-agent'] = ua
    next()

