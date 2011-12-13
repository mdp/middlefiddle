(function() {
  var exports, fs, siteFiddlePath, siteFiddlePaths, siteMiddlewares, stdin, _i, _len;

  fs = require('fs');

  siteFiddlePaths = [Mf.config.mfDir + '/site_fiddles'];

  siteMiddlewares = [];

  for (_i = 0, _len = siteFiddlePaths.length; _i < _len; _i++) {
    siteFiddlePath = siteFiddlePaths[_i];
    siteMiddlewares = fs.readdirSync(siteFiddlePath);
    log.debug("Found" + siteMiddlewares);
  }

  stdin = process.openStdin();

  require('tty').setRawMode(true);

  stdin.on('keypress', function(chunk, key) {
    if (key && key.ctrl && key.name === 'r') console.log("Reload");
    if (key && key.ctrl && key.name === 'c') return process.exit();
  });

  exports = module.exports = function() {
    return function(req, res, next) {
      return next();
    };
  };

}).call(this);
