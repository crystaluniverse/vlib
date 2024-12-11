module mdbook

import freeflowuniverse.crystallib.develop.vscode
import freeflowuniverse.crystallib.osal
import freeflowuniverse.crystallib.core.base
import os

pub fn book_open(name string) ! {
	mut c := base.context()!
	mut r := c.redis()!
	mut path_publish := r.get('mdbook:${name}:publish')!
	path_publish = path_publish.replace('~', os.home_dir())
	if path_publish.len == 0 {
		return error("can't find book: ${name}, was it generated before?")
	}
	if !os.exists(path_publish) {
		return error("can't find generated book in ${path_publish}, was it generated properly.")
	}
	cmd3 := "open '${path_publish}/index.html'"
	// console.print_debug(cmd3)
	osal.exec(cmd: cmd3)!
}

pub fn book_edit(name string) ! {
	mut c := base.context()!
	mut r := c.redis()!
	path_build := r.get('mdbook:${name}:build')!
	if path_build.len == 0 {
		return error("can't find book: ${name}, was it generated before?")
	}
	edit_path := '${path_build}/edit'.replace('~', os.home_dir())
	if !os.exists(edit_path) {
		return error("can't find book edit path in ${edit_path}, was it generated properly.")
	}
	vscode_helper := vscode.new(edit_path)
	vscode_helper.open()!
}
