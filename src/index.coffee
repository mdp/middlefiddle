exports.createProxy =      require "./proxy_server"

middlewares =              require './middlewares'
for property of middlewares
  console.log(property)
  if (middlewares.hasOwnProperty(property))
    module.exports[property] = middlewares[property]
