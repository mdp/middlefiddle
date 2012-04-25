# Take the following command line arguments
# --url URL
# --status STATUSCODE
# --contains TEXT
exports.middleware = (Mf, args) ->
  checkArguments(args)
  if args.h
    usage()
  requestFilter = {}
  responseFilter = {}
  if args.url
    requestFilter.href = args.url
  if args.status
    responseFilter.statusCode = args.status
  if args.grep
    flags = 'g'
    flags += 'i' if args.i
    search = RegExp args.grep, flags
    Mf.log.info "Searching for \"#{search}\""
    responseFilter.contains = search

  [Mf.logger(requestFilter, responseFilter)]

checkArguments = (args) ->
  validArguments = ['grep', 'url', 'status']
  for prop, val of args
    if prop.search(/^[a-zA-Z0-9]+$/) >= 0
      if validArguments.indexOf(prop)
        usage()

usage = ->
  console.error "usage: mf logger --url URL --status STATUS --contains TEXT"
  console.error "--url/--status/--contains can be combined and used multiple time"
  process.exit -1
