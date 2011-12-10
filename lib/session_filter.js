(function() {
  var check, matches, _;

  _ = require('underscore');

  exports.matches = matches = function(filter, session) {
    var key, t, test, _i, _len, _results;
    if (!filter) return true;
    if (filter.length === 0) return true;
    _results = [];
    for (key in filter) {
      test = filter[key];
      if (session[key]) {
        if (_.isArray(test)) {
          matches = false;
          for (_i = 0, _len = test.length; _i < _len; _i++) {
            t = test[_i];
            if (check(session[key], t)) {
              matches = true;
              break;
            }
          }
          if (matches) {
            return true;
          } else {
            _results.push(void 0);
          }
        } else {
          _results.push(check(session[key], test));
        }
      } else {
        _results.push(void 0);
      }
    }
    return _results;
  };

  check = function(value, test) {
    if (_.isRegExp(test)) {
      if (value.match(test)) return true;
    } else if (_.isString(test)) {
      if (value.match(test)) return true;
    } else if (_.isFunction(test)) {
      if (test(value)) return true;
    }
  };

}).call(this);
