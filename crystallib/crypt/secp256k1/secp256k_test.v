module secp256k1

import os
import freeflowuniverse.crystallib.osal.sshagent
import freeflowuniverse.crystallib.core.texttools
import freeflowuniverse.crystallib.core.pathlib
import freeflowuniverse.crystallib.ui.console
import encoding.hex
import crypto.sha256
import freeflowuniverse.crystallib.crypt.secp256k1

fn test_check() {

	console.print_debug('${'[+] initializing libsecp256 vlang wrapper'}')

	wendy := secp256k1.new()!
	webdy_priv_key:=wendy.private_key()
	webdy_pub_key:=wendy.public_key()
	console.print_debug('-------')
	console.print_debug('Wendy Private: ${webdy_priv_key}')
	console.print_debug('Wendy Public: ${webdy_pub_key}')
	console.print_debug('-------')

	// create 'bob' from a private key, full features will be available
	bob := secp256k1.new(
		privhex: '0x478b45390befc3097e3e6e1a74d78a34a113f4b9ab17deb87e9b48f43893af83'
	)!

	// create 'alice' from a private key, full features will be available
	alice := secp256k1.new(
		privhex: '0x8225825815f42e1c24a2e98714d99fee1a20b5ac864fbcb7a103cd0f37f0ffec'
	)!

	// create 'bobpub' from bob only public key, reduced features available (only sign check, shared keys, etc.)
	bobpub := secp256k1.new(
		pubhex: bob.public_key()
	)!

	// create 'alicepub' from alice only public key, reduced features available
	alicepub := secp256k1.new(
		pubhex: alice.public_key()
	)!

	shr1 := bob.sharedkeys(alice)
	console.print_debug('${shr1}')

	shr2 := alice.sharedkeys(bob)
	console.print_debug('${shr2}')

	// example in real world, where private key is available and only target public key
	shr1pub := bob.sharedkeys(alicepub)
	console.print_debug('${shr1pub}')

	shr2pub := alice.sharedkeys(bobpub)
	console.print_debug('${shr2pub}')

	console.print_debug('-----')

	mut message := 'Hello world, this is my awesome message'
	message += message
	message += message
	message += message
	message += message

	h256 := sha256.hexhash(message)
	console.print_debug('${h256}')
	console.print_debug('${h256.len}')
	console.print_debug('${sha256.sum(message.bytes())}')

	parsed := hex.decode(h256) or { panic(err) }
	console.print_debug('${parsed}')
	console.print_debug('${parsed.len}')

	//
	// signature (ecdca)
	//
	signed := alice.sign_data(message.bytes())
	console.print_debug('${signed}')

	signed_hex := alice.sign_data_hex(message.bytes())
	console.print_debug('${signed_hex}')
	console.print_debug('${signed_hex.len}')

	signed_str := alice.sign_str(message)
	console.print_debug('${signed_str}')
	console.print_debug('${signed_str.len}')

	signed_str_hex := alice.sign_str_hex(message)
	assert signed_str_hex=="656699dde22d8b89d91070dee4fc8dba136172fb54e6de475024c40e4f8d5111562212c8976b5a4ccd530bdb7f40c5d9bd2cdeeec1473656566fbb9c4576ed8c"
	assert signed_str_hex.len==128

	// instanciate alice with only her public key
	assert alicepub.verify_data(signed, message.bytes()) == true
	assert alicepub.verify_str(signed_str, message) == true
	assert alicepub.verify_str(signed_str, message+"s") == false


	//
	// signature (schnorr)
	//
	// schnorr_signed := alice.schnorr_sign_data(message.bytes())
	// console.print_debug('${schnorr_signed}')

	// schnorr_signed_hex := alice.schnorr_sign_data_hex(message.bytes())
	// console.print_debug('${schnorr_signed_hex}')

	// schnorr_signed_str := alice.schnorr_sign_str(message)
	// console.print_debug('${schnorr_signed_str}')

	// schnorr_signed_str_hex := alice.schnorr_sign_str_hex(message)
	// console.print_debug('${schnorr_signed_str_hex}')

	// console.print_debug('${alicepub.schnorr_verify_data(schnorr_signed, message.bytes())}')
	// console.print_debug('${alicepub.schnorr_verify_str(schnorr_signed_str, message)}')

	// // should fails, it's not the right signature method (ecdsa / schnorr)
	// console.print_debug('${alicepub.verify_data(schnorr_signed, message.bytes())}')
	// console.print_debug('${alicepub.verify_str(schnorr_signed_str, message)}')


}
