module generic

import os
import freeflowuniverse.crystallib.core.pathlib
import freeflowuniverse.crystallib.ui.console

// scan over a set of directories call the play where
pub fn scan(args_ GeneratorArgs) ! {
	mut args := args_
	console.print_header('Scan for generation of code for path: ${args.path} (reset:${args.force}, force:${args.force})')

	if args.path.len == 0 {
		args.path = os.getwd()
	}

	// now walk over all directories, find .heroscript
	mut pathroot := pathlib.get_dir(path: args.path, create: false)!
	mut plist := pathroot.list(
		recursive:     true
		ignoredefault: false
		regex:         ['.heroscript']
	)!

	for mut p in plist.paths {
		pparent := p.parent()!
		args.path = pparent.path
		// println("-- ${pparent}")
		generate(args)!
	}
}
