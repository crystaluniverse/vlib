module memdb

import os
import hash.crc32

// MemDB represents a binary database with variable-length records
@[heap]
pub struct MemDB {
pub mut:
	path    string
	lookup  &LookupTable
	file    os.File
}

// Record header size: 2 (size) + 4 (crc) + 4 (prev_pos) = 10 bytes
const header_size = 10

// new_memdb creates a new memory database with the given path and lookup table
pub fn new_memdb(path string, lookup &LookupTable) !MemDB {
	mut file := os.open_file(path, 'c+') or { 
		// Create if doesn't exist with read/write permissions
		os.create(path)!
	}
	return MemDB{
		path: path
		lookup: lookup
		file: file
	}
}

// calculate_crc computes CRC32 for the data
fn calculate_crc(data []u8) u32 {
	return crc32.sum(data)
}

// set stores data at position x
pub fn (mut db MemDB) set(x u32, data []u8) ! {
	// Get current file position for lookup
	pos := db.file.tell()!
	
	// Get previous position if exists
	prev_pos := db.lookup.get(x) or { u32(0) }
	
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
	
	// Write previous position (4 bytes)
	header[6] = u8(prev_pos & 0xFF)
	header[7] = u8((prev_pos >> 8) & 0xFF)
	header[8] = u8((prev_pos >> 16) & 0xFF)
	header[9] = u8((prev_pos >> 24) & 0xFF)
	
	// Write header
	db.file.write(header)!
	
	// Write actual data
	db.file.write(data)!
	
	// Update lookup table with new position
	db.lookup.set(x, u32(pos))!
}

// get retrieves data at position x
pub fn (mut db MemDB) get(x u32) ![]u8 {
	// Get position from lookup
	pos := db.lookup.get(x)!
	if pos == 0 {
		return error('Record not found')
	}
	
	// Seek to position
	db.file.seek(i64(pos), .start)!
	
	// Read header
	header := db.file.read_bytes(header_size)
	
	// Parse size (2 bytes)
	size := u16(header[0]) | (u16(header[1]) << 8)
	
	// Parse CRC (4 bytes)
	stored_crc := u32(header[2]) | 
				  (u32(header[3]) << 8) |
				  (u32(header[4]) << 16) |
				  (u32(header[5]) << 24)
	
	// Read data
	data := db.file.read_bytes(int(size))
	
	// Verify CRC
	calculated_crc := calculate_crc(data)
	if calculated_crc != stored_crc {
		return error('CRC mismatch: data corruption detected')
	}
	
	return data
}

// get_prev_pos retrieves the previous position for a record
pub fn (mut db MemDB) get_prev_pos(x u32) !u32 {
	pos := db.lookup.get(x)!
	if pos == 0 {
		return error('Record not found')
	}
	
	// Seek to position
	db.file.seek(i64(pos), .start)!
	
	// Skip size and CRC (6 bytes)
	db.file.seek(i64(pos + 6), .start)!
	
	// Read previous position (4 bytes)
	prev_pos_bytes := db.file.read_bytes(4)
	return u32(prev_pos_bytes[0]) |
		   (u32(prev_pos_bytes[1]) << 8) |
		   (u32(prev_pos_bytes[2]) << 16) |
		   (u32(prev_pos_bytes[3]) << 24)
}

// delete zeros out the record at position x
pub fn (mut db MemDB) delete(x u32) ! {
	pos := db.lookup.get(x)!
	if pos == 0 {
		return error('Record not found')
	}
	
	// Seek to position
	db.file.seek(i64(pos), .start)!
	
	// Read size first
	size_bytes := db.file.read_bytes(2)
	size := u16(size_bytes[0]) | (u16(size_bytes[1]) << 8)
	
	// Write zeros for the entire record (header + data)
	zeros := []u8{len: int(size) + header_size, init: 0}
	db.file.seek(i64(pos), .start)!
	db.file.write(zeros)!
	
	// Clear lookup entry
	db.lookup.delete(x)!
}

// condense removes empty records and updates positions
pub fn (mut db MemDB) condense() ! {
	temp_path := db.path + '.temp'
	mut temp_file := os.create(temp_path)!
	
	// Track current position in temp file
	mut new_pos := u32(0)
	
	// Iterate through lookup table
	entry_size := int(db.lookup.bytes_per_entry)
	for i := 0; i < db.lookup.data.len / entry_size; i++ {
		pos := db.lookup.get(u32(i)) or { continue }
		if pos == 0 {
			continue
		}
		
		// Read record from original file
		db.file.seek(i64(pos), .start)!
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
		new_pos += u32(size) + header_size
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
pub fn (mut db MemDB) close() {
	db.file.close()
}
