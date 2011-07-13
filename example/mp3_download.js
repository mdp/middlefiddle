var Mf = require('../lib/index');
var url = require('url');
var fs = require('fs');


var mp3Grab = function() {
  return function(req, res, next){
    var path = url.parse(req.url).pathname;
    var filename;
    if (path) {filename = path.split('/').pop()}
    if (filename && filename.match(/\.mp3$/)){
      console.log("Beginning capture of " + filename);
      var file = fs.createWriteStream(filename);
      res.addListener('data', function (chunk) {
        file.write(chunk);
      });
      res.addListener("end", function(chunk) {
        if (chunk) {
          file.write(chunk);
        }
        file = undefined;
        console.log("Downloaded - " + filename);
      });
    }
    next();
  };
};

Mf.createProxy(mp3Grab()).listen(8088).listenHTTPS(8089);
