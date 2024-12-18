module main

import crypto.sha256
import freeflowuniverse.crystallib.algo.secp256k1

fn main() {
	message := 'Hello world, this is my awesome message'

	println('Coucou')
	println(sha256.hexhash(message))

	secp256k1.init()
}
