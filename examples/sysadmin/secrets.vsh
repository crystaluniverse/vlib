#!/usr/bin/env -S v -gc none -no-retry-compilation -cc tcc -d use_openssl -enable-globals run

import freeflowuniverse.crystallib.crypt.secrets

mut box := secrets.get()!
box.delete('myapp.something')!

// will generate a key (hex of 24 chars) if it doesn't exist yet .
mysecret := box.secret(key: 'myapp.something.a', reset: false)!
println(mysecret)

mut test_string := 'This is a test string with {ss} and {MYAPP.SOMETHING.A} and {ABC123}.'

test_string1 := box.replace(txt: test_string)!

println(test_string1)

test_string2 := box.replace(
	txt:      test_string
	defaults: {
		'MYAPP.SOMETHING.A': secrets.DefaultSecretArgs{
			secret: 'AAA'
		}
	}
)!

println(test_string2)
