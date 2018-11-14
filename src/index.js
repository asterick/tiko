const encoders = require("./encoders")
const parser = require("./parser");

const { CompilerContext } = require("./compiler");
const { formatError } = require("./util");

function compile(files) {
	const context = new CompilerContext();

	files.forEach(fn => context.import(fn, null));

	context.resolve();
}

module.exports = {
	parser,
	compile,
	encoders
};
