#!/usr/bin/env -S v -gc none -no-retry-compilation -cc tcc -d use_openssl -enable-globals run

import freeflowuniverse.crystallib.virt.herocontainers
import freeflowuniverse.crystallib.ui.console
import freeflowuniverse.crystallib.core.base
import freeflowuniverse.crystallib.osal
import freeflowuniverse.crystallib.installers.virt.pacman

mut installer := pacman.get()!

// installer.destroy()!
// installer.install()!

// exit(0)

// interative means will ask for login/passwd

mut engine := herocontainers.new(install: true, herocompile: false)!

engine.reset_all()!

mut builder_gorust := engine.builder_go_rust()!

// will build nodejs, python build & crystallib, hero
// mut builder_crystal := engine.builder_crystal(reset:true)!

// mut builder_web := engine.builder_heroweb(reset:true)!

builder_gorust.shell()!
