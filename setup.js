var exec = require('child_process').exec;
var sysPath = require('path');

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

if (mode === 'postinstall') {
  console.log("Creating .middlefiddle home directory");
} else if (mode === 'test') {
  execute(['node_modules', 'mocha', 'bin', 'mocha'],
    '--compilers coffee:coffee-script test/*.coffee');
}
