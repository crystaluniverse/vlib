module pathlib

import os
import freeflowuniverse.crystallib.ui.console
// import time

@[params]
pub struct BackupArgs {
pub mut:
	root      string
	dest      string
	overwrite bool
	restore   bool // if we want to find the latest one, if we can't find one then its error
}

// start from existing name and look for name.$nr.$ext, nr need to be unique, ideal for backups
// if dest "" then will use the directory of the fileitself + "/.backup"
//		e.g. /code/myaccount/despiegk/somedir/test.v if
// 		would be backed up to /code/myaccount/despiegk/somedir/.backup/test.1.v
// root is the start of the dir we process
//		e.g. /code/myaccount/despiegk/somedir/test.v if
//		if source = /code/myaccount/despiegk and dest = /backup then the file will be backed up to /backup/somedir/test.1.v
//
// struct BackupArgs{
// 	root string
// 	dest string
// 	overwrite bool
//  restore bool //if we want to find the latest one, if we can't find one then its error
// }
// if overwrite this means will overwrite the last one in the directory
pub fn (mut path Path) backup_path(args BackupArgs) !Path {
	if !path.exists() && args.restore == false {
		error('cannot find path, so cannot create backup for ${path}')
	}
	mut dest := ''
	mut rel := ''

	if args.dest == '' {
		dest = path.path_dir() + '/.backup'
	}
	if !os.exists(dest) {
		os.mkdir_all(dest)!
	}

	if args.dest != '' || args.root != '' {
		panic('not implemented')
	}

	// if source != '' {
	// 	path_abs := path.absolute()
	// 	mut source_path := Path{
	// 		path: source
	// 	}.absolute()
	// 	if path_abs.starts_with(source_path) {
	// 		rel = os.dir(path_abs.substr(source_path.len + 1, path_abs.len)) + '/'
	// 	}
	// }
	// os.mkdir_all('$dest/$rel')!

	for i in 0 .. 1000 {
		console.print_debug(i.str())
		path_str := '${dest}/${rel}${path.name_no_ext()}.${path.extension()}.${i}'
		path_str_next := '${dest}/${rel}${path.name_no_ext()}.${path.extension()}.${i + 1}'
		mut path_found := Path{
			path: path_str
			cat:  .file
		}
		mut path_found_next := Path{
			path: path_str_next
			cat:  .file
		}
		if !path_found.exists() {
			if args.restore {
				return error('could not find a backup file in ${path_found.path} for restore')
			}
			path_found.exists()
			return path_found
		}

		size := path_found.size()!

		if size > 0 {
			// console.print_debug("size > 0 ")
			// this makes sure we only continue if there is no next file, we only need to check size for latest one
			if !path_found_next.exists() {
				// means is the last file
				// console.print_debug("current: ${path_found}")
				// console.print_debug("next: ${path_found_next}")
				// console.print_debug(args)
				if args.restore || args.overwrite {
					// console.print_debug("RESTORE: $path_found")
					return path_found
				}
				size2 := path_found.size()!
				if size2 == size {
					// means we found the last one which is same as the one we are trying to backup
					// console.print_debug("*** SIZE EQUAL EXISTS")
					path_found.exist = .yes
					return path_found
				}
				// console.print_debug("nothing")
			}
		}
	}
	return error('cannot find path for backup')
}

// create a backup, will maintain the extension
pub fn (mut path Path) backup(args BackupArgs) !Path {
	// console.print_debug(path.path)
	mut pbackup := path.backup_path(args)!
	if !pbackup.exists() {
		os.cp(path.path, pbackup.path)!
	}
	return pbackup
}

pub fn (mut path Path) restore(args BackupArgs) ! {
	// console.print_debug("restore")
	// console.print_debug(path.path)
	mut args2 := args
	args2.restore = true
	mut prestore := path.backup_path(args2)!
	if args.overwrite || path.exists() {
		os.cp(prestore.path, path.path)!
	} else {
		return error('Cannot restore, because to be restored file exists: ${path.path}\n${args}')
	}
}

pub fn (mut path Path) backups_remove(args BackupArgs) ! {
	mut pl := path.list(recursive: true)!
	for mut p in pl.paths {
		if p.is_dir() {
			if p.name() == '.backup' {
				p.delete()!
			}
		}
	}
	// TODO: is not good enough, can be other path
}

// //represents one directory in which backup was done
// struct BackupDir{
// pub mut:
// 	items []BackupItem
// 	path Path //path where the backed up items are in
// }

// pub struct BackupItem{
// pub:
// 	name string //only the base name of the file
// 	hash string
// 	time time.Time
// 	backupdir &BackupDir
// }

// get the pathobject
// pub fn (bi BackupItem) path_get() Path {
// 	return get("${bi.backupdir.path.path}/${bi.name}")
// }	

// //save the metadata for the backups
// pub fn (mut backupdir BackupDir) metadate_save() ! {
// 	mut out :=[]string{}
// 	// for item in backupdir.items{
// 	// 	out << item.metadata()
// 	// }
// }
