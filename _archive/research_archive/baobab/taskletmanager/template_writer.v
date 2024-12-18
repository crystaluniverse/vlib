module taskletmanager

import freeflowuniverse.crystallib.core.pathlib

fn (mut tm TaskletManager) generate_code() ! {
	mut path := tm.path.file_get_new('selector.v')!
	c := $tmpl('templates/selector.v')
	path.write(c)!
}
