module flist

@[table: 'block']
pub struct Block {
pub mut:
	ino u64
	id  string
	key string
}

fn (mut f Flist) add_block(block Block) ! {
	sql f.con {
		insert block into Block
	}!
}

fn do_blocks_match(b1 []Block, b2 []Block) bool {
	if b1.len != b2.len {
		return false
	}

	for i, b in b1 {
		if b.key != b2[i].key || b.id != b2[i].id {
			return false
		}
	}

	return true
}

fn (mut f Flist) get_inode_blocks(ino u64) ![]Block {
	blocks := sql f.con {
		select from Block where ino == ino
	}!

	return blocks
}

fn (mut f Flist) delete_block(ino u64) ! {
	f.con.exec_param('delete from block where ino = ?;', '${ino}')!
}

// copy_blocks creates block a copy of the block entries related to src_ino and relates them to dest_ino
fn (mut f Flist) copy_blocks(src_ino u64, dest_ino u64) ! {
	mut blocks := f.get_inode_blocks(src_ino)!

	for mut block in blocks {
		block.ino = dest_ino
		f.add_block(block)!
	}
}
