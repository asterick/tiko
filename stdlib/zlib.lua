function inflate(peek, index, base_tbl, ins_tbl)
	local function bits(n)
		local out = 0
		for i = 0, n-1 do
			out += shl(band(1, peek(index) / 256 ^ (index % 1)), i)
			index += 0x.2
		end
		return out
	end

	local function make_tbl(lens, count, width, ...)
		if count then 
			for k = 1, count do
			 	add(lens, width)
			end 
			return def_tbl(lens, ...)
		end

		local idx, out = 0, {}
		for b = 0, 15 do
			for c = 0, 287 do
				if lens[c+1] == b+1 then
					out[b/16+idx] = c
					idx = idx + 1
				end
			end
			idx *= 2
		end
		return out
	end

	local function get_code(table)
		local code = 0
		for b=0, 0x.f, 0x.1 do
			code = code * 2 + bits(1)
			local out = table[b + code]
			if out then
				return out
			end
		end
	end

	local function get_int(symbol, n)
		if symbol > n then
		local i = flr(symbol / n - 1)
			return shl(symbol % n + n, i) + bits(i)
		end
		return symbol
	end

	local output = {}

	repeat
		local final, method = bits(1), bits(2)

		if method == 1 then
			-- these are special ones
			base_tbl = make_tbl({}, 144, 8, 112, 9, 24, 7, 8, 8)
			ins_tbl = make_tbl({}, 32, 5)
		elseif method == 2 then
			-- create dynamic table
			base_tbl, ins_tbl, hf_tbl = 257 + bits(5), 1 + bits(5), {}

			-- create our code length table
			for i=1, 4 + bits(4) do
				hf_tbl[({ 17, 18, 19, 1, 9, 8, 10, 7, 11, 6, 12, 5, 13, 4, 14, 3, 15, 2, 16 })[i]] = bits(3)
			end

			local hf_tbl = make_tbl(hf_tbl)

			local function build(count)
				local out = {}

				while #out < count do
					local code = get_code(hf_tbl)

					if code < 16 then
						add(out, code)
					elseif code == 16 then
						for i = -2, bits(2) do
							add(out, out[#out])
						end
					elseif code == 17 then
						for i = -2, bits(3) do
							add(out, 0)
						end
					else
						for i = -10, bits(7) do 
							add(out, 0) 
						end
					end
				end

				return make_tbl(out)
			end

			base_tbl, ins_tbl = build(base_tbl), build(ins_tbl)
		end

		repeat
			local code = get_code(base_tbl)

			if code <= 255 then	
				add(output, code)
			elseif code == 256 then
				break
			else
				local length = code < 285 and get_int(code - 257, 4) + 3 or 258

				local offs = get_int(get_code(ins_tbl), 2)
				for i = 1, length do
					add(output, output[#output - offs])
				end
			end
		until false
	until final > 0

	return output
end
