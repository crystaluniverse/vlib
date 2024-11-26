module flist

@[table: 'extra']
pub struct Extra {
pub mut:
	ino  u64
	data string
}

fn (mut f Flist) get_extra(ino u64) ?Extra {
	extra := sql f.con {
		select from Extra where ino == ino
	} or { return none }

	if extra.len == 0 {
		return none
	}

	return extra[0]
}

// copy_extra creates a copy of the extra record related to src_ino and relates it to dest_ino
fn (mut f Flist) copy_extra(src_ino u64, dest_ino u64) ! {
	if mut extra := f.get_extra(src_ino) {
		extra.ino = dest_ino
		f.add_extra(extra)!
	}
}

fn (mut f Flist) delete_extra(ino u64) ! {
	f.con.exec_param('delete from extra where ino = ?;', '${ino}')!
}

fn (mut f Flist) add_extra(extra Extra) ! {
	sql f.con {
		insert extra into Extra
	}!
}
