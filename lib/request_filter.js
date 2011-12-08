(function() {
  var matches, _;

  _ = require('underscore');

  exports.matches = matches = function(filter, request) {
    var f, _i, _len;
    if (_.isArray(filter)) {
      for (_i = 0, _len = filter.length; _i < _len; _i++) {
        f = filter[_i];
        if (matches(f, request)) return true;
      }
    } else if (_.isRegExp(filter)) {
      return request.fullUrl.match(filter);
    } else if (_.isFunction(filter)) {
      return filter(request.fullUrl);
    } else if (_.isString(filter)) {
      if (filter.match(/^\/.+\/$/)) {
        return request.fullUrl.match(new RegExp(filter.substring(1, filter.length - 1)));
      } else {
        return request.fullUrl.match(filter);
      }
    } else {
      return true;
    }
  };

}).call(this);
