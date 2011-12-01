(function() {
  exports.middleware = function(Mf, args) {
    return [Mf.weblogger(args)];
  };
}).call(this);
