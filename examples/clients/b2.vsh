#!/usr/bin/env -S v -gc none -no-retry-compilation -cc tcc -d use_openssl -enable-globals run
import freeflowuniverse.crystallib.clients.stellar

mut cl:=stellar.get(instance:"test")!

// cl.config_delete()!

mut cfg:=cl.config()!
if cfg.secret==""{
	// will ask questions if not filled in yet
	cl.config_interactive()!
}
println(cfg)

//will now change programatically
cfg.description="this is my main key"
//will now save the config
cl.config_save()!

//we will now see how the description has been overwritten
println(cfg)

