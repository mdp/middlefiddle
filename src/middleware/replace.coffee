sessionFilter = require '../session_filter'

# Can only be filtered by request
exports = module.exports = (find, replace, filter) ->
  filter ||= {}
  return (req, res, next) ->
    if !sessionFilter.matches(filter.request, req)
      return next()
    writeHead = res.writeHead
    write = res.write
    end = res.end
    res.writeHead = (status, h) ->
      # Nope
    res.write = (data) ->
      # Nope
    res.end = (data) ->
      # Nope
    res.on 'body', ->
      content = ''
      for b in res.body
        content += b.toString('utf-8')
      content = content.replace(find, replace)
      res.headers['content-length'] = content.length
      writeHead.call(res, res.statusCode, res.headers)
      write.call(res, content)
      end.call(res)
    next()

