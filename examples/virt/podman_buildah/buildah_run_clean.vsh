#!/usr/bin/env -S v -gc none -no-retry-compilation -cc tcc -d use_openssl -enable-globals run

import freeflowuniverse.crystallib.virt.herocontainers
import freeflowuniverse.crystallib.ui.console
import freeflowuniverse.crystallib.core.base
// import freeflowuniverse.crystallib.builder
import time
import os

mut pm := herocontainers.new(herocompile: false)!

mut b := pm.builder_new()!

println(b)

// mut mybuildcontainer := pm.builder_get("builderv")!

// mybuildcontainer.clean()!

// mybuildcontainer.commit('localhost/buildersmall')!

b.shell()!
