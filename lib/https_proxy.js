(function() {
  var CERTS_DIR, HttpProxy, HttpsProxy, STATES, fs, generateCerts, getCerts, http, net, path, pipe, spawn, tls;
  var __hasProp = Object.prototype.hasOwnProperty, __extends = function(child, parent) {
    for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; }
    function ctor() { this.constructor = child; }
    ctor.prototype = parent.prototype;
    child.prototype = new ctor;
    child.__super__ = parent.prototype;
    return child;
  }, __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };
  STATES = {
    UNCONNECTED: 0,
    CONNECTING: 1,
    CONNECTED: 2
  };
  net = require('net');
  tls = require('tls');
  http = require('http');
  HttpProxy = require('./http_proxy').HttpProxy;
  fs = require('fs');
  path = require('path');
  spawn = require('child_process').spawn;
  exports.createProxy = function(middlewares) {
    var proxy;
    proxy = new HttpsProxy(middlewares);
    return proxy;
  };
  exports.HttpsProxy = HttpsProxy = (function() {
    __extends(HttpsProxy, HttpProxy);
    function HttpsProxy(middlewares) {
            if (middlewares != null) {
        middlewares;
      } else {
        middlewares = [];
      };
      middlewares.unshift(this.proxyCleanup);
      middlewares.push(this.outboundProxy);
      HttpsProxy.__super__.constructor.call(this, middlewares);
    }
    HttpsProxy.prototype.hijackSsl = function(headers, c) {
      var host, match, port;
      match = headers.match("CONNECT +([^:]+):([0-9]+).*");
      host = match[1];
      port = match[2];
      return generateCerts(host, __bind(function(tlsContext) {
        var cleartext, httpServer, pair;
        pair = tls.createSecurePair(tlsContext, true, false, false);
        httpServer = new http.Server;
        httpServer.addListener('request', this.handle);
        cleartext = pipe(pair, c);
        http._connectionListener.call(this, cleartext);
        this.httpAllowHalfOpen = false;
        return c.write("HTTP/1.0 200 Connection established\r\nProxy-agent: MiddleFiddle\r\n\r\n");
      }, this));
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
                console.log("Bad proxy call");
                console.log("Sent: " + headers);
                return c.end();
              }
            }
          } else {
            ;
          }
        });
      });
      return tlsServer.listen(port);
    };
    return HttpsProxy;
  })();
  generateCerts = function(host, callback) {
    var currentCerts, prc;
    currentCerts = getCerts(host);
    if (currentCerts) {
      return callback(currentCerts);
    } else {
      prc = spawn("" + __dirname + "/bin/certgen.sh", [host]);
      return prc.on('exit', function(code, err) {
        if (code === 0) {
          console.log("Generated new certs for " + host);
          return callback(getCerts(host));
        } else {
          console.log(err);
          return callback(getCerts(host));
        }
      });
    }
  };
  CERTS_DIR = "" + process.env['HOME'] + "/.middlefiddle/certs";
  getCerts = function(host) {
    var tlsOptions, tlsSettings;
    if (path.existsSync("" + CERTS_DIR + "/" + host + ".key") && path.existsSync("" + CERTS_DIR + "/" + host + ".crt")) {
      tlsOptions = {
        key: fs.readFileSync("" + CERTS_DIR + "/" + host + ".key"),
        cert: fs.readFileSync("" + CERTS_DIR + "/" + host + ".crt"),
        ca: fs.readFileSync("" + CERTS_DIR + "/../ca.crt")
      };
      tlsSettings = require('crypto').createCredentials(tlsOptions);
      tlsSettings.context.setCiphers('RC4-SHA:AES128-SHA:AES256-SHA');
      return tlsSettings;
    } else {
      return false;
    }
  };
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
      if (cleartext._controlReleased) {
        return cleartext.emit('error', e);
      }
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
