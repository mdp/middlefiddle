(function() {
  var Mf, log, middleware, passedArgs, usage;
  require('coffee-script');
  log = require('./logger');
  process.title = "middlefiddle";
  usage = function() {
    console.error("usage: mf [middleware]");
    return process.exit(-1);
  };
  if (!(process.argv.length > 1)) {
    usage();
  }
  passedArgs = process.argv.slice(3);
  Mf = require('./index');
  middleware = require(Mf.config.mfDir + '/fiddles/' + process.argv[2]).middleware(Mf, passedArgs);
  log.info("Starting HTTP Proxy on port " + Mf.config.httpPort);
  log.info("Starting HTTPS Proxy on port " + Mf.config.httpsPort);
  Mf.createProxy.apply(this, middleware).listen(Mf.config.httpPort).listenHTTPS(Mf.config.httpsPort);
}).call(this);
