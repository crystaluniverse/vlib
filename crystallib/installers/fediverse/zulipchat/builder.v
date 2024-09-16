module zulipchat

import freeflowuniverse.crystallib.installers.base
import freeflowuniverse.crystallib.installers.lang.python
import freeflowuniverse.crystallib.osal
import freeflowuniverse.crystallib.develop.gittools
import freeflowuniverse.crystallib.installers.db.postgresql
import freeflowuniverse.crystallib.ui.console

const url = 'https://github.com/matrix-org/conduit'

@[params]
pub struct BuildArgs {
pub mut:
	reset bool
}

// install conduit will return true if it was already installed
pub fn build(args BuildArgs) ! {
	// make sure we install base on the node
	if osal.platform() != .ubuntu {
		return error('only support ubuntu for now')
	}
	python.install()!
	// osal.execute_stdout(cmd)!

	panic('implement')
}
