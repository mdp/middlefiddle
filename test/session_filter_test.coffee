vows = require 'vows'
assert = require 'assert'
session_filter = require '../lib/session_filter'
mock_request = require './mock_request'
mock_request.headers = {}

vows
  .describe('Testing a filter')
  .addBatch
    "when it's given a null/undefined value":
      topic: ->
        mock_request['href'] = 'http://google.com'
        session_filter.matches(null, mock_request)

      'we should return true': (topic) ->
        assert.equal topic, true

    'when given a string matcher that matches':
      topic: ->
        mock_request['href'] = 'http://google.com'
        filter =
          href: 'google.com'
        session_filter.matches(filter, mock_request)

      'should return true':
        'is not a number': (topic) ->
          assert.equal topic, true

    'when given a string matcher that does not match':
      topic: ->
        mock_request['href'] = 'http://google.com'
        filter =
          href: 'bing.com'
        session_filter.matches(filter, mock_request)

      'should return false':
        'is not a number': (topic) ->
          assert.equal topic, false

    'when given a function':
      topic: ->
        filter = (req) ->
          return true
        session_filter.matches(filter, mock_request)

      'should return the function result':
        'is not a number': (topic) ->
          assert.equal topic, true

    'when given a function for a key':
      topic: ->
        mock_request['href'] = 'http://google.com'
        filter =
          href: (url) ->
            return true if url.match("google")
        session_filter.matches(filter, mock_request)

      'should return the function result':
        'is not a number': (topic) ->
          assert.equal topic, true

    # Handling a contains key
    'when given a contains with a match':
      topic: ->
        buffers = [new Buffer('middle'), new Buffer('fiddle')]
        mock_request['content'] = buffers
        mock_request.headers['content-type'] = 'text/html'
        filter =
          contains: /middlefiddle/
        session_filter.matches(filter, mock_request)

      'should return true': (topic) ->
          assert.equal topic, true

    'when given a contains with a miss':
      topic: ->
        buffers = [new Buffer('middle'), new Buffer('fiddle')]
        mock_request['content'] = buffers
        mock_request.headers['content-type'] = 'text/html'
        filter =
          contains: /middlef1ddle/
        session_filter.matches(filter, mock_request)

      'should return true': (topic) ->
          assert.equal topic, false

  .export(module)
