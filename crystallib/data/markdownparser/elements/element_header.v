module elements

@[heap]
pub struct Header {
	DocBase
pub mut:
	depth int
}

pub fn (mut self Header) process() !int {
	if self.processed {
		return 0
	}
	self.processed = true
	return 1
}

pub fn (mut self Header) markdown() !string {
	mut h := ''
	for _ in 0 .. self.depth {
		h += '#'
	}
	return '${h} ${self.content}'
}

pub fn (mut self Header) html() !string {
	return '<h${self.depth}>${self.content}</h${self.depth}>\n'
}

pub fn (mut self Header) pug() !string {
	return error('cannot return pug, not implemented')
}
