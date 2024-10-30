#!/usr/bin/env -S v -n -w -enable-globals run

import os
import freeflowuniverse.crystallib.osal
import freeflowuniverse.crystallib.virt.podman

// println(osal.tcp_port_test(address:"65.21.132.119",port:22,timeout:1000))


mut engine:=podman.new(reset:false)!

println(engine.bcontainers()!)

mut c:=engine.bcontainer_new(name:"test")!

c.package_install("mc,curl")!
c.hero_install(reset:true)! //build in separate container, if not done yet, then copy to this current container
c.hero_execute(heroscript:"
		!!...

		!!...


		")!

c.go_install()!  //check go exists, if not then add, check platform
c.rust_install()!
c.v_install()!
c.node_install()!

c.get_repo(reset:true, url:...)! //see gitstructure path = gs.get_repo(reset: reset, pull: pull, url: url)!  use herscript underneith to do it

c.add(...) //add content


println(c)

// println(c.inspect()!) //TODO: not working yet, please fix