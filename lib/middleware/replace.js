(function() {
  var exports, sessionFilter;

  sessionFilter = require('../session_filter');

  exports = module.exports = function(replacer, filter) {
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
        var b, content, replacedContent, _i, _j, _len, _len2, _ref, _ref2;
        if (res.isBinary) {
          res.headers['content-length'] = res.length;
          writeHead.call(res, res.statusCode, res.headers);
          _ref = res.body;
          for (_i = 0, _len = _ref.length; _i < _len; _i++) {
            b = _ref[_i];
            write.call(res, b);
          }
          return end.call(res);
        } else {
          content = '';
          _ref2 = res.body;
          for (_j = 0, _len2 = _ref2.length; _j < _len2; _j++) {
            b = _ref2[_j];
            content += b.toString('utf-8');
          }
          replacedContent = replacer(content, req, res);
          content = replacedContent || content;
          res.headers['content-length'] = content.length;
          delete res.headers['content-encoding'];
          writeHead.call(res, res.statusCode, res.headers);
          write.call(res, content);
          return end.call(res);
        }
      });
      return next();
    };
  };

}).call(this);
