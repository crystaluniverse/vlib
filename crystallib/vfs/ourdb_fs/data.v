module ourdb_fs

// DataBlock represents a block of file data
pub struct DataBlock {
pub mut:
	id   u32  // Block ID
	data []u8 // Actual data content
	size u32  // Size of data in bytes
	next u32  // ID of next block (0 if last block)
}
