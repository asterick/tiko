const fs = require('fs');

const locate = require("./locate");
const parser = require("../parser");

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
		Module.fromFile(locate(fn, root));
	}
}

module.exports = {
	CompilerContext	
}
