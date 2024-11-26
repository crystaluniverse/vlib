module dbfs

import os
import freeflowuniverse.crystallib.core.texttools
import freeflowuniverse.crystallib.crypt.secp256k1
import freeflowuniverse.crystallib.ui.console

fn test_dbname1() {
	data_dir := '/tmp/namedbtest'

	mut ndb := namedb_new(data_dir)!

	console.print_debug('delete ${data_dir}')
	os.rmdir_all(data_dir) or {}

	mut test_cases := []string{}
	mut nr := 1
	for i := 0; i < nr * 1000 + 1; i++ {
		privkey := secp256k1.new()!
		pubkey := privkey.public_key_base64()
		if i % 1000 == 0 {
			console.print_debug(i)
		}
		test_cases << pubkey
	}

	defer {
		// os.rmdir_all(data_dir) or {}
		console.print_debug('rmdir done')
	}

	// Register public keys and store their unique IDs
	mut ids := []u32{}
	mut i := 0
	for pubkey in test_cases {
		if i % 1000 == 0 {
			console.print_debug('b${i}')
		}
		myid := ndb.set(pubkey, '${i}')!
		ids << myid
		i++
	}

	// Retrieve public keys using their unique IDs
	console.print_debug('retrieve starts')
	for i2, myid in ids {
		retrieved_pubkey, data := ndb.get(myid)!
		myid_found, data_found := ndb.getdata(retrieved_pubkey)!
		assert myid_found == myid
		assert data_found == data
		tc := test_cases[i2] or {
			panic("can't find ${i2} in test_cases with len: ${test_cases.len}")
		}
		assert retrieved_pubkey == tc, 'Retrieved pubkey doesn\'t match for ID: ${myid}'
	}

	console.print_debug('All tests passed!')
}

fn test_dbname2() {
	assert namedb_dbid(0).str() == '(0, 0, 0)'
	assert namedb_dbid(1).str() == '(0, 0, 1)'
	assert namedb_dbid(255).str() == '(0, 0, 255)'
	assert namedb_dbid(256).str() == '(0, 1, 0)'
	assert namedb_dbid(256 * 256).str() == '(1, 0, 0)'
	assert namedb_dbid(256 * 256 + 3).str() == '(1, 0, 3)'
	assert namedb_dbid(256 * 256 + 3 + 256).str() == '(1, 1, 3)'
}
