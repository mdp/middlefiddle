exports.logger = (regex) ->
  regex ?= /.*/
  (req, res, next) ->
    if req.fullUrl.match(regex)
      console.log(req.method + ": " + req.fullUrl)
      next()
    else
      next()
