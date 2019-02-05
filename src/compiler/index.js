const fs = require('fs');
const path = require("path");

const parser = require("../parser");
const logging = require("../logging");

// Locate a module (path
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

class Module {
	constructor(fn) {
		this.path = fn;
		this.source = fs.readFileSync(fn, 'utf-8');

		try {
			const ast = parser.parse(this.source);
			this.process(ast);
		} catch(e) {
			e.module = this;
			throw e;
		}
	}

	process(ast, context) {
		context = context || {};

		ast.forEach((node) => {
			console.log(node);
		});
	}
}

class CompilerContext {
	constructor() {
		this._modules = {};
	}

	import (fn, root) {
		const path = locate(fn, root);

		logging.silly(`${fn}: loading from ${path}`);

		return this._modules[path] ||
			(this._modules[path] = new Module(path));
	}
}

module.exports = CompilerContext;
