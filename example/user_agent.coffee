Mf = require '../lib/index'
Connect = require 'connect'

Mf.createProxy(Mf.logger(), Mf.user_agent("MSIE 6", /httpbin\.org/)).listen(8088)
Mf.createHttpsProxy(Mf.logger(), Mf.user_agent("MSIE 6", /httpbin\.org/)).listen(8089)
