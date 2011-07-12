(function() {
  var exports, fmt;
  exports = module.exports = function(options) {
    var stream;
    options || (options = {});
    stream = options.stream || process.stdout;
    return function(req, res, next) {
      var end;
      req._startTime = new Date;
      if (req._logging) {
        return next();
      }
      req._logging = true;
      end = res.end;
      res.end = function(chunk, encoding) {
        res.end = end;
        res.end(chunk, encoding);
        return stream.write(fmt(req, res) + '\n', 'ascii');
      };
      return next();
    };
  };
  fmt = function(req, res) {
    return "" + res.statusCode + " - " + req.fullUrl;
  };
}).call(this);
