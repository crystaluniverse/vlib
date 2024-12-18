module ourdb

import os

// LOOKUP table is link between the id and the posititon in a file with the data

const data_file_name = 'data'
const incremental_file_name = '.inc'

@[params]
pub struct LookupConfig {
pub:
	size       u32    // size of the table
	keysize    u8     // size of each entry in bytes (2-6), 6 means we store data over multiple files
	lookuppath string // if set, use disk-based lookup

	incremental_mode bool = true
}

pub struct LookupTable {
	keysize    u8
	lookuppath string
mut:
	data        []u8
	incremental ?u32 // points to next empty slot in the lookup table if incremental mode is enabled
}

// Method to create a new lookup table
fn new_lookup(config LookupConfig) !LookupTable {
	// First verify keysize is valid
	if config.keysize !in [2, 3, 4, 6] {
		return error('keysize must be 2,3,4 or 6')
	}

	if config.lookuppath.len > 0 {
		if !os.exists(config.lookuppath) {
			os.mkdir_all(config.lookuppath)!
		}

		// For disk-based lookup, create empty file if it doesn't exist
		if !os.exists(os.join_path(config.lookuppath, data_file_name)) {
			data := []u8{len: int(config.size * config.keysize), init: 0}
			os.write_file(os.join_path(config.lookuppath, data_file_name), data.bytestr())!
		}

		return LookupTable{
			// size: config.size
			data:        []u8{}
			keysize:     config.keysize
			lookuppath:  config.lookuppath
			incremental: get_incremental_info(config)
		}
	}

	return LookupTable{
		// size: config.size
		data:        []u8{len: int(config.size * config.keysize), init: 0}
		keysize:     config.keysize
		lookuppath:  ''
		incremental: get_incremental_info(config)
	}
}

fn get_incremental_info(config LookupConfig) ?u32 {
	if !config.incremental_mode {
		return none
	}

	if config.lookuppath.len > 0 {
		if !os.exists(os.join_path(config.lookuppath, incremental_file_name)) {
			// Create a separate file for storing the incremental value
			os.write_file(os.join_path(config.lookuppath, incremental_file_name), '0') or {
				panic('failed to write .inc file: ${err}')
			}
		}

		inc_str := os.read_file(os.join_path(config.lookuppath, incremental_file_name)) or {
			panic('failed to read .inc file: ${err}')
		}

		incremental := inc_str.u32()
		return incremental
	}

	return 0
}

// Method to get value from a specific position
fn (lut LookupTable) get(x u32) !Location {
	entry_size := int(lut.keysize)
	if lut.lookuppath.len > 0 {
		// Check file size first
		file_size := os.file_size(lut.get_data_file_path()!)
		start_pos := x * entry_size

		if start_pos + entry_size > file_size {
			return error('Invalid read for get in lut: ${lut.lookuppath}: ${start_pos + entry_size} would exceed file size ${file_size}')
		}

		// Read directly from file for disk-based lookup
		mut file := os.open(lut.get_data_file_path()!)!
		defer { file.close() }

		mut data := []u8{len: entry_size}
		bytes_read := file.read_from(u64(start_pos), mut data)!
		if bytes_read < entry_size {
			return error('Incomplete read: expected ${entry_size} bytes but got ${bytes_read}')
		}
		return lut.location_new(data)!
	}

	if x * entry_size >= u32(lut.data.len) {
		return error('Index out of bounds')
	}

	start := u32(x * entry_size)
	return lut.location_new(lut.data[start..start + entry_size])!
}

fn (mut lut LookupTable) get_next_id() !u32 {
	incremental := lut.incremental or { return error('lookup table not in incremental mode') }

	table_size := if lut.lookuppath.len > 0 {
		u32(os.file_size(lut.get_data_file_path()!))
	} else {
		u32(lut.data.len)
	}

	if incremental * lut.keysize >= table_size {
		return error('lookup table is full')
	}

	return incremental
}

fn (mut lut LookupTable) increment_index() ! {
	mut incremental := lut.incremental or { return error('lookup table not in incremental mode') }

	incremental += 1
	lut.incremental = incremental
	if lut.lookuppath.len > 0 {
		os.write_file(lut.get_inc_file_path()!, incremental.str())!
	}
}

// Method to set a value at a specific position
fn (mut lut LookupTable) set(x u32, location Location) ! {
	entry_size := int(lut.keysize)

	mut id := x
	if incremental := lut.incremental {
		if x == incremental {
			lut.increment_index()!
		}

		if x > incremental {
			return error('cannot set id for insertions when incremental mode is enabled')
		}
	}

	// Always store at the ID position
	if lut.lookuppath.len > 0 {
		// Check file size first
		file_size := os.file_size(lut.lookuppath)
		start_pos := id * entry_size
		data_file_path := lut.get_data_file_path()!
		if start_pos + entry_size > file_size {
			return error('Invalid write position: ${start_pos + entry_size} would exceed file size ${file_size}')
		}

		// Write directly to file for disk-based lookup
		mut file := os.open_file(data_file_path, 'r+')!
		defer {
			file.flush()
			file.close()
		}

		data := location.to_bytes()!
		bytes_written := file.write_to(u64(start_pos), data[(6 - entry_size)..])! // Only write the required bytes based on keysize
		if bytes_written < entry_size {
			return error('Incomplete write: expected ${entry_size} bytes but wrote ${bytes_written}')
		}

		return
	}

	if id * u32(entry_size) >= u32(lut.data.len) {
		return error('Index out of bounds')
	}

	start := int(id) * entry_size
	bytes := location.to_bytes()!

	for i in 0 .. entry_size {
		lut.data[start + i] = bytes[6 - entry_size + i] // Only use the required bytes based on keysize
	}
}

// Method to delete an entry (set bytes to 0)
fn (mut lut LookupTable) delete(x u32) ! {
	entry_size := int(lut.keysize)

	if lut.lookuppath.len > 0 {
		// Check file size first
		file_size := os.file_size(lut.get_data_file_path()!)
		start_pos := x * entry_size

		if start_pos + entry_size > file_size {
			return error('Invalid read for get in lut: ${lut.lookuppath}: ${start_pos + entry_size} would exceed file size ${file_size}')
		}

		// Write zeros directly to file for disk-based lookup
		mut file := os.open_file(lut.get_data_file_path()!, 'r+')!
		defer {
			file.flush()
			file.close()
		}

		zeros := []u8{len: entry_size, init: 0}
		bytes_written := file.write_to(u64(start_pos), zeros)!
		if bytes_written < entry_size {
			return error('Incomplete delete: expected ${entry_size} bytes but wrote ${bytes_written}')
		}
		return
	}

	if x * u32(entry_size) >= u32(lut.data.len) {
		return error('Index out of bounds')
	}

	start := int(x) * entry_size
	for i in 0 .. entry_size {
		lut.data[start + i] = 0
	}
}

// Method to export the lookup table to a file
fn (lut LookupTable) export_data(path string) ! {
	if lut.lookuppath.len > 0 {
		// For disk-based lookup, copy both the main file and incremental value
		os.cp(lut.get_data_file_path()!, os.join_path(path, data_file_name))!
		if _ := lut.incremental {
			os.cp(lut.get_inc_file_path()!, os.join_path(path, incremental_file_name))!
		}
		return
	}

	os.write_file(os.join_path(path, data_file_name), lut.data.bytestr())!
	if incremental := lut.incremental {
		os.write_file(os.join_path(path, incremental_file_name), incremental.str())!
	}
}

// Method to export the table in a sparse format
fn (lut LookupTable) export_sparse(path string) ! {
	mut output := []u8{}
	entry_size := int(lut.keysize)

	if lut.lookuppath.len > 0 {
		// For disk-based lookup, read the file in chunks
		mut file := os.open(lut.get_data_file_path()!)!
		defer { file.close() }

		file_size := os.file_size(lut.get_data_file_path()!)
		mut buffer := []u8{len: entry_size}
		mut pos := u32(0)

		for {
			if i64(pos) * i64(entry_size) >= file_size {
				break
			}

			bytes_read := file.read(mut buffer)!
			if bytes_read == 0 {
				break
			}
			if bytes_read < entry_size {
				break
			}

			location := lut.location_new(buffer)!
			if location.position != 0 || location.file_nr != 0 {
				// Write position (4 bytes)
				output << u8(pos & 0xff)
				output << u8((pos >> 8) & 0xff)
				output << u8((pos >> 16) & 0xff)
				output << u8((pos >> 24) & 0xff)

				// Write value
				output << buffer
			}
			pos++
		}
	} else {
		for i := u32(0); i < u32(lut.data.len / entry_size); i++ {
			location := lut.get(i) or { continue }
			if location.position != 0 || location.file_nr != 0 {
				// Write position (4 bytes)
				output << u8(i & 0xff)
				output << u8((i >> 8) & 0xff)
				output << u8((i >> 16) & 0xff)
				output << u8((i >> 24) & 0xff)

				// Write value
				bytes := location.to_bytes()!
				output << bytes[6 - entry_size..] // Only write the required bytes based on keysize
			}
		}
	}
	os.write_file(os.join_path(path, data_file_name), output.bytestr())!
	// Also export the incremental value
	if incremental := lut.incremental {
		os.write_file(os.join_path(path, incremental_file_name), incremental.str())!
	}
}

// Method to import a lookup table from a file
fn (mut lut LookupTable) import_data(path string) ! {
	if lut.lookuppath.len > 0 {
		// For disk-based lookup, copy both files
		os.cp(os.join_path(path, data_file_name), lut.get_data_file_path()!)!

		if _ := lut.incremental {
			os.cp(os.join_path(path, incremental_file_name), os.join_path(lut.lookuppath,
				incremental_file_name))!
			// Update the incremental value in memory
			inc_str := os.read_file(os.join_path(path, incremental_file_name))!
			println('inc_str: ${inc_str}')
			lut.incremental = inc_str.u32()
		}
		return
	}

	lut.data = os.read_bytes(os.join_path(path, data_file_name))!
	if _ := lut.incremental {
		// Import the incremental value
		inc_str := os.read_file(os.join_path(path, incremental_file_name))!
		lut.incremental = inc_str.u32()
	}
}

// Method to import a sparse lookup table
fn (mut lut LookupTable) import_sparse(path string) ! {
	sparse_data := os.read_bytes(os.join_path(path, data_file_name))!
	entry_size := int(lut.keysize)
	chunk_size := 4 + entry_size // 4 bytes for position + entry_size for value

	if sparse_data.len % chunk_size != 0 {
		return error('Invalid sparse data format: data length must be multiple of ${chunk_size}')
	}

	for i := 0; i < sparse_data.len; i += chunk_size {
		// Read position from first 4 bytes
		position := u32(sparse_data[i]) | (u32(sparse_data[i + 1]) << 8) | (u32(sparse_data[i + 2]) << 16) | (u32(sparse_data[
			i + 3]) << 24)

		// Read value bytes
		value_bytes := sparse_data[i + 4..i + 4 + entry_size]
		location := lut.location_new(value_bytes)!

		lut.set(position, location)!
	}

	if _ := lut.incremental {
		// Import the incremental value
		inc_str := os.read_file(os.join_path(path, incremental_file_name))!
		lut.incremental = inc_str.u32()
	}
}

fn (lut LookupTable) get_data_file_path() !string {
	if lut.lookuppath.len == 0 {
		return error('lookup table is memory based')
	}

	return os.join_path(lut.lookuppath, data_file_name)
}

fn (lut LookupTable) get_inc_file_path() !string {
	_ := lut.incremental or { return error('incremental mode is disabled') }

	return os.join_path(lut.lookuppath, incremental_file_name)
}
