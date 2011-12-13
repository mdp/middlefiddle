(function() {
  var config, createServer, currentSocket, exports, express, impracticalMimeTypes, io, liveLog, log, longFormat, ringBuffer, sessionFilter, shortFormat;

  express = require('express');

  io = require('socket.io');

  ringBuffer = require('../utils/ringbuffer').create(1000);

  log = require('../logger');

  sessionFilter = require('../session_filter');

  config = require('../config');

  currentSocket = null;

  impracticalMimeTypes = /^(image|audio|video)\//;

  createServer = function(callback) {
    var app;
    app = express.createServer();
    io = io.listen(app, {
      "log level": 0
    });
    app.configure(function() {
      return app.use(express.static(__dirname + '/../../live_logger/public'));
    });
    app.get('/', function(req, res) {
      var index;
      index = require('fs').readFileSync(__dirname + '/../../live_logger/index.html');
      return res.send(index.toString(), 200);
    });
    app.get('/:key', function(req, res) {
      var requestLog;
      requestLog = ringBuffer.retrieve(req.params.key);
      if (requestLog) {
        return res.send(JSON.stringify(longFormat.apply(this, requestLog), 200));
      } else {
        return res.send("Not Found", 404);
      }
    });
    io.sockets.on('connection', function(socket) {
      return currentSocket = socket;
    });
    return app.listen(config.liveLoggerPort);
  };

  exports = module.exports = function(requestFilter, responseFilter) {
    log.info("Starting LiveLogger on " + config.liveLoggerPort);
    createServer();
    return function(req, res, next) {
      var end;
      if (!sessionFilter.matches(requestFilter, req)) return next();
      end = res.end;
      res.end = function() {
        res.end = end;
        return res.end();
      };
      res.on('processed', function() {
        if (sessionFilter.matches(responseFilter, res)) return liveLog(req, res);
      });
      return next();
    };
  };

  liveLog = function(req, res) {
    res.mf.logKey = ringBuffer.add([req, res]);
    if (currentSocket) {
      currentSocket.emit('request', {
        request: shortFormat(req, res)
      });
      return currentSocket.broadcast.emit('request', {
        request: shortFormat(req, res)
      });
    }
  };

  shortFormat = function(req, res) {
    return {
      id: res.mf.logKey,
      status: res.statusCode,
      url: req.href,
      method: req.method,
      length: res.length,
      time: res.endTime - req.startTime
    };
  };

  longFormat = function(req, res) {
    var buffer, key, req_headers, requestContent, res_headers, responseContent, val, _i, _j, _len, _len2, _ref, _ref2;
    req_headers = (function() {
      var _ref, _results;
      _ref = req.headers;
      _results = [];
      for (key in _ref) {
        val = _ref[key];
        _results.push("" + key + ": " + val);
      }
      return _results;
    })();
    res_headers = (function() {
      var _ref, _results;
      _ref = res.headers;
      _results = [];
      for (key in _ref) {
        val = _ref[key];
        _results.push("" + key + ": " + val);
      }
      return _results;
    })();
    responseContent = '';
    requestContent = '';
    _ref = req.content;
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      buffer = _ref[_i];
      requestContent += buffer.toString('utf-8');
      if (requestContent.length > 100000) break;
    }
    if (!(res.headers['content-type'] && res.headers['content-type'].match(impracticalMimeTypes))) {
      responseContent = '';
      _ref2 = res.content;
      for (_j = 0, _len2 = _ref2.length; _j < _len2; _j++) {
        buffer = _ref2[_j];
        responseContent += buffer.toString('utf-8');
        if (responseContent.length > 100000) break;
      }
    }
    return {
      request: {
        url: req.href,
        method: req.method,
        headers: req_headers,
        content: requestContent
      },
      response: {
        status: res.statusCode,
        headers: res_headers,
        content: responseContent
      },
      time: res.endTime - req.startTime
    };
  };

}).call(this);
