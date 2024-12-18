#!/usr/bin/env -S v -cg -n -gc none -no-retry-compilation -cc tcc -d use_openssl -enable-globals run

import freeflowuniverse.crystallib.data.encoder
import crypto.ed25519
import freeflowuniverse.crystallib.ui.console

struct AStruct {
mut:
	items   []string
	nr      int
	privkey []u8
}

_, privkey := ed25519.generate_key()!
mut a := AStruct{
	items: ['a', 'b']
	nr:    10
	// privkey: []u8{len: 5, init: u8(0xf8)}
	privkey: privkey
}

// do encoding
mut e := encoder.new()
e.add_list_string(a.items)
e.add_int(a.nr)
e.add_bytes(privkey)

console.print_debug('${e.data}')

// do decoding
mut d := encoder.decoder_new(e.data)
mut aa := AStruct{}
aa.items = d.get_list_string()
aa.nr = d.get_int()
aa.privkey = d.get_bytes()

assert a == aa

a = AStruct{
	items:   ['a', 'b']
	nr:      10
	privkey: []u8{len: 5, init: u8(0xf8)}
}

serialize_data := encoder.encode(a)!

r := encoder.decode[AStruct](serialize_data) or {
	console.print_stderr('Failed to decode, error: ${err}')
	return
}

console.print_debug('${r}')
