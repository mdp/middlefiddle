(function() {
  var config, configFile, defaultConfig, homeDir, homeMfDir, log, mfDir, mfPath, mfPaths, path, userConfig, _, _i, _len;
  _ = require('underscore');
  path = require('path');
  homeDir = process.env['HOME'];
  homeMfDir = homeDir + "/.middlefiddle";
  mfDir = null;
  log = require('./logger');
  mfPaths = ['./.middlefiddle', homeMfDir];
  for (_i = 0, _len = mfPaths.length; _i < _len; _i++) {
    mfPath = mfPaths[_i];
    if (path.existsSync(mfPath)) {
      mfDir = mfPath;
      break;
    }
  }
  if (!mfDir) {
    mfDir = homeMfDir;
  }
  log.info("Using " + mfDir + " for cert/config/fiddle source");
  configFile = mfDir + "/config.json";
  try {
    userConfig = require(configFile);
  } catch (error) {
    log.warn("Unable to load " + configFile);
    userConfig = {};
  }
  defaultConfig = {
    mfDir: mfDir,
    httpPort: 8088,
    httpsPort: 8089,
    liveLoggerPort: 8411
  };
  config = _.extend(defaultConfig, userConfig);
  module.exports = config;
}).call(this);
