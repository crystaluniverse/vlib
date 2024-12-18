module twinsafe

import freeflowuniverse.crystallib.crypt.secp256k1
// import freeflowuniverse.crystallib.baobab.mbus

pub struct OtherTwin {
	conn_type_str string
pub mut:
	id          u32    @[primary; sql: serial]
	name        string @[nonull; unique]
	description string
	conn_type   TwinConnectionType @[skip]
	addr        string // ipv4 or ipv6 or redis connection string
	keysafe     &KeysSafe @[skip] // allows us to remove ourselves from mem, or go to db
	state       TwinState @[skip] // only keep this in mem, does not have to be in sqlitedb
	pubkey_str  string // pubkey is given in hex
	pubkey      secp256k1.Secp256k1 @[skip] // to be used for signing, verifying, only to be filled in when public key	
}

pub enum TwinConnectionType {
	ipv6
	ipv4
	redis
}

// The possible states of a job
pub enum TwinState {
	active
	unreacheable
}

// ADD

@[params]
pub struct OtherTwinAddArgs {
pub:
	name        string
	description string
	pubkey      string // given in hex
	conn_type   TwinConnectionType
	addr        string //
}

fn twin_conn_str(conn_type TwinConnectionType) string {
	return match conn_type {
		.ipv4 { 'ipv4' }
		.ipv6 { 'ipv6' }
		.redis { 'redis' }
	}
}

fn twin_conn_from_str(conn_type string) TwinConnectionType {
	return match conn_type {
		'ipv4' {
			TwinConnectionType.ipv4
		}
		'ipv6' {
			TwinConnectionType.ipv6
		}
		'redis' {
			TwinConnectionType.redis
		}
		else {
			TwinConnectionType.ipv4
		}
	}
}

fn (mut ks KeysSafe) othertwin_db_exists(args GetArgs) !bool {
	twins := sql ks.db {
		select from OtherTwin where name == args.name
	}!
	if twins.len > 0 {
		return true
	}
	return false
}

// generate a new key is just importing a key with a random seed
// if it exists will return the key which is already there
pub fn (mut ks KeysSafe) othertwin_add(args_ OtherTwinAddArgs) ! {
	mut args := args_
	exists := ks.othertwin_db_exists(name: args.name)!
	if exists {
		return GetError{
			args:       GetArgs{
				id:   0
				name: args.name
			}
			msg:        'othertwin with name: ${args.name} aleady exist'
			error_type: GetErrorType.alreadyexists
		}
	}

	pubkey := secp256k1.new(pubhex: args.pubkey)!
	twin := OtherTwin{
		name:          args.name
		description:   args.description
		pubkey_str:    args.pubkey
		pubkey:        pubkey
		conn_type_str: twin_conn_str(args.conn_type)
		addr:          args.addr
		keysafe:       ks
	}

	sql ks.db {
		insert twin into OtherTwin
	}!
	ks.othertwins[twin.name] = twin
}

////GET

// other twins, are remote twins
// they have the info as required to connect to them
pub fn (mut ks KeysSafe) othertwin_get(args GetArgs) !OtherTwin {
	if args.name in ks.othertwins {
		return ks.othertwins[args.name]
	}
	twins := sql ks.db {
		select from OtherTwin where name == args.name
	}!
	if twins.len == 1 {
		mut othertwin := twins[0]
		othertwin.keysafe = ks
		othertwin.state = TwinState.unreacheable // TODO: check which state to be added after loading from db
		othertwin.conn_type = twin_conn_from_str(othertwin.conn_type_str)
		ks.othertwins[othertwin.name] = othertwin
		return othertwin
	}
	return GetError{
		args:       args
		msg:        "couldn't get mytwin with name ${args.name}"
		error_type: GetErrorType.notfound
	}
}

// // send message to this other twin
// pub fn (mut twin OtherTwin) send(msg mbus.RPCMessage) ! {
// 	// TODO: convert to binary (means signature is part of it too)
// 	// TODO: give to mbus to send
// }

// // receive info from mbus, if anything in there
// pub fn (mut twin OtherTwin) receive() !mbus.RPCMessage {
// 	// TODO: receive data from mbus for this twin
// 	// TODO: verify the data which comes back over mbus with twin.verify...
// 	// TODO: probably need to use ? as return, so its optional result
// }

// // verify the received data from the mbus and make sure signature is ok
fn (mut twin OtherTwin) verify(data []u8, signature []u8) bool {
	return twin.pubkey.verify_data(signature, data)
}

pub fn (mut twin OtherTwin) delete() ! {
	twin.keysafe.othertwins.delete(twin.name)
	sql twin.keysafe.db {
		delete from OtherTwin where id == twin.id
	}!
}

pub fn (mut twin OtherTwin) save() ! {
	exists := twin.keysafe.othertwin_db_exists(name: twin.name)!
	if exists {
		sql twin.keysafe.db {
			update OtherTwin set name = twin.name, description = twin.description, pubkey_str = twin.pubkey_str,
			conn_type_str = twin.conn_type_str, addr = twin.addr where name == twin.name
		}!
		return
	}
	sql twin.keysafe.db {
		insert twin into OtherTwin
	}!
}
