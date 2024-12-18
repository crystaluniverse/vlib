#!/usr/bin/env -S v -gc none -no-retry-compilation -cc tcc -d use_openssl -enable-globals run

import freeflowuniverse.crystallib.core.pathlib
import freeflowuniverse.crystallib.data.paramsparser
import os

const testpath3 = os.dir(@FILE) + '/../..'

// if we return True then it means the dir or file is processed
fn filter_1(mut path pathlib.Path, mut params paramsparser.Params) !bool {
	if path.is_dir() {
		if path.path.ends_with('.dSYM') {
			return false
		}
		return true
	}
	if path.path.ends_with('.vsh') {
		return true
	}
	return false
}

fn executor_1(mut patho pathlib.Path, mut params paramsparser.Params) !paramsparser.Params {
	if patho.is_file() {
		// println( " - exec: $patho.path" )
		params.add(patho.path)!
	}
	return params
}

mut p := pathlib.get_dir(path: testpath3)!
mut params := paramsparser.Params{}
mut params2 := p.scan(mut params, [filter_1], [executor_1])!
println(params2)
assert params2.args.len == 4
