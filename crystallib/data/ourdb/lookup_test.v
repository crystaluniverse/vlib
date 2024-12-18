module ourdb

import os
import rand

const test_dir = '/tmp/lookuptest'

fn testsuite_begin() {
	if os.exists(test_dir) {
		os.rmdir_all(test_dir)!
	}
	os.mkdir_all(test_dir)!
}

fn testsuite_end() {
	if os.exists(test_dir) {
		os.rmdir_all(test_dir)!
	}
}

fn test_incremental() {
	config := LookupConfig{
		size:    100
		keysize: 2
	}
	mut lut := new_lookup(config)!

	assert lut.get_next_id()! == 0

	lut.set(0, Location{ position: 23, file_nr: 0 })!
	assert lut.get_next_id()! == 1

	lut.set(1, Location{ position: 2, file_nr: 3 })!
	assert lut.get_next_id()! == 2
}

fn test_new_lookup() {
	// Test memory-based lookup
	config := LookupConfig{
		size:    100
		keysize: 2
	}
	lut := new_lookup(config)!
	assert lut.keysize == 2
	assert lut.data.len == 200 // size * keysize
	assert lut.lookuppath == ''

	// Test disk-based lookup
	disk_config := LookupConfig{
		size:       100
		keysize:    2
		lookuppath: os.join_path(test_dir, 'test.lut')
	}
	disk_lut := new_lookup(disk_config)!
	assert disk_lut.keysize == 2
	assert disk_lut.lookuppath == os.join_path(test_dir, 'test.lut')
	assert os.exists(os.join_path(test_dir, 'test.lut'))

	// Test invalid keysize
	invalid_config := LookupConfig{
		size:    100
		keysize: 7
	}
	if _ := new_lookup(invalid_config) {
		assert false, 'should fail on invalid keysize'
	}
}

fn test_set_get() {
	config := LookupConfig{
		size:             100
		keysize:          2
		incremental_mode: true
	}

	mut lut := new_lookup(config)!

	// Test setting and getting values
	loc1 := Location{
		position: 1234
		file_nr:  0
	}

	id := lut.get_next_id()!
	lut.set(id, loc1)!

	result1 := lut.get(id)!
	assert result1.position == 1234
	assert result1.file_nr == 0

	// Test setting with specific ID
	loc2 := Location{
		position: 5678
		file_nr:  0
	}

	id2 := lut.get_next_id()!
	lut.set(id2, loc2)!
	assert id2 == 1 // Should return the specified ID
	result2 := lut.get(id2)!
	assert result2.position == 5678
	assert result2.file_nr == 0

	// Test out of bounds
	if _ := lut.get(100) {
		assert false, 'should fail on out of bounds'
	}
	if _ := lut.set(100, loc1) {
		assert false, 'should fail on out of bounds'
	}
}

fn test_disk_set_get() {
	config := LookupConfig{
		size:       100
		keysize:    2
		lookuppath: os.join_path(test_dir, rand.string(4))
	}
	mut lut := new_lookup(config)!

	// Test setting and getting values on disk
	loc1 := Location{
		position: 1234
		file_nr:  0
	}

	id := lut.get_next_id()!
	lut.set(id, loc1)!
	assert id == 0 // First auto-increment should be 1
	result1 := lut.get(id)!
	assert result1.position == 1234
	assert result1.file_nr == 0

	// Test persistence by creating new instance
	mut lut2 := new_lookup(config)!
	result2 := lut2.get(id)!
	assert result2.position == 1234
	assert result2.file_nr == 0

	// Test next auto-increment continues from previous value
	loc2 := Location{
		position: 5678
		file_nr:  0
	}

	id2 := lut2.get_next_id()!
	lut2.set(id2, loc2)!
	assert id2 == 1 // Should increment from previous value
}

fn test_delete() {
	config := LookupConfig{
		size:    100
		keysize: 2
	}
	mut lut := new_lookup(config)!

	// Set and then delete a value
	loc1 := Location{
		position: 1234
		file_nr:  0
	}

	id := lut.get_next_id()!
	lut.set(id, loc1)!
	assert id == 0

	lut.delete(id)!
	result := lut.get(id)!
	assert result.position == 0
	assert result.file_nr == 0

	// Test out of bounds
	if _ := lut.delete(100) {
		assert false, 'should fail on out of bounds'
	}
}

fn test_export_import() {
	config := LookupConfig{
		size:    100
		keysize: 2
	}
	mut lut := new_lookup(config)!

	// Set some values
	loc1 := Location{
		position: 1234
		file_nr:  0
	}

	id1 := lut.get_next_id()!
	lut.set(id1, loc1)!
	assert id1 == 0

	loc2 := Location{
		position: 5678
		file_nr:  0
	}
	id2 := lut.get_next_id()!
	lut.set(id2, loc2)!
	assert id2 == 1

	// Export and then import to new table
	export_path := os.join_path(test_dir, 'export.lut')
	os.mkdir(export_path)!

	lut.export_data(export_path)!
	mut lut2 := new_lookup(config)!
	lut2.import_data(export_path)!

	// Verify values
	result1 := lut2.get(id1)!
	assert result1.position == 1234
	assert result1.file_nr == 0
	result2 := lut2.get(id2)!
	assert result2.position == 5678
	assert result2.file_nr == 0

	// Verify incremental was imported
	assert lut2.incremental! == 2
}

fn test_export_import_sparse() {
	config := LookupConfig{
		size:             100
		keysize:          2
		incremental_mode: false
	}

	mut lut := new_lookup(config)!

	// Set some values with gaps
	loc1 := Location{
		position: 1234
		file_nr:  0
	}

	id1 := u32(0)
	lut.set(id1, loc1)!

	loc2 := Location{
		position: 5678
		file_nr:  0
	}
	id2 := u32(50)
	lut.set(id2, loc2)! // Create a gap

	// Export and import sparse
	sparse_path := os.join_path(test_dir, 'sparse.lut')
	os.mkdir(sparse_path)!

	lut.export_sparse(sparse_path)!
	mut lut2 := new_lookup(config)!
	lut2.import_sparse(sparse_path)!

	// Verify values
	result1 := lut2.get(id1)!
	assert result1.position == 1234
	assert result1.file_nr == 0
	result2 := lut2.get(id2)!
	assert result2.position == 5678
	assert result2.file_nr == 0
}

fn test_incremental_memory() {
	config := LookupConfig{
		size:    100
		keysize: 2
	}
	mut lut := new_lookup(config)!

	// Initial value should be 0
	if incremental := lut.incremental {
		assert incremental == 0
	} else {
		assert false, 'incremental should have a value'
	}

	// Set at x=0 should increment and return new ID
	loc1 := Location{
		position: 1234
		file_nr:  0
	}
	id1 := lut.get_next_id()!
	lut.set(id1, loc1)!
	assert id1 == 0
	assert lut.incremental! == 1

	// Set at x=1 should not increment and return specified ID
	loc2 := Location{
		position: 5678
		file_nr:  0
	}
	id2 := lut.get_next_id()!
	lut.set(id2, loc2)!
	assert id2 == 1
	assert lut.incremental! == 2

	// Another set at x=0 should increment and return new ID
	loc3 := Location{
		position: 9012
		file_nr:  0
	}

	id3 := lut.get_next_id()!
	lut.set(id3, loc3)!
	assert id3 == 2
	assert lut.incremental! == 3

	// Test persistence through export/import
	export_path := os.join_path(test_dir, 'inc_export.lut')
	os.mkdir(export_path)!

	lut.export_data(export_path)!

	mut lut2 := new_lookup(config)!
	lut2.import_data(export_path)!
	assert lut2.incremental! == 3

	// Further operations should continue from last value
	loc4 := Location{
		position: 3456
		file_nr:  0
	}
	id4 := lut2.get_next_id()!
	lut2.set(id4, loc4)!
	assert id4 == 3
	assert lut2.incremental! == 4
}

fn test_incremental_disk() {
	config := LookupConfig{
		size:       100
		keysize:    2
		lookuppath: os.join_path(test_dir, 'inc_test.lut')
	}
	mut lut := new_lookup(config)!

	// Initial value should be 0
	assert lut.incremental! == 0
	assert os.exists(lut.get_inc_file_path()!)
	inc_content := os.read_file(lut.get_inc_file_path()!)!
	assert inc_content == '0'

	// Set at x=0 should increment
	loc1 := Location{
		position: 1234
		file_nr:  0
	}
	id1 := lut.get_next_id()!
	lut.set(id1, loc1)!
	assert id1 == 0
	assert lut.incremental! == 1
	inc_content1 := os.read_file(lut.get_inc_file_path()!)!
	assert inc_content1 == '1'

	// Set at x=1 should not increment
	loc2 := Location{
		position: 5678
		file_nr:  0
	}
	id2 := lut.get_next_id()!
	lut.set(id2, loc2)!
	assert id2 == 1
	assert lut.incremental! == 2
	inc_content2 := os.read_file(lut.get_inc_file_path()!)!
	assert inc_content2 == '2'

	// Test persistence by creating new instance
	mut lut2 := new_lookup(config)!
	assert lut2.incremental! == 2

	// Further operations at x=0 should continue from last value
	loc3 := Location{
		position: 9012
		file_nr:  0
	}
	id3 := lut2.get_next_id()!
	lut2.set(id3, loc3)!
	assert id3 == 2
	assert lut2.incremental! == 3
	inc_content3 := os.read_file(lut.get_inc_file_path()!)!
	assert inc_content3 == '3'
}

fn test_multiple_sets() {
	config := LookupConfig{
		size:    100
		keysize: 2
	}
	mut lut := new_lookup(config)!

	// Set at x=0 five times
	mut ids := []u32{}
	for i in 0 .. 5 {
		loc := Location{
			position: 1000 * (i + 1)
			file_nr:  0
		}
		id := lut.get_next_id()!
		lut.set(id, loc)!
		assert id == i
		ids << id
	}

	// Verify incremental is 5
	assert lut.incremental! == 5
	assert ids == [u32(0), 1, 2, 3, 4]
}
