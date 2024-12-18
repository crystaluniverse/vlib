module ourdb_fs

import freeflowuniverse.crystallib.data.encoder

// encode_metadata encodes the common metadata structure
fn encode_metadata(mut e encoder.Encoder, m Metadata) {
	e.add_u32(m.id)
	e.add_string(m.name)
	e.add_u8(u8(m.file_type)) // FileType enum as u8
	e.add_u64(m.size)
	e.add_i64(m.created_at)
	e.add_i64(m.modified_at)
	e.add_i64(m.accessed_at)
	e.add_u32(m.mode)
	e.add_string(m.owner)
	e.add_string(m.group)
}

// decode_metadata decodes the common metadata structure
fn decode_metadata(mut d encoder.Decoder) Metadata {
	id := d.get_u32()
	name := d.get_string()
	file_type_byte := d.get_u8()
	size := d.get_u64()
	created_at := d.get_i64()
	modified_at := d.get_i64()
	accessed_at := d.get_i64()
	mode := d.get_u32()
	owner := d.get_string()
	group := d.get_string()

	return Metadata{
		id:          id
		name:        name
		file_type:   unsafe { FileType(file_type_byte) }
		size:        size
		created_at:  created_at
		modified_at: modified_at
		accessed_at: accessed_at
		mode:        mode
		owner:       owner
		group:       group
	}
}

// Directory encoding/decoding

// encode encodes a Directory to binary format
pub fn (dir Directory) encode() []u8 {
	mut e := encoder.new()
	e.add_u8(1) // version byte
	e.add_u8(u8(FileType.directory)) // type byte

	// Encode metadata
	encode_metadata(mut e, dir.metadata)

	// Encode parent_id
	e.add_u32(dir.parent_id)

	// Encode children IDs
	e.add_u16(u16(dir.children.len))
	for child_id in dir.children {
		e.add_u32(child_id)
	}

	return e.data
}

// decode_directory decodes a binary format back to Directory
pub fn decode_directory(data []u8) !Directory {
	mut d := encoder.decoder_new(data)
	version := d.get_u8()
	if version != 1 {
		return error('Unsupported version ${version}')
	}

	type_byte := d.get_u8()
	if type_byte != u8(FileType.directory) {
		return error('Invalid type byte for directory')
	}

	// Decode metadata
	metadata := decode_metadata(mut d)

	// Decode parent_id
	parent_id := d.get_u32()

	// Decode children IDs
	children_count := int(d.get_u16())
	mut children := []u32{cap: children_count}

	for _ in 0 .. children_count {
		children << d.get_u32()
	}

	return Directory{
		metadata:  metadata
		parent_id: parent_id
		children:  children
		myvfs:     unsafe { nil } // Will be set by caller
	}
}

// File encoding/decoding

// encode encodes a File to binary format
pub fn (f File) encode() []u8 {
	mut e := encoder.new()
	e.add_u8(1) // version byte
	e.add_u8(u8(FileType.file)) // type byte

	// Encode metadata
	encode_metadata(mut e, f.metadata)

	// Encode parent_id
	e.add_u32(f.parent_id)

	// Encode file data
	e.add_string(f.data)

	return e.data
}

// decode_file decodes a binary format back to File
pub fn decode_file(data []u8) !File {
	mut d := encoder.decoder_new(data)
	version := d.get_u8()
	if version != 1 {
		return error('Unsupported version ${version}')
	}

	type_byte := d.get_u8()
	if type_byte != u8(FileType.file) {
		return error('Invalid type byte for file')
	}

	// Decode metadata
	metadata := decode_metadata(mut d)

	// Decode parent_id
	parent_id := d.get_u32()

	// Decode file data
	data_content := d.get_string()

	return File{
		metadata:  metadata
		parent_id: parent_id
		data:      data_content
		myvfs:     unsafe { nil } // Will be set by caller
	}
}

// Symlink encoding/decoding

// encode encodes a Symlink to binary format
pub fn (sl Symlink) encode() []u8 {
	mut e := encoder.new()
	e.add_u8(1) // version byte
	e.add_u8(u8(FileType.symlink)) // type byte

	// Encode metadata
	encode_metadata(mut e, sl.metadata)

	// Encode parent_id
	e.add_u32(sl.parent_id)

	// Encode target path
	e.add_string(sl.target)

	return e.data
}

// decode_symlink decodes a binary format back to Symlink
pub fn decode_symlink(data []u8) !Symlink {
	mut d := encoder.decoder_new(data)
	version := d.get_u8()
	if version != 1 {
		return error('Unsupported version ${version}')
	}

	type_byte := d.get_u8()
	if type_byte != u8(FileType.symlink) {
		return error('Invalid type byte for symlink')
	}

	// Decode metadata
	metadata := decode_metadata(mut d)

	// Decode parent_id
	parent_id := d.get_u32()

	// Decode target path
	target := d.get_string()

	return Symlink{
		metadata:  metadata
		parent_id: parent_id
		target:    target
		myvfs:     unsafe { nil } // Will be set by caller
	}
}
