Mf = require('../lib/index');

Mf.createProxy(Mf.weblogger(), Mf.user_agent("iPhone", /twitter\.com/)).listen(8088).listenHTTPS(8089);
