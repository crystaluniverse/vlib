module elements

import toml

// Frontmatter struct
@[heap]
pub struct Frontmatter {
	DocBase
pub mut:
	doc toml.Doc // Stores the parsed TOML document
}

pub fn (mut self Frontmatter) process() !int {
	if self.processed {
		return 0
	}
	// Parse the TOML frontmatter content into a toml.Doc
	self.doc = toml.parse_text(self.content) or {
		return error('Failed to parse TOML frontmatter: ${err.msg()}')
	}
	// Clear content after parsing
	self.content = ''
	self.processed = true
	return 1
}

pub fn (self Frontmatter) markdown() !string {
	mut out := '+++\n'
	// Convert the TOML document back to string
	for key, value in self.doc.to_any().as_map() {
		out += '${key} = ${value.to_toml()}\n'
	}
	out += '+++'
	return out
}

pub fn (self Frontmatter) html() !string {
	mut out := '<div class="frontmatter">\n'
	for key, value in self.doc.to_any().as_map() {
		out += '  <p><strong>${key}</strong>: ${value.string()}</p>\n'
	}
	out += '</div>'
	return out
}

pub fn (self Frontmatter) pug() !string {
	mut out := ''
	out += 'div(class="frontmatter")\n'
	for key, value in self.doc.to_any().as_map() {
		out += '  p\n'
		out += '    strong ${key}: ${value.string()}\n'
	}
	return out
}

pub fn (self Frontmatter) get_value(key string) !toml.Any {
	// Retrieve a value using a query string
	return self.doc.value_opt(key) or { return error('Key "${key}" not found in frontmatter') }
}

pub fn (self Frontmatter) get_string(key string) !string {
	return self.get_value(key)!.string()
}

pub fn (self Frontmatter) get_bool(key string) !bool {
	return self.get_value(key)!.bool()
}

pub fn (self Frontmatter) get_int(key string) !int {
	return self.get_value(key)!.int()
}
