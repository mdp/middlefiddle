exports.middleware = (Mf, args) ->
  checkArgs(args)
  user_agent = args._.shift()
  if args.url
    requestFilter =
      href: args.url
  [Mf.logger(), Mf.user_agent(user_agent, requestFilter)]

usage = ->
  console.error "usage: user_agent UA_STRING [--url site.com]"
  process.exit -1

checkArgs = (args) ->
  unless args._.length > 0
    usage()
