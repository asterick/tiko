'use strict';
var compiler = require("../compiler"),
	fs = require('fs');

const { spawn } = require('child_process');

module.exports = function(grunt) {
	grunt.registerMultiTask('pico', 'Generates pico-8 games', function() {
		var done = this.async();
		var data = this.data;

		this.files.forEach(function(f) {
			var source = f.header.concat(
				f.src.filter(function (filepath, i) {
					return grunt.file.exists(filepath) && !grunt.file.isDir(filepath);	
				}).map(function (fp) {
					return grunt.file.read(fp);
				})).join("\n");

			compiler(f.dest, source, f.payload(), done)
		});
	});

	grunt.registerMultiTask('pico-run', 'Run cart directly', function() {
		spawn(this.data.runtime, ["-run", this.data.cartridge]);
	});
};
