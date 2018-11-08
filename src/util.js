const colors = require('colors/safe');

function formatError(file, e) {
	const lines = file.split(/\r\n?|\n/g)

	console.error(`${e.name}(${e.location.start.line}:${e.location.start.column}): ${e.message}`);

	if (!e.location) return ;

	const { start, end } = e.location;

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

		console.log(text.slice(0, first) + colors.inverse(text.slice(first, last)) + text.slice(last) );
	}
}

module.exports = {
	formatError
}
