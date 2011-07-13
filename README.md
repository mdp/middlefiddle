# MiddleFiddle

*This project is still pretty beta, expect changes*

### What is MiddleFiddle

MiddleFiddle is an outbound local proxy which lets to modify your outbound request and responses
via Connect middleware. It support HTTP and HTTPS, the latter through a hijacking of the request
with locally generated SSL certs.

### Installation

    npm install middlefiddle

### Example

Grab any mp3 downloaded or streamed to your browser:

    var Mf = require('middlefiddle');
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

### HTTPS Hijacking

When an HTTPS request is first seen, MiddleFiddle generates a certificate for that domain, signs
it with it's own generated root cert, and stores the cert for future use in
~/.middlefiddle/certs

In order to make this look legit to your browser, you'll need to add the generated
root cert in ~/.middlefiddle/ca.crt to your keychain. This cert is auto generated
just for your machine, so you won't be compromising your browser security.

### Things to note

Connect typically doesn't have a simple way to hijack downstream responses, so
middlefiddle emits events on the response along with writing to the stream.

You've also got a couple helper properties:

req.fullUrl #=> The full requested URL, including the schema
req.isSecure #=> Did it come via SSL?

### TODO

- Clean up HTTPS cert generation. Right now 3 parrallel request to the same domain cause a race condition.
  This only happens the first time you visit a site, but it's hacky.

- Expand logging

### Want to contribute

This is my first node project, so please excuse the poor coding. If you have any suggestions,
feel free to address them in a pull request.

### Development

MiddleFiddle is written in CoffeeScript. It's set
up with a Cakefile for building files in `src/` to `lib/` and running
tests with nodeunit. There's also a `docs` task that generates Docco
documentation from the source in `src/`.

Released under the MIT license.

Mark Percival <mark@markpercival.us>
