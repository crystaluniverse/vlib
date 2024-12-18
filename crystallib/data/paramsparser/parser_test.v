module paramsparser

fn test_parse_list() ! {
	mut params := parse("list0: 'Apple'")!

	// Test parsing lists with single string item
	mut fruit_list := [
		"list0: 'Apple'",
		'list1: Apple',
		'list2:Apple',
		'list3:  Apple ',
	]

	for i, param in fruit_list {
		params = parse(param)!
		assert params == Params{
			params:   [
				Param{
					key:     'list${i}'
					value:   'Apple'
					comment: ''
				},
			]
			args:     []
			comments: []
		}
	}

	// Test parsing lists with multiple string items
	fruit_list = [
		'list0: Apple, Banana',
		'list1: Apple ,Banana',
		'list2: Apple , Banana',
		'list3: Apple  ,  Banana',
		"list4: 'Apple', Banana",
		"list5: Apple, 'Banana'",
		"list6: 'Apple', 'Banana'",
	]

	for i, param in fruit_list {
		params = parse(param)!
		assert params == Params{
			params:   [
				Param{
					key:     'list${i}'
					value:   'Apple,Banana'
					comment: ''
				},
			]
			args:     []
			comments: []
		}
	}

	// Test parsing lists with multi-word items
	fruit_list = [
		'list0: Apple, "Dragon Fruit", "Passion Fruit"',
		'list1: "Apple", "Dragon Fruit", "Passion Fruit"',
		"list2: Apple, 'Dragon Fruit', 'Passion Fruit'",
		"list3: 'Apple', 'Dragon Fruit', 'Passion Fruit'",
	]

	for i, param in fruit_list {
		params = parse(param)!
		assert params == Params{
			params:   [
				Param{
					key:     'list${i}'
					value:   'Apple,"Dragon Fruit","Passion Fruit"'
					comment: ''
				},
			]
			args:     []
			comments: []
		}
	}

	// // test parsing lists in square brackets
	// params = parse("list1: ['Kiwi']")!
	// assert params == Params{
	// 	params: [Param{
	// 		key: 'list1'
	// 		value: "['Kiwi']"
	// 		comment: ''
	// 	}]
	// 	args: []
	// 	comments: []
	// }
	// params = parse("list2: 'Apple', 'Banana'")!
	// assert params == Params{
	// 	params: [
	// 		Param{
	// 			key: 'list2'
	// 			value: "['Apple', 'Banana']"
	// 			comment: ''
	// 		},
	// 	]
	// 	args: []
	// 	comments: []
	// }
}
