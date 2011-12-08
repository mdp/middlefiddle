(function() {
  var exports, requestFilter;

  requestFilter = require('../request_filter');

  exports = module.exports = function(ua, filter) {
    return function(req, res, next) {
      if (requestFilter.matches(filter, req)) req.headers['user-agent'] = ua;
      return next();
    };
  };

}).call(this);
