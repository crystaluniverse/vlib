module data

import freeflowuniverse.crystallib.core.pathlib
import os

pub enum FileStatus {
	unknown
	ok
	error
}

pub enum FileType {
	file
	image
}

@[heap]
pub struct File {
pub mut:
	collection_path pathlib.Path
	name            string // received a name fix
	ext             string
	path            pathlib.Path
	pathrel         string
	state           FileStatus
	pages_linked    []&Page // pointer to pages which use this file
	ftype           FileType
	collection_name string
}

@[params]
pub struct NewFileArgs {
pub:
	name            string // received a name fix
	collection_path pathlib.Path
	pathrel         string
	path            pathlib.Path
	collection_name string       @[required]
}

pub fn new_file(args NewFileArgs) !File {
	mut f := File{
		name: args.name
		path: args.path
		collection_path: args.collection_path
		pathrel: args.pathrel
		collection_name: args.collection_name
	}

	f.init()!

	return f
}

pub fn (file File) file_name() string {
	return '${file.name}.${file.ext}'
}

// parses file name, extension and relative path
pub fn (mut file File) init() ! {
	if file.path.is_image() {
		file.ftype = .image
	}

	file.name = file.path.name_fix_no_ext()
	file.ext = file.path.path.all_after_last('.').to_lower()

	path_rel := file.path.path_relative(file.collection_path.path) or {
		return error('cannot get relative path.\n${err}')
	}

	file.pathrel = path_rel.trim('/')
}

fn (mut file File) delete() ! {
	file.path.delete()!
}

// TODO: what if this is moved to another collection, or outside the scope of the tree?
fn (mut file File) mv(dest string) ! {
	mut destination := pathlib.get_dir(path: dest)! // will fail if dir doesn't exist

	os.mv(file.path.path, destination.path) or {
		return error('could not move ${file.path.path} to ${destination.path} .\n${err}\n${file}')
	}

	// need to get relative path in, in relation to collection
	file.pathrel = destination.path_relative(file.collection_path.path)!
	file.path = destination
}

fn (mut file File) exists() !bool {
	return file.path.exists()
}

pub fn (mut file File) copy(dest string) ! {
	mut dest2 := pathlib.get(dest)
	file.path.copy(dest: dest2.path, rsync: false) or {
		return error('Could not copy file: ${file.path.path} to ${dest} .\n${err}\n${file}')
	}
}
