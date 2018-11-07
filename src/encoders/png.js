const { PNG } = require('pngjs'),
	  fs = require('fs');

const CHARACTER_SET = "\n 0123456789abcdefghijklmnopqrstuvwxyz!#%(){}[]<>+=/*:;.,~_";

function compress(string) {
	const maxOffset = (0xFF-0x3D)*16 + 0xF;
	const minSize = 2;
	const maxSize = 0x0F + minSize;
	var bytes = [];

	var i = 0;
	while (i < string.length) {
		var bestLength = 0, 
			bestOffset = null;
		
		for (var o = Math.max(i - maxOffset, 0); o != i; o++) {
			var l = 0;
			while (l < maxSize) {
				if (o + l >= i || string[o+l] != string[i+l]) break ;
				
				l += 1;
			}

			if (l > bestLength) {
				bestLength = l;
				bestOffset = i - o;
			}

			// Pre-empt break if we can never find a longer string
			if (bestLength + o >= string.length) break ;
		}

		if (bestLength >= minSize) {
			bytes.push((bestOffset >> 4) + 0x3C);
			bytes.push(((bestLength - minSize) << 4) | (bestOffset & 0xF));

			i += bestLength;
		} else {
			var char = string[i++];
			var index = CHARACTER_SET.indexOf(char);

			bytes.push(index + 1);
			if (index < 0) {
				bytes.push(char.charCodeAt(0));
			}
		}
	}

	var encoded = [0x3a, 0x63, 0x3a, 0x00, string.length >> 8, string.length & 0xFF, 0x00, 0x00].concat(bytes);
	return Buffer.from(encoded);
}

module.exports = function(fn, runtime, payload) {
	var data = Buffer.alloc(0x8001),
		idx = 0x4300;

	runtime = compress(runtime);

	console.log("Runtime size:", runtime.length);
	console.log("Payload size:", payload.length);

	if (payload.length > 0x4300 || 
		runtime.length > (0x8000 - 0x4300)) {
		throw new Error("Out of memory");
	}

	// Map to the rom	
	for (var i = 0; i < payload.length; i++) {
		data[i] = payload[i];
	}
	for (var i = 0; i < runtime.length; i++) {
		data[0x4300 + i] = runtime[i];
	}

	data[0x8000] = 4;

	fs.createReadStream(path.join(__dirname, '/cartridge.png'))
	    .pipe(new PNG({
	        filterType: 4
	    }))
	    .on('parsed', function() {
	    	var px = 0;
	    	for (var idx = 0; idx < data.length; idx++) {
	    		var b = data[idx];
	    		
	    		b = ((b >> 4) & 0x3) | ((b & 0x3) << 4) | (b & 0xCC);

	    		for (var bit = 0; bit < 8; bit += 2, px++) {
	    			this.data[px] = (this.data[px] & ~3) | ((b >> bit) & 0x3);
	    		}
	    	}

	        this.pack().pipe(fs.createWriteStream(fn));
	    });
}
