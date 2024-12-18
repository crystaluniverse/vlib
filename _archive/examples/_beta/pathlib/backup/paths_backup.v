module main

import freeflowuniverse.crystallib.core.pathlib
import os

const testpath = os.dir(@FILE) + '/test_path/test_parent/readme.md'

const testdir = os.dir(@FILE) + '/test_path'

fn do() ! {
	mut p := pathlib.get_file(path: testpath)!

	// TODO: implement, call the vault methods
}

fn main() {
	do() or { panic(err) }
}
