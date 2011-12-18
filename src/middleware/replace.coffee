sessionFilter = require '../session_filter'

# Can only be filtered by request for now
# Takes a function(bodyString){return "new value")
exports = module.exports = (replacer, filter) ->
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
      if res.isBinary
        res.headers['content-length'] = res.length
        writeHead.call(res, res.statusCode, res.headers)
        for b in res.body
          write.call(res, b)
        end.call(res)
      else
        content = ''
        for b in res.body
          content += b.toString('utf-8')

        # Can return false if no action needs to be taken
        replacedContent = replacer(content, req, res)
        content = replacedContent || content

        # Set the new length
        res.headers['content-length'] = content.length
        # No more gzip for you
        delete res.headers['content-encoding']

        writeHead.call(res, res.statusCode, res.headers)
        write.call(res, content)
        end.call(res)
    next()

