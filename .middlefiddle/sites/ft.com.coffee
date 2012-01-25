module.exports = (Mf) ->
  # I'm the Google, let me in!
  (req, res, next) ->
    req.headers['user-agent'] = "GoogleBot"
    next()
