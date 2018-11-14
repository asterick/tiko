const encoders = require("./encoders")
const parser = require("./parser");
const logging = require("./logging");

const { CompilerContext } = require("./compiler");
const { formatError } = require("./util");

function compile(files) {
	const context = new CompilerContext();

	files.forEach(fn => context.import(fn, process.cwd()));
}

module.exports = {
	logging,
	parser,
	compile,
	encoders
};
