const fs = require('fs');

const locate = require("./locate");
const parser = require("../parser");

class Module {
	constructor(fn) {
		this.path = fn;
		this.source = fs.readFileSync(fn, 'utf-8');

		try {
			this.ast = parser.parse(this.source);
		} catch(e) {
			e.module = this;
			throw e;
		}
	}
}

class CompilerContext {
	constructor() {
		this._modules = {};
	}

	import (fn, root) {
		const path = locate(fn, root);
		this._modules[path] = new Module(path);
	}
}

module.exports = CompilerContext;
