(function() {
  var createServer, currentSocket, exports, express, io, log, logContentEnabled, longFormat, ringBuffer, shortFormat, zlib;
  zlib = require('zlib');
  express = require('express');
  io = require('socket.io');
  ringBuffer = require('../utils/ringbuffer').create(1000);
  currentSocket = null;
  logContentEnabled = function(res) {
    var type;
    type = res.headers['content-type'].match(/^([^\;]+)/)[1];
    return type.match(/^text/);
  };
  createServer = function(callback) {
    var app;
    app = express.createServer();
    io = io.listen(app);
    io.set('log level', 0);
    app.configure(function() {
      return app.use(express.static(__dirname + '/../../weblogger/public'));
    });
    app.get('/', function(req, res) {
      var index;
      index = require('fs').readFileSync(__dirname + '/../../weblogger/index.html');
      return res.send(index.toString(), 200);
    });
    app.get('/:key', function(req, res) {
      var log;
      log = ringBuffer.retrieve(req.params.key);
      if (log) {
        return res.send(JSON.stringify(ringBuffer.retrieve(req.params.key)), 200);
      } else {
        return res.send("Not Found", 404);
      }
    });
    io.sockets.on('connection', function(socket) {
      return currentSocket = socket;
    });
    return app.listen(8411);
  };
  exports = module.exports = function(options) {
    var stream;
    console.log('Starting server');
    createServer();
    options || (options = {});
    stream = options.stream || process.stdout;
    return function(req, res, next) {
      var end;
      req._startTime = new Date;
      res._length = 0;
      res._content = '';
      if (req._logging) {
        return next();
      }
      req._logging = true;
      end = res.end;
      res.on('data', function(data) {
        res._length += data.length;
        return res._content += data.toString('binary');
      });
      res.end = function() {
        res.end = end;
        log(req, res);
        return res.end();
      };
      return next();
    };
  };
  log = function(req, res) {
    var logger;
    logger = function(req, res) {
      res._logKey = ringBuffer.add(longFormat(req, res));
      if (currentSocket) {
        currentSocket.emit('request', {
          request: shortFormat(req, res)
        });
        return currentSocket.broadcast.emit('request', {
          request: shortFormat(req, res)
        });
      }
    };
    if (res.headers['content-encoding'] && res.headers['content-encoding'].match(/gzip/)) {
      return zlib.unzip(new Buffer(res._content, 'binary'), function(err, buffer) {
        res._content = buffer.toString('utf-8');
        return logger(req, res);
      });
    } else {
      res._content = res._content.toString('utf-8');
      return logger(req, res);
    }
  };
  shortFormat = function(req, res) {
    return {
      id: res._logKey,
      status: res.statusCode,
      url: req.fullUrl,
      method: req.method,
      length: res._length,
      time: new Date - req._startTime
    };
  };
  longFormat = function(req, res) {
    var key, req_headers, res_headers, val;
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
    return {
      request: {
        method: req.method,
        headers: req_headers
      },
      response: {
        status: res.statusCode,
        headers: res_headers,
        content: res._content
      },
      time: new Date - req._startTime
    };
  };
}).call(this);
