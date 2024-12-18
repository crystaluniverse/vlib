#!/usr/bin/env -S v -gc none -no-retry-compilation -cc tcc -d use_openssl -enable-globals run

import freeflowuniverse.crystallib.ui.console
import encoding.hex
import crypto.sha256
import freeflowuniverse.crystallib.crypt.secp256k1

//
// signature (schnorr)
//
schnorr_signed := alice.schnorr_sign_data(message.bytes())
console.print_debug('${schnorr_signed}')

schnorr_signed_hex := alice.schnorr_sign_data_hex(message.bytes())
console.print_debug('${schnorr_signed_hex}')

schnorr_signed_str := alice.schnorr_sign_str(message)
console.print_debug('${schnorr_signed_str}')

schnorr_signed_str_hex := alice.schnorr_sign_str_hex(message)
console.print_debug('${schnorr_signed_str_hex}')

console.print_debug('${alicepub.schnorr_verify_data(schnorr_signed, message.bytes())}')
console.print_debug('${alicepub.schnorr_verify_str(schnorr_signed_str, message)}')

// should fails, it's not the right signature method (ecdsa / schnorr)
console.print_debug('${alicepub.verify_data(schnorr_signed, message.bytes())}')
console.print_debug('${alicepub.verify_str(schnorr_signed_str, message)}')
