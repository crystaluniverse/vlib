module ourdb

import os

// LOOKUP table is link between the id and the posititon in a file with the data

@[params]
pub struct LookupConfig {
pub:
	size       u32    // size of the table
	keysize    u8     // size of each entry in bytes (2-6), 6 means we store data over multiple files
	lookuppath string // if set, use disk-based lookup
}

pub struct LookupTable {
	keysize    u8
	lookuppath string
mut:
	data        []u8
	incremental u32 // tracks the last used incremental value
}

// Method to create a new lookup table
fn new_lookup(config LookupConfig) !LookupTable {
	// First verify keysize is valid
	if config.keysize !in [2, 3, 4, 6] {
		return error('keysize must be 2,3,4 or 6')
	}

	if config.lookuppath.len > 0 {
		// For disk-based lookup, create empty file if it doesn't exist
		if !os.exists(config.lookuppath) {
			data := []u8{len: int(config.size * config.keysize), init: 0}
			os.write_file(config.lookuppath, data.bytestr())!
			// Create a separate file for storing the incremental value
			os.write_file(config.lookuppath + '.inc', '0')!
		}
		// Read the incremental value from file
		inc_str := os.read_file(config.lookuppath + '.inc')!
		incremental := inc_str.u32()
		return LookupTable{
			data: []u8{}
			keysize: config.keysize
			lookuppath: config.lookuppath
			incremental: incremental
		}
	}

	return LookupTable{
		data: []u8{len: int(config.size * config.keysize), init: 0}
		keysize: config.keysize
		lookuppath: ''
		incremental: 0
	}
}

// Method to get value from a specific position
fn (lut LookupTable) get(x u32) !Location {
	entry_size := int(lut.keysize)
	if lut.lookuppath.len > 0 {
		// Check file size first
		file_size := os.file_size(lut.lookuppath)
		start_pos := x * entry_size

		if start_pos + entry_size > file_size {
			return error('Invalid read for get in lut: ${lut.lookuppath}: ${start_pos + entry_size} would exceed file size ${file_size}')
		}

		// Read directly from file for disk-based lookup
		mut file := os.open(lut.lookuppath)!
		defer { file.close() }

		file.seek(start_pos, .start)!
		mut data := []u8{len: entry_size}
		bytes_read := file.read(mut data)!
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

// returns next free entry after incremental id
fn (mut lut LookupTable) get_next_free_entry() !u32 {
	table_size := lut.data.len / lut.keysize
	for i := lut.incremental + 1; i < table_size; i++ {
		if lut.is_entry_empty(i)! {
			return i
		}
	}

	return error('failed to find free space in look up table')
}

// check if entry (id) is empty
fn (mut lut LookupTable) is_entry_empty(id int) !bool {
	start_pos := id * lut.keysize
	if lut.lookuppath.len > 0 {
		mut file := os.open_file(lut.lookuppath, 'r')!
		file.seek(start_pos, .start)!
		key_bytes := file.read_bytes(lut.keysize)
		if key_bytes.len != lut.keysize {
			return error('key does not exist in lookup table file: ${id}')
		}

		for b in key_bytes {
			if b != 0 {
				return false
			}
		}

		return true
	}

	for i := start_pos; i < start_pos + lut.keysize; i++ {
		if i == lut.data.len {
			return error('key does not exist in lookup table data: ${id}')
		}

		if lut.data[i] != 0 {
			return false
		}
	}

	return true
}

// Method to set a value at a specific position
// Returns the ID used (either x if specified, or incremental if x=0)
fn (mut lut LookupTable) set(x u32, location Location) !u32 {
	entry_size := int(lut.keysize)

	mut id := x
	// Only increment if x is 0
	if x == 0 {
		// check if position is empty

		id = lut.get_next_free_entry()!
		lut.incremental = id

		if lut.lookuppath.len > 0 {
			// Update incremental value in file
			os.write_file(lut.lookuppath + '.inc', lut.incremental.str())!
		}
	}

	// Always store at the ID position
	if lut.lookuppath.len > 0 {
		// Check file size first
		file_size := os.file_size(lut.lookuppath)
		start_pos := id * entry_size

		if start_pos + entry_size > file_size {
			return error('Invalid write position: ${start_pos + entry_size} would exceed file size ${file_size}')
		}

		// Write directly to file for disk-based lookup
		mut file := os.open_file(lut.lookuppath, 'w+')!
		defer {
			file.flush()
			file.close()
		}

		file.seek(start_pos, .start)!

		data := location.to_bytes()!
		bytes_written := file.write(data[6 - entry_size..])! // Only write the required bytes based on keysize
		if bytes_written < entry_size {
			return error('Incomplete write: expected ${entry_size} bytes but wrote ${bytes_written}')
		}
		return id
	}

	if id * u32(entry_size) >= u32(lut.data.len) {
		return error('Index out of bounds')
	}

	start := int(id) * entry_size
	bytes := location.to_bytes()!

	for i in 0 .. entry_size {
		lut.data[start + i] = bytes[6 - entry_size + i] // Only use the required bytes based on keysize
	}
	return id
}

// Method to delete an entry (set bytes to 0)
fn (mut lut LookupTable) delete(x u32) ! {
	entry_size := int(lut.keysize)

	if lut.lookuppath.len > 0 {
		// Check file size first
		file_size := os.file_size(lut.lookuppath)
		start_pos := x * entry_size

		if start_pos + entry_size > file_size {
			return error('Invalid read for get in lut: ${lut.lookuppath}: ${start_pos + entry_size} would exceed file size ${file_size}')
		}

		// Write zeros directly to file for disk-based lookup
		mut file := os.open_file(lut.lookuppath, 'w+')!
		defer {
			file.flush()
			file.close()
		}

		file.seek(start_pos, .start)!
		zeros := []u8{len: entry_size, init: 0}
		bytes_written := file.write(zeros)!
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
		os.cp(lut.lookuppath, path)!
		os.cp(lut.lookuppath + '.inc', path + '.inc')!
		return
	}
	os.write_file(path, lut.data.bytestr())!
	os.write_file(path + '.inc', lut.incremental.str())!
}

// Method to export the table in a sparse format
fn (lut LookupTable) export_sparse(path string) ! {
	mut output := []u8{}
	entry_size := int(lut.keysize)

	if lut.lookuppath.len > 0 {
		// For disk-based lookup, read the file in chunks
		mut file := os.open(lut.lookuppath)!
		defer { file.close() }

		file_size := os.file_size(lut.lookuppath)
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
	os.write_file(path, output.bytestr())!
	// Also export the incremental value
	os.write_file(path + '.inc', lut.incremental.str())!
}

// Method to import a lookup table from a file
fn (mut lut LookupTable) import_data(path string) ! {
	if lut.lookuppath.len > 0 {
		// For disk-based lookup, copy both files
		os.cp(path, lut.lookuppath)!
		os.cp(path + '.inc', lut.lookuppath + '.inc')!
		// Update the incremental value in memory
		inc_str := os.read_file(path + '.inc')!
		lut.incremental = inc_str.u32()
		return
	}
	lut.data = os.read_bytes(path)!
	// Import the incremental value
	inc_str := os.read_file(path + '.inc')!
	lut.incremental = inc_str.u32()
}

// Method to import a sparse lookup table
fn (mut lut LookupTable) import_sparse(path string) ! {
	sparse_data := os.read_bytes(path)!
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

	// Import the incremental value
	inc_str := os.read_file(path + '.inc')!
	lut.incremental = inc_str.u32()
}
