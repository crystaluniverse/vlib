module vstor

// import freeflowuniverse.crystallib.core.pathlib
// import time

pub struct ZDB {
pub mut:
	location  Location
	address   string
	port      u32
	secret    string
	namespace string
	stats     []ZDBSTAT
}

pub fn (mut vstor VSTOR) zdb_new(args ZDB) !ZDB {
	// maintain all properties as defined before only change the ZDB's
	mut zdb := ZDB{
		address:   args.address
		port:      args.port
		namespace: args.namespace
		secret:    args.secret
		location:  args.location
	}
	return zdb
}
