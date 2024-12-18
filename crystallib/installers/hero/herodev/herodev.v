module herodev

import freeflowuniverse.crystallib.installers.web.mdbook
import freeflowuniverse.crystallib.installers.web.zola
import freeflowuniverse.crystallib.installers.sysadmintools.daguserver

@[params]
pub struct InstallArgs {
pub mut:
	reset bool
}

// install mdbook will return true if it was already installed
pub fn install(args_ InstallArgs) ! {
	mut args := args_

	mdbook.install(reset: args.reset)!
	mut i := zola.get()!
	i.install()!
	mut dagu := daguserver.get()!
	dagu.install(reset: args.reset)!
}
