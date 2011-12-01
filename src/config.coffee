_ = require('underscore')
path = require('path')
homeDir = process.env['HOME']
homeMfDir = homeDir + "/.middlefiddle"
mfDir = null
log = require './logger'


# Check first to see if we have a local .middlefiddle directory
# If not, default to $HOME/.middlefiddle
mfPaths = [
  './.middlefiddle'
  homeMfDir
]

for mfPath in mfPaths
  if path.existsSync(mfPath)
    mfDir = mfPath
    break
unless mfDir
  mfDir = homeMfDir
log.info("Using #{mfDir} for cert/config/fiddle source")

configFile = mfDir + "/config.json"
try
  userConfig = require(configFile)
catch error
  log.warn("Unable to load " + configFile)
  userConfig = {}

defaultConfig =
  mfDir: mfDir
  httpPort: 8088
  httpsPort: 8089
  liveLoggerPort: 8411

config = _.extend(defaultConfig, userConfig)
module.exports = config
