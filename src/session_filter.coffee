_ = require 'underscore'
# Test the values in a reqeust or response
exports.matches = matches = (filter, session) ->
  return true unless filter
  for key, test of filter
    if session[key]
      if _.isArray(test)
        for t in test
          return true if check(session[key], t)
      else
        check(session[key], test)

check = (value, test) ->
  if _.isRegExp(test)
    return true if value.match(test)
  else if _.isString(test)
    return true if value.match(test)
  else if _.isFunction(test)
    return true if test(value)
