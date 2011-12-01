exports.middleware = (Mf, args) ->
  user_agent = args.shift()
  filter = args
  [Mf.weblogger(), Mf.user_agent(user_agent, filter)]
