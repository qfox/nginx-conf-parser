var assert = require("assert"),
  scope = require("../lib/nginx.js"),
  parser = scope.parser;


describe('check load balancing directives parsing', function() {
	it ('should parse "least_conn" method', function() {
		var result = parser.parse('' +
			'upstream upst {' +
			'  least_conn;' +
			'  server 8.8.8.8;' +
			'}');
		assert.equal(result[0][2][0][0], "least_conn");
	});

	it ('should parse "ip_hash" method', function() {
		var result = parser.parse('' +
			'upstream upst {' +
			'  ip_hash;' +
			'  server 8.8.8.8;' +
			'}');
		assert.equal(result[0][2][0][0], "ip_hash");
	});

	it ('should work fine with comments in the end of line', function() {
		var result = parser.parse('' +
			'upstream upst {' +
			'  ip_hash; #comment\n' +
			'  server 8.8.8.8;' +
			'}');
		assert.equal(result[0][2][0][0], "ip_hash");
	});

	it ('should not allow setting load balancing method twice', function() {
		assert.throws( function() {
      parser.parse('' +
        'upstream upst {' +
        '  ip_hash;' +
        '  ip_hash;' +
        '  server 8.8.8.8;' +
        '}');
		});
	});

	it ('should not allow redefining load balancing method in the same section', function() {
		assert.throws( function() {
			parser.parse('' +
				'upstream upst {' +
				'  ip_hash;' +
				'  least_conn;' +
				'  server 8.8.8.8;' +
				'}');
		});
	});

	it ('should not allow setting load balancing method in the middle of upstream section', function() {
		assert.throws( function() {
			parser.parse('' +
				'upstream upst {' +
				'  server 8.8.8.8;' +
				'  ip_hash;' +
				'}');
		});
	});
});
