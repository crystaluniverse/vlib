module dbfs

import freeflowuniverse.crystallib.core.pathlib
// import freeflowuniverse.crystallib.clients.redisclient
import os

@[params]
pub struct CollectionGetArgs {
pub mut:
	dbpath    string
	secret    string
	contextid u32
}

// will return the dbcollection for a specific context
pub fn get(args_ CollectionGetArgs) !DBCollection {
	mut args := args_
	mut secret := args.secret
	if args.dbpath == '' {
		args.dbpath = '${os.home_dir()}/var/dbfs/${args.contextid}'
	}
	mut p := pathlib.get_dir(create: true, path: args.dbpath)!

	// mut c:=base.context()!
	// mut r:=c.redis()!
	// r.selectdb(args_.contextid)!

	mut dbcollection := DBCollection{
		path: p
		secret: secret
		contextid: args.contextid
		// redis:r
	}
	return dbcollection
}
