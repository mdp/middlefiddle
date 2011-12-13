_ = require 'underscore'

# Test the values in a reqeust or response
exports.matches = matches = (filter, session) ->
  if _.isFunction(filter)
    match = filter(session) || false
    return match
  return true unless _.keys(filter).length > 0

  # A word of warning about contains:
  # After a page loads you'll have it catched, and subsequent loads will
  # result in a likely 304, which of course won't show up
  if filter.contains && session.headers
    contentType = session.headers['content-type'] || ''
    if session.content && (contentType.search(/^(image|audio|video)/) < 0)
      content = ''
      regex = new RegExp(filter.contains, 'g')
      for s in session.content
        content += s.toString('utf-8')
      if(content.search(regex) >= 0)
        return true
    else
      return false

  match = false
  for key, test of filter
    if session[key]
      if _.isArray(test)
        for t in test
          if check(session[key], t)
            match = true
            break
      else if check(session[key], test)
        match = true
  return match

check = (value, test) ->
  if _.isRegExp(test)
    return true if value.search(test) >= 0
  else if _.isString(test)
    return true if value.search(test) >= 0
  else if _.isNumber(test)
    return true if value.toString().search(test.toString()) >= 0
  else if _.isFunction(test)
    return true if test(value)
