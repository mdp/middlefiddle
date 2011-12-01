sys = require('util')
colors = require('colors')
verbosity = ()->
  switch(process.env['LOGLEVEL'])
    when "DEBUG"
      3
    when "INFO"
      2
    when "WARN"
      1
    when "ERROR"
      0
    else
      2

level = verbosity()
module.exports =
  debug: (msg) ->
    if level >= 3
      sys.puts(msg)
  info: (msg) ->
    if level >= 2
      sys.puts(msg.green)
  warn: (msg) ->
    if level >= 1
      sys.puts("WARNING: #{msg}".magenta)
  error: (msg) ->
    if level >= 0
      sys.puts("ERROR: #{msg}".red)

