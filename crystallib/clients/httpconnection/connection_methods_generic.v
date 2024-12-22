module httpconnection

import json

pub fn (mut h HTTPConnection) get_json_generic[T](req Request) !T {
	data := h.get_json(req)!
	return json.decode(T, data) or { return error("couldn't decode json for ${req} for ${data}") }
}

pub fn (mut h HTTPConnection) post_json_generic[T](req Request) !T {
	data := h.post_json_str(req)!
	return json.decode(T, data) or { return error("couldn't decode json for ${req} for ${data}") }
}

pub fn (mut h HTTPConnection) get_json_list_generic[T](req Request) ![]T {
	mut r := []T{}
	for item in h.get_json_list(req)! {
		// println(item)
		r << json.decode(T, item) or { return error("couldn't decode json for ${req} for ${item}") }
	}
	return r
}
