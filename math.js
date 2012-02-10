listOfFile['snip/view'] = function(exports){

  var privateFucntion = function(){}
  var privateVariable = 1

  var PIE = 3.14

  exports.multiply = function(x, y){ return x*y };
  exports.circleArea = function(x) { PIE * x};
  return exports
}({})
