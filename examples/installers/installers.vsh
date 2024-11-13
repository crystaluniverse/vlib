#!/usr/bin/env -S v -gc none -no-retry-compilation -cc tcc -d use_openssl -enable-globals run

import freeflowuniverse.crystallib.data.dbfs
import freeflowuniverse.crystallib.installers.lang.vlang
import freeflowuniverse.crystallib.installers.db.redis as redis_installer
import freeflowuniverse.crystallib.installers.infra.coredns as coredns_installer
import freeflowuniverse.crystallib.installers.sysadmintools.daguserver as dagu_installer
import freeflowuniverse.crystallib.installers.sysadmintools.b2 as b2_installer
import freeflowuniverse.crystallib.installers.net.mycelium as mycelium_installer
import freeflowuniverse.crystallib.osal.screen
// import freeflowuniverse.crystallib.osal

// redis_installer.new()!
// dagu_installer.install(passwd:"1234",secret:"1234",restart:true)!

// coredns_installer.install()!
mycelium_installer.install()!
// mycelium_installer.restart()!

// mut screens:=screen.new()!
// println(screens)


// dagu_installer.check(secret:"1234")!


vlang.v_analyzer_install()!

// b2_installer.install()!