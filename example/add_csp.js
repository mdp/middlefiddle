var Mf = require('../lib/index');

var addCSP = function(urlRegex) {
  return function(req, res, next){
    if (req.fullUrl.match(urlRegex)) {
      var writeHead = res.writeHead;
      res.writeHead = function(){
        var headers = arguments[arguments.length-1];
        var statusCode = arguments[0];
        headers['x-content-security-policy'] = "allow 'self'";
        writeHead.call(res, statusCode, headers);
      };
    }
    next();
  };
};

Mf.createProxy(addCSP(/google.com/)).listen(8088).listenHTTPS(8089);
