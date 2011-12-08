(function() {
  var colors, level, sys, verbosity;

  sys = require('util');

  colors = require('colors');

  verbosity = function() {
    switch (process.env['LOGLEVEL']) {
      case "DEBUG":
        return 3;
      case "INFO":
        return 2;
      case "WARN":
        return 1;
      case "ERROR":
        return 0;
      default:
        return 2;
    }
  };

  level = verbosity();

  module.exports = {
    debug: function(msg) {
      if (level >= 3) return sys.puts(msg);
    },
    info: function(msg) {
      if (level >= 2) return sys.puts(msg.green);
    },
    warn: function(msg) {
      if (level >= 1) return sys.puts(("WARNING: " + msg).magenta);
    },
    error: function(msg) {
      if (level >= 0) return sys.puts(("ERROR: " + msg).red);
    }
  };

}).call(this);
