(function() {
  var exports;
  exports = module.exports = function(ua, matchRegex) {
    matchRegex || (matchRegex = /(?:)/);
    return function(req, res, next) {
      if (req.fullUrl.match(matchRegex)) {
        req.headers['user-agent'] = ua;
      }
      return next();
    };
  };
}).call(this);
