module flist

@[table: 'inode']
pub struct Inode {
pub mut:
	ino    u64    @[primary; sql: serial]
	parent u64
	name   string
	size   u64
	uid    u32
	gid    u32
	mode   u32
	rdev   u64
	ctime  i64
	mtime  i64
}

fn (mut f Flist) add_inode(inode Inode) ! {
	sql f.con {
		insert inode into Inode
	}!
}

fn (mut f Flist) get_inode_children(parent u64) ![]Inode {
	children := sql f.con {
		select from Inode where parent == parent
	}!

	return children
}

fn (mut f Flist) find_inode_with_pattern(pattern string) ![]Inode {
	inodes := sql f.con {
		select from Inode where name like pattern
	}!

	return inodes
}

fn (mut f Flist) get_inode_from_path(path_ string) !Inode {
	mut path := path_.trim('/')

	items := path.split('/')
	root_inodes := sql f.con {
		select from Inode where ino == 1
	}!

	if root_inodes.len != 1 {
		return error('invalid flist: failed to get root directory inode')
	}

	mut inode := root_inodes[0]
	if path == '' {
		return inode
	}

	for item in items {
		if item == '' {
			return error('invalid path ${path_}')
		}

		inodes := sql f.con {
			select from Inode where name == item && parent == inode.ino
		}!

		// at most only one entry should match
		if inodes.len == 0 {
			return error('file or directory ${item} does not exist in flist')
		}

		inode = inodes[0]
	}

	return inode
}

fn (mut f Flist) get_inode_path(inode Inode) !string {
	mut path := ''
	mut cur_inode := inode
	for cur_inode.ino != 1 {
		path = '/${cur_inode.name}${path}'
		cur_inode = f.get_inode(cur_inode.parent)!
	}

	return path
}

fn (mut f Flist) get_inode(ino u64) !Inode {
	inode := sql f.con {
		select from Inode where ino == ino
	}!

	if inode.len == 0 {
		return error('inode ${ino} was not found')
	}

	return inode[0]
}

// get_last_inode_number returns the biggest inode number in flist
fn (mut f Flist) get_last_inode_number() !u64 {
	inodes := f.list(true)!
	mut last_inode := u64(0)
	for inode in inodes {
		if inode.ino > last_inode {
			last_inode = inode.ino
		}
	}

	return last_inode
}

fn (mut f Flist) delete_inode(ino u64) ! {
	// delete from block table
	f.delete_block(ino)!

	// delete from extra table
	f.delete_extra(ino)!

	// get children if any
	children := sql f.con {
		select from Inode where parent == ino
	}!

	for child in children {
		f.delete_inode(child.ino)!
	}

	// delete inode
	f.con.exec_param('delete from inode where ino = ?;', '${ino}')!
}
