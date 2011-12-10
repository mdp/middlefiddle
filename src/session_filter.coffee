_ = require 'underscore'

# Test the values in a reqeust or response
exports.matches = matches = (filter, session) ->
  return true unless filter
  if filter.length == 0
    return true
  for key, test of filter
    if session[key]
      if _.isArray(test)
        matches = false
        for t in test
          if check(session[key], t)
            matches = true
            break
        return true if matches
      else
        check(session[key], test)

check = (value, test) ->
  if _.isRegExp(test)
    return true if value.match(test)
  else if _.isString(test)
    return true if value.match(test)
  else if _.isFunction(test)
    return true if test(value)
