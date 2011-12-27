
DOCS = docs/*.md
HTMLDOCS = $(DOCS:.md=.html)
TESTS = test/*.coffee
REPORTER = dot

test:
	./node_modules/.bin/mocha \
		--reporter $(REPORTER) \
		--growl \
		$(TESTS)

.PHONY: test
