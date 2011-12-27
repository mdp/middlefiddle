(function() {
  var checkArgs, usage;

  exports.middleware = function(Mf, args) {
    var requestFilter, user_agent;
    checkArgs(args);
    user_agent = args._.shift();
    if (args.url) {
      requestFilter = {
        href: args.url
      };
    }
    return [Mf.logger(), Mf.user_agent(user_agent, requestFilter)];
  };

  usage = function() {
    console.error("usage: user_agent UA_STRING [--url site.com]");
    return process.exit(-1);
  };

  checkArgs = function(args) {
    if (!(args._.length > 0)) return usage();
  };

}).call(this);
