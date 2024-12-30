module codemodel

import freeflowuniverse.crystallib.core.pathlib

pub interface IFile {
	write(string, WriteOptions) !
}

pub struct File {
pub mut:
	name      string
	extension string
	content   string
}

pub fn (f File) write(path string, params WriteOptions) ! {
	mut fd_file := pathlib.get_file(path: '${path}/${f.name}.${f.extension}')!
	fd_file.write(f.content)!
}