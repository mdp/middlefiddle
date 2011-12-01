(function() {
  exports.middleware = function(Mf, args) {
    var filter, user_agent;
    user_agent = args.shift();
    filter = args;
    return [Mf.weblogger(), Mf.user_agent(user_agent, filter)];
  };
}).call(this);
