module heroweb

// import freeflowuniverse.crystallib.ui.console
// import freeflowuniverse.crystallib.osal
// import freeflowuniverse.crystallib.core.texttools
import freeflowuniverse.crystallib.installers.web.mdbook
import freeflowuniverse.crystallib.installers.web.zola
// import freeflowuniverse.crystallib.installers.web.caddy
import freeflowuniverse.crystallib.installers.sysadmintools.daguserver
import freeflowuniverse.crystallib.installers.net.mycelium

@[params]
pub struct InstallArgs {
pub mut:
	reset bool
}

// // install mdbook will return true if it was already installed
// pub fn install(args_ InstallArgs) ! {
// 	mut args := args_

// 	mdbook.install(reset: args.reset)!
// 	zola.install(reset: args.reset)!
// 	mut dagu := daguserver.get()!
// 	dagu.install()!
// 	caddy.install(reset: args.reset)!
// 	mycelium.install(reset: args.reset)!
// }
