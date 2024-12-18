module ourdb

fn test_location_new_keysize_2() {
	mut lt := LookupTable{
		keysize: 2
	}

	// Test small number
	loc1 := lt.location_new([u8(0), 5])!
	assert loc1.file_nr == 0
	assert loc1.position == 5

	// Test medium number
	loc2 := lt.location_new([u8(1), 244])! // 500
	assert loc2.file_nr == 0
	assert loc2.position == 500

	// Test max allowed (0xFFFF = 65535)
	loc3 := lt.location_new([u8(255), 255])!
	assert loc3.file_nr == 0
	assert loc3.position == 65535

	// Test error cases
	if _ := lt.location_new([u8(1), 0, 0]) {
		assert false, 'should error on too many bytes'
	}
}

fn test_location_new_keysize_3() {
	mut lt := LookupTable{
		keysize: 3
	}

	// Test small number
	loc1 := lt.location_new([u8(0), 0, 5])!
	assert loc1.file_nr == 0
	assert loc1.position == 5

	// Test medium number
	loc2 := lt.location_new([u8(0), 1, 244])! // 500
	assert loc2.file_nr == 0
	assert loc2.position == 500

	// Test larger number
	loc3 := lt.location_new([u8(1), 0, 0])! // 65536
	assert loc3.file_nr == 0
	assert loc3.position == 65536

	// Test max allowed (0xFFFFFF = 16777215)
	loc4 := lt.location_new([u8(255), 255, 255])!
	assert loc4.file_nr == 0
	assert loc4.position == 16777215
}

fn test_location_new_keysize_4() {
	mut lt := LookupTable{
		keysize: 4
	}

	// Test small number
	loc1 := lt.location_new([u8(0), 0, 0, 5])!
	assert loc1.file_nr == 0
	assert loc1.position == 5

	// Test medium number
	loc2 := lt.location_new([u8(0), 0, 1, 244])! // 500
	assert loc2.file_nr == 0
	assert loc2.position == 500

	// Test larger number
	loc3 := lt.location_new([u8(0), 1, 0, 0])! // 65536
	assert loc3.file_nr == 0
	assert loc3.position == 65536

	// Test max value
	loc4 := lt.location_new([u8(255), 255, 255, 255])!
	assert loc4.file_nr == 0
	assert loc4.position == 0xFFFFFFFF
}

fn test_location_new_keysize_6() {
	mut lt := LookupTable{
		keysize: 6
	}

	// Test small numbers for both file_nr and position
	loc1 := lt.location_new([u8(0), 1, 0, 0, 0, 5])!
	assert loc1.file_nr == 1
	assert loc1.position == 5

	// Test medium numbers
	loc2 := lt.location_new([u8(0), 100, 0, 0, 1, 244])!
	assert loc2.file_nr == 100
	assert loc2.position == 500

	// Test max values
	loc3 := lt.location_new([u8(255), 255, 255, 255, 255, 255])!
	assert loc3.file_nr == 0xFFFF
	assert loc3.position == 0xFFFFFFFF
}

fn test_to_bytes() ! {
	// Test small numbers
	loc1 := Location{
		file_nr:  1
		position: 5
	}
	bytes1 := loc1.to_bytes()!
	assert bytes1 == [u8(0), 1, 0, 0, 0, 5]

	// Test medium numbers
	loc2 := Location{
		file_nr:  100
		position: 500
	}
	bytes2 := loc2.to_bytes()!
	assert bytes2 == [u8(0), 100, 0, 0, 1, 244]

	// Test max values
	loc3 := Location{
		file_nr:  0xFFFF
		position: 0xFFFFFFFF
	}
	bytes3 := loc3.to_bytes()!
	assert bytes3 == [u8(255), 255, 255, 255, 255, 255]
}

fn test_u64() ! {
	// Test small numbers
	loc1 := Location{
		file_nr:  1
		position: 5
	}
	val1 := loc1.u64()!
	assert val1 == (u64(1) << 32) | 5

	// Test medium numbers
	loc2 := Location{
		file_nr:  100
		position: 500
	}
	val2 := loc2.u64()!
	assert val2 == (u64(100) << 32) | 500

	// Test max values
	loc3 := Location{
		file_nr:  0xFFFF
		position: 0xFFFFFFFF
	}
	val3 := loc3.u64()!
	assert val3 == (u64(0xFFFF) << 32) | 0xFFFFFFFF
}

fn test_roundtrip() ! {
	mut lt := LookupTable{
		keysize: 6
	}

	// Test various combinations
	locations := [
		Location{0, 5},
		Location{1, 500},
		Location{100, 65536},
		Location{0xFFFF, 0xFFFFFFFF},
	]

	for original in locations {
		// Test to_bytes() -> location_new() roundtrip
		bytes := original.to_bytes()!
		reconstructed := lt.location_new(bytes)!
		assert reconstructed.file_nr == original.file_nr
		assert reconstructed.position == original.position

		// Test u64() conversion roundtrip
		u64_val := original.u64()!
		assert (u64_val >> 32) == original.file_nr
		assert (u64_val & 0xFFFFFFFF) == original.position
	}
}
