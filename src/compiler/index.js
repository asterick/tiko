const fs = require("fs");
const path = require("path");

const parser = require("../parser");

const SEARCH_PATHS = process.env.SEARCH_PATHS
	? process.env.SEARCH_PATHS.split(",")
	: [path.resolve(__dirname, "../../stdlib")];

const EXTENSIONS = ['', '.lua'];

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

		// Attempt to locate module
		for (let dir of [root].concat(SEARCH_PATHS)) {
			for (let extension of EXTENSIONS) {
				const qualified = path.resolve(dir, `${fn}${extension}`);

				try {
					const stat = fs.statSync(qualified);

					if (this._modules[qualified] !== undefined) {
						return this._modules[qualified];
					}

					return this._modules[qualified] = Module.fromFile(qualified);
				} catch(e) {
					continue ;
				}
			}
		}

		throw new Error(`Could not resolve: ${fn}`);
	}
}

module.exports = {
	CompilerContext	
}
