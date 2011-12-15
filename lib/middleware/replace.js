(function() {
  var exports, sessionFilter;

  sessionFilter = require('../session_filter');

  exports = module.exports = function(find, replace, filter) {
    filter || (filter = {});
    return function(req, res, next) {
      var end, write, writeHead;
      if (!sessionFilter.matches(filter.request, req)) return next();
      writeHead = res.writeHead;
      write = res.write;
      end = res.end;
      res.writeHead = function(status, h) {};
      res.write = function(data) {};
      res.end = function(data) {};
      res.on('body', function() {
        var b, content, _i, _len, _ref;
        content = '';
        _ref = res.body;
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          b = _ref[_i];
          content += b.toString('utf-8');
        }
        content = content.replace(find, replace);
        res.headers['content-length'] = content.length;
        writeHead.call(res, res.statusCode, res.headers);
        write.call(res, content);
        return end.call(res);
      });
      return next();
    };
  };

}).call(this);
