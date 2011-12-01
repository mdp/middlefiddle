(function() {
  var Mf, activeFiddle, fiddlePath, fiddlePaths, log, middleware, passedArgs, path, testPath, usage, _i, _len;
  require('coffee-script');
  path = require('path');
  log = require('./logger');
  process.title = "middlefiddle";
  usage = function() {
    console.error("usage: mf [middleware]");
    return process.exit(-1);
  };
  if (!(process.argv.length > 2)) {
    usage();
  }
  passedArgs = process.argv.slice(3);
  Mf = require('./index');
  fiddlePaths = [process.cwd(), Mf.config.mfDir + '/fiddles', __dirname + '/fiddles'];
  log.debug("Checking the following locations");
  log.debug(fiddlePaths);
  activeFiddle = null;
  for (_i = 0, _len = fiddlePaths.length; _i < _len; _i++) {
    fiddlePath = fiddlePaths[_i];
    testPath = fiddlePath + "/" + process.argv[2];
    if (path.existsSync(testPath + ".coffee") || path.existsSync(testPath + ".js")) {
      activeFiddle = testPath;
      break;
    }
  }
  if (activeFiddle === null) {
    log.error(("Can't find a fiddle named '" + process.argv[2] + "'. Looked in: ") + fiddlePaths);
    process.exit(-1);
  }
  middleware = require(activeFiddle).middleware(Mf, passedArgs);
  log.info("Starting HTTP Proxy on port " + Mf.config.httpPort);
  log.info("Starting HTTPS Proxy on port " + Mf.config.httpsPort);
  Mf.createProxy.apply(this, middleware).listen(Mf.config.httpPort).listenHTTPS(Mf.config.httpsPort);
}).call(this);
