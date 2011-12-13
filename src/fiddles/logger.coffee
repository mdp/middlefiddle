exports.middleware = (Mf, args) ->
  requestFilter = {}
  responseFilter = {}
  if args.url
    requestFilter.href = args.url
  if args.status
    responseFilter.statusCode = args.status
  if args.contains
    responseFilter.contains = args.contains

  [Mf.live_logger(requestFilter, responseFilter)]
