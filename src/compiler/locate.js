const fs = require("fs");
const path = require("path");

const SEARCH_PATHS = process.env.SEARCH_PATHS
	? process.env.SEARCH_PATHS.split(",")
	: [path.resolve(__dirname, "../../stdlib")];

const EXTENSIONS = ['', '.lua'];

function locate(fn, root) {
	// Attempt to locate module
	for (let dir of [root].concat(SEARCH_PATHS)) {
		for (let extension of EXTENSIONS) {
			const qualified = path.resolve(dir, `${fn}${extension}`);

			try {
				const stat = fs.statSync(qualified);

				return qualified;
			} catch(e) {
				continue ;
			}
		}
	}

	throw new Error(`Could not resolve: ${fn}`);
}

module.exports = locate;
