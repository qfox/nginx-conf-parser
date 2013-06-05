SHELL = /bin/sh

YACC = ./node_modules/.bin/jison
UGLIFYJS = ./node_modules/.bin/uglifyjs


.PHONY: all
all:
	npm install --silent
	$(YACC) ./src/nginx.jison -o ./lib/nginx.js
	$(UGLIFYJS) ./lib/nginx.js -o ./lib/nginx.min.js

test:
	npm install --silent
	npm test

clean:
	rm ./lib/nginx.js ./lib/nginx.min.js
