_ = require('underscore')
path = require('path')
homeDir = process.env['HOME']
defaultMfDir = homeDir + "/.middlefiddle"
mfDir = null
log = require './logger'


# Check first to see if we have a local .middlefiddle directory
# If not, default to $HOME/.middlefiddle
mfPaths = [
  process.cwd() + '/.middlefiddle'
  defaultMfDir
]

for mfPath in mfPaths
  if path.existsSync(mfPath)
    mfDir = mfPath
    break
unless mfDir
  mfDir = defaultMfDir
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
