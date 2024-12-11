module flist

import db.sqlite
import os
import time

pub struct Flist {
	path string
	con  sqlite.DB
}

pub struct FlistGetArgs {
	path   string @[required]
	create bool
}

pub fn new(args FlistGetArgs) !Flist {
	if args.create {
		os.create(args.path)!
	}

	con := sqlite.connect(args.path)!
	con.journal_mode(sqlite.JournalMode.delete)!

	return Flist{
		path: args.path
		con: con
	}
}

// list directories and files in root directory. if recursive is allowed directories are explored.
pub fn (mut f Flist) list(recursive bool) ![]Inode {
	inodes := match recursive {
		true {
			res := sql f.con {
				select from Inode
			}!
			res
		}
		false {
			res := sql f.con {
				select from Inode where parent == 1
			}!
			res
		}
	}

	return inodes
}

// copy copies an flist entry from source path to destination path.
pub fn (mut f Flist) copy(source string, destination string) ! {
	dest := destination.trim_right('/')

	src_inode := f.get_inode_from_path(source)!

	if _ := f.get_inode_from_path(dest) {
		return error('${dest} exists')
	}

	dest_parent := if dest.contains('/') {
		dest.all_before_last('/')
	} else {
		''
	}

	dest_parent_inode := f.get_inode_from_path(dest_parent)!
	dest_inode := Inode{
		parent: dest_parent_inode.ino
		ctime: time.now().unix()
		mtime: time.now().unix()
		mode: src_inode.mode
		name: dest.all_after_last('/')
		rdev: src_inode.rdev
		size: src_inode.size
		gid: u32(os.getgid())
		uid: u32(os.getuid())
	}

	f.add_inode(dest_inode)!

	dest_ino := u64(f.con.last_id())

	f.copy_blocks(src_inode.ino, dest_ino)!
	f.copy_extra(src_inode.ino, dest_ino)!

	children := f.get_inode_children(src_inode.ino)!

	for child in children {
		f.copy(os.join_path(source, child.name), os.join_path(dest, child.name))!
	}
}

// delete file or directory from flist. path is relative to flist root directory.
// empty path will delete all flist entries.
// (actual data is not deleted, only flist information)
pub fn (mut f Flist) delete_path(path_ string) ! {
	/*
		delete from inode table and all related tables
	*/
	inode := f.get_inode_from_path(path_) or {
		return error('failed to get inode from path: ${err}')
	}

	f.delete_inode(inode.ino) or { return error('failed to delete inode: ${err}') }
}

// delete_match deletes any entry that matches pattern. it simply calls find() and deletes matching inodes.
pub fn (mut f Flist) delete_match(pattern string) ! {
	inodes := f.find(pattern)!
	for inode in inodes {
		f.delete_inode(inode.ino)!
	}
}

// merge merges two flists together.
//
// - copies all routes
// - copies all inodes with the following restrictions:
// 	 - no two entries can have the same inode number. this can happen by shifting an flist's inode numbers to start after the last inode number of the other flist.
// 	 - the changed flist should reflect the inode changes on all affected tables (extra and block).
// 	 - no two files that exist in the same dir can have the same name.
// 	 - if two files have the same name and have the same blocks, they are identical and won't be copied, otherwise, the incoming entry is renamed.
pub fn merge(source string, destination string) ! {
	mut f_src := new(path: source)!
	mut f_dest := new(path: destination)!

	f_dest.con.exec('BEGIN;')!
	f_dest.merge_(mut f_src) or {
		f_dest.con.exec('ROLLBACK;')!
		return error('faild to merge flists: ${err}')
	}
	f_dest.con.exec('COMMIT;')!
}

fn (mut f Flist) merge_(mut f_src Flist) ! {
	src_routes := f_src.get_routes()!
	f.add_routes(src_routes)!

	dest_last_inode_num := f.get_last_inode_number()!
	mut next_inode_num := dest_last_inode_num + 1
	mut src_inodes := f_src.list(true)!

	for mut inode in src_inodes {
		if inode.ino == 1 && inode.parent == 0 {
			// this is root inode, not included in merge
			continue
		}

		mut src_blocks := f_src.get_inode_blocks(inode.ino)!
		src_inode_path := f_src.get_inode_path(inode)!
		// if entry is not a dir and has a match with an entry from destination
		// then skip
		if matching_dest_inode := f.get_inode_from_path(src_inode_path) {
			// two entries exist with the same path: there might be a match,
			// need to check blocks to make sure
			if inode.mode == matching_dest_inode.mode {
				if inode.mode == 16384 {
					// this is a directory, skip it
					continue
				}

				dest_blocks := f.get_inode_blocks(matching_dest_inode.ino)!
				if do_blocks_match(src_blocks, dest_blocks) {
					continue
				}
			}

			// need to assign new name to incoming entry
			mut new_name := ''
			for i in 1 .. 100 {
				new_src_inode_path := '${src_inode_path} (${i})'
				if _ := f.get_inode_from_path(new_src_inode_path) {
					continue
				} else {
					new_name = '${inode.name} (${i})'
					break
				}
			}

			if new_name == '' {
				return error('failed to assign new name to entry ${inode.name}')
			}

			inode.name = new_name
		}

		// get blocks for inode
		for mut block in src_blocks {
			block.ino = next_inode_num
			f.add_block(block)!
		}

		// get extras for inode
		if mut extra := f_src.get_extra(inode.ino) {
			extra.ino = next_inode_num
			f.add_extra(extra)!
		}

		inode.ino = next_inode_num
		f.add_inode(inode)!

		next_inode_num += 1
	}

	src_tags := f_src.get_tags()!
	for tag in src_tags {
		f.add_tag(tag)!
	}
}

// find entries that match pattern, it uses the `LIKE` operator;
// The percent sign (%) matches zero or more characters and the underscore (_) matches exactly one.
pub fn (mut f Flist) find(pattern string) ![]Inode {
	return f.find_inode_with_pattern(pattern)
}

// update_routes will overwrite the current routes with the new routes
pub fn (mut f Flist) update_routes(new_routes []Route) ! {
	f.delete_all_routes()!

	f.add_routes(new_routes)!
}

// add_routes adds routes to the route table of the flist
pub fn (mut f Flist) add_routes(new_routes []Route) ! {
	current_routes := f.get_routes()!

	for route in new_routes {
		if current_routes.contains(route) {
			continue
		}

		f.add_route(route)!
	}
}
