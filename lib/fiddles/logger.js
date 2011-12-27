(function() {
  var checkArguments, usage;

  exports.middleware = function(Mf, args) {
    var requestFilter, responseFilter;
    checkArguments(args);
    if (args.h) usage();
    requestFilter = {};
    responseFilter = {};
    if (args.url) requestFilter.href = args.url;
    if (args.status) responseFilter.statusCode = args.status;
    if (args.contains) responseFilter.contains = args.contains;
    return [Mf.logger(requestFilter, responseFilter)];
  };

  checkArguments = function(args) {
    var prop, val, validArguments, _results;
    validArguments = ['contains', 'url', 'status'];
    _results = [];
    for (prop in args) {
      val = args[prop];
      if (prop.search(/^[a-zA-Z0-9]+$/) >= 0) {
        if (validArguments.indexOf(prop)) {
          _results.push(usage());
        } else {
          _results.push(void 0);
        }
      } else {
        _results.push(void 0);
      }
    }
    return _results;
  };

  usage = function() {
    console.error("usage: mf logger --url URL --status STATUS --contains TEXT");
    console.error("--url/--status/--contains can be combined and used multiple time");
    return process.exit(-1);
  };

}).call(this);
