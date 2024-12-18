module couchdb

import json

// see http://127.0.0.1:5984/_utils/docs/intro/api.html#documents attachments

// make sure we return as binary

// QUESTION: how should we deal with big documents

pub struct Attachment {
pub mut:
	content_type   string
	data           ?string
	digest         string
	encoded_length ?u64
	encoding       ?string
	length         ?u64
	revpos         u64
	stub           ?bool
}

pub fn (mut cl CouchDBInstance) attachment_get(doc_id string, attachment_name string) !string {
	res := cl.connection.send(method: .get, prefix: '${cl.name}/${doc_id}/${attachment_name}')!
	if !res.is_ok() {
		return error('failed to get attachment: (${res.code}) ${res.data}')
	}

	return res.data
}

pub fn (mut cl CouchDBInstance) attachment_add(doc_id ID, rev Rev, attachment_name string, data string) !(ID, Rev) {
	res := cl.connection.send(
		method: .put
		prefix: '${cl.name}/${doc_id}/${attachment_name}?rev=${rev}'
		data:   data
	)!
	if !res.is_ok() {
		return error('failed to add attachment: (${res.code}) ${res.data}')
	}

	mp := json.decode(map[string]string, res.data)!
	mut id := ''
	if _id := mp['id'] {
		id = _id
	}

	mut new_rev := ''
	if _rev := mp['rev'] {
		new_rev = _rev
	}

	return id, new_rev
}

pub fn (mut cl CouchDBInstance) attachment_delete(doc_id ID, rev Rev, attachment_name string) !(ID, Rev) {
	res := cl.connection.send(
		method: .delete
		prefix: '${cl.name}/${doc_id}/${attachment_name}?rev=${rev}'
	)!
	if !res.is_ok() {
		return error('failed to delete attachment: (${res.code}) ${res.data}')
	}

	mp := json.decode(map[string]string, res.data)!
	mut id := ''
	if _id := mp['id'] {
		id = _id
	}

	mut new_rev := ''
	if _rev := mp['rev'] {
		new_rev = _rev
	}

	return id, new_rev
}

pub fn (mut cl CouchDBInstance) attachment_list(doc_id ID) !Attachments {
	res := cl.connection.send(method: .get, prefix: '${cl.name}/${doc_id}')!
	if !res.is_ok() {
		return error('failed to get document: (${res.code}) ${res.data}')
	}

	doc_info := json.decode(DocInfo, res.data)!
	if attachments := doc_info.attachments {
		return attachments
	}

	return Attachments(map[string]Attachment{})
}
