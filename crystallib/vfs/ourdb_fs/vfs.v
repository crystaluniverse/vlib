module ourdb_fs

import freeflowuniverse.crystallib.data.ourdb

// OurDBFS represents the virtual filesystem
@[heap]
pub struct OurDBFS {
pub mut:
	root_id      u32          // ID of root directory
	block_size   u32          // Size of data blocks in bytes
	data_dir     string       // Directory to store OurDBFS data
	metadata_dir string       // Directory where we store the metadata
	db_data      &ourdb.OurDB // Database instance for persistent storage
	db_meta      &ourdb.OurDB // Database instance for metadata storage
}

// get_root returns the root directory
pub fn (mut fs OurDBFS) get_root() !&Directory {
	// Try to load root directory from DB if it exists
	if data := fs.db_meta.get(fs.root_id) {
		mut loaded_root := decode_directory(data) or {
			return error('Failed to decode root directory: ${err}')
		}
		loaded_root.myvfs = &fs
		return &loaded_root
	}
	// Save new root to DB
	mut myroot := Directory{
		metadata:  Metadata{}
		parent_id: 0
		myvfs:     &fs
	}
	myroot.save()!

	return &myroot
}

// load_entry loads an entry from the database by ID and sets up parent references
fn (mut fs OurDBFS) load_entry(id u32) !FSEntry {
	if data := fs.db_meta.get(id) {
		// First byte is version, second byte indicates the type
		// TODO: check we dont overflow filetype (u8 in boundaries of filetype)
		entry_type := unsafe { FileType(data[1]) }

		match entry_type {
			.directory {
				mut dir := decode_directory(data) or {
					return error('Failed to decode directory: ${err}')
				}
				dir.myvfs = unsafe { &fs }
				return dir
			}
			.file {
				mut file := decode_file(data) or { return error('Failed to decode file: ${err}') }
				file.myvfs = unsafe { &fs }
				return file
			}
			.symlink {
				mut symlink := decode_symlink(data) or {
					return error('Failed to decode symlink: ${err}')
				}
				symlink.myvfs = unsafe { &fs }
				return symlink
			}
		}
	}
	return error('Entry not found')
}

// save_entry saves an entry to the database
pub fn (mut fs OurDBFS) save_entry(entry FSEntry) !u32 {
	match entry {
		Directory {
			encoded := entry.encode()
			return fs.db_meta.set(entry.metadata.id, encoded) or {
				return error('Failed to save directory on id:${entry.metadata.id}: ${err}')
			}
		}
		File {
			encoded := entry.encode()
			return fs.db_meta.set(entry.metadata.id, encoded) or {
				return error('Failed to save file on id:${entry.metadata.id}: ${err}')
			}
		}
		Symlink {
			encoded := entry.encode()
			return fs.db_meta.set(entry.metadata.id, encoded) or {
				return error('Failed to save symlink on id:${entry.metadata.id}: ${err}')
			}
		}
	}
}

// delete_entry deletes an entry from the database
pub fn (mut fs OurDBFS) delete_entry(id u32) ! {
	fs.db_meta.delete(id) or { return error('Failed to delete entry: ${err}') }
}
