(function() {
  var HttpProxy, Stream, addHeader, bodyLogger, connect, fs, http, https, isSecure, log, modifyHeaders, removeHeader, safeParsePath, sessionFilter, url, util, zlib;
  var __slice = Array.prototype.slice, __hasProp = Object.prototype.hasOwnProperty, __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor; child.__super__ = parent.prototype; return child; };

  util = require('util');

  Stream = require("stream");

  fs = require('fs');

  zlib = require("zlib");

  http = require("http");

  https = require("https");

  url = require("url");

  connect = require("connect");

  log = require("./logger");

  sessionFilter = require("./session_filter");

  safeParsePath = function(req) {};

  isSecure = function(req) {
    if (req.client && req.client.pair) {
      return true;
    } else if (req.forceSsl) {
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

    __extends(HttpProxy, connect.HTTPServer);

    function HttpProxy(middlewares) {
      var _ref;
      this.middlewares = middlewares;
      if ((_ref = this.middlewares) == null) this.middlewares = [];
      HttpProxy.__super__.constructor.call(this, this.bookendedMiddleware());
    }

    HttpProxy.prototype.bookendedMiddleware = function() {
      this.middlewares.unshift(this.proxyCleanup);
      this.middlewares.push(this.outboundProxy);
      return this.middlewares;
    };

    HttpProxy.prototype.proxyCleanup = function(req, res, next) {
      var proxyUrl, safeUrl, serverPort;
      req.mf || (req.mf = {});
      res.mf || (res.mf = {});
      req.host = req.headers['host'].split(":")[0];
      serverPort = req.host.split(":")[1];
      if (serverPort != null) {
        req.port = serverPort;
      } else if (req.ssl) {
        req.port = 443;
      } else {
        req.port = 80;
      }
      if (isSecure(req)) {
        req.href = "https://" + req.headers['host'] + req.path;
        req.ssl = true;
      } else {
        safeUrl = '';
        proxyUrl = url.parse(req.url.slice(1));
        safeUrl += proxyUrl.pathname;
        if (proxyUrl.search != null) safeUrl += proxyUrl.search;
        req.url = safeUrl;
        req.href = "http://" + req.headers['host'] + req.url;
      }
      res.addHeader = addHeader;
      res.removeHeader = removeHeader;
      res.modifyHeaders = modifyHeaders;
      bodyLogger(req);
      return next();
    };

    HttpProxy.prototype.listenHTTPS = function(port) {
      var httpsProxy;
      httpsProxy = require('./https_proxy');
      return httpsProxy.createProxy(this.middlewares).listen(port);
    };

    HttpProxy.prototype.listen = function(port) {
      HttpProxy.__super__.listen.call(this, port);
      return this;
    };

    HttpProxy.prototype.outboundProxy = function(req, res, next) {
      var passed_opts, upstream_processor, upstream_request;
      req.startTime = new Date;
      passed_opts = {
        method: req.method,
        path: req.url,
        host: req.host,
        headers: req.headers,
        port: req.port
      };
      upstream_processor = function(upstream_res) {
        res.statusCode = upstream_res.statusCode;
        res.headers = upstream_res.headers;
        res.modifyHeaders();
        if (res.headers && res.headers['content-type'] && res.headers['content-type'].search(/(text)|(application)/) >= 0) {
          res.isBinary = false;
        } else {
          res.isBinary = true;
        }
        bodyLogger(res);
        res.writeHead(upstream_res.statusCode, upstream_res.headers);
        upstream_res.on('data', function(chunk) {
          res.write(chunk, 'binary');
          return res.emit('data', chunk);
        });
        upstream_res.on('end', function(data) {
          res.endTime = new Date;
          res.end(data);
          return res.emit('end');
        });
        upstream_res.on('close', function() {
          return res.emit('close');
        });
        return upstream_res.on('error', function() {
          return res.abort();
        });
      };
      req.on('data', function(chunk) {
        return upstream_request.write(chunk);
      });
      req.on('error', function(error) {
        return log.error("ERROR: " + error);
      });
      if (req.ssl) {
        upstream_request = https.request(passed_opts, upstream_processor);
      } else {
        upstream_request = http.request(passed_opts, upstream_processor);
      }
      upstream_request.on('error', function(err) {
        log.error("Fail - " + req.method + " - " + req.fullUrl);
        log.error(err);
        return res.end();
      });
      return upstream_request.end();
    };

    return HttpProxy;

  })();

  addHeader = function(header, value) {
    this.addedHeaders || (this.addedHeaders = []);
    return this.addedHeaders.push([header, value]);
  };

  removeHeader = function(header) {
    this.removedHeaders || (this.removedHeaders = []);
    return this.removedHeaders.push(header);
  };

  modifyHeaders = function() {
    var header, _i, _j, _len, _len2, _ref, _ref2, _results;
    if (this.addedHeaders) {
      _ref = this.addedHeaders;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        header = _ref[_i];
        this.headers[header[0]] = header[1];
      }
    }
    if (this.removedHeaders) {
      _ref2 = this.removedHeaders;
      _results = [];
      for (_j = 0, _len2 = _ref2.length; _j < _len2; _j++) {
        header = _ref2[_j];
        _results.push(delete this.headers[header]);
      }
      return _results;
    }
  };

  bodyLogger = function(stream, callback) {
    var unzipper;
    callback || (callback = function() {
      return stream.emit('body');
    });
    stream.body = [];
    stream.length = 0;
    unzipper = zlib.createUnzip();
    unzipper.on('data', function(data) {
      stream.length += data.length;
      return stream.body.push(data);
    });
    unzipper.on('end', function() {
      return callback();
    });
    switch (stream.headers['content-encoding']) {
      case 'gzip':
        log.debug("Unzipping");
        stream.pipe(unzipper);
        break;
      case 'deflate':
        log.debug("Deflating");
        stream.pipe(unzipper);
        break;
      default:
        stream.on('data', function(data) {
          stream.body.push(data);
          return stream.length += data.length;
        });
        stream.on('end', function() {
          return callback();
        });
        break;
    }
  };

}).call(this);
