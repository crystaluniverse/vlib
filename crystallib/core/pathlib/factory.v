module pathlib

import os

// gets Path object, will check if it exists, is dir_file, ...
pub fn get(path_ string) Path {
	mut p2 := get_no_check(path_)
	p2.check()
	return p2
}

pub fn get_no_check(path_ string) Path {
	mut path := path_
	if path.contains('~') {
		path = path.replace('~', os.home_dir())
	}
	if path.contains('file://') {
		path = path.trim_string_left('file://')
	}
	mut p2 := Path{
		path: path
	}
	if p2.path.contains('..') {
		p2.path = p2.absolute()
	}
	return p2
}

@[params]
pub struct GetArgs {
pub mut:
	path   string
	create bool
	check  bool = true // means will check the dir, link or file exists
	empty  bool // will empty the dir or the file
	delete bool
}

// get a directory, or needs to be created
// if the dir doesn't exist and is not created, then there will be an error
pub fn get_dir(args_ GetArgs) !Path {
	mut args := args_
	if args.empty {
		args.create = true
	}
	if args.create {
		args.check = true
	}
	mut p2 := get_no_check(args.path)
	if args.check {
		p2.check()
		p2.absolute()
		if p2.exist == .no {
			if args.create {
				os.mkdir_all(p2.absolute()) or { return error('cannot create path ${p2}, ${err}') } // Make sure that all the needed paths created		
				p2.check()
			}
			return p2
		}
		if !p2.is_dir() {
			return error('Path ${args.path} is not a dir.')
		}
		if args.empty {
			p2.empty()!
		}
		if args.delete {
			p2.delete()!
		}
	}
	return p2
}

pub fn get_file(args_ GetArgs) !Path {
	mut args := args_
	if args.empty {
		args.create = true
	}
	if args.create {
		args.check = true
	}
	mut p2 := get_no_check(args.path)
	if args.check {
		p2.check()
		if args.create {
			mut parent_ := p2.parent()!
			parent_.check()
			if parent_.exist == .no {
				os.mkdir_all(parent_.path) or { return error('cannot create path:${args.path}') }
			}
			if p2.exist == .no || args.empty {
				os.write_file(args.path, '') or {
					return error('cannot create empty file:${args.path} ${err}')
				}
				p2.check()
			}
		}
		if p2.exists() && !p2.is_file() {
			return error('Path ${args.path} is not a file.')
		}
		if args.delete {
			p2.delete()!
		}
	}
	return p2
}

pub fn get_link(args_ GetArgs) !Path {
	mut args := args_
	if args.create {
		return error("can't create link out of nothing")
	}
	mut p2 := get_no_check(args.path)
	if args.check {
		p2.check()
		if !p2.exists() {
			p2.cat = Category.linkfile
			return p2
		}
		if !p2.is_link() {
			return error('Path ${args.path} is not a link.')
		}
		if args.delete {
			p2.delete()!
		}
		if args.empty {
			mut p3 := p2.getlink()!
			p3.empty()!
		}
	}
	return p2
}

// gets working directory
pub fn get_wd() Path {
	return get_dir(path: os.getwd()) or { panic('This should never happen') }
}
