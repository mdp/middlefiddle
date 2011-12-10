
  exports.middleware = function(Mf, args) {
    var requestFilter, user_agent;
    user_agent = args._.shift();
    if (args.url) {
      requestFilter = {
        _url: args.url
      };
    }
    return [Mf.weblogger(), Mf.user_agent(user_agent, requestFilter)];
  };
