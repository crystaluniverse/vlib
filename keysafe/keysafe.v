module keysafe

import freeflowuniverse.crystallib.pathlib
import freeflowuniverse.crystallib.mnemonic
import libsodium
import json
import os

pub struct KeysSafe {
pub mut:
	path    pathlib.Path          // file path of keys
	loaded  bool                  // flag to know if keysafe is loaded or loading
	secret  string                // secret to encrypt local file
	keys    map[string]PrivKey    // list of keys
}

pub struct PersistantKeysSafe {
pub mut:
	keys    map[string]string     // store name/mnemonics only
}

// note: root key needs to be 'SigningKey' from libsodium
//       from that SigningKey we can derivate PrivateKey needed to encrypt

pub fn keysafe_get(path0 string, secret string) !KeysSafe {
	mut path := pathlib.get_file_dir_create(path0 + '/.keys')!
	mut safe := KeysSafe{
		path: path
		secret: secret
	}

	if os.exists(path.absolute()) {
		println("[+] key file already exists, loading it")
		safe.load()
	}

	safe.loaded = true

	return safe
}

// for testing purposes you can generate multiple keys
pub fn (mut ks KeysSafe) generate_multiple(count int) ! {
	for i in 0 .. count {
		ks.key_generate_add('name_${i}')!
	}
}

// generate a new key is just importing a key with a random seed
pub fn (mut ks KeysSafe) key_generate_add(name string) !PrivKey {
	mut seed := []u8{}

	// generate a new random seed
	for _ in 0 .. 32 {
		seed << u8(libsodium.randombytes_random())
	}

	return ks.key_import_add(name, seed)
}

// import based on an existing seed
pub fn (mut ks KeysSafe) key_import_add(name string, seed []u8) !PrivKey {
	if name in ks.keys {
		return error("A key with that name already exists")
	}

	mnemonic := mnemonic.dumps(seed)
	signkey := libsodium.new_ed25519_signing_key_seed(seed)
	privkey := libsodium.new_private_key_from_signing_ed25519(signkey)

	pk := PrivKey{
		name: name
		mnemonic: mnemonic
		privkey: privkey
		signkey: signkey
	}

	ks.key_add(pk)!
	return pk
}

pub fn (mut ks KeysSafe) exists(name string) bool {
	return (name in ks.keys)
}

pub fn (mut ks KeysSafe) key_add(pk PrivKey) ! {
	ks.keys[pk.name] = pk

	// do not persist keys if keysafe is not loaded
	// this mean we are probably loading keys from file
	if ks.loaded {
		ks.persist()
	}
}

pub fn (mut ks KeysSafe) persist() {
	println("[+] saving keys to $ks.path.absolute()")
	serialized := ks.serialize()
	println(serialized)

	encrypted := symmetric_encrypt_blocks(serialized.bytes(), ks.secret)

	mut f := os.create(ks.path.absolute()) or { panic(err) }
	f.write(encrypted) or { panic(err) }
	f.close()
}

pub fn (mut ks KeysSafe) serialize() string {
	mut pks := PersistantKeysSafe{}

	// serializing mnemonics only
	for key, val in ks.keys {
		pks.keys[key] = val.mnemonic
	}

	export := json.encode(pks)

	return export
}

pub fn (mut ks KeysSafe) load() {
	println("[+] loading keys from $ks.path.absolute()")

	mut f := os.open(ks.path.absolute()) or { panic(err) }

	// read encrypted file
	filesize := os.file_size(ks.path.absolute())
	mut encrypted := []u8{len: int(filesize)}

	f.read(mut encrypted) or { panic(err) }
	f.close()

	// decrypt file using ks secret
	plaintext := symmetric_decrypt_blocks(encrypted, ks.secret)

	// (try to) decode the json and load keys
	ks.deserialize(plaintext.bytestr())
}

pub fn (mut ks KeysSafe) deserialize(input string) {
	mut pks := json.decode(PersistantKeysSafe, input) or {
		eprintln('Failed to decode json, wrong secret or corrupted file: ${err}')
		return
	}

	// serializing mnemonics only
	for name, mnemo in pks.keys {
		println("[+] loading key: $name")
		ks.key_import_add(name, mnemonic.parse(mnemo)) or { panic(err) }
	}

	println(ks)
}
