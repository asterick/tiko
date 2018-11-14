const fs = require("fs");
const path = require("path");

const parser = require("../parser");

const SEARCH_PATHS = process.env.SEARCH_PATHS
	? process.env.SEARCH_PATHS.split(",")
	: [path.resolve(__dirname, "../../stdlib")];

class Module {
	constructor(ast) {
		this._ast = ast;
		console.log(ast);
	}

	static fromFile(fn) {
		const mod = Module.fromSource(fs.readFileSync(fn, 'utf-8'));
		mod._path = fn;
		return mod;
	}

	static fromSource(src) {
		return new Module(parser.parse(src));
	}
}

class CompilerContext {
	constructor(loader) {
		this._loader = loader;

		this._modules = {};
	}

	import (fn, root) {
		root = root || process.cwd();

		// Assumed extension
		if (!path.extname(fn)) {
			fn += ".lua";
		}

		// Attempt to locate module
		const qualified = [root].concat(SEARCH_PATHS).reduce((acc, dir) => {
			if (acc) return acc;

			const target = path.resolve(dir, fn);

			try {
				const stat = fs.statSync(target);
				return target;
			} catch(e) {
				return null;
			}
		}, null);

		if (qualified === null) {
			throw new Error(`Could not resolve: ${fn}`);
		}

		if (this._modules[qualified] !== undefined) {
			return this._modules[qualified];
		}

		return this._modules[qualified] = Module.fromFile(qualified);
	}
}

module.exports = {
	CompilerContext	
}
