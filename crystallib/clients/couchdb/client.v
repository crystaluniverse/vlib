module couchdb

import json

// return DB client
pub fn (mut cl CouchDBClient[Config]) db_instance(db_name string) !CouchDBInstance {
	res := cl.connection.send(method: .get, prefix: '${db_name}/_security')!
	db_security := json.decode(DBSecurity, res.data)!
	if cl.username !in db_security.admins.names && cl.username !in db_security.members.names {
		return error('user ${cl.username} is not authorized to access db ${db_name}')
	}

	return CouchDBInstance{
		name:       db_name
		connection: cl.connection
	}
}

@[params]
pub struct CoudDBCreateArgs {
pub mut:
	// database name
	name string
	// they have all the privileges of members plus the privileges: write (and edit) design documents,
	// add/remove database admins and members and set the database revisions limit.
	// They can not create a database nor delete a database.
	admins []string
	// they can read all types of documents from the DB, and they can write (and edit) documents to the DB except for design documents.
	members []string
}

pub fn (mut cl CouchDBClient[Config]) db_create(args CoudDBCreateArgs) ! {
	// PUT request to /db_name
	mut res := cl.connection.send(method: .put, prefix: args.name)!
	if !res.is_ok() {
		return error('failed to create db: (${res.code}) ${res.data}')
	}

	// add authorization for admins and members
	res = cl.connection.send(
		method: .put
		prefix: '${args.name}/_security'
		data:   json.encode({
			'admins':  {
				'names': args.admins
				'roles': []string{}
			}
			'members': {
				'names': args.members
				'roles': []string{}
			}
		})
	)!
	if !res.is_ok() {
		return error('faile to add database admins/members: (${res.code}) ${res.data}')
	}
}

pub fn (mut cl CouchDBClient[Config]) db_delete(name string) ! {
	// DELETE request to /db_name
	res := cl.connection.send(method: .delete, prefix: name)!
	if !res.is_ok() {
		return error('failed to delete db: (${res.code}) ${res.data}')
	}
}

// list dbs found on connection
pub fn (mut cl CouchDBClient[Config]) db_list() ![]string {
	// GET request to /_all_dbs
	res := cl.connection.send(method: .get, prefix: '_all_dbs')!
	if !res.is_ok() {
		return error('failed to list all dbs: (${res.code}) ${res.data}')
	}

	r := json.decode([]string, res.data)!
	return r
}
