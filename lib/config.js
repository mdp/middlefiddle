(function() {
  var config, configFile, defaultConfig, homeDir, log, mfDir, userConfig, _;
  _ = require('underscore');
  homeDir = process.env['HOME'];
  mfDir = homeDir + "/.middlefiddle";
  configFile = mfDir + "/config.json";
  log = require('./logger');
  defaultConfig = {
    mfDir: mfDir,
    httpPort: 8088,
    httpsPort: 8089,
    liveLoggerPort: 8411
  };
  try {
    userConfig = require(configFile);
  } catch (error) {
    log.warn("Unable to load " + configFile);
    userConfig = {};
  }
  config = _.extend(defaultConfig, userConfig);
  module.exports = config;
}).call(this);
