module calendar

import freeflowuniverse.crystallib.core.pathlib
import os

pub struct Calendar {}

pub fn (calendar Calendar) html() string {
	dollar := '$'
	mut style_file := pathlib.get_file(path: '${os.dir(@FILE)}/templates/index.css') or {
		panic(err)
	}
	style := style_file.read() or { panic(err) }

	mut script_file := pathlib.get_file(path: '${os.dir(@FILE)}/templates/index.js') or {
		panic(err)
	}
	script := script_file.read() or { panic(err) }
	return $tmpl('./templates/calendar.html')
}
