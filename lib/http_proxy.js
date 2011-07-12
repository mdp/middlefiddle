(function() {
  var HttpProxy, connect, fs, http, https, isSecure, safeParsePath, sys, url;
  var __slice = Array.prototype.slice, __hasProp = Object.prototype.hasOwnProperty, __extends = function(child, parent) {
    for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; }
    function ctor() { this.constructor = child; }
    ctor.prototype = parent.prototype;
    child.prototype = new ctor;
    child.__super__ = parent.prototype;
    return child;
  };
  fs = require("fs");
  sys = require("sys");
  http = require("http");
  https = require("https");
  url = require("url");
  connect = require("connect");
  safeParsePath = function(req) {};
  isSecure = function(req) {
    if (req.client && req.client.pair) {
      return true;
    } else {
      return false;
    }
  };
  exports.createProxy = function() {
    var middlewares, proxy;
    middlewares = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
    proxy = new HttpProxy(middlewares);
    return proxy;
  };
  exports.HttpProxy = HttpProxy = (function() {
    function HttpProxy(middlewares) {
      var _ref;
      this.middlewares = middlewares;
            if ((_ref = this.middlewares) != null) {
        _ref;
      } else {
        this.middlewares = [];
      };
      HttpProxy.__super__.constructor.call(this, this.bookendedMiddleware());
    }
    __extends(HttpProxy, connect.HTTPServer);
    HttpProxy.prototype.bookendedMiddleware = function() {
      this.middlewares.unshift(this.proxyCleanup);
      this.middlewares.push(this.outboundProxy);
      return this.middlewares;
    };
    HttpProxy.prototype.proxyCleanup = function(req, res, next) {
      var proxyUrl, safeUrl;
      if (isSecure(req)) {
        req.fullUrl = "https://" + req.headers['host'] + req.url;
        req.ssl = true;
      } else {
        safeUrl = '';
        proxyUrl = url.parse(req.url.slice(1));
        safeUrl += proxyUrl.pathname;
        if (proxyUrl.search != null) {
          safeUrl += proxyUrl.search;
        }
        req.url = safeUrl;
        req.fullUrl = "http://" + req.headers['host'] + req.url;
      }
      return next();
    };
    HttpProxy.prototype.listenHTTPS = function(port) {
      var httpsProxy;
      httpsProxy = require('./https_proxy');
      return httpsProxy.createProxy(this.bookendedMiddleware()).listen(port);
    };
    HttpProxy.prototype.listen = function(port) {
      HttpProxy.__super__.listen.call(this, port);
      return this;
    };
    HttpProxy.prototype.outboundProxy = function(req, res, next) {
      var passed_opts, server_host, upstream_processor, upstream_request;
      if ((req.realHost != null)) {
        server_host = req.realHost;
      } else {
        server_host = req.headers['host'];
      }
      passed_opts = {
        method: req.method,
        path: req.url,
        host: server_host,
        headers: req.headers,
        port: req.port
      };
      upstream_processor = function(upstream_res) {
        upstream_res.on('data', function(chunk) {
          return res.write(chunk, 'binary');
        });
        upstream_res.on('end', function(data) {
          return res.end();
        });
        upstream_res.on('close', function() {
          return res.destroy();
        });
        upstream_res.on('error', function() {
          return res.abort();
        });
        return res.writeHead(upstream_res.statusCode, upstream_res.headers);
      };
      req.on('data', function(chunk) {
        return upstream_request.write(chunk);
      });
      req.on('error', function(error) {
        return console.log("ERROR: " + error);
      });
      if (req.ssl) {
        upstream_request = https.request(passed_opts, upstream_processor);
      } else {
        upstream_request = http.request(passed_opts, upstream_processor);
      }
      upstream_request.on('error', function() {
        console.log("Fail");
        return res.end();
      });
      return upstream_request.end();
    };
    return HttpProxy;
  })();
}).call(this);
