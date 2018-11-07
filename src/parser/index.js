const fs = require('fs'),
	  path = require('path');

const { generate } = require("pegjs");

module.exports = generate(fs.readFileSync(path.join(__dirname, "grammar.pegjs"), 'utf-8'), { cache: true });
