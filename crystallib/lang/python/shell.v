module python

import freeflowuniverse.crystallib.osal
import freeflowuniverse.crystallib.core.texttools

pub fn (py PythonEnv) shell(name_ string) ! {
    _ := texttools.name_fix(name_)
	cmd := '
	cd ${py.path.path}
	source bin/activate
	
	'
	osal.exec(cmd: cmd)!
}
