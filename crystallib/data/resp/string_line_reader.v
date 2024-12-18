module resp

struct StringLineReader {
	data []u8
	y    int
mut:
	x int
}

pub fn new_line_reader(data []u8) StringLineReader {
	return StringLineReader{
		data: data
		y:    data.len
	}
}

fn (mut r StringLineReader) read_line() []u8 {
	mut out := []u8{}
	mut c := ''.bytes()
	for {
		if r.x >= r.y {
			return []
		}
		c = [r.data[r.x]]
		if c == '\t'.bytes() {
			c = ' '.bytes()
		}
		if c == '\r'.bytes() {
			r.x++
			continue
		}
		if c == '\n'.bytes() {
			r.x++
			return out
		}
		out << c
		r.x++
	}
	panic('should not get here')
}

fn (mut r StringLineReader) read(x int) []u8 {
	mut out := []u8{}
	for _ in 0 .. x {
		if r.x > r.y - 1 {
			return []u8{}
		}
		out << r.data[r.x]
		r.x++
	}
	return out
}

fn (mut r StringLineReader) reset() {
	r.x = 0
}
