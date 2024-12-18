module ourdb

// in lookuptable.keysize we specify what nr of bytes are we use as id
// they are encoded big_endian
// if + 2^32 then we know we store the data in multiple files, the most significant parts define the filenr, the others the id

pub struct Location {
pub mut:
	file_nr  u16
	position u32
}

// keysize = 2, means we have 2^16 nr of records in 1 file = position
// keysize = 3, means we have 2^24 nr of records in 1 file
// keysize = 4, means we have 2^32 nr of records in 1 file
// keysize = 6, means we have 2^32 nr of records per file, and there can be maximum 2^16 nr of files
// check validity, keysize needs to define max position
fn (lookuptable LookupTable) location_new(b_ []u8) !Location {
	mut new_location := Location{
		file_nr:  0
		position: 0
	}

	// First verify keysize is valid
	if lookuptable.keysize !in [2, 3, 4, 6] {
		return error('keysize must be 2,3,4 or 6')
	}

	// Create padded b
	mut b := []u8{len: int(lookuptable.keysize), init: 0}
	start_idx := int(lookuptable.keysize) - b_.len
	if start_idx < 0 {
		return error('input bytes exceed keysize')
	}

	for i := 0; i < b_.len; i++ {
		b[start_idx + i] = b_[i]
	}

	match lookuptable.keysize {
		2 {
			// Only position, 2 bytes big endian
			new_location.position = u32(b[0]) << 8 | u32(b[1])
			new_location.file_nr = 0
		}
		3 {
			// Only position, 3 bytes big endian
			new_location.position = u32(b[0]) << 16 | u32(b[1]) << 8 | u32(b[2])
			new_location.file_nr = 0
		}
		4 {
			// Only position, 4 bytes big endian
			new_location.position = u32(b[0]) << 24 | u32(b[1]) << 16 | u32(b[2]) << 8 | u32(b[3])
			new_location.file_nr = 0
		}
		6 {
			// 2 bytes file_nr + 4 bytes position, all big endian
			new_location.file_nr = u16(b[0]) << 8 | u16(b[1])
			new_location.position = u32(b[2]) << 24 | u32(b[3]) << 16 | u32(b[4]) << 8 | u32(b[5])
		}
		else {}
	}

	// Verify limits based on keysize
	match lookuptable.keysize {
		2 {
			if new_location.position > 0xFFFF {
				return error('position exceeds max value for keysize=2 (max 65535)')
			}
			if new_location.file_nr != 0 {
				return error('file_nr must be 0 for keysize=2')
			}
		}
		3 {
			if new_location.position > 0xFFFFFF {
				return error('position exceeds max value for keysize=3 (max 16777215)')
			}
			if new_location.file_nr != 0 {
				return error('file_nr must be 0 for keysize=3')
			}
		}
		4 {
			if new_location.file_nr != 0 {
				return error('file_nr must be 0 for keysize=4')
			}
		}
		6 {
			// For keysize 6: both file_nr and position can use their full range
			// No additional checks needed as u16 and u32 already enforce limits
		}
		else {}
	}

	return new_location
}

fn (self Location) to_bytes() ![]u8 {
	mut bytes := []u8{len: 6}

	// Put file_nr first (2 bytes)
	bytes[0] = u8(self.file_nr >> 8)
	bytes[1] = u8(self.file_nr)

	// Put position next (4 bytes)
	bytes[2] = u8(self.position >> 24)
	bytes[3] = u8(self.position >> 16)
	bytes[4] = u8(self.position >> 8)
	bytes[5] = u8(self.position)

	return bytes
}

// Convert Location to u64, with file_nr as most significant (big endian)
fn (self Location) u64() !u64 {
	return (u64(self.file_nr) << 32) | u64(self.position)
}
