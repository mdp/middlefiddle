(function() {
  var CERTS_DIR, chain, chainGang, config, fs, generateCerts, getCerts, log, path, spawn;
  fs = require('fs');
  path = require('path');
  spawn = require('child_process').spawn;
  chainGang = require('chain-gang');
  chain = chainGang.create({
    workers: 1
  });
  log = require('./logger');
  config = require('./config');
  generateCerts = function(host, callback) {
    var currentCerts, prc;
    currentCerts = getCerts(host);
    if (currentCerts) {
      return callback(currentCerts);
    } else {
      log.info("Generating certs for " + host);
      prc = spawn("" + __dirname + "/bin/certgen.sh", [host, Date.now(), config.mfDir]);
      return prc.on('exit', function(code, err) {
        if (code === 0) {
          return callback(getCerts(host));
        } else {
          log.error(err);
          return callback(getCerts(host));
        }
      });
    }
  };
  CERTS_DIR = "" + config.mfDir + "/certs";
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
  exports.build = function(host, tlsCallback) {
    var callback, job, tlsSettings;
    if (tlsSettings = getCerts(host)) {
      return tlsCallback(tlsSettings);
    } else {
      log.debug("Queuing up cert gen");
      callback = function(err) {
        return tlsCallback(getCerts(host));
      };
      job = function(host) {
        return function(worker) {
          return generateCerts(host, function() {
            return worker.finish();
          });
        };
      };
      return chain.add(job(host), host, callback);
    }
  };
}).call(this);
