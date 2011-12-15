(function() {
  var Mf, fs, loadMiddlewares, loadSiteMiddleware, siteMiddlewares, sitesDir, stdin, watchMiddleware;

  fs = require('fs');

  Mf = require('../index');

  sitesDir = Mf.config.mfDir + '/sites';

  siteMiddlewares = {};

  stdin = process.openStdin();

  require('tty').setRawMode(true);

  stdin.on('keypress', function(chunk, key) {
    if (key && key.ctrl && key.name === 'r') {
      console.log("Reloading Middleware");
      loadMiddlewares();
    }
    if (key && key.ctrl && key.name === 'c') return process.exit();
  });

  loadMiddlewares = function() {
    var site, _i, _len, _ref, _results;
    siteMiddlewares = {};
    _ref = fs.readdirSync(sitesDir);
    _results = [];
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      site = _ref[_i];
      loadSiteMiddleware(site);
      _results.push(watchMiddleware(site));
    }
    return _results;
  };

  watchMiddleware = function(site) {
    return fs.watchFile("" + sitesDir + "/" + site, function(c, p) {
      return loadSiteMiddleware(site);
    });
  };

  loadSiteMiddleware = function(site) {
    var key;
    key = site.replace(/\.coffee$/, '').replace(/\.js$/, '');
    Mf.log.info("Loading: " + key);
    delete require.cache[sitesDir + '/' + site];
    siteMiddlewares[key] = require(sitesDir + '/' + site);
    fs.unwatchFile("" + sitesDir + "/" + site);
    return watchMiddleware(site);
  };

  exports.middleware = function() {
    var siteMiddleware;
    loadMiddlewares();
    siteMiddleware = function(req, res, next) {
      var key, m, middleware;
      middleware = null;
      for (key in siteMiddlewares) {
        m = siteMiddlewares[key];
        if (req.host.match(key)) {
          Mf.log.debug("Fiddling with " + req.host);
          middleware = m;
          break;
        }
      }
      if (middleware) {
        return middleware(Mf)(req, res, next);
      } else {
        return next();
      }
    };
    return [Mf.live_logger(), siteMiddleware];
  };

}).call(this);
