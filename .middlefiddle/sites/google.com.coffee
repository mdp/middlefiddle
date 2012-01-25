module.exports = (Mf) ->
  ua = (req, res, next) ->
    req.headers['user-agent'] = "GoogleBotZ"
    res.addHeader("server", "Apachame")
    next()

  replace = (string, req, res) ->
    if res.headers['content-type'].match('html')
      string.replace(/Lucky/gi, 'Unlucky')
    else
      false
  return [ua, Mf.replace(replace)]

