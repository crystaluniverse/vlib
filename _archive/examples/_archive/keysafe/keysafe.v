module main

import freeflowuniverse.crystallib.crypt.keysafe

fn main() {
	//
	// load a keyssafe from disk (or generate a new one)
	//
	mut ks := keysafe.keysafe_get('/tmp/', 'helloworld')!
	// println(ks)

	//
	// generate a new key, silent the error
	//
	ks.key_generate_add('maxux') or { println(err) }
	// println(ks)

	if ks.exists('maxux') {
		println("Key 'maxux' exists in the KeySafe")
	}

	//
	// clean way to add key, used to sumulate a public key
	// for our test
	//
	if !ks.exists('target') {
		ks.key_generate_add('target') or { println(err) }
	}

	//
	// test public key exporting
	//
	key_maxux := ks.get('maxux') or { panic(err) }
	key_target := ks.get('target') or { panic(err) }

	share_maxux := key_maxux.master_public()
	share_target := key_target.master_public()

	println('Maxux Public Key: ${share_maxux}')
	println('Target Public Key: ${share_target}')

	//
	// test signing system
	//
	signed := key_maxux.sign('Hello World, Sign Me Please'.bytes())
	println('=== Signed Data Dump ===')
	println(signed)

	// QUESTION: how to get the data out ?

	// load public key like it was received from external channel
	checker := keysafe.verifykey_new('maxux', share_maxux)!
	value := checker.verify(signed)

	println('Signature verification: ${value}')

	//
	// test encryption system
	//

	// encrypt some data with 'target' public key and
	// maxux private for signing
	encrypter := keysafe.pubkey_new('test', key_maxux, share_target)!
	data := encrypter.encrypt('HELLO WORLD, ENCRYPT ME'.bytes())!

	println('=== TARGET PUBKEY DATA ENCRYPTED ===')
	println(data)

	println('Decrypt data')
	// try to decrypt data with target private key
	// and maxux public key (to ensure it comes from him)
	decrypter := keysafe.pubkey_new('test2', key_target, share_maxux)!
	plaintext := decrypter.decrypt(data)
	println(plaintext.bytestr())
}
