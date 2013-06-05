
// mymodule.js
var fs = require('fs');
var util = require('util');
var scope = require("./nginx");
var parser = scope.parser;

[
	[fs.readFileSync('nginx.root.conf', {encoding: 'utf8'})]
]
.forEach(function(v, k) {
	var r = parser.parse(v[0]);
	console.log(util.inspect(r, false, null));
	console.log();
});
