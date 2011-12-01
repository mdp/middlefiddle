# Require coffee-script to allow us to use .coffee proxies
require 'coffee-script'
log = require './logger'

# Let us find this in 'top'
process.title = "middlefiddle"

# Print valid command-line arguments and exit with a non-zero exit
usage = ->
  console.error "usage: mf [middleware]"
  process.exit -1
unless process.argv.length > 1
  usage()

passedArgs = process.argv.slice(3)
Mf = require './index' # Dependency injection for the middleware proxies

# Middleware are passed both the MiddleFiddle object, and any additional arguments
middleware = require(Mf.config.mfDir + '/fiddles/' + process.argv[2]).middleware(Mf, passedArgs)


log.info("Starting HTTP Proxy on port #{Mf.config.httpPort}")
log.info("Starting HTTPS Proxy on port #{Mf.config.httpsPort}")
Mf.createProxy.apply(this, middleware).listen(Mf.config.httpPort).listenHTTPS(Mf.config.httpsPort)
