module ourdb

import os

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

fn test_new_lookup() {
	// Test memory-based lookup
	config := LookupConfig{
		size: 100
		keysize: 2
	}
	lut := new_lookup(config)!
	assert lut.keysize == 2
	assert lut.data.len == 200 // size * keysize
	assert lut.lookuppath == ''

	// Test disk-based lookup
	disk_config := LookupConfig{
		size: 100
		keysize: 2
		lookuppath: os.join_path(test_dir, 'test.lut')
	}
	disk_lut := new_lookup(disk_config)!
	assert disk_lut.keysize == 2
	assert disk_lut.lookuppath == os.join_path(test_dir, 'test.lut')
	assert os.exists(os.join_path(test_dir, 'test.lut'))

	// Test invalid keysize
	invalid_config := LookupConfig{
		size: 100
		keysize: 7
	}
	if _ := new_lookup(invalid_config) {
		assert false, 'should fail on invalid keysize'
	}
}

fn test_set_get() {
	config := LookupConfig{
		size: 100
		keysize: 2
	}
	mut lut := new_lookup(config)!

	// Test setting and getting values
	loc1 := Location{
		position: 1234
		file_nr: 0
	}
	lut.set(0, loc1)!
	result1 := lut.get(0)!
	assert result1.position == 1234
	assert result1.file_nr == 0

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
		size: 100
		keysize: 2
		lookuppath: os.join_path(test_dir, 'test.lut')
	}
	mut lut := new_lookup(config)!

	// Test setting and getting values on disk
	loc1 := Location{
		position: 1234
		file_nr: 0
	}
	lut.set(0, loc1)!
	result1 := lut.get(0)!
	assert result1.position == 1234
	assert result1.file_nr == 0

	// Test persistence by creating new instance
	mut lut2 := new_lookup(config)!
	result2 := lut2.get(0)!
	assert result2.position == 1234
	assert result2.file_nr == 0
}

fn test_delete() {
	config := LookupConfig{
		size: 100
		keysize: 2
	}
	mut lut := new_lookup(config)!

	// Set and then delete a value
	loc1 := Location{
		position: 1234
		file_nr: 0
	}
	lut.set(0, loc1)!
	lut.delete(0)!
	result := lut.get(0)!
	assert result.position == 0
	assert result.file_nr == 0

	// Test out of bounds
	if _ := lut.delete(100) {
		assert false, 'should fail on out of bounds'
	}
}

fn test_export_import() {
	config := LookupConfig{
		size: 100
		keysize: 2
	}
	mut lut := new_lookup(config)!

	// Set some values
	loc1 := Location{
		position: 1234
		file_nr: 0
	}
	lut.set(0, loc1)!
	loc2 := Location{
		position: 5678
		file_nr: 0
	}
	lut.set(1, loc2)!

	// Export and then import to new table
	export_path := os.join_path(test_dir, 'export.lut')
	lut.export_data(export_path)!
	mut lut2 := new_lookup(config)!
	lut2.import_data(export_path)!

	// Verify values
	result1 := lut2.get(0)!
	assert result1.position == 1234
	assert result1.file_nr == 0
	result2 := lut2.get(1)!
	assert result2.position == 5678
	assert result2.file_nr == 0
}

fn test_export_import_sparse() {
	config := LookupConfig{
		size: 100
		keysize: 2
	}
	mut lut := new_lookup(config)!

	// Set some values with gaps
	loc1 := Location{
		position: 1234
		file_nr: 0
	}
	lut.set(0, loc1)!
	loc2 := Location{
		position: 5678
		file_nr: 0
	}
	lut.set(50, loc2)! // Create a gap

	// Export and import sparse
	sparse_path := os.join_path(test_dir, 'sparse.lut')
	lut.export_sparse(sparse_path)!
	mut lut2 := new_lookup(config)!
	lut2.import_sparse(sparse_path)!

	// Verify values
	result1 := lut2.get(0)!
	assert result1.position == 1234
	assert result1.file_nr == 0
	result2 := lut2.get(50)!
	assert result2.position == 5678
	assert result2.file_nr == 0
}
