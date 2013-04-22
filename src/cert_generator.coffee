fs        = require('fs')
{spawn}   = require('child_process')
async     = require 'async'
log       = require './logger'
config       = require './config'

_generateCerts = (host, callback) ->
  # TODO: Make async
  currentCerts = getCerts(host)
  if currentCerts
    log.debug("Found existing certs for #{host}")
    callback(currentCerts)
  else
    log.info("Generating certs for #{host}")
    prc = spawn "#{__dirname}/../lib/bin/certgen.sh", [host, Date.now(), config.mfDir]
    prc.on 'exit', (code, err) ->
      if code == 0
        callback getCerts(host)
      else
        log.error(err)
        callback getCerts(host)

# Prevents a double gen'd cert
generateCerts = async.memoize(_generateCerts)

CERTS_DIR = "#{config.mfDir}/certs"
getCerts = (host) ->
  if fs.existsSync("#{CERTS_DIR}/#{host}.key") && fs.existsSync("#{CERTS_DIR}/#{host}.crt")
    tlsOptions =
      key: fs.readFileSync("#{CERTS_DIR}/#{host}.key"),
      cert: fs.readFileSync("#{CERTS_DIR}/#{host}.crt"),
      ca: fs.readFileSync("#{CERTS_DIR}/../ca.crt")
    tlsSettings = require('crypto').createCredentials(tlsOptions)
    tlsSettings.context.setCiphers('RC4-SHA:AES128-SHA:AES256-SHA')
    tlsSettings
  else
    return false

exports.build = (host, tlsCallback) ->
  # TODO: Gen and sign certs using native Node Openssl hooks
  if tlsSettings = getCerts(host)
    tlsCallback(tlsSettings)
  else
    log.debug("Queuing up cert gen")
    generateCerts(host, tlsCallback)
