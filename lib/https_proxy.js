(function() {
  var HttpProxy, HttpsProxy, STATES, certGenerator, http, log, net, pipe, tls;
  var __hasProp = Object.prototype.hasOwnProperty, __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor; child.__super__ = parent.prototype; return child; };

  net = require('net');

  tls = require('tls');

  http = require('http');

  HttpProxy = require('./http_proxy').HttpProxy;

  certGenerator = require('./cert_generator');

  log = require("./logger");

  STATES = {
    UNCONNECTED: 0,
    CONNECTING: 1,
    CONNECTED: 2
  };

  exports.createProxy = function(middlewares) {
    var proxy;
    proxy = new HttpsProxy(middlewares);
    return proxy;
  };

  exports.HttpsProxy = HttpsProxy = (function() {

    __extends(HttpsProxy, HttpProxy);

    function HttpsProxy(middlewares) {
      if (middlewares == null) middlewares = [];
      middlewares.unshift(this.proxyCleanup);
      middlewares.push(this.outboundProxy);
      HttpsProxy.__super__.constructor.call(this, middlewares);
    }

    HttpsProxy.prototype.hijackSsl = function(headers, c) {
      var host, match, port;
      var _this = this;
      match = headers.match("CONNECT +([^:]+):([0-9]+).*");
      host = match[1];
      port = match[2];
      return certGenerator.build(host, function(tlsContext) {
        var cleartext, httpServer, pair;
        pair = tls.createSecurePair(tlsContext, true, false, false);
        httpServer = new http.Server;
        httpServer.addListener('request', _this.handle);
        cleartext = pipe(pair, c);
        http._connectionListener.call(_this, cleartext);
        _this.httpAllowHalfOpen = false;
        return c.write("HTTP/1.0 200 Connection established\r\nProxy-agent: MiddleFiddle\r\n\r\n");
      });
    };

    HttpsProxy.prototype.listen = function(port) {
      var self, tlsServer;
      self = this;
      tlsServer = net.createServer(function(c) {
        var data, headers, state;
        headers = '';
        data = [];
        state = STATES.UNCONNECTED;
        c.addListener('connect', function() {
          return state = STATES.CONNECTING;
        });
        return c.addListener('data', function(data) {
          if (state !== STATES.CONNECTED) {
            headers += data.toString();
            if (headers.match("\r\n\r\n")) {
              state = STATES.CONNECTED;
              if (headers.match(/^CONNECT/)) {
                return self.hijackSsl(headers, c);
              } else {
                log.warn("Bad proxy call");
                log.debug("Sent: " + headers);
                return c.end();
              }
            }
          }
        });
      });
      return tlsServer.listen(port);
    };

    return HttpsProxy;

  })();

  pipe = function(pair, socket) {
    var cleartext, onclose, onerror, ontimeout;
    pair.encrypted.pipe(socket);
    socket.pipe(pair.encrypted);
    pair.fd = socket.fd;
    cleartext = pair.cleartext;
    cleartext.socket = socket;
    cleartext.encrypted = pair.encrypted;
    cleartext.authorized = false;
    onerror = function(e) {
      if (cleartext._controlReleased) return cleartext.emit('error', e);
    };
    onclose = function() {
      socket.removeListener('error', onerror);
      socket.removeListener('close', onclose);
      return socket.removeListener('timeout', ontimeout);
    };
    ontimeout = function() {
      return cleartext.emit('timeout');
    };
    socket.on('error', onerror);
    socket.on('close', onclose);
    socket.on('timeout', ontimeout);
    return cleartext;
  };

}).call(this);
