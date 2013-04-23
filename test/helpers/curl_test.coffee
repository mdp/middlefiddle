fs = require 'fs'
curl = require './curl'

httpResp = fs.readFileSync('./test/fixtures/https_response.txt')
httpProxyResp = fs.readFileSync('./test/fixtures/https_proxy_response.txt')

#console.log curl.parse httpResp
console.log curl.parse httpProxyResp

curl.fetch 'https://bing.com', "-i -k", (err, resp) ->
  console.log resp

