module.exports = (Mf) ->
  ua = (req, res, next) ->
    req.headers['user-agent'] = "GoogleBotZ"
    res.on 'headers', (headers) ->
      headers['server'] = "Apache"
    next()

  replace = (string, req, res) ->
    if res.headers['content-type'].match('html')
      string.replace(/Lucky/gi, 'Unlucky')
    else
      false
  return [ua, Mf.replace(replace)]

