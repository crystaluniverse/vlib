module ourdb

fn test_location_new_keysize_2() {
	lt := LookupTable{
		keysize: 2
	}
	// Test valid cases
	loc1 := lt.location_new([u8(0), 1])!
	assert loc1.position == 1
	assert loc1.file_nr == 0

	loc2 := lt.location_new([u8(255), 255])!
	assert loc2.position == 65535
	assert loc2.file_nr == 0

	// Test padding
	loc3 := lt.location_new([u8(1)])!
	assert loc3.position == 1

	// Test errors
	if _ := lt.location_new([u8(1), 1, 1]) {
		assert false, 'should fail on too many bytes'
	}
}

fn test_location_new_keysize_3() {
	lt := LookupTable{
		keysize: 3
	}
	// Test valid cases
	loc1 := lt.location_new([u8(0), 1, 1])!
	assert loc1.position == 257
	assert loc1.file_nr == 0

	loc2 := lt.location_new([u8(255), 255, 255])!
	assert loc2.position == 0xFFFFFF
	assert loc2.file_nr == 0

	// Test padding
	loc3 := lt.location_new([u8(0), 1])!
	assert loc3.position == 1

	// Test errors
	if _ := lt.location_new([u8(1), 1, 1, 1]) {
		assert false, 'should fail on too many bytes'
	}
}

fn test_location_new_keysize_4() {
	lt := LookupTable{
		keysize: 4
	}
	// Test valid cases
	loc1 := lt.location_new([u8(0), 0, 1, 1])!
	assert loc1.position == 257
	assert loc1.file_nr == 0

	loc2 := lt.location_new([u8(255), 255, 255, 255])!
	assert loc2.position == 0xFFFFFFFF
	assert loc2.file_nr == 0

	// Test padding
	loc3 := lt.location_new([u8(0), 0, 1])!
	assert loc3.position == 1

	// Test errors
	if _ := lt.location_new([u8(1), 1, 1, 1, 1]) {
		assert false, 'should fail on too many bytes'
	}
}

fn test_location_new_keysize_6() {
	lt := LookupTable{
		keysize: 6
	}
	// Test valid cases
	loc1 := lt.location_new([u8(0), 1, 0, 0, 1, 1])!
	assert loc1.file_nr == 1
	assert loc1.position == 257

	loc2 := lt.location_new([u8(255), 255, 255, 255, 255, 255])!
	assert loc2.file_nr == 0xFFFF
	assert loc2.position == 0xFFFFFFFF

	// Test padding
	loc3 := lt.location_new([u8(0), 1, 0, 0, 1])!
	assert loc3.file_nr == 0
	assert loc3.position == (1 << 24) + 1

	// Test errors
	if _ := lt.location_new([u8(1), 1, 1, 1, 1, 1, 1]) {
		assert false, 'should fail on too many bytes'
	}
}

fn test_invalid_keysize() {
	// Test invalid keysizes
	invalid_sizes := [u8(0), 1, 5, 7, 8]
	for size in invalid_sizes {
		lt := LookupTable{
			keysize: size
		}
		if _ := lt.location_new([u8(0)]) {
			assert false, 'should fail on invalid keysize ${size}'
		}
	}
}

fn test_to_bytes() {
	// Test keysize 2
	lt2 := LookupTable{
		keysize: 2
	}
	loc1 := lt2.location_new([u8(1), 1])!
	bytes1 := loc1.to_bytes()!
	assert bytes1 == [u8(0), 0, 0, 0, 1, 1]

	// Test keysize 3
	lt3 := LookupTable{
		keysize: 3
	}
	loc2 := lt3.location_new([u8(1), 1, 1])!
	bytes2 := loc2.to_bytes()!
	assert bytes2 == [u8(0), 0, 0, 1, 1, 1]

	// Test keysize 4
	lt4 := LookupTable{
		keysize: 4
	}
	loc3 := lt4.location_new([u8(1), 1, 1, 1])!
	bytes3 := loc3.to_bytes()!
	assert bytes3 == [u8(0), 0, 1, 1, 1, 1]

	// Test keysize 6
	lt6 := LookupTable{
		keysize: 6
	}
	loc4 := lt6.location_new([u8(1), 1, 1, 1, 1, 1])!
	bytes4 := loc4.to_bytes()!
	assert bytes4 == [u8(1), 1, 1, 1, 1, 1]
}

fn test_u64() {
	// Test keysize 2
	lt2 := LookupTable{
		keysize: 2
	}
	loc1 := lt2.location_new([u8(1), 1])!
	val1 := loc1.u64()!
	assert val1 == 257

	// Test keysize 6 with file_nr
	lt6 := LookupTable{
		keysize: 6
	}
	loc2 := lt6.location_new([u8(0), 1, 0, 0, 1, 1])!
	val2 := loc2.u64()!
	assert val2 == (u64(1) << 32) | 257
}
