
  exports.middleware = function(Mf, args) {
    var requestFilter, responseFilter;
    requestFilter = {};
    responseFilter = {};
    if (args.url) requestFilter.href = args.url;
    if (args.status) responseFilter.statusCode = args.status;
    if (args.contains) responseFilter.contains = args.contains;
    return [Mf.live_logger(requestFilter, responseFilter)];
  };
