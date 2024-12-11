module base

import freeflowuniverse.crystallib.data.paramsparser
import freeflowuniverse.crystallib.clients.redisclient
import freeflowuniverse.crystallib.data.dbfs
// import freeflowuniverse.crystallib.crypt.secp256k1
import freeflowuniverse.crystallib.crypt.aes_symmetric
import freeflowuniverse.crystallib.ui
import freeflowuniverse.crystallib.ui.console
import freeflowuniverse.crystallib.core.pathlib
import freeflowuniverse.crystallib.core.texttools
import freeflowuniverse.crystallib.core.rootpath
import json
import os
import crypto.md5

@[heap]
pub struct Context {
mut:
	// priv_key_     ?&secp256k1.Secp256k1 @[skip; str: skip]
	params_       ?&paramsparser.Params
	dbcollection_ ?&dbfs.DBCollection   @[skip; str: skip]
	redis_        ?&redisclient.Redis   @[skip; str: skip]
pub mut:
	// snippets     map[string]string
	config ContextConfig
}

@[params]
pub struct ContextConfig {
pub mut:
	id          u32    @[required]
	name        string = 'default'
	params      string
	coderoot    string
	interactive bool
	secret      string // is hashed secret
	priv_key    string // encrypted version
	db_path     string // path to dbcollection
	encrypt     bool
}

// return the gistructure as is being used in context
pub fn (mut self Context) params() !&paramsparser.Params {
	mut p := self.params_ or {
		mut p := paramsparser.new(self.config.params)!
		self.params_ = &p
		&p
	}

	return p
}

pub fn (self Context) id() string {
	return self.config.id.str()
}

pub fn (self Context) name() string {
	return self.config.name
}

pub fn (self Context) guid() string {
	return '${self.id()}:${self.name()}'
}

//////DATA

// pub fn (mut self Context) str() string {
// 	return self.heroscript() or { "BUG: can't represent the object properly, I try raw" }
// }

// fn (mut self Context) str2() string {
// 	panic("implement")
// 	//return 'cid:${self.cid} name:${self.name}'
// }

// pub fn (mut self Context) heroscript() !string {
// 	panic("implement")
// 	mut out := '!!core.context_define ${self.str2()}\n'
// 	mut p:=self.params()!
// 	if !p.empty() {
// 		out += '\n!!core.params_context_set'
// 		out += texttools.indent(p.heroscript(), '    ') + '\n'
// 	}
// 	// if self.snippets.len > 0 {
// 	// 	for key, snippet in self.snippets {
// 	// 		out += '\n!!core.snippet guid:${self.guid()} name:${key}'
// 	// 		out += texttools.indent(snippet.heroscript(),"    ") + '\n'
// 	// 	}
// 	// }
// 	return out
// }

pub fn (mut self Context) redis() !&redisclient.Redis {
	mut r2 := self.redis_ or {
		mut r := redisclient.core_get()!
		if self.config.id > 0 {
			// make sure we are on the right db
			r.selectdb(self.config.id)!
		}
		self.redis_ = &r
		&r
	}

	return r2
}

pub fn (mut self Context) save() ! {
	jsonargs := json.encode_pretty(self.config)
	mut r := self.redis()!
	// console.print_debug("save")
	// console.print_debug(jsonargs)	
	r.set('context:config', jsonargs)!
}

// get context from out of redis
pub fn (mut self Context) load() ! {
	mut r := self.redis()!
	d := r.get('context:config')!
	// console.print_debug("load")
	// console.print_debug(d)
	if d.len > 0 {
		self.config = json.decode(ContextConfig, d)!
	}
}

fn (mut self Context) cfg_redis_exists() !bool {
	mut r := self.redis()!
	return r.exists('context:config')!
}

// return db collection
pub fn (mut self Context) dbcollection() !&dbfs.DBCollection {
	mut dbc2 := self.dbcollection_ or {
		if self.config.db_path.len == 0 {
			self.config.db_path = '${os.home_dir()}/hero/db/${self.config.id}'
		}
		mut dbc := dbfs.get(
			contextid: self.config.id
			dbpath: self.config.db_path
			secret: self.config.secret
		)!
		self.dbcollection_ = &dbc
		&dbc
	}

	return dbc2
}

pub fn (mut self Context) db_get(dbname string) !dbfs.DB {
	mut dbc := self.dbcollection()!
	return dbc.db_get_create(name: dbname, withkeys: true)!
}

// always return the config db which is the same for all apps in context
pub fn (mut self Context) db_config_get() !dbfs.DB {
	mut dbc := self.dbcollection()!
	return dbc.db_get_create(name: 'config', withkeys: true)!
}

pub fn (mut self Context) hero_config_set(cat string, name string, content_ string) ! {
	mut content := texttools.dedent(content_)
	content = rootpath.shell_expansion(content)
	path := '${os.home_dir()}/hero/context/${self.config.name}/${cat}__${name}.yaml'
	mut config_file := pathlib.get_file(path: path)!
	config_file.write(content)!
}

pub fn (mut self Context) hero_config_exists(cat string, name string) bool {
	path := '${os.home_dir()}/hero/context/${self.config.name}/${cat}__${name}.yaml'
	return os.exists(path)
}

pub fn (mut self Context) hero_config_get(cat string, name string) !string {
	path := '${os.home_dir()}/hero/context/${self.config.name}/${cat}__${name}.yaml'
	mut config_file := pathlib.get_file(path: path, create: false)!
	return config_file.read()!
}

/////////////PRIVKEY

// pub fn (mut self Context) privkey_new() !&secp256k1.Secp256k1 {
// 	mypk := secp256k1.new()!
// 	return self.privkey_set(mypk.private_key_hex())!
// }

// pub fn (mut self Context) privkey_set(keyhex string) !&secp256k1.Secp256k1 {
// 	privkeyencr := self.secret_encrypt(keyhex)!
// 	self.config.priv_key = privkeyencr
// 	// self.save()!
// 	return self.privkey()
// }

// // get the private key
// pub fn (mut self Context) privkey() !&secp256k1.Secp256k1 {
// 	mut mypk := self.priv_key_ or {
// 		mut r := self.redis()!
// 		mut key := r.get('context:privkey') or { '' }
// 		if key == '' {
// 			return error("can't find priv key for context:${self.config.id}")
// 		}
// 		key = self.secret_decrypt(key)!
// 		mut mypk := secp256k1.new(
// 			privhex: key
// 		)!
// 		self.priv_key_ = &mypk
// 		&mypk
// 	}

// 	return mypk
// }

// will use our secret as configured for the hero to encrypt, uses base64
pub fn (mut self Context) secret_encrypt(txt string) !string {
	return aes_symmetric.encrypt_str(txt, self.secret_get()!)
}

pub fn (mut self Context) secret_decrypt(txt string) !string {
	return aes_symmetric.decrypt_str(txt, self.secret_get()!)
}

pub fn (mut self Context) secret_get() !string {
	mut secret := self.config.secret
	if secret == '' {
		self.secret_configure()!
		secret = self.config.secret
		self.save()!
	}
	if secret == '' {
		return error("can't get secret")
	}
	return secret
}

/////////////SECRET MANAGEMENT

// show a UI in console to configure the secret
pub fn (mut self Context) secret_configure() ! {
	mut myui := ui.new()!
	console.clear()
	secret_ := myui.ask_question(question: 'Please enter your hero secret string:')!
	self.secret_set(secret_)!
}

// unhashed secret
pub fn (mut self Context) secret_set(secret_ string) ! {
	secret := secret_.trim_space()
	secret2 := md5.hexhash(secret)
	self.config.secret = secret2
	self.save()!
}
