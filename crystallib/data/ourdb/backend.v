module ourdb

import os
import hash.crc32

// this is the implementation of the lowlevel datastor, doesnt know about ACL or signature, it just stores a binary blob

// the backend can be in 1 file or multiple files, if multiple files each file has a nr, we support max 65536 files in 1 dir

// calculate_crc computes CRC32 for the data
fn calculate_crc(data []u8) u32 {
	return crc32.sum(data)
}

fn (mut db OurDB) db_file_select(file_nr u16) ! {
	// open file for read/write
	// file is in "${db.path}/${nr}.db"
	// return the file for read/write
	if file_nr > 65535 {
		return error('file_nr needs to be < 65536')
	}

	path := '${db.path}/${file_nr}.db'

	if db.file_nr == file_nr {
		// make sure file is opened
		if !db.file.is_opened {
			if !os.exists(path) {
				db.create_new_db_file(file_nr)!
			}

			mut file := os.open_file(path, 'r+')!
			db.file = file
		}
		return
	}

	if db.file.is_opened {
		db.file.close()
	}

	if !os.exists(path) {
		db.create_new_db_file(file_nr)!
	}
	mut file := os.open_file(path, 'r+')!

	db.file = file
	db.file_nr = file_nr
}

fn (mut db OurDB) create_new_db_file(file_nr u16) ! {
	new_file_path := '${db.path}/${file_nr}.db'
	mut f := os.create(new_file_path)!
	f.write([u8(0)])! // to make all positions start from 1
	f.close()
}

fn (mut db OurDB) get_file_nr() !u16 {
	path := '${db.path}/${db.last_used_file_nr}.db'
	if !os.exists(path) {
		db.create_new_db_file(db.last_used_file_nr)!
		return db.last_used_file_nr
	}

	stat := os.stat(path)!
	if stat.size >= db.file_size {
		db.last_used_file_nr += 1
		db.create_new_db_file(db.last_used_file_nr)!
	}

	return db.last_used_file_nr
}

// set stores data at position x
pub fn (mut db OurDB) set_(x u32, old_location Location, data []u8) ! {
	// Convert u64 to Location
	file_nr := db.get_file_nr()!

	// TODO: can't file_nr change between two revisions?
	db.db_file_select(file_nr)!

	// Get current file position for lookup
	db.file.seek(0, .end)!
	new_location := Location{
		file_nr:  file_nr
		position: u32(db.file.tell()!)
	}

	// Calculate CRC of data
	crc := calculate_crc(data)

	// Write size as u16 (2 bytes)
	size := u16(data.len)
	mut header := []u8{len: header_size, init: 0}

	// Write size (2 bytes)
	header[0] = u8(size & 0xFF)
	header[1] = u8((size >> 8) & 0xFF)

	// Write CRC (4 bytes)
	header[2] = u8(crc & 0xFF)
	header[3] = u8((crc >> 8) & 0xFF)
	header[4] = u8((crc >> 16) & 0xFF)
	header[5] = u8((crc >> 24) & 0xFF)

	// Convert previous location to bytes and store in header
	prev_bytes := old_location.to_bytes()!
	for i := 0; i < 6; i++ {
		header[6 + i] = prev_bytes[i]
	}

	// Write header
	db.file.write(header)!

	// Write actual data
	db.file.write(data)!
	db.file.flush()

	// Update lookup table with new position
	db.lookup.set(x, new_location)!
}

// get retrieves data at specified location
fn (mut db OurDB) get_(location Location) ![]u8 {
	db.db_file_select(location.file_nr)!

	if location.position == 0 {
		return error('Record not found')
	}

	// Seek to position
	db.file.seek(i64(location.position), .start)!

	// Read header
	mut header := []u8{len: header_size}
	header_read_bytes := db.file.read(mut header)!
	if header_read_bytes != header_size {
		return error('failed to read header')
	}

	// Parse size (2 bytes)
	size := u16(header[0]) | (u16(header[1]) << 8)

	// Parse CRC (4 bytes)
	stored_crc := u32(header[2]) | (u32(header[3]) << 8) | (u32(header[4]) << 16) | (u32(header[5]) << 24)

	// Read data
	mut data := []u8{len: int(size)}
	data_read_bytes := db.file.read(mut data)!
	if data_read_bytes != int(size) {
		return error('failed to read data bytes')
	}

	// Verify CRC
	calculated_crc := calculate_crc(data)
	if calculated_crc != stored_crc {
		return error('CRC mismatch: data corruption detected')
	}

	return data
}

// get_prev_pos retrieves the previous position for a record
fn (mut db OurDB) get_prev_pos_(location Location) !Location {
	if location.position == 0 {
		return error('Record not found')
	}

	// Skip size and CRC (6 bytes)
	db.file.seek(i64(location.position + 6), .start)!

	// Read previous location (6 bytes)
	mut prev_bytes := []u8{len: 6}
	read_bytes := db.file.read(mut prev_bytes)!
	if read_bytes != 6 {
		return error('failed to read previous location bytes: read ${read_bytes} while expected to read 6 bytes')
	}

	return db.lookup.location_new(prev_bytes)!
}

// delete zeros out the record at specified location
fn (mut db OurDB) delete_(x u32, location Location) ! {
	if location.position == 0 {
		return error('Record not found')
	}

	// Seek to position
	db.file.seek(i64(location.position), .start)!

	// Read size first
	size_bytes := db.file.read_bytes(2)
	size := u16(size_bytes[0]) | (u16(size_bytes[1]) << 8)

	// Write zeros for the entire record (header + data)
	zeros := []u8{len: int(size) + header_size, init: 0}
	db.file.seek(i64(location.position), .start)!
	db.file.write(zeros)!

	// Clear lookup entry
	db.lookup.delete(x)!
}

// condense removes empty records and updates positions
fn (mut db OurDB) condense() ! {
	temp_path := db.path + '.temp'
	mut temp_file := os.create(temp_path)!

	// Track current position in temp file
	mut new_pos := Location{
		file_nr:  0
		position: 0
	}

	// Iterate through lookup table
	entry_size := int(db.lookup.keysize)
	for i := 0; i < db.lookup.data.len / entry_size; i++ {
		location := db.lookup.get(u32(i)) or { continue }
		if location.position == 0 {
			continue
		}

		// Read record from original file
		db.file.seek(i64(location.position), .start)!
		header := db.file.read_bytes(header_size)
		size := u16(header[0]) | (u16(header[1]) << 8)

		if size == 0 {
			continue
		}

		data := db.file.read_bytes(int(size))

		// Write to temp file
		temp_file.write(header)!
		temp_file.write(data)!

		// Update lookup with new position
		db.lookup.set(u32(i), new_pos)!

		// Update position counter
		new_pos.position += u32(size) + header_size
	}

	// Close both files
	temp_file.close()
	db.file.close()

	// Replace original with temp
	os.rm(db.path)!
	os.mv(temp_path, db.path)!

	// Reopen the file
	db.file = os.open_file(db.path, 'c+')!
}

// close closes the database file
fn (mut db OurDB) close_() {
	db.file.close()
}
