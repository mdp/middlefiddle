module.exports = (Mf) ->
  cookieKiller = (req, res, next) ->
    res.removeHeader("set-cookie")
  replacement = (string, req, res) ->
    contentType = res.headers['content-type'] || ''
    if contentType.search(/html/) >= 0
      string.replace(/Signup/g, "Sign-up")
    else
      false

  return [cookieKiller, Mf.replace(replacement)]

