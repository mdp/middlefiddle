(function() {
  var exports, sessionFilter;

  sessionFilter = require('../session_filter');

  exports = module.exports = function(ua, requestFilter) {
    return function(req, res, next) {
      if (sessionFilter.matches(requestFilter, req)) {
        req.headers['user-agent'] = ua;
      }
      return next();
    };
  };

}).call(this);
