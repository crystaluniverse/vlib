module paramsparser

import time

struct TestStruct {
	name     string
	nick     ?string
	birthday time.Time
	number   int
	yesno    bool
	liststr  []string
	listint  []int
	listbool []bool
	child    TestChild
}

struct TestChild {
	child_name     string
	child_number   int
	child_yesno    bool
	child_liststr  []string
	child_listint  []int
	child_listbool []bool
}

const test_child = TestChild{
	child_name:    'test_child'
	child_number:  3
	child_yesno:   false
	child_liststr: ['three', 'four']
	child_listint: [3, 4]
}

const test_struct = TestStruct{
	name:     'test'
	nick:     'test_nick'
	birthday: time.new(
		day:   12
		month: 12
		year:  2012
	)
	number:   2
	yesno:    true
	liststr:  ['one', 'two']
	listint:  [1, 2]
	child:    test_child
}

const test_child_params = Params{
	params: [
		Param{
			key:   'child_name'
			value: 'test_child'
		},
		Param{
			key:   'child_number'
			value: '3'
		},
		Param{
			key:   'child_yesno'
			value: 'false'
		},
		Param{
			key:   'child_liststr'
			value: 'three,four'
		},
		Param{
			key:   'child_listint'
			value: '3,4'
		},
	]
}

const test_params = Params{
	params: [Param{
		key:   'name'
		value: 'test'
	}, Param{
		key:   'nick'
		value: 'test_nick'
	}, Param{
		key:   'birthday'
		value: '2012-12-12 00:00:00'
	}, Param{
		key:   'number'
		value: '2'
	}, Param{
		key:   'yesno'
		value: 'true'
	}, Param{
		key:   'liststr'
		value: 'one,two'
	}, Param{
		key:   'listint'
		value: '1,2'
	}, Param{
		key:   'child'
		value: test_child_params.export()
	}]
}

fn test_decode() {
	// test single level struct
	decoded_child := test_child_params.decode[TestChild]()!
	assert decoded_child == test_child

	// test recursive decode struct with child
	decoded := test_params.decode[TestStruct]()!
	assert decoded == test_struct
}

fn test_encode() {
	// test single level struct
	encoded_child := encode[TestChild](test_child)!
	assert encoded_child == test_child_params
}
