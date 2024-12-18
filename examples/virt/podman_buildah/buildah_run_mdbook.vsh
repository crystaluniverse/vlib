#!/usr/bin/env -S v -gc none -no-retry-compilation -cc tcc -d use_openssl -enable-globals run

import os
import flag
import freeflowuniverse.crystallib.virt.herocontainers
import freeflowuniverse.crystallib.ui.console
import freeflowuniverse.crystallib.core.base
// import freeflowuniverse.crystallib.builder
import time

mut fp := flag.new_flag_parser(os.args)
fp.application('buildah mdbook example')
fp.limit_free_args(0, 0)! // comment this, if you expect arbitrary texts after the options
fp.skip_executable()
url := fp.string_opt('url', `u`, 'mdbook heroscript url')!

additional_args := fp.finalize() or {
	eprintln(err)
	println(fp.usage())
	return
}

mut pm := herocontainers.new(herocompile: true, install: false)!

mut mybuildcontainer := pm.builder_get('builder_heroweb')!

// //bash & python can be executed directly in build container

// //any of the herocommands can be executed like this
mybuildcontainer.run(cmd: 'installers -n heroweb', runtime: .herocmd)!

mybuildcontainer.run(cmd: 'hero mdbook -u ${url} -o', runtime: .bash)!
