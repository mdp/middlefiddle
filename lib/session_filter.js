(function() {
  var check, matches, _;

  _ = require('underscore');

  exports.matches = matches = function(filter, session) {
    var content, contentType, key, match, regex, s, t, test, _i, _j, _len, _len2, _ref;
    if (!filter) return true;
    if (filter === true) return true;
    if (_.isFunction(filter)) {
      match = filter(session) || false;
      return match;
    }
    if (!(_.keys(filter).length > 0)) return true;
    if (filter.contains && session.headers) {
      contentType = session.headers['content-type'] || '';
      if (session.body && (contentType.search(/^(image|audio|video)/) < 0)) {
        content = '';
        if (_.isRegExp(filter.contains)) {
          regex = filter.contains;
        } else {
          regex = new RegExp(filter.contains, 'g');
        }
        _ref = session.body;
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          s = _ref[_i];
          content += s.toString('utf-8');
        }
        if (content.search(regex) >= 0) return true;
      } else {
        return false;
      }
    }
    match = false;
    for (key in filter) {
      test = filter[key];
      if (session[key]) {
        if (_.isArray(test)) {
          for (_j = 0, _len2 = test.length; _j < _len2; _j++) {
            t = test[_j];
            if (check(session[key], t)) {
              match = true;
              break;
            }
          }
        } else if (check(session[key], test)) {
          match = true;
        }
      }
    }
    return match;
  };

  check = function(value, test) {
    if (_.isRegExp(test)) {
      if (value.search(test) >= 0) return true;
    } else if (_.isString(test)) {
      if (value.search(test) >= 0) return true;
    } else if (_.isNumber(test)) {
      if (value.toString().search(test.toString()) >= 0) return true;
    } else if (_.isFunction(test)) {
      if (test(value)) return true;
    }
  };

}).call(this);
