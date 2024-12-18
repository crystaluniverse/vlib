#!/usr/bin/env -S v -gc none -no-retry-compilation -cc tcc -d use_openssl -enable-globals run

import freeflowuniverse.crystallib.threefold.grid as tfgrid

mut cl := tfgrid.get('my_config')!
mut cfg := cl.config()!

println(cl.instance)
cfg = cl.config()!
println(cfg)

if cfg.mnemonics == '' {
	// will ask questions if not filled in yet
	cl.config_interactive()!
}

println(cl.instance)
cfg = cl.config()!
println(cfg)

// cl.instance = 'new_name'
cfg.mnemonics = ''
cfg.network = 'qa'
cl.config_save()!

println(cl.instance)
cfg = cl.config()!
println(cfg)

cl = tfgrid.get('empty_config')!

println(cl.instance)
cfg = cl.config()!
println(cfg)

// TO CONFIGURE NEW
// cl.config_delete()!
