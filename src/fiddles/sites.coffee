# This is the default Fiddle loaded when you start MiddleFiddle
# Logs traffic to the weblogger, and injects middleware into sites
# using files found in .middlefiddle/site/*.coffee[.js]
# Sites are matched to the host
# Example:
# google.com.coffee will run on any request to google.com as well as www.google.com
#
fs = require 'fs'
Mf = require '../index'
sitesDir = Mf.config.mfDir + '/sites'
siteMiddlewares = {}

# To reload middlewares, simple press Ctrl-R
stdin = process.openStdin()
require('tty').setRawMode(true)

stdin.on 'keypress', (chunk, key) ->
  if (key && key.ctrl && key.name == 'r')
    console.log("Reloading Middleware")
    loadMiddlewares()
  if (key && key.ctrl && key.name == 'c')
    process.exit()

# Looks in '/sites' inside you .middlefiddle directory
# Matches to the host
loadMiddlewares = () ->
  siteMiddlewares = {}
  for site in fs.readdirSync(sitesDir)
    loadSiteMiddleware(site)
    watchMiddleware(site)

watchMiddleware = (site) ->
  fs.watchFile "#{sitesDir}/#{site}", (c, p) ->
    loadSiteMiddleware(site)

loadSiteMiddleware = (site) ->
  key = site.replace(/\.coffee$/,'').replace(/\.js$/,'')
  Mf.log.info("Loading: #{key}")
  delete require.cache[sitesDir + '/' + site]
  siteMiddlewares[key] = require(sitesDir + '/' + site)
  fs.unwatchFile "#{sitesDir}/#{site}"
  watchMiddleware(site)

exports.middleware = () ->
  loadMiddlewares()

  siteMiddleware = (req, res, next) ->
    middleware = null
    for key, m of siteMiddlewares
      if req.host.match(key)
        Mf.log.debug("Fiddling with #{req.host}")
        middleware = m
        break
    if middleware
      return middleware(Mf)(req, res, next)
    else
      return next()

  return [Mf.live_logger(), siteMiddleware]
