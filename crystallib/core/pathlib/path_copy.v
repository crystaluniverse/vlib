module pathlib

import os

@[params]
pub struct CopyArgs {
pub mut:
	dest           string // path
	delete         bool   // if true will remove files which are on dest which are not on source
	rsync          bool = true // we use rsync as default
	ssh_target     string   // e.g. root@195.192.213.2:999
	ignore         []string // arguments to ignore e.g. ['*.pyc','*.bak']
	ignore_default bool = true // if set will ignore a common set
}

// copy file,dir is always recursive
// if ssh_target used then will copy over ssh e.g. .
// dest needs to be a directory or file .
// return Path of the destination file or dir .
pub fn (mut path Path) copy(args_ CopyArgs) ! {
	mut args := args_
	if args.ignore.len > 0 || args.ssh_target.len > 0 {
		args.rsync = true
	}
	path.check()
	if !path.exists() {
		return error("can't find path for copy operation on ${path.path}")
	}
	if args.rsync == true {
		rsync(
			source:         path.path
			dest:           args.dest
			delete:         args.delete
			ipaddr_dst:     args.ssh_target
			ignore:         args.ignore
			ignore_default: args.ignore_default
		)!
	} else {
		mut dest := get(args.dest)
		if dest.exists() {
			if !(path.cat in [.file, .dir] && dest.cat in [.file, .dir]) {
				return error('Source or Destination path is not file or directory.\n\n${path.path} cat:${path.cat}---${dest.path} cat:${dest.cat}')
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
		// $if debug {
		// 	console.print_debug(' copy: ${path.path} ${dest.path}')
		// }
		os.cp_all(path.path, dest.path, true)! // Always overwite if needed

		dest.check()
	}
}
