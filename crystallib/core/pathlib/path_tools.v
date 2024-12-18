module pathlib

import os
import freeflowuniverse.crystallib.core.texttools
import time
import crypto.md5
import rand
import freeflowuniverse.crystallib.ui.console

// check path exists
pub fn (mut path Path) exists() bool {
	// if path.cat == .unknown || path.exist == .unknown {
	// 	path.check()
	// }
	path.check()
	return path.exist == .yes
}

// case insentive check on paths
pub fn path_equal(a_ string, b_ string) bool {
	a := os.abs_path(a_.replace('~', os.home_dir())).to_lower()
	b := os.abs_path(b_.replace('~', os.home_dir())).to_lower()
	return a == b
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

// TODO: make part of pathlib of Path

// uncompress to specified directory .
// if copy then will keep the original
pub fn (mut path Path) expand(dest string) !Path {
	$if debug {
		console.print_header('expand ${path.path}')
	}
	if dest.len < 4 {
		return error("Path dest needs to be mentioned and +4 char. Now '${dest}'")
	}
	filext := os.file_ext(path.name()).to_lower()

	// the ones who return a filepath
	if filext == '.xz' {
		cmd := 'xz --decompress ${path.path} --stdout > ${dest}'
		if os.is_file(dest) {
			os.rm(dest)!
		}
		os.mkdir_all(dest)!
		os.rmdir(dest)!

		res := os.execute(cmd)
		// console.print_debug(res)
		if res.exit_code > 0 {
			// console.print_debug(cmd)
			return error('Could not expand xz.\n${res}')
		}
		return get_file(path: dest, create: false)!
	}

	mut desto := get_dir(path: dest, create: true)!
	desto.empty()!

	if path.name().to_lower().ends_with('.tar.gz') || path.name().to_lower().ends_with('.tgz') {
		cmd := 'tar -xzvf ${path.path} -C ${desto.path}'
		console.print_debug(cmd)
		res := os.execute(cmd)
		if res.exit_code > 0 {
			return error('Could not expand.\n${res}')
		}
	} else if path.name().to_lower().ends_with('.zip') {
		cmd := 'unzip  ${path.path} -d ${dest}'
		// console.print_debug(cmd)
		res := os.execute(cmd)
		// console.print_debug(res)
		if res.exit_code > 0 {
			return error('Could not expand zip.\n${res}')
		}
	} else if path.name().to_lower().ends_with('.bz2') {
		cmd := '
			bunzip2 -f -k ${path.path}
			' // console.print_debug(cmd)

		res := os.execute(cmd)
		if res.exit_code > 0 {
			return error('Could not expand bz2.\n${res.output}')
		}
		dest_tmp := path.path.all_before_last('.bz2')
		desto.delete()!
		mut desto2 := get_file(path: dest, create: false)!
		os.mv(dest_tmp, desto2.path)!
		return desto2
	} else {
		panic('expand not implemented yet for : ${path.path}')
	}
	return desto
}

// chown changes the owner and group attributes of path to owner and group.
pub fn (mut path Path) chown(owner int, group int) ! {
	os.chown(path.path, owner, group)!
}

// chmod change file access attributes of path to mode.
// Octals like 0o600 can be used.
pub fn (mut path Path) chmod(mode int) ! {
	os.chmod(path.path, mode)!
}

// get relative path in relation to destpath .
// will not resolve symlinks
pub fn (path Path) path_relative(destpath string) !string {
	// console.print_header(' path relative: '$path.path' '$destpath'")
	return path_relative(destpath, path.path)
}

// recursively finds the least common ancestor of array of paths .
// will always return the absolute path (relative gets changed to absolute).
pub fn find_common_ancestor(paths_ []string) string {
	for p in paths_ {
		if p.trim_space() == '' {
			panic('cannot find commone ancestors if any of items in paths is empty.\n${paths_}')
		}
	}
	paths := paths_.map(os.abs_path(os.real_path(it))) // get the real path (symlinks... resolved)
	console.print_debug(paths.str())
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

// same as above but will treat symlinks as if normal links
// allowing finding relative paths between links as well
// QUESTION: should we merge with above?
pub fn find_simple_common_ancestor(paths_ []string) string {
	for p in paths_ {
		if p.trim_space() == '' {
			panic('cannot find commone ancestors if any of items in paths is empty.\n${paths_}')
		}
	}
	paths := paths_.map(os.abs_path(it))
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
			path:  '/'
			cat:   Category.dir
			exist: .unknown
		}
	}
	return Path{
		path:  parent
		cat:   Category.dir
		exist: .unknown
	}
}

pub struct MoveArgs {
pub mut:
	dest          string // path
	delete        bool   // if true will remove files which are on dest which are not on source
	chmod_execute bool
}

// move to other location
// ```
// dest           string   // path
// delete         bool     // if true will remove files which are on dest which are not on source
// ```
pub fn (mut path Path) move(args MoveArgs) ! {
	mut d := get(args.dest)
	if d.exists() {
		if args.delete {
			d.delete()!
		} else {
			return error("Found dest dir in move and can't delete. \n${args}")
		}
	}
	os.mv(path.path, d.path)!
	if args.chmod_execute {
		d.chmod(0o770)!
	}
}

// the path will move itself up 1 level .
// e.g. path is /tmp/rclone and there is /tmp/rclone/rclone-v1.64.2-linux-amd64 .
// that last dir needs to move 1 up
pub fn (mut path Path) moveup_single_subdir() ! {
	mut plist := path.list(recursive: false, ignoredefault: true, dirs_only: true)!
	console.print_debug(plist.str())
	if plist.paths.len != 1 {
		return error('could not find one subdir in ${path.path} , so cannot move up')
	}
	mut pdest := plist.paths[0]
	pdest.moveup()!
}

// the path will move itself up 1 level .
// the e.g. /tmp/rclone/rclone-v1.64.2-linux-amd64/ -> /tmp/rclone
pub fn (mut path Path) moveup() ! {
	console.print_stdout('move up: ${path}')
	pdest := path.parent()!
	tmpdir := '${os.temp_dir()}/${rand.u16()}'
	path.move(dest: tmpdir, delete: true)!
	mut tmpdirpath := get_dir(path: tmpdir)!
	tmpdirpath.move(dest: pdest.path, delete: true)!
	path.path = pdest.path
	path.check()
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
		// console.print_debug("exists: $path")
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
	if os.is_link(path.path) {
		os.rm(path.path.replace('//', '/'))!
	}
}

// remove all content but if dir let the dir exist
pub fn (mut path Path) empty() ! {
	if path.cat == .dir {
		os.mkdir_all(path.path)!
		path.exist = .yes
		mut list := path.list()!
		for mut subpath in list.paths {
			subpath.delete()!
		}
	} else if path.cat == Category.linkfile {
		mut p2 := path.getlink()!
		p2.empty()!
	} else {
		path.write('')!
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

// write bytes to file
pub fn (mut path Path) writeb(content []u8) ! {
	if !os.exists(path.path_dir()) {
		os.mkdir_all(path.path_dir())!
	}
	if path.exists() && path.cat == Category.linkfile {
		mut pathlinked := path.getlink()!
		pathlinked.writeb(content)!
	}

	if path.exists() && path.cat != Category.file && path.cat != Category.linkfile {
		return error('Path must be a file for ${path}')
	}

	os.write_file_array(path.path, content)!
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

// read bytes from file
pub fn (mut path Path) readb() ![]u8 {
	path.check()
	match path.cat {
		.file, .linkfile {
			p := path.absolute()
			if !os.exists(p) {
				return error('File does not exist, ${p} is a wrong path')
			}
			return os.read_bytes(p)
		}
		else {
			return error('Path is not a file when reading. ${path.path}')
		}
	}
}

// recalc path between target & source .
// we only support if source_ is an existing dir, links will not be supported .
// a0 := pathlib.path_relative('$testpath/a/b/c', '$testpath/a/d.txt') or { panic(err) } .
// assert a0 == '../../d.txt' .
// a2 := pathlib.path_relative('$testpath/a/b/c', '$testpath/d.txt') or { panic(err) } .
// assert a2 == '../../../d.txt' .
// a8 := pathlib.path_relative('$testpath/a/b/c', '$testpath/a/b/c/d/e/e.txt') or { panic(err) } .
// assert a8 == 'd/e/e.txt' .
// symlinks will not be resolved, as it leads to unexpected behaviour
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

	if p.cat != .dir && p.cat != .linkdir {
		return error('Cannot do path_relative()! if source is not a dir Now:${source_} is ${p.cat}')
	} else if !p.exists() {
		return error('Cannot do path_relative()! if source doesnt exist. Now:${source_}')
	}

	common := find_simple_common_ancestor([source, linkpath])

	// if source is common, returns source
	if source.len <= common.len + 1 {
		// TODO: this should be safer
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

	// console.print_stdout('source: ${source_short}')
	// console.print_stdout('link: ${linkpath_short}')

	source_count := source_short.count('/')
	// link_count := linkpath_short.count('/')
	// console.print_debug(" + source_short:$source_short ($source_count)")
	// console.print_debug(" + linkpath_short:$linkpath_short ($link_count)")
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

@[params]
pub struct TMPWriteArgs {
pub mut:
	name   string // optional name to remember it more easily
	tmpdir string
	text   string // text to put in file
	path   string // to overrule the path where script will be stored
	ext    string = 'sh'
}

// write temp file and return path
pub fn temp_write(args_ TMPWriteArgs) !string {
	mut args := args_

	if args.path.len == 0 {
		if args.tmpdir.len == 0 {
			if 'TMPDIR' in os.environ() {
				args.tmpdir = os.environ()['TMPDIR'] or { '/tmp' }
			} else {
				args.tmpdir = '/tmp'
			}
		}
		mut t := time.now().format_ss_milli().replace(' ', '-').replace('.', ':')
		texthash := md5.hexhash(args.text)
		t += '_${texthash}'
		mut tmppath := '${args.tmpdir}/execscripts/${t}.${args.ext}'
		if args.name.len > 0 {
			tmppath = '${args.tmpdir}/execscripts/${args.name}_${t}.${args.ext}'
		}

		if !os.exists('${args.tmpdir}/execscripts/') {
			os.mkdir('${args.tmpdir}/execscripts') or {
				return error('Cannot create ${args.tmpdir}/execscripts,${err}')
			}
		}
		if os.exists(tmppath) {
			for i in 1 .. 200 {
				// console.print_debug(i)
				tmppath = '${args.tmpdir}/execscripts/{${t}}_${i}.${args.ext}'
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

// pub fn path_relative(source_ string, dest_ string) !string {
// 	mut source := source_.trim_right('/')
// 	mut dest := dest_.replace('//', '/').trim_right('/')
// 	// console.print_debug("path relative: '$source' '$dest' ")
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
