#!/usr/bin/env -S v -gc none -no-retry-compilation -cc tcc -d use_openssl -enable-globals run

import freeflowuniverse.crystallib.installers.infra.zinit as zinitinstaller
import freeflowuniverse.crystallib.sysadmin.startupmanager

mut z := zinitinstaller.get()!
z.destroy()!
z.install()!

println('zinit installed')

cmd := '/usr/local/bin/zinit init'
name := 'zinit'

mut sm := startupmanager.get()!
println(sm.list()!)
sm.new(
	name:  name
	cmd:   cmd
	start: false
)!

println(sm.list()!)
assert sm.exists(name)!

sm.delete(name)!
