exports.middleware = (Mf, args) ->
  user_agent = args._.shift()
  if args.url
    requestFilter =
      _url: args.url
  [Mf.weblogger(), Mf.user_agent(user_agent, requestFilter)]
