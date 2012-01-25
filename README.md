# MiddleFiddle

MiddleFiddle is an outbound local proxy which lets to modify your outbound request and responses
via [Connect](http://senchalabs.github.com/connect/) middleware. It support HTTP and HTTPS, the
latter through a hijacking of the request with locally generated SSL certs.

### Web Logging

By default MiddleFiddle logs all outbound traffic to a web based logger on localhost:8411

![Request Logger](http://mdp.github.com/middlefiddle/images/RequestLogger.jpg)
![Request Logger](http://mdp.github.com/middlefiddle/images/RequestDetails.jpg)


### Installation via Github

    # Depends on Node 0.6.x
    git clone git://github.com/mdp/middlefiddle.git
    cd middlefiddle
    npm install
    npm link #If you want to use it globally

### Usage

#### Launch the basic logger

    mf logger

#### Configuration

MiddleFiddle looks for a .middlefiddle directory in the current working directory, or at ~/.middlefiddle.

Inside you'll find a config.coffee file, https certs, and a sites directory.

##### Sites

MiddleFiddle can alter requests based on the host name. You'll find some examples in
[.middlefiddle/sites](https://github.com/mdp/middlefiddle/tree/master/.middlefiddle/sites)


### Building your own Middleware

Coming soon

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

- req.fullUrl #=> The full requested URL, including the schema
- req.isSecure #=> Did it come via SSL?

### TODO

- Clean up cert generation
- Expand logging
- Add more middleware

### Want to contribute

This is my first node project, criticism is gladly accepted as long as it's in
the form of a pull request.

### Development

MiddleFiddle is written in CoffeeScript. It's set
up with a Cakefile for building files in `src/` to `lib/` and running
tests with nodeunit. There's also a `docs` task that generates Docco
documentation from the source in `src/`.

Released under the MIT license.

Mark Percival <mark@markpercival.us>
