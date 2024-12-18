#!/usr/bin/env -S v -gc none -no-retry-compilation -cc tcc -d use_openssl -enable-globals run

import freeflowuniverse.crystallib.virt.docker

mut engine := docker.new()!

engine.reset_all()!

println(engine)
