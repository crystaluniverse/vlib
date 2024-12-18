#!/usr/bin/env -S v -gc none -no-retry-compilation -cc tcc -d use_openssl -enable-globals run

import freeflowuniverse.crystallib.clients.b2

mut cl := b2.get(instance: 'despiegktest')!

mut cfg := cl.config()!
// TO CONFIGURE NEW
// cl.config_delete()!

cfg.keyid = 'cd8f15212206'
cfg.appkey = ''
cfg.bucketname = 'despiegktest'
cl.config_save()!

if cfg.appkey == '' {
	cl.config_interactive()!
}

println(cfg)

items := cl.list_buckets()!
println(items)

cl.upload(src: '/Users/despiegk1/hero/bin/hero')!
