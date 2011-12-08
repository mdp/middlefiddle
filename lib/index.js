(function() {
  var fs;

  fs = require('fs');

  exports.createProxy = require("./http_proxy").createProxy;

  exports.createHttpsProxy = require("./https_proxy").createProxy;

  exports.config = require("./config");

  fs.readdirSync(__dirname + '/middleware').forEach(function(filename) {
    var name;
    if (/\.js$/.test(filename)) {
      name = filename.substr(0, filename.lastIndexOf('.'));
      return exports.__defineGetter__(name, function() {
        return require('./middleware/' + name);
      });
    }
  });

  process.on('uncaughtException', function(err) {
    return console.log(err);
  });

}).call(this);
