module codemodel

import freeflowuniverse.crystallib.core.pathlib
import os

pub struct Module {
pub mut:
	name       string
	files      []CodeFile
	misc_files []File
	// model   CodeFile
	// methods CodeFile
}

pub fn (mod Module) write_v(path string, options WriteOptions) ! {
	mut module_dir := pathlib.get_dir(
		path:  '${path}/${mod.name}'
		empty: options.overwrite
	)!

	if !options.overwrite && module_dir.exists() {
		return
	}

	for file in mod.files {
		file.write_v(module_dir.path, options)!
	}
	for file in mod.misc_files {
		file.write(module_dir.path)!
	}

	if options.format {
		os.execute('v fmt -w ${module_dir.path}')
	}
	if options.document {
		os.execute('v doc -f html -o ${module_dir.path}/docs ${module_dir.path}')
	}
}
