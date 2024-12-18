module twinsafe

import freeflowuniverse.crystallib.core.pathlib
// import freeflowuniverse.crystallib.data.mnemonic // buggy for now
import db.sqlite

pub struct KeysSafe {
pub mut:
	mytwins    map[string]MyTwin // is like a cache for what is in the sqlitedb
	secret     string            // secret to encrypt local file
	db         sqlite.DB
	othertwins map[string]OtherTwin // is like a cache for what is in the sqlitedb
	myconfigs  map[string]MyConfig
}

@[params]
pub struct KeysSafeNewArgs {
pub mut:
	path   string // location where sqlite db will be which holds the keys
	secret string // secret to encrypt local file
}

pub fn new(args_ KeysSafeNewArgs) !KeysSafe {
	mut args := args_
	if args.path.len == 0 {
		args.path = '~/.twin'
	}
	pathlib.get_dir(path: args.path, create: true)!
	mut db := sqlite.connect('${args.path}/keysafe.db')!
	mut safe := KeysSafe{
		db:     db
		secret: args.secret
	}

	return safe
}

pub fn (mut safe KeysSafe) save() ! {
	// walk over mem, make sure all info from mem is also in sqlitedb
	for _, twin in safe.mytwins {
		mut twin_ := twin
		twin_.save()!
	}
	for _, other_twin in safe.othertwins {
		mut othertwin_ := other_twin
		othertwin_.save()!
	}
	for _, config in safe.myconfigs {
		mut config_ := config
		config_.save()!
	}
}

pub fn (mut safe KeysSafe) loadall() ! {
	// walk over sqlitedb, load all in mem
	mytwins := safe.load_mytwins()!
	for twin in mytwins {
		args := GetArgs{
			id:   twin.id
			name: twin.name
		}
		safe.mytwins[twin.name] = safe.mytwin_get(args)!
	}
	other_twins := safe.load_other_twins()!
	for otwin in other_twins {
		args := GetArgs{
			id:   otwin.id
			name: otwin.name
		}
		safe.othertwins[otwin.name] = safe.othertwin_get(args)!
	}
	configs := safe.load_myconfig()!
	for config in configs {
		args := GetArgs{
			id:   config.id
			name: config.name
		}
		safe.myconfigs[config.name] = safe.myconfig_get(args)!
	}
}

fn (mut safe KeysSafe) load_mytwins() ![]MyTwin {
	twins := sql safe.db {
		select from MyTwin
	}!
	return twins
}

fn (mut safe KeysSafe) load_other_twins() ![]OtherTwin {
	other_twins := sql safe.db {
		select from OtherTwin
	}!
	return other_twins
}

fn (mut safe KeysSafe) load_myconfig() ![]MyConfig {
	configs := sql safe.db {
		select from MyConfig
	}!
	return configs
}
