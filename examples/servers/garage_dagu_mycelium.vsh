#!/usr/bin/env -S v -gc none -no-retry-compilation -cc tcc -d use_openssl -enable-globals run

import freeflowuniverse.crystallib.installers.sysadmintools.garage_s3
import freeflowuniverse.crystallib.installers.sysadmintools.rfs
import freeflowuniverse.crystallib.installers.sysadmintools.daguserver
import freeflowuniverse.crystallib.installers.net.mycelium
import freeflowuniverse.crystallib.installers.db.zdb
import freeflowuniverse.crystallib.installers.db.redis

redis.install(start: true)!

zdb.install(start: true)!

mycelium.install()!

rfs.install()!

dagu.install(start: true)!

garage_s3.install(start: true)!
