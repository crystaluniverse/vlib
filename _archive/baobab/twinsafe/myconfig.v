module twinsafe

import encoding.hex
import freeflowuniverse.crystallib.crypt.aes_symmetric

// this is me, my representation
pub struct MyConfig {
pub mut:
	id          u32    @[primary; sql: serial]
	name        string @[nonull; unique]
	description string
	config      string    @[skip] // this is heroscript which holds the initialization content for configuration of anything
	keysafe     &KeysSafe @[skip] // allows us to remove ourselves from mem, or go to db
	config_enc  string
}

@[params]
pub struct MyConfigAddArgs {
pub:
	name        string
	description string
	config      string
}

fn (mut ks KeysSafe) myconfig_db_exists(args GetArgs) !bool {
	configs := sql ks.db {
		select from MyConfig where name == args.name
	}!
	if configs.len > 0 {
		return true
	}
	return false
}

// generate a new key is just importing a key with a random seed
// if it exists will return the key which is already there
pub fn (mut ks KeysSafe) myconfig_add(args_ MyConfigAddArgs) ! {
	mut args := args_
	exists := ks.myconfig_db_exists(name: args.name)!
	if exists {
		return GetError{
			args:       GetArgs{
				id:   0
				name: args_.name
			}
			msg:        'myconfig with name: ${args.name} already exist'
			error_type: GetErrorType.alreadyexists
		}
	}

	config_enc := hex.encode(aes_symmetric.encrypt(args.config.bytes(), ks.secret))
	myconfig := MyConfig{
		name:        args.name
		description: args.description
		config:      args.config
		config_enc:  config_enc
		keysafe:     ks
	}

	sql ks.db {
		insert myconfig into MyConfig
	}!
	ks.myconfigs[myconfig.name] = myconfig
}

// I can have more than 1 myconfig, ideal for testing as well
pub fn (mut ks KeysSafe) myconfig_get(args GetArgs) !MyConfig {
	if args.name in ks.myconfigs {
		return ks.myconfigs[args.name]
	}
	configs := sql ks.db {
		select from MyConfig where name == args.name
	}!
	if configs.len == 1 {
		mut myconfig := configs[0]
		config_enc := hex.decode(myconfig.config_enc)!
		config_bytes := aes_symmetric.decrypt(config_enc, ks.secret)
		myconfig.config = config_bytes.bytestr()
		myconfig.keysafe = ks
		return myconfig
	}
	return GetError{
		args:       args
		msg:        "couldn't get myconfig with name: ${args.name}"
		error_type: GetErrorType.notfound
	}
}

pub fn (mut myconfig MyConfig) delete() ! {
	myconfig.keysafe.myconfigs.delete(myconfig.name)
	sql myconfig.keysafe.db {
		delete from MyConfig where id == myconfig.id
	}!
}

pub fn (mut myconfig MyConfig) save() ! {
	config_enc := aes_symmetric.encrypt(myconfig.config.bytes(), myconfig.keysafe.secret)

	exists := myconfig.keysafe.myconfig_db_exists(name: myconfig.name)!

	if exists {
		sql myconfig.keysafe.db {
			update MyConfig set name = myconfig.name, description = myconfig.description,
			config_enc = hex.encode(config_enc) where name == myconfig.name
		}!
		return
	}
	sql myconfig.keysafe.db {
		insert myconfig into MyConfig
	}!
}
