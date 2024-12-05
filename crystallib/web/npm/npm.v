module npm

import freeflowuniverse.crystallib.core.pathlib
import freeflowuniverse.crystallib.osal
import os

pub fn new_project(path string) !Project {
	dir := pathlib.get_dir(path: path)!
	return Project{
		directory: dir
		build_dir: pathlib.get_dir(path: '${dir.path}/build')!
	}
}

pub struct Project {
pub mut:
	directory pathlib.Path
	build_dir pathlib.Path
}

pub fn (p Project) install() {
	os.execute('cd ${p.directory.path} && npm install')
}

pub fn (mut p Project) build() ! {
	cmd := "cd /Users/timurgordon/code/github/open-rpc/playground

export NODE_OPTIONS='--openssl-legacy-provider'

npm run build"
	os.execute(cmd)
}

pub fn (mut p Project) export(dest pathlib.Path) ! {
	p.build_dir.copy(dest: dest.path)!
}
