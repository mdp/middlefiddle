exports.createProxy      =    require("./http_proxy").createProxy
exports.createHttpsProxy =    require("./https_proxy").createProxy

middlewares =              require './middlewares'
for property of middlewares
  if (middlewares.hasOwnProperty(property))
    module.exports[property] = middlewares[property]
