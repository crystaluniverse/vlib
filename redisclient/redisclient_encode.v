module redisclient

import resp2

pub fn (mut r Redis) get_response() ?resp2.RValue {
	line_ := r.read_line() ?
	line := line_.bytestr()

	if line.starts_with('-') {
		return resp2.RError{
			value: line[1..]
		}
	}
	if line.starts_with(':') {
		return resp2.RInt{
			value: line[1..].int()
		}
	}
	if line.starts_with('+') {
		return resp2.RString{
			value: line[1..]
		}
	}
	if line.starts_with('$') {
		mut bulkstring_size := line[1..].int()
		if bulkstring_size == -1 {
			return resp2.RNil{}
		}
		if bulkstring_size == 0 {
			// extract final \r\n and not reading
			// any payload
			r.read_line() ?
			return resp2.RString{
				value: ''
			}
		}
		// read payload
		buffer := r.read(bulkstring_size) or { panic(err) }
		// extract final \r\n
		r.read_line() ?
		// println("readline result:'$buffer.bytestr()'")
		return resp2.RBString{
			value: buffer
		} // TODO: won't support binary (afaik), need to fix		
	}

	if line.starts_with('*') {
		mut arr := resp2.RArray{
			values: []resp2.RValue{}
		}
		items := line[1..].int()

		// proceed each entries, they can be of any types
		for _ in 0 .. items {
			value := r.get_response() ?
			arr.values << value
		}

		return arr
	}

	return error('unsupported response type')
}

pub fn (mut r Redis) get_int() ?int {
	line_ := r.read_line() ?
	line := line_.bytestr()
	if line.starts_with(':') {
		return line[1..].int()
	} else {
		return error("Did not find int, did find:'$line'")
	}
}

pub fn (mut r Redis) get_list_int() ?[]int {
	line_ := r.read_line() ?
	line := line_.bytestr()
	mut res := []int{}

	if line.starts_with('*') {
		items := line[1..].int()
		// proceed each entries, they can be of any types
		for _ in 0 .. items {
			value := r.get_int() ?
			res << value
		}
		return res
	} else {
		return error("Did not find int, did find:'$line'")
	}
}

pub fn (mut r Redis) get_list_str() ?[]string {
	line_ := r.read_line() ?
	line := line_.bytestr()
	mut res := []string{}

	if line.starts_with('*') {
		items := line[1..].int()
		// proceed each entries, they can be of any types
		for _ in 0 .. items {
			value := r.get_string() ?
			res << value
		}
		return res
	} else {
		return error("Did not find int, did find:'$line'")
	}
}

pub fn (mut r Redis) get_string() ?string {
	line_ := r.read_line() ?
	line := line_.bytestr()
	if line.starts_with('+') {
		// println("getstring:'${line[1..]}'")
		return line[1..]
	}
	if line.starts_with('$') {
		r2 := r.get_bytes_from_line(line) ?
		return r2.bytestr()
	} else {
		return error("Did not find string, did find:'$line'")
	}
}

pub fn (mut r Redis) get_string_nil() ?string {
	r2 := r.get_bytes_nil() ?
	return r2.bytestr()
}

pub fn (mut r Redis) get_bytes_nil() ?[]byte {
	line_ := r.read_line() ?
	line := line_.bytestr()
	if line.starts_with('+') {
		return line_[1..]
	}
	if line.starts_with('$') {
		return r.get_bytes_from_line(line)
	} else {
		return error("Did not find string or nil, did find:'$line'")
	}
}

pub fn (mut r Redis) get_bool() ?bool {
	i := r.get_int() ?
	return i == 1
}

pub fn (mut r Redis) get_bytes() ?[]byte {
	line_ := r.read_line() ?
	line := line_.bytestr()
	if line.starts_with('$') {
		return r.get_bytes_from_line(line)
	} else {
		return error("Did not find bulkstring, did find:'$line'")
	}
}

fn (mut r Redis) get_bytes_from_line(line string) ?[]byte {
	mut bulkstring_size := line[1..].int()
	if bulkstring_size == -1 {
		return none
	}
	if bulkstring_size == 0 {
		// extract final \r\n and not reading
		// any payload
		r.read_line() ?
		return ''.bytes()
	}
	// read payload
	buffer := r.read(bulkstring_size) ?
	// extract final \r\n
	r.read_line() ?
	return buffer
}
