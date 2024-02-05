#!/usr/bin/env v -w -enable-globals run

import freeflowuniverse.crystallib.data.fskvs
import freeflowuniverse.crystallib.installers.db.redis as redis_installer
import freeflowuniverse.crystallib.installers.infra.coredns as coredns_installer
import freeflowuniverse.crystallib.installers.sysadmintools.dagu as dagu_installer
import freeflowuniverse.crystallib.installers.net.mycelium as mycelium_installer
import freeflowuniverse.crystallib.osal.screen
// import freeflowuniverse.crystallib.osal

fskvs.dbcontext_init_default()!

// redis_installer.new()!
// dagu_installer.install(passwd:"1234",secret:"1234",restart:true)!
// coredns_installer.install()!
// mycelium_installer.install()!
// mycelium_installer.restart()!

// mut screens:=screen.new()!
// println(screens)


// dagu_installer.check(secret:"1234")!