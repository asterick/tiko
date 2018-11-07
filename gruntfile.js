const fs = require("fs"),
      zlib = require("zlib"),
      os = require("os");

function payload() {
	var payload = new Array(0x4300);
	for (var i = 0; i < 0x4300; i++) payload[i] = 0

	return zlib.deflateRawSync(new Buffer(payload), { level: 9 });
}

module.exports = function(grunt) {
	grunt.initConfig({
		"pico": {
			pico: {
				src: ["runtime/main.lua", "runtime/**/*"],
				dest: "tiko.p8.png",
				payload: payload
			}
		},
		"pico-run": {
			pico: {
				runtime: "/Applications/PICO-8.app/Contents/MacOS/pico8",
				cartridge: "tiko.p8.png"
			}
		},
		watch: {
			pico: {
				files: ["runtime/**/*", "runtime/main.lua"],
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
