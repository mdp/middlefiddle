assert = require 'assert'
session_filter = require '../src/session_filter'
mock_request = require './helpers/mock_request'
mock_request.headers = {}

describe 'Testing a filter', ->
  describe "when it's given a null/undefined value", ->
    beforeEach (done) ->
      mock_request['href'] = 'http://google.com'
      done()

    it 'should return true', ->
      assert.equal true, session_filter.matches(null, mock_request)

  describe 'when given a string matcher that matches', ->

    it 'should return true', ->
      mock_request['href'] = 'http://google.com'
      filter =
        href: 'google.com'
      assert.equal true, session_filter.matches(filter, mock_request)

  describe 'when given a string matcher that does not match', ->
    it 'should return false', () ->
      mock_request['href'] = 'http://google.com'
      filter =
        href: 'bing.com'
      assert.equal session_filter.matches(filter, mock_request), false

  describe 'when given a function', ->
    it 'should return the function result', () ->
      filter = (req) ->
        return true
      assert.equal session_filter.matches(filter, mock_request), true

  describe 'when given a function for a key', () ->
    it 'should return the function result', () ->
      mock_request['href'] = 'http://google.com'
      filter =
        href: (url) ->
          return true if url.match("google")
      assert.equal session_filter.matches(filter, mock_request), true

  # Handling a contains key
  describe 'when given a contains with a match', () ->
    it 'should return true', () ->
      buffers = [new Buffer('middle'), new Buffer('fiddle')]
      mock_request['body'] = buffers
      mock_request.headers['content-type'] = 'text/html'
      filter =
        contains: /middlefiddle/
      assert.equal session_filter.matches(filter, mock_request), true

  describe 'when given a contains with a string is a match', () ->
    it 'should return true', () ->
      buffers = [new Buffer('middle'), new Buffer('fiddle')]
      mock_request['body'] = buffers
      mock_request.headers['content-type'] = 'text/html'
      filter =
        contains: 'middlefiddle'
      assert.equal session_filter.matches(filter, mock_request), true

  describe 'when given a contains with a miss', () ->
    it 'should return false', () ->
      buffers = [new Buffer('middle'), new Buffer('fiddle')]
      mock_request['content'] = buffers
      mock_request.headers['content-type'] = 'text/html'
      filter =
        contains: /middlef1ddle/
      assert.equal session_filter.matches(filter, mock_request), false

