module pathlib

import freeflowuniverse.crystallib.core.texttools
import os

@[params]
pub struct SubGetParams {
pub mut:
	name          string
	name_fix_find bool // means we will also find if name is same as the name_fix
	name_fix      bool // if file found and name fix was different than file on filesystem, will rename
	dir_ensure    bool // if dir_ensure on will fail if its not a dir
	file_ensure   bool // if file_ensure on will fail if its not a dir
}

// An internal struct for representing failed jobs.
pub struct SubGetError {
	Error
pub mut:
	msg        string
	path       string
	error_type JobErrorType
}

pub enum JobErrorType {
	error
	nodir
	notfound
	wrongtype // asked for dir or file, but found other type
	islink
}

pub fn (err SubGetError) msg() string {
	mut msg := ''
	if err.error_type == .nodir {
		msg = 'could not get sub of path, because was no dir'
	}
	if err.error_type == .notfound {
		msg = 'could not find'
	}
	if err.error_type == .wrongtype {
		msg = 'asked for a dir or a file, but this did not correspond on filesystem.'
	}
	if err.error_type == .islink {
		msg = 'we found a link, this is not supported for now.'
	}
	return "Dir Get Error for path:'${err.path}' -- (${err.code()}) failed with error: ${msg}"
}

pub fn (err SubGetError) code() int {
	return int(err.error_type)
}

// will get dir or file underneith a dir .
// e.g. mypath.sub_get(name:"mysub_file.md",name_fix_find:true,name_fix:true)! .
// this will find Mysubfile.md as well as mysub_File.md and rename to mysub_file.md and open .
// params: .
//		- name .
// 		- name_fix_find bool :means we will also find if name is same as the name_fix.
// 		- name_fix bool	   	 :if file found and name fix was different than file on filesystem, will rename .
// 		- dir_ensure bool	 :if dir_ensure on will fail if its not a dir .
// 		- file_ensure bool   :if file_ensure on will fail if its not a dir .
// .
// will return SubGetError if error .
//
// returns a path
pub fn (mut path Path) sub_get(args_ SubGetParams) !Path {
	mut args := args_
	if path.cat != Category.dir {
		return SubGetError{
			error_type: .nodir
			path:       path.path
		}
	}
	if args.name == '' {
		return error('name cannot be empty')
	}
	if args.name_fix {
		args.name_fix_find = true
	}
	if args.name_fix_find {
		args.name = texttools.name_fix(args.name)
	}
	items := os.ls(path.path) or { []string{} }
	for item in items {
		mut itemfix := item
		if args.name_fix_find {
			itemfix = texttools.name_fix(item)
		}
		if itemfix == args.name {
			// we found what we were looking for
			mut p := get(os.join_path(path.path, item)) // get the path
			if args.dir_ensure {
				if !p.is_dir() {
					return SubGetError{
						error_type: .wrongtype
						path:       path.path
					}
				}
			}
			if args.file_ensure {
				if !p.is_file() {
					return SubGetError{
						error_type: .wrongtype
						path:       path.path
					}
				}
			}
			if args.name_fix {
				p.path_normalize() or {
					return SubGetError{
						msg:  'could not normalize path: ${err}'
						path: path.path
					}
				}
			}
			return p
		}
	}
	return SubGetError{
		error_type: .notfound
		path:       path.path
	}
}

// will check if dir exists
// params: .
//		- name
// 		- name_fix_find bool :means we will also find if name is same as the name_fix .
// 		- name_fix bool	   :if file found and name fix was different than file on filesystem, will rename .
// 		- dir_ensure bool	   :if dir_ensure on will fail if its not a dir .
// 		- file_ensure bool   :if file_ensure on will fail if its not a dir .
//
pub fn (mut path Path) sub_exists(args_ SubGetParams) !bool {
	_ := path.sub_get() or {
		if err.code() == 2 {
			return false // means did not exist
		}
		return err
	}
	return true
	// TODO: need to write test for sub_get and sub_exists
}

//////////////FILE

// find file underneith dir path, if exists return True
pub fn (path Path) file_exists(tofind string) bool {
	if path.cat != Category.dir {
		return false
	}
	if os.exists('${path.path}/${tofind}') {
		if os.is_file('${path.path}/${tofind}') {
			return true
		}
	}
	return false
}

// is case insensitive
pub fn (mut path Path) file_exists_ignorecase(tofind string) bool {
	return path.file_name_get_ignorecase(tofind) != ''
}

fn (mut path Path) file_name_get_ignorecase(tofind string) string {
	if path.cat != Category.dir {
		return ''
	}
	files := os.ls(path.path) or { []string{} }
	for item in files {
		if tofind.to_lower() == item.to_lower() {
			file_path := os.join_path(path.path, item)
			if os.is_file(file_path) {
				return item
			}
		}
	}
	return ''
}

// find file underneith path, if exists return as Path, otherwise error .
pub fn (mut path Path) file_get(tofind string) !Path {
	if path.cat != Category.dir || !(path.exists()) {
		return error('File get for ${tofind} in ${path.path}: is not a dir or dir does not exist.')
	}
	if path.file_exists(tofind) {
		file_path := os.join_path(path.path, tofind)
		return Path{
			path:  file_path
			cat:   Category.file
			exist: .yes
		}
	}
	return error("Could not find file '${tofind}' in ${path.path}.")
}

pub fn (mut path Path) file_get_ignorecase(tofind string) !Path {
	if path.cat != Category.dir || !(path.exists()) {
		return error('File get ignore case for ${tofind} in ${path.path}: is not a dir or dir does not exist.')
	}
	filename := path.file_name_get_ignorecase(tofind)
	if filename == '' {
		return error("Could not find file (igore case) '${tofind}' in ${path.path}.")
	}
	file_path := os.join_path(path.path, filename)
	return Path{
		path:  file_path
		cat:   Category.file
		exist: .yes
	}
}

// get file, if not exist make new one
pub fn (mut path Path) file_get_new(tofind string) !Path {
	if path.cat != Category.dir || !(path.exists()) {
		return error('File get new for ${tofind} in ${path.path}: is not a dir or dir does not exist.')
	}
	mut p := path.file_get(tofind) or {
		return get_file(path: '${path.path}/${tofind}', create: true)!
	}
	return p
}

//////////////LINK

// find link underneith path, if exists return True
// is case insensitive
pub fn (mut path Path) link_exists(tofind string) bool {
	if path.cat != Category.dir {
		return false
	}
	// TODO: need to check, if this is correct, make test
	if os.exists('${path.path}/${tofind}') {
		if os.is_link('${path.path}/${tofind}') {
			return true
		}
	}
	return false
}

// find link underneith path, if exists return True
// is case insensitive
pub fn (mut path Path) link_exists_ignorecase(tofind string) bool {
	if path.cat != Category.dir {
		return false
	}
	files := os.ls(path.path) or { []string{} }
	if tofind.to_lower() in files.map(it.to_lower()) {
		file_path := os.join_path(path.path.to_lower(), tofind.to_lower())
		if os.is_link(file_path) {
			return true
		}
	}
	return false
}

// find link underneith path, return as Path, can only be one
// tofind is part of link name
pub fn (mut path Path) link_get(tofind string) !Path {
	if path.cat != Category.dir || !(path.exists()) {
		return error('Link get for ${tofind} in ${path.path}: is not a dir or dir does not exist.')
	}
	if path.link_exists(tofind) {
		file_path := os.join_path(path.path, tofind)
		return Path{
			path:  file_path
			cat:   Category.linkfile
			exist: .yes
		}
	}
	return error("Could not find link '${tofind}' in ${path.path}.")
}

///////// DIR

// find dir underneith path, if exists return True
pub fn (mut path Path) dir_exists(tofind string) bool {
	if path.cat != Category.dir {
		return false
	}
	if os.exists('${path.path}/${tofind}') {
		if os.is_dir('${path.path}/${tofind}') {
			return true
		}
	}
	return false
}

// find dir underneith path, return as Path
pub fn (mut path Path) dir_get(tofind string) !Path {
	if path.cat != Category.dir || !(path.exists()) {
		return error('is not a dir or dir does not exist: ${path.path}')
	}
	if path.dir_exists(tofind) {
		dir_path := os.join_path(path.path, tofind)
		return Path{
			path:  dir_path
			cat:   Category.dir
			exist: .yes
		}
	}
	return error('${tofind} is not in ${path.path}')
}

// get file, if not exist make new one
pub fn (mut path Path) dir_get_new(tofind string) !Path {
	if path.cat != Category.dir || !(path.exists()) {
		return error('is not a dir or dir does not exist: ${path.path}')
	}
	mut p := path.dir_get(tofind) or {
		return get_dir(path: '${path.path}/${tofind}', create: true)!
	}
	return p
}
