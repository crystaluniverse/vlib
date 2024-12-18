#!/usr/bin/env -S v -w -cg -gc none -no-retry-compilation -cc tcc -d use_openssl -enable-globals run

import freeflowuniverse.crystallib.crypt.aes_symmetric { decrypt, encrypt }
import freeflowuniverse.crystallib.ui.console

msg := 'my message'.bytes()
console.print_debug('${msg}')

secret := '1234'
encrypted := encrypt(msg, secret)
console.print_debug('${encrypted}')

decrypted := decrypt(encrypted, secret)
console.print_debug('${decrypted}')

assert decrypted == msg
