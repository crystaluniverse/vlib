#!/usr/bin/env -S v -gc none -cg -no-retry-compilation -cc tcc -d use_openssl -enable-globals run

import freeflowuniverse.crystallib.osal.systemd

mut systemdfactory := systemd.new()!
// mut systemdprocess := systemdfactory.new(
// 	cmd: '/usr/local/bin/zinit init'
// 	name: 'zinit'
// 	description: 'a super easy to use startup manager.'
// )!
l := systemd.process_list()!
println(l)
systemdfactory.destroy('zinit')!
