module nodejs

import freeflowuniverse.crystallib.osal
// import freeflowuniverse.crystallib.ui.console
// import freeflowuniverse.crystallib.core.texttools
// import freeflowuniverse.crystallib.installers.base

@[params]
pub struct InstallArgs {
pub mut:
	reset bool
}

pub fn install(args_ InstallArgs) ! {
    _ := args_
	pl := osal.platform()
	if pl == .arch {
		osal.package_install('npm')!
	} else {
		return error('only support arch for now')
	}
}
