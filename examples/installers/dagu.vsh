#!/usr/bin/env -S v -gc none -no-retry-compilation -cc tcc -d use_openssl -enable-globals run

import freeflowuniverse.crystallib.installers.sysadmintools.daguserver

mut ds := daguserver.get()!

println(ds)
