# MiddleFiddle

This project is very alpha, I'll be updating the docs over the next week.

### What is MiddleFiddle

MiddleFiddle is an outbound local proxy which lets to modify your outbound request and responses
via Connect middleware. It support HTTP and HTTPS, the latter through a hijacking of the request
with locally generated SSL certs.


### Development

This is a Node.js project template written in CoffeeScript. It's set
up with a Cakefile for building files in `src/` to `lib/` and running
tests with nodeunit. There's also a `docs` task that generates Docco
documentation from the source in `src/`.

Released under the MIT license.

Mark Percival <mark@markpercival.us>
