# Shell out to curl to let us test the libcurl with HTTPS
{exec} = require 'child_process'

exports.fetch = (url, options, callback) ->
  curlCmd url, options, (err, stdOut, stdErr) ->
    if err
      callback(err)
    else
      callback(null, parse(stdOut))

exports.parse = parse = (stdOut) ->
  response =
    headers: {}
    body: ''
  parsingHeader = true
  lines = stdOut.toString().split(/\n/)
  status = lines.shift()
  if status.match(/Connection established/)
    lines.shift(); lines.shift();
    status = lines.shift()
  response.statusCode = status.match(/\s([0-9]+)\s/)[1]
  for line in lines
    if !parsingHeader
      response.body += line
    else
      line = line.replace(/(\r\n|\n|\r)/gm,'')
      if line.length < 1
        parsingHeader = false
      else
        [k,v] = line.split(': ')
        response.headers[k] = v
  response

curlCmd = (host, params, callback) ->
  exec("curl #{params} #{host}", callback)


