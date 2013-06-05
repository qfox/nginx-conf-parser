#!/usr/bin/env node

exports = require("./nginx");
if (typeof module !== 'undefined' && require.main === module) {
	exports.main(process.argv.slice(1));
}
