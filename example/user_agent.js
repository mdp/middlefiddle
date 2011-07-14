Mf = require('../lib/index');

Mf.createProxy(Mf.logger(), Mf.user_agent("MSIE 6", /httpbin\.org/)).listen(8088).listenHTTPS(8089);
