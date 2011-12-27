(function() {
  var usage;

  exports.middleware = function(Mf, args) {
    var minLength, responseFilter;
    Mf.config.transparent = true;
    minLength = args.minLength || 100;
    responseFilter = function(res) {
      var contentType;
      contentType = res.headers['content-type'];
      if (contentType && contentType.search(/html/) < 0) return false;
      if (res.statusCode !== 200) return false;
      if (res.length < Number(minLength)) return false;
      return true;
    };
    return [Mf.logger(null, responseFilter)];
  };

  usage = function() {
    console.error("Logs relevant tor traffice through a transparent proxy");
    console.error("minLength is the minumum length of the body, default 100");
    console.error("usage: tor [--minLength 1000]");
    return process.exit(-1);
  };

}).call(this);
