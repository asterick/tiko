const logging = require("./logging");

const colors = require('colors/safe');

function formatError(e) {
	const error = [`${e.name}: ${e.message}`];

	if (e.module && e.location) {
		const lines = e.module.source.split(/\r\n?|\n/g)
		const { start, end } = e.location;

		error.push(`\n${e.module.path}(${start.line}:${start.column})`)

		for (var i = Math.max(1, start.line - 1); i <= Math.min(end.line + 1, lines.length); i++) {
			const text = lines[i - 1] + " ";
			let first, last = 0;

			if (start.line < i) {
				first = 0;
			} else if (start.line > i) {
				first = text.length;
			} else {
				first = start.column-1;
			}

			if (end.line < i) {
				last = 0;
			} else if (end.line > i) {
				last = text.length;
			} else {
				last = end.column-1;
			}

			error.push(text.slice(0, first) + colors.bgRed(text.slice(first, last)) + text.slice(last) );
		}
	}

	logging.error(error.join('\n'))
}

module.exports = {
	formatError
}
