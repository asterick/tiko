const fs = require("fs");
const zlib = require("zlib");
const os = require("os");

function dest() {
	switch (os.platform()) {
	case 'darwin':
		return "/Users/bryon/Library/Application Support/pico-8/carts/tiko.p8.png"
	case 'win32':
		return "C:\\Users\\unicd\\AppData\\Roaming\\pico-8\\carts\\tiko.p8.png"
	default:
		throw new Error(`Unknown platform ${os.platform()}`);
	}
}	

function payload() {
	var payload = new Array(0x4300);
	for (var i = 0; i < 0x4300; i++) payload[i] = 0

	return zlib.deflateRawSync(new Buffer(payload), { level: 9 });
}

module.exports = function(grunt) {
	grunt.initConfig({
		pico: {
			tiko: {
				header: [
					"-- tiko",
					"-- by: asterick",
					"-- http://www.github.com/asterick/pico-tiko",
				],

				src: ["runtime/**/*", "runtime/main.lua"],
				dest: dest(),
				payload: payload
			}
		},
		"pico-run": {
			tiko: {
				runtime: "/Applications/PICO-8.app/Contents/MacOS/pico8",
				cartridge: dest()
			}
		},
		watch: {
			pico: {
				files: ["runtime/**/*"],
				tasks: ["pico"]
			}
		}
	});

	grunt.loadTasks("tasks");
	grunt.loadNpmTasks('grunt-contrib-watch');
	
	grunt.registerTask("default", ["pico"]);
	grunt.registerTask("dev", ["default", "watch"]);
	grunt.registerTask("run", ["default", "pico-run"]);
};
