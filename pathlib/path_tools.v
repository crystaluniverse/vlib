module pathlib

import os
import freeflowuniverse.crystallib.texttools
import time

// check path exists
pub fn (mut path Path) exists() bool {
	// if path.cat == .unknown || path.exist == .unknown {
	// 	path.check()
	// }
	path.check()
	return path.exist == .yes
}

// rename the file or directory
pub fn (mut path Path) rename(name string) ! {
	if name.contains('/') {
		return error("should only be a name no dir inside: '${name}'")
	}
	mut dest := ''
	if path.path.contains('/') {
		before := path.path.all_before_last('/')
		dest = before + '/' + name
	} else {
		dest = name
	}
	os.mv(path.path, dest)!
	path.path = dest
	path.check()
}

// get relative path in relation to destpath
// will not resolve symlinks
pub fn (mut path Path) path_relative(destpath string) !string {
	// println(" - path relative: '$path.path' '$destpath'")
	return path_relative(destpath, path.path)
}

// recursively finds the least common ancestor of array of paths
// will always return the absolute path (relative gets changed to absolute)
pub fn find_common_ancestor(paths_ []string) string {
	for p in paths_ {
		if p.trim_space() == '' {
			panic('cannot find commone ancestors if any of items in paths is empty.\n${paths_}')
		}
	}
	paths := paths_.map(os.abs_path(os.real_path(it))) // get the real path (symlinks... resolved)
	// println(paths)
	parts := paths[0].split('/')
	mut totest_prev := '/'
	for i in 1 .. parts.len {
		totest := parts[0..i + 1].join('/')
		if paths.any(!it.starts_with(totest)) {
			return totest_prev
		}
		totest_prev = totest
	}
	return totest_prev
}

// find parent of path
pub fn (path Path) parent() !Path {
	mut p := path.absolute()
	parent := os.dir(p) // get parent directory
	if parent == '.' || parent == '/' {
		return error('no parent for path ${path.path}')
	} else if parent == '' {
		return Path{
			path: '/'
			cat: Category.dir
			exist: .yes
		}
	}
	return Path{
		path: parent
		cat: Category.dir
		exist: .yes
	}
}

// returns extension without .
pub fn (path Path) extension() string {
	return os.file_ext(path.path).trim('.')
}

// returns extension without and all lower case
pub fn (path Path) extension_lower() string {
	return path.extension().to_lower()
}

// will rewrite the path to lower_case if not the case yet
// will also remove weird chars
// if changed will return true
// the file will be moved to the new location
pub fn (mut path Path) path_normalize() !bool {
	path_original := path.path + '' // make sure is copy, needed?

	// if path.cat == .file || path.cat == .dir || !path.exists() {
	// 		return error('path $path does not exist, cannot namefix (only support file and dir)')
	// }

	if path.extension().to_lower() == 'jpeg' {
		path.path = path.path_no_ext() + '.jpg'
	}

	namenew := texttools.name_fix_keepext(path.name())
	if namenew != path.name() {
		path.path = os.join_path(os.dir(path.path), namenew)
	}

	if path.path != path_original {
		os.mv(path_original, path.path)!
		path.check()
		return true
	}
	return false
}

// walk upwards starting from path untill dir or file tofind is found
// works recursive
pub fn (path Path) parent_find(tofind string) !Path {
	if os.exists(os.join_path(path.path, tofind)) {
		return path
	}
	path2 := path.parent()!
	return path2.parent_find(tofind)
}

// delete
pub fn (mut path Path) rm() ! {
	return path.delete()
}

// delete
pub fn (mut path Path) delete() ! {
	if path.exists() {
		// println("exists: $path")
		match path.cat {
			.file, .linkfile, .linkdir {
				os.rm(path.path.replace('//', '/'))!
			}
			.dir {
				os.rmdir_all(path.path)!
			}
			.unknown {
				return error('Path cannot be unknown type')
			}
		}
		path.exist = .no
	}
}

//remove all content but if dir let the dir exist
pub fn (mut path Path) empty() ! {
	path.delete()!
	if path.cat == .dir{
		os.mkdir_all(path.path)!
		path.exist = .yes
	}
}

// write content to the file, check is file
// if the path is a link to a file then will change the content of the file represented by the link
pub fn (mut path Path) write(content string) ! {
	if !os.exists(path.path_dir()) {
		os.mkdir_all(path.path_dir())!
	}
	if path.exists() && path.cat == Category.linkfile {
		mut pathlinked := path.getlink()!
		pathlinked.write(content)!
	}
	if path.exists() && path.cat != Category.file && path.cat != Category.linkfile {
		return error('Path must be a file for ${path}')
	}
	os.write_file(path.path, content)!
}

// read content from file
pub fn (mut path Path) read() !string {
	path.check()
	match path.cat {
		.file, .linkfile {
			p := path.absolute()
			if !os.exists(p) {
				return error('File is not exist, ${p} is a wrong path')
			}
			return os.read_file(p)
		}
		else {
			return error('Path is not a file when reading. ${path.path}')
		}
	}
}

// copy file,dir is always recursive
// dest needs to be a directory or file
// need to check than only valid items can be done
// return Path of the destination file or dir
pub fn (mut path Path) copy(mut dest Path) !Path {
	path.check()
	dest.check()
	if dest.exists() {
		if !(path.cat in [.file, .dir] && dest.cat in [.file, .dir]) {
			return error('Source or Destination path is not file or directory.\n\n${path.path}-${path.cat}---${dest.path}-${dest.cat}')
		}
		if path.cat == .dir && dest.cat == .file {
			return error("Can't copy directory to file")
		}
	}
	if path.cat == .file && dest.cat == .dir {
		// In case src is a file and dest is dir, we need to join the file name to the dest file
		file_name := os.base(path.path)
		dest.path = os.join_path(dest.path, file_name)
	}

	if !os.exists(dest.path_dir()) {
		os.mkdir_all(dest.path_dir())!
	}

	os.cp_all(path.path, dest.path, true)! // Always overwite if needed

	dest.check()
	return dest
}

// recalc path between target & source
// we only support if source_ is an existing dir, links will not be supported
// a0 := pathlib.path_relative('$testpath/a/b/c', '$testpath/a/d.txt') or { panic(err) }
// assert a0 == '../../d.txt'
// a2 := pathlib.path_relative('$testpath/a/b/c', '$testpath/d.txt') or { panic(err) }
// assert a2 == '../../../d.txt'
// a8 := pathlib.path_relative('$testpath/a/b/c', '$testpath/a/b/c/d/e/e.txt') or { panic(err) }
// assert a8 == 'd/e/e.txt'
pub fn path_relative(source_ string, linkpath_ string) !string {
	mut source := os.abs_path(source_)
	mut linkpath := os.abs_path(linkpath_)
	// now both start with /

	mut p := get(source_)

	// converts file source to dir source
	if source.all_after_last('/').contains('.') {
		source = source.all_before_last('/')
		p = p.parent() or { return error("Parent of source ${source_} doesn't exist") }
	}
	p.check()

	if p.cat != .dir || !p.exists() {
		return error('Cannot do path_relative()! if source is not a dir and exists. Now:${source_}')
	}

	// println(" + source:$source compare:$linkpath")

	common := find_common_ancestor([source, linkpath])
	// println(" + common:$common")

	// if source is common, returns source
	if source.len <= common.len + 1 {
		path := linkpath_.trim_string_left(source)
		if path.starts_with('/') {
			return path[1..]
		} else {
			return path
		}
	}

	mut source_short := source[(common.len)..]
	mut linkpath_short := linkpath[(common.len)..]

	source_short = source_short.trim_string_left('/')
	linkpath_short = linkpath_short.trim_string_left('/')

	source_count := source_short.count('/')
	// link_count := linkpath_short.count('/')
	// println (" + source_short:$source_short ($source_count)")
	// println (" + linkpath_short:$linkpath_short ($link_count)")
	mut dest := ''

	if source_short == '' { // source folder is common ancestor
		dest = linkpath_short
	} else {
		go_up := ['../'].repeat(source_count + 1).join('')
		dest = '${go_up}${linkpath_short}'
	}

	dest = dest.replace('//', '/')
	return dest
}

// pub fn path_relative(source_ string, dest_ string) !string {
// 	mut source := source_.trim_right('/')
// 	mut dest := dest_.replace('//', '/').trim_right('/')
// 	// println("path relative: '$source' '$dest' ")
// 	if source !="" {
// 		if source.starts_with('/') && !dest.starts_with('/') {
// 			return error('if source starts with / then dest needs to start with / as well.\n - $source\n - $dest')
// 		}
// 		if !source.starts_with('/') && dest.starts_with('/') {
// 			return error('if source starts with / then dest needs to start with / as well\n - $source\n - $dest')
// 		}
// 	}
// 	if dest.starts_with(source) {
// 		return dest[source.len..]
// 	} else {
// 		msg := "Destination path is not in source directory: $source_ $dest_"
// 		return error(msg)
// 	}
// }

[params]
pub struct TMPWriteArgs {
pub mut:
	tmpdir string
	text   string // text to put in file
	path   string // to overrule the path where script will be stored
}

// write temp file and return path
pub fn temp_write(args_ TMPWriteArgs) !string {
	mut args := args_

	if args.path.len == 0 {
		if args.tmpdir.len == 0 {
			if 'TMPDIR' in os.environ() {
				args.tmpdir = os.environ()['TMPDIR'] or { '/tmp' }
			}
		}
		t := time.now().format_ss_milli().replace(' ', '-')
		mut tmppath := '${args.tmpdir}/execscripts/${t}.sh'
		if !os.exists('${args.tmpdir}/execscripts/') {
			os.mkdir('${args.tmpdir}/execscripts') or {
				return error('Cannot create ${args.tmpdir}/execscripts,${err}')
			}
		}
		if os.exists(tmppath) {
			for i in 1 .. 200 {
				// println(i)
				tmppath = '${args.tmpdir}/execscripts/{${t}}_${i}.sh'
				if !os.exists(tmppath) {
					break
				}
				// TODO: would be better to remove older files, e.g. if older than 1 day, remove
				if i > 99 {
					// os.rmdir_all('$tmpdir/execscripts')!
					// return temp_write(text)
					panic("should not get here, can't find temp file to write for process job.")
				}
			}
		}
		args.path = tmppath
	}
	os.write_file(args.path, args.text)!
	os.chmod(args.path, 0o777)!
	return args.path
}
