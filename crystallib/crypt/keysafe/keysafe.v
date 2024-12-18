module keysafe

import freeflowuniverse.crystallib.core.pathlib
// import freeflowuniverse.crystallib.data.mnemonic // buggy for now
import encoding.hex
import libsodium
import json
import os
import freeflowuniverse.crystallib.ui.console

/*
* KeysSafe
 *
 * This module implement a secure keys manager.
 *
 * When loading a keysafe object, you can specify a directory and a secret.
 * In that directory, a file called '.keys' will be created and encrypted using
 * the 'secret' provided (AES-CBC).
 *
 * Content of that file is a JSON dictionnary of key-name and it's mnemonic,
 * a single mnemonic is enough to derivate ed25519 and x25519 keys.
 *
 * When loaded, private/public signing key and public/private encryption keys
 * are loaded and ready to be used.
 *
 * key_generate_add() generate a new key and store is as specified name
 * key_import_add() import an existing key based on it's seed and specified name
 *
*/

pub struct KeysSafe {
pub mut:
	path   pathlib.Path       // file path of keys
	loaded bool               // flag to know if keysafe is loaded or loading
	secret string             // secret to encrypt local file
	keys   map[string]PrivKey // list of keys
}

pub struct PersistantKeysSafe {
pub mut:
	keys map[string]string // store name/mnemonics only
}

// note: root key needs to be 'SigningKey' from libsodium
//       from that SigningKey we can derivate PrivateKey needed to encrypt

pub fn keysafe_get(path0 string, secret string) !KeysSafe {
	mut path := pathlib.get_file(path: path0 + '/.keys', create: true)!
	mut safe := KeysSafe{
		path:   path
		secret: secret
	}

	if os.exists(path.absolute()) {
		console.print_debug('[+] key file already exists, loading it')
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

fn internal_key_encode(key []u8) string {
	return '0x' + hex.encode(key)
}

fn internal_key_decode(key string) []u8 {
	parsed := hex.decode(key.substr(2, key.len)) or { panic(err) }
	return parsed
}

// import based on an existing seed
pub fn (mut ks KeysSafe) key_import_add(name string, seed []u8) !PrivKey {
	if name in ks.keys {
		return error('A key with that name already exists')
	}

	mnemonic := internal_key_encode(seed) // mnemonic(seed)
	signkey := libsodium.new_ed25519_signing_key_seed(seed)
	privkey := libsodium.new_private_key_from_signing_ed25519(signkey)

	// console.print_debug("===== SEED ====")
	// console.print_debug(seed)
	// console.print_debug(mnemonic)

	pk := PrivKey{
		name:     name
		mnemonic: mnemonic
		privkey:  privkey
		signkey:  signkey
	}

	ks.key_add(pk)!
	return pk
}

pub fn (mut ks KeysSafe) get(name string) !PrivKey {
	if !ks.exists(name) {
		return error('key not found')
	}

	return ks.keys[name]
}

pub fn (mut ks KeysSafe) exists(name string) bool {
	return name in ks.keys
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
	console.print_debug('[+] saving keys to ${ks.path.absolute()}')
	serialized := ks.serialize()
	// console.print_debug(serialized)

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
	console.print_debug('[+] loading keys from ${ks.path.absolute()}')

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
		console.print_debug('Failed to decode json, wrong secret or corrupted file: ${err}')
		return
	}

	// serializing mnemonics only
	for name, mnemo in pks.keys {
		console.print_debug('[+] loading key: ${name}')
		seed := internal_key_decode(mnemo) // mnemonic.parse(mnemo)

		// console.print_debug("==== SEED ====")
		// console.print_debug(mnemo)
		// console.print_debug(seed)

		ks.key_import_add(name, seed) or { panic(err) }
	}

	// console.print_debug(ks)
}
