module zola

import freeflowuniverse.crystallib.osal
import freeflowuniverse.crystallib.core.base
import os

pub fn site_open(name string) ! {
	mut c := base.context()!
	mut r := c.redis()!
	mut path_publish := r.get('zola:${name}:publish')!
	path_publish = path_publish.replace('~', os.home_dir())
	if path_publish.len == 0 {
		return error("can't find site: ${name}, was it generated before?")
	}
	if !os.exists(path_publish) {
		return error("can't find generated site in ${path_publish}, was it generated properly.")
	}
	cmd3 := "open '${path_publish}/index.html'"
	osal.exec(cmd: cmd3)!
}
