module couchdb

import freeflowuniverse.crystallib.clients.httpconnection
import json

// one specific DB in the CouchDB server
pub struct CouchDBInstance {
pub mut:
	// db name
	name       string
	connection &httpconnection.HTTPConnection
}

@[params]
pub struct DBSecurity {
pub mut:
	admins  DBUsers
	members DBUsers
}

@[params]
pub struct DBUsers {
pub mut:
	names []string
	roles []string
}

pub struct DB {
pub mut:
	instance_start_time u64
	db_name             string
	purge_seq           string
	update_seq          string
	sizes               Sizes
	props               Props
	doc_del_count       u64
	doc_count           u64
	disk_format_version u64
	compact_running     bool
	cluster             Cluster
}

pub struct Sizes {
pub mut:
	file     u64
	external u64
	active   u64
}

pub struct Props {
pub mut:
	partitioned bool
}

pub struct Cluster {
pub mut:
	n u64
	q u64
	r u64
	w u64
}

pub struct DocInfo {
	id                string       @[json: '_id']
	rev               string       @[json: '_rev']
	deleted           ?bool        @[json: '_deleted']
	attachments       ?Attachments @[json: '_attachments']
	conflicts         ?[]string    @[json: '_conflicts']
	deleted_conflicts ?[]string    @[json: '_deleted_conflicts']
	local_seq         ?string      @[json: '_local_seq']
	revs_info         ?[]RevInfo   @[json: '_revs_info']
	revisions         ?[]string    @[json: '_revisions']
}

pub struct RevInfo {
pub mut:
	rev    string
	status string
}

type Attachments = map[string]Attachment
type ID = string
type Rev = string

pub fn (mut cl CouchDBInstance) get_db() !DB {
	res := cl.connection.send(method: .get, prefix: cl.name)!
	if !res.is_ok() {
		return error('failed to get db: (${res.code}) ${res.data}')
	}

	db := json.decode(DB, res.data)!
	return db
}

pub fn (mut cl CouchDBInstance) get_document[T](doc_id ID, params GetDocumentQueryParams) !(T, DocInfo) {
	res := cl.connection.send(method: .get, prefix: '${cl.name}/${doc_id}?${params.encode()}')!
	if !res.is_ok() {
		return error('failed to get document: (${res.code}) ${res.data}')
	}

	doc := json.decode(T, res.data)!
	doc_info := json.decode(DocInfo, res.data)!
	return doc, doc_info
}

pub fn (mut cl CouchDBInstance) create_document[T](doc T) !(ID, Rev) {
	res := cl.connection.send(method: .post, prefix: cl.name, data: json.encode(doc))!
	if !res.is_ok() {
		return error('failed to create document: (${res.code}) ${res.data}')
	}

	mp := json.decode(map[string]string, res.data)!
	mut id := ''
	if _id := mp['id'] {
		id = _id
	}

	mut rev := ''
	if _rev := mp['rev'] {
		rev = _rev
	}

	return id, rev
}

pub fn (mut cl CouchDBInstance) create_or_update_document[T](doc_id ID, rev ?Rev, doc T) !(ID, Rev) {
	mut query := ''
	if _rev := rev {
		query = 'rev=${_rev}'
	}

	res := cl.connection.send(
		method: .put
		prefix: '${cl.name}/${doc_id}?${query}'
		data:   json.encode(doc)
	)!
	if !res.is_ok() {
		return error('failed to create/update document: (${res.code}) ${res.data}')
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

pub fn (mut cl CouchDBInstance) delete_document(doc_id ID, rev Rev) ! {
	res := cl.connection.send(method: .delete, prefix: '${cl.name}/${doc_id}?rev=${rev}')!
	if !res.is_ok() {
		return error('failed to delete document: (${res.code}) ${res.data}')
	}
}

// pub fn (mut cl CouchDBInstance) query(...)!{

// }
