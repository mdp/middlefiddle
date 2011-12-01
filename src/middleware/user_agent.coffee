requestFilter = require '../request_filter'
exports = module.exports = (ua, filter) ->

  return (req, res, next) ->
    if requestFilter.matches(filter,req)
      req.headers['user-agent'] = ua
    next()

