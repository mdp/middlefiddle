_ = require('underscore')
fs = require('fs')
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
  if fs.existsSync(mfPath)
    mfDir = mfPath
    break
unless mfDir
  mfDir = defaultMfDir
log.info("Loading from #{mfDir}")

configFile = mfDir + "/config.json"
try
  userConfig = require(configFile)
catch error
  log.warn("Unable to load " + configFile)
  userConfig = {}

defaultConfig =
  mfDir: mfDir
  port: 8088

config = _.extend(defaultConfig, userConfig)
module.exports = config
