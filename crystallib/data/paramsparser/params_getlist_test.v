module paramsparser

fn test_get_list_single_quotes() {
	testparams := Params{
		params: [
			Param{
				key:   'mylist'
				value: 'A,A,A,A'
			},
		]
	}
	list := testparams.get_list('mylist')!
	assert list == ['A', 'A', 'A', 'A']
}

fn test_get_list_smallstr() {
	testparams := Params{
		params: [
			Param{
				key:   'mylist'
				value: 'a'
			},
		]
	}
	list := testparams.get_list('mylist') or { panic(err) }
	assert list == ['a']
	// if true{panic("sdsdsdsdsdsdsdsd")}
}

fn test_get_list_smallstr2() {
	testparams := Params{
		params: [
			Param{
				key:   'mylist'
				value: 'a,b,dddeegggdf ,e'
			},
		]
	}
	list := testparams.get_list('mylist') or { panic(err) }
	assert list == ['a', 'b', 'dddeegggdf', 'e']
}

fn test_get_list_double_quotes() {
	testparams := Params{
		params: [
			Param{
				key:   'mylist'
				value: '["A","A","A","A"]'
			},
		]
	}
	list := testparams.get_list('mylist')!
	assert list == ['A', 'A', 'A', 'A']
}

fn test_get_list_single_and_double_quotes() {
	testparams := Params{
		params: [
			Param{
				key:   'mylist'
				value: '["A","A",\'A\',"A"]'
			},
		]
	}
	list := testparams.get_list('mylist')!
	assert list == ['A', 'A', 'A', 'A']
}

fn test_get_list_double_quote_inside_single() {
	testparams := Params{
		params: [
			Param{
				key:   'mylist'
				value: '["A",\'"A"\',"A","A"]'
			},
		]
	}
	list := testparams.get_list('mylist')!
	assert list == ['A', 'A', 'A', 'A']
}

// we need to be more defensive this succeeds
// fn test_get_list_invalid() {
// 	testparams := Params{
// 		params: [
// 			Param{
// 				key: 'mylist'
// 				value: '["A,"A","A","A"]'
// 			},
// 		]
// 	}
// 	list := testparams.get_list('mylist') or { return }
// 	assert false, 'expected get_list to throw an error'
// }

fn test_get_list_u8() {
	testparams := Params{
		params: [
			Param{
				key:   'mylist'
				value: '1, 5, 7, 2'
			},
		]
	}
	list := testparams.get_list_u8('mylist')!
	assert list == [u8(1), u8(5), u8(7), u8(2)]
}

fn test_get_list_u8_default() {
	testparams := Params{
		params: []
	}
	list := testparams.get_list_u8_default('mylist', []u8{})
	assert list == []u8{}
}

fn test_get_list_u16() {
	testparams := Params{
		params: [
			Param{
				key:   'mylist'
				value: '1, 5, 7, 2'
			},
		]
	}
	list := testparams.get_list_u16('mylist')!
	assert list == [u16(1), u16(5), u16(7), u16(2)]
}

fn test_get_list_u16_default() {
	testparams := Params{
		params: []
	}
	list := testparams.get_list_u16_default('mylist', []u16{})
	assert list == []u16{}
}

fn test_get_list_u32() {
	testparams := Params{
		params: [
			Param{
				key:   'mylist'
				value: '1, 5, 7, 15148'
			},
		]
	}
	list := testparams.get_list_u32('mylist')!
	assert list == [u32(1), u32(5), u32(7), u32(15148)]
}

fn test_get_list_u32_default() {
	testparams := Params{
		params: []
	}
	list := testparams.get_list_u32_default('mylist', []u32{})
	assert list == []u32{}
}

fn test_get_list_u64() {
	testparams := Params{
		params: [
			Param{
				key:   'mylist'
				value: '1, 5, 7, 15148'
			},
		]
	}
	list := testparams.get_list_u64('mylist')!
	assert list == [u64(1), u64(5), u64(7), u64(15148)]
}

fn test_get_list_u64_default() {
	testparams := Params{
		params: []
	}
	list := testparams.get_list_u64_default('mylist', []u64{})
	assert list == []u64{}
}

fn test_get_list_i8() {
	testparams := Params{
		params: [
			Param{
				key:   'mylist'
				value: '1, -5, 10, -2'
			},
		]
	}
	list := testparams.get_list_i8('mylist')!
	assert list == [i8(1), i8(-5), i8(10), i8(-2)]
}

fn test_get_list_i8_default() {
	testparams := Params{
		params: []
	}
	list := testparams.get_list_i8_default('mylist', []i8{})
	assert list == []i8{}
}

fn test_get_list_i16() {
	testparams := Params{
		params: [
			Param{
				key:   'mylist'
				value: '1, -25, 165, -148'
			},
		]
	}
	list := testparams.get_list_i16('mylist')!
	assert list == [i16(1), i16(-25), i16(165), i16(-148)]
}

fn test_get_list_i16_default() {
	testparams := Params{
		params: []
	}
	list := testparams.get_list_i16_default('mylist', []i16{})
	assert list == []i16{}
}

fn test_get_list_int() {
	testparams := Params{
		params: [
			Param{
				key:   'mylist'
				value: '1, -25, 165, -1484984'
			},
		]
	}
	list := testparams.get_list_int('mylist')!
	assert list == [1, -25, 165, -1484984]
}

fn test_get_list_int_default() {
	testparams := Params{
		params: []
	}
	list := testparams.get_list_int_default('mylist', []int{})
	assert list == []int{}
}

fn test_get_list_i64() {
	testparams := Params{
		params: [
			Param{
				key:   'mylist'
				value: '1, -25, 165, -148'
			},
		]
	}
	list := testparams.get_list_i64('mylist')!
	assert list == [i64(1), i64(-25), i64(165), i64(-148)]
}

fn test_get_list_i64_default() {
	testparams := Params{
		params: []
	}
	list := testparams.get_list_i64_default('mylist', []i64{})
	assert list == []i64{}
}

fn test_get_list_f32() {
	testparams := Params{
		params: [
			Param{
				key:   'mylist'
				value: '1.5, 5.78, 7.478, 15148.4654'
			},
		]
	}
	list := testparams.get_list_f32('mylist')!
	assert list == [f32(1.5), f32(5.78), f32(7.478), f32(15148.4654)]
}

fn test_get_list_f32_default() {
	testparams := Params{
		params: []
	}
	list := testparams.get_list_f32_default('mylist', []f32{})
	assert list == []f32{}
}

fn test_get_list_f64() {
	testparams := Params{
		params: [
			Param{
				key:   'mylist'
				value: '1.5, 5.78, 7.478, 15148.4654'
			},
		]
	}
	list := testparams.get_list_f64('mylist')!
	assert list == [1.5, 5.78, 7.478, 15148.4654]
}

fn test_get_list_f64_default() {
	testparams := Params{
		params: []
	}
	list := testparams.get_list_f64_default('mylist', []f64{})
	assert list == []f64{}
}
