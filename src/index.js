const encoders = require("./encoders")
const parser = require("./parser");
const fs = require("fs");

const { formatError } = require("./util");

function compile(files) {
	files.forEach(fn => {
		const file = fs.readFileSync(fn, 'utf-8');
		try {
			const out = parser.parse(file);
			console.log(JSON.stringify(out, null, 4))
		} catch(e) {
			formatError(file, e)
		}
	})
}

module.exports = {
	parser,
	compile,
	encoders
};
