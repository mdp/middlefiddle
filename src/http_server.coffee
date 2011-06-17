fs              = require "fs"
sys             = require "sys"
connect         = require "connect"


{version} = JSON.parse fs.readFileSync __dirname + "/../package.json", "utf8"

# `HttpServer` is a subclass of
# [Connect](http://senchalabs.github.com/connect/)'s `HTTPServer` with
# but with the final middleware an external directed proxy
module.exports = class HttpServer extends connect.HTTPServer
