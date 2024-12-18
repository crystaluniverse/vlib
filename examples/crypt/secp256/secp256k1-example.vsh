#!/usr/bin/env -S v -gc none -no-retry-compilation -cc tcc -d use_openssl -enable-globals run

import freeflowuniverse.crystallib.ui.console
import encoding.hex
import crypto.sha256
import freeflowuniverse.crystallib.crypt.secp256k1

console.print_debug('${'[+] initializing libsecp256 vlang wrapper'}')

wendy := secp256k1.new()!
console.print_debug('-------')
console.print_debug('Wendy Private hex:  ${wendy.private_key_hex()} ${wendy.private_key_hex().len}')
console.print_debug('Wendy Public hex: ${wendy.public_key_hex()} ${wendy.public_key_hex().len}')
console.print_debug('Wendy Private base64: ${wendy.private_key_base64()} ${wendy.private_key_base64().len}')
console.print_debug('Wendy Public base64: ${wendy.public_key_base64()} ${wendy.public_key_base64().len}')

// create 'bob' from a private key, full features will be available
bob_privhex := '478b45390befc3097e3e6e1a74d78a34a113f4b9ab17deb87e9b48f43893af83'
bob := secp256k1.new(privhex: bob_privhex)!
assert bob.private_key_hex() == bob_privhex
bob_privbase64 := bob.private_key_base64()
bob2 := secp256k1.new(privbase64: bob_privbase64)!
assert bob2.private_key_hex() == bob_privhex

console.print_debug('Box Private hex: ${bob.private_key_hex()} ${bob.private_key_hex().len}')

// create 'alice' from a private key, full features will be available
alice := secp256k1.new(
	privhex: '8225825815f42e1c24a2e98714d99fee1a20b5ac864fbcb7a103cd0f37f0ffec'
)!

console.print_debug('-------\nSHOW HOW TO GET PUBKEY OBJ FROM PUBLICKEY')
console.print_debug('bob pubkey as input hex: ${bob.public_key_hex()}')
console.print_debug('bob pubkey as input base64: ${bob.public_key_base64()}')

// create 'bobpub' from bob only public key, reduced features available (only sign check, shared keys, etc.)
bobpub := secp256k1.new(
	pubbase64: bob.public_key_base64()
)!

// create 'alicepub' from alice only public key, reduced features available
alicepub := secp256k1.new(
	pubhex: alice.public_key_hex()
)!

assert bobpub.public_key_base64() == bob.public_key_base64()
assert alicepub.public_key_base64() == alice.public_key_base64()

console.print_debug('-----\nSHOW HOW SHARED KEYS CAN BE DERIVED')

shr1 := bob.sharedkeys_hex(alice)
console.print_debug('bob shared key with alice: ${shr1}')

shr2 := alice.sharedkeys_hex(bob)
console.print_debug('alice shared key with bob ${shr2}')

// example in real world, where private key is available and only target public key
shr1pub := bob.sharedkeys_hex(alicepub)
console.print_debug('bob shared key with alice from pub: ${shr1pub}')

shr2pub := alice.sharedkeys_hex(bobpub)
console.print_debug('alice shared key with bob from pub ${shr2pub}')

console.print_debug('----- SIGN test')

mut message := 'Hello world, this is my awesome message'
message += message
message += message
message += message
message += message

h256 := sha256.hexhash(message)
console.print_debug('message sha256 hex: ${h256} ${h256.len}')
console.print_debug('message sha256: ${sha256.sum(message.bytes())} ${sha256.sum(message.bytes()).len}')

//
// signature (ecdca)
//
signed := alice.sign_data(message.bytes())
console.print_debug('signed_bin: ${signed}')

signed_hex := alice.sign_data_hex(message.bytes())
console.print_debug('signed_hex: ${signed_hex} ${signed_hex.len}')
signed_base64 := alice.sign_data_base64(message.bytes())
console.print_debug('sign_data_base64: ${signed_base64} ${signed_base64.len}')

signed_str := alice.sign_str_base64(message)
console.print_debug('sign_str sign_str_base64:  ${signed_str} ${signed_str.len}')

signedbin := alice.sign_str(message) // binary format

assert signed_str == signed_base64

// instanciate alice with only her public key
assert alicepub.verify_data(signedbin, message.bytes())
console.print_debug('${alicepub.verify_data(signedbin, message.bytes())}')

assert alicepub.verify_str_base64(signed_base64, message)
assert alicepub.verify_str_hex(signed_hex, message)
