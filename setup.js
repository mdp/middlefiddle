var exec = require('child_process').exec;
var sysPath = require('path');
var mkdirp = require('mkdirp');
var fs = require('fs');
var util = require("util");

var mode = process.argv[2];

var execute = function(pathParts, params, callback) {
  if (callback === null) callback = function() {};
  var path = sysPath.join.apply(null, pathParts);
  var command = 'node ' + path + ' ' + params;
  console.log('Executing', command);
  exec(command, function(error, stdout, stderr) {
    if (error !== null) return process.stderr.write(stderr.toString());
    console.log(stdout.toString());
  });
};

var copy = function(path, targetPath) {
  var target = fs.createWriteStream(targetPath);
  var original = fs.createReadStream(path);
  target.once('open', function(fd){
      util.pump(original, target);
  });
}

if (mode === 'postinstall') {
  console.log("Creating .middlefiddle home directory");
  mkdirp.sync(process.env["HOME"] + "/.middlefiddle");
  mkdirp.sync(process.env["HOME"] + "/.middlefiddle/sites");
  copy(__dirname + "/.middlefiddle/config.json", process.env["HOME"] + "/.middlefiddle/config.json");
} else if (mode === 'test') {
  execute(['node_modules', 'mocha', 'bin', 'mocha'],
    '--compilers coffee:coffee-script test/*.coffee');
}
