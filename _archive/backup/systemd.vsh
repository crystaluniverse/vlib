#!/usr/bin/env -S v -n -w -enable-globals run

import freeflowuniverse.crystallib.osal.systemd
import freeflowuniverse.crystallib.installers.infra.zinit as zinitinstaller

zinitinstaller.install()!

mut systemdfactory := systemd.new()!
mut systemdprocess := systemdfactory.new(
	cmd:         '/usr/local/bin/zinit init'
	name:        'zinit'
	description: 'a super easy to use startup manager.'
)!

l := systemd.process_list()!
println(l)
