const encoders = require("./encoders")
const parser = require("./parser");
const fs = require("fs");

function compile(files) {
	files.forEach(fn => {
		const file = fs.readFileSync(fn, 'utf-8');
		try {
			const out = parser.parse(file);
			console.log(JSON.stringify(out, null, 4))
		} catch(e) {
			const lines = file.split(/\r\n?|\n/g)
			console.log(lines)
			console.log(e);
		}
	})
}

module.exports = {
	parser,
	compile,
	encoders
};
