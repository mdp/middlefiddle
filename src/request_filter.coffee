_ = require 'underscore'
exports.matches = matches = (filter, request) ->
  if _.isArray(filter)
    for f in filter
      return true if matches(f, request)
  else if _.isRegExp(filter)
    request.fullUrl.match(filter)
  else if _.isFunction(filter)
    filter(request.fullUrl)
  else if _.isString(filter)
    if filter.match(/^\/.+\/$/)
      request.fullUrl.match(new RegExp(filter.substring(1, filter.length - 1)))
    else
      request.fullUrl.match(filter)
  else
    true
