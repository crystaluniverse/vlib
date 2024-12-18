module paramsparser

import freeflowuniverse.crystallib.core.texttools
import json
import freeflowuniverse.crystallib.ui.console

const textin = "
	id:a1 name6:aaaaa
	name:'need to do something 1' 
	//comment
	description:'
		## markdown works in it

		description can be multiline
		lets see what happens

		- a
		- something else

		### subtitle

		```python
		#even code block in the other block, crazy parsing for sure
		def test():
			console.print_debug()
		```
		'

	name2:   test
	name3: hi name10:'this is with space'  name11:aaa11

	//some comment

	name4: 'aaa'

	//somecomment
	name5:   'aab' 
"

const textin2 = "
	//this is a cool piece of text
	//
	//now end of comment
	id:a1 name6:aaaaa
	name:'need to do something 1' 
	description:'something<BR>yes' //comment 1

	aa //arg comment
	bb
	name2:   test
	name3: hi name10:'this is with space'  name11:aaa11

	// some comment 2

	name4: 'aaa'

	name5:   'aab' //somecomment 3
"

const textin3 = '
	zz //comment 1
	id:a1 name6:aaaaa //comment 2
'

fn test_hexhash() {
	mut params := parse(textin2)!
	console.print_debug('${params}')
	h := params.hexhash()
	assert h == 'fca5c320391e7a91ec91999b1b3d66bf5cb7658905284c431777ff6d2fa4a4c3'
}

fn test_textin3() {
	params := parse(textin3) or { panic(err) }
	assert params == Params{
		params:   [
			Param{
				key:     'id'
				value:   'a1'
				comment: 'comment 2'
			},
			Param{
				key:     'name6'
				value:   'aaaaa'
				comment: ''
			},
		]
		args:     ['zz']
		comments: ['comment 1']
	}
}

fn test_macro_args() {
	mut text := "arg1 arg2 color:red priority:'incredible' description:'with spaces, lets see if ok'"
	params := parse(text) or { panic(err) }

	expexted_res := Params{
		params: [Param{
			key:   'color'
			value: 'red'
		}, Param{
			key:   'priority'
			value: 'incredible'
		}, Param{
			key:   'description'
			value: 'with spaces, lets see if ok'
		}]
		args:   ['arg1', 'arg2']
	}

	assert expexted_res == params

	mut text2 := "arg1 color:red priority:'incredible' arg2    description:'with spaces, lets see if ok'"
	params2 := parse(text2) or { panic(err) }

	assert expexted_res == params2
}

fn test_args_get() {
	mut text := "arg1  color:red priority:'2' description:'with spaces, lets see if ok' x:5 arg2"
	mut params := parse(text) or { panic(err) }

	assert params.exists_arg('arg1')
	assert params.exists_arg('arg2')
	assert !params.exists_arg('arg')

	mut x := params.get_int('x') or { panic(err) }
	assert x == 5
	x = params.get_int('y') or { 6 }
	assert x == 6
	x = params.get_int('priority') or { panic(err) }
	assert x == 2

	mut y := params.get('priority') or { panic(err) }
	assert y == '2'
}

fn test_url1() {
	mut text := "color:red url:'https://github.com/freeflowuniverse/crystallib/tree/development/examples/mdbook/books_to_include1'"
	mut params := parse(text) or { panic(err) }
	mut text2 := 'color:red url:"https://github.com/freeflowuniverse/crystallib/tree/development/examples/mdbook/books_to_include1 "'
	mut params2 := parse(text2) or { panic(err) }
	assert params.get('url')? == 'https://github.com/freeflowuniverse/crystallib/tree/development/examples/mdbook/books_to_include1'
	assert params2.get('url')? == 'https://github.com/freeflowuniverse/crystallib/tree/development/examples/mdbook/books_to_include1'
}

// // fn test_json() {

// // 	mut params := parse(textin) or { panic(err) }

// // 	d:=params.export_json()

// // 	mut params2 := json_import(d) or {panic(err)}

// // 	panic("ssss")

// // }

// fn test_export() {
// 	mut params := parse(textin)!

// 	d := params.export()

// 	mut out := "
// 	description:'## markdown works in it\\n\\ndescription can be multiline\\nlets see what happens\\n\\n- a\\n- something else\\n\\n### subtitle\\n\\n```python\\n#even code block in the other block, crazy parsing for sure\\ndef test():\\n    console.print_debug()\\n```'
// 	id:a1
// 	name:'need to do something 1'
// 	name10:'this is with space'
// 	name11:aaa11
// 	name2:test
// 	name3:hi
// 	name4:aaa
// 	name5:aab
// 	name6:aaaaa
// 	"
// 	assert texttools.dedent(d) == texttools.dedent(out).trim_space()
// }

// fn test_export2() {
// 	mut params := parse(textin2) or { panic(err) }

// 	d := params.export()

// 	mut out := "
// 	description:something\\nyes
// 	id:a1
// 	name:'need to do something 1'
// 	name10:'this is with space'
// 	name11:aaa11
// 	name2:test
// 	name3:hi
// 	name4:aaa
// 	name5:aab
// 	name6:aaaaa
// 	aa
// 	bb
// 	zz	
// 	"
// 	assert texttools.dedent(d) == texttools.dedent(out).trim_space()
// }

// fn test_import1() {
// 	mut params := parse(textin2) or { panic(err) }

// 	d := params.export()
// 	mut params2 := importparams(d) or { panic(err) }

// 	assert params.equal(params2)
// }

// fn test_import2() {
// 	mut params := parse(textin2) or { panic(err) }

// 	d := "
// 	id:a1
// 	zz
// 	name:'need to do something 1'
// 	name10:'this is with space'
// 	name11:aaa11
// 	name2:test
// 	name3:hi
// 	name4:aaa
// 	name5:aab
// 	name6:aaaaa
// 	aa
// 	bb
// 	description:something\\nyes

// 	"
// 	mut params2 := importparams(d)!

// 	assert params.equal(params2)
// }

// fn test_params_default_false() {
// 	mut params := parse('
// 	certified:false
// 	certified1:no
// 	certified2:n
// 	certified3:0
// 	')!

// 	assert params.get_default_false('certified') == false
// 	assert params.get_default_false('certified1') == false
// 	assert params.get_default_false('certified2') == false
// 	assert params.get_default_false('certified3') == false
// 	assert params.get_default_false('certified4') == false
// }

// fn test_params_default_true() {
// 	mut params := parse('
// 	certified:true
// 	certified1:yes
// 	certified2:y
// 	certified3:1
// 	')!

// 	assert params.get_default_true('certified') == true
// 	assert params.get_default_true('certified1') == true
// 	assert params.get_default_true('certified2') == true
// 	assert params.get_default_true('certified3') == true
// 	assert params.get_default_true('certified4') == true
// }

// fn test_kwargs_add() {
// 	mut params := parse(textin2) or { panic(err) }

// 	console.print_debug(params.params)

// 	assert params.params.len == 10

// 	params.set('name3', 'anotherhi')
// 	assert params.params.len == 10
// 	params.set('name7', 'anotherhi')
// 	assert params.params.len == 11 // because is new one

// 	assert params.get('name3') or { '' } == 'anotherhi'
// }

// fn test_args_add() {
// 	mut params := parse('urgency:yes red green') or { panic(err) }

// 	console.print_debug(params.args)

// 	assert params.params.len == 1
// 	assert params.args.len == 2

// 	params.set_arg('red')
// 	assert params.args.len == 2
// 	params.set_arg('yellow')
// 	assert params.args.len == 3
// }

// fn test_merge() {
// 	mut params := parse('urgency:yes red green') or { panic(err) }

// 	console.print_debug(params.args)

// 	params.merge('urgency:green blue') or { panic('s') }

// 	console.print_debug(params.args)

// 	assert params.params.len == 1
// 	assert params.args.len == 3

// 	assert params.get('urgency') or { '' } == 'green'
// }

// fn test_textin2() {
// 	params := parse(paramsparser.textin2) or { panic(err) }
// 	console.print_debug(params)
// 	assert params == Params{
// 		params: [
// 			Param{
// 				key: 'id'
// 				value: 'a1'
// 				comment: 'this is a cool piece of text

// now end of comment'
// 			},
// 			Param{
// 				key: 'name6'
// 				value: 'aaaaa'
// 				comment: ''
// 			},
// 			Param{
// 				key: 'name'
// 				value: 'need to do something 1'
// 				comment: ''
// 			},
// 			Param{
// 				key: 'description'
// 				value: 'something\\nyes'
// 				comment: 'comment 1'
// 			},
// 			Param{
// 				key: 'name2'
// 				value: 'test'
// 				comment: ''
// 			},
// 			Param{
// 				key: 'name3'
// 				value: 'hi'
// 				comment: ''
// 			},
// 			Param{
// 				key: 'name10'
// 				value: 'this is with space'
// 				comment: ''
// 			},
// 			Param{
// 				key: 'name11'
// 				value: 'aaa11'
// 				comment: ''
// 			},
// 			Param{
// 				key: 'name4'
// 				value: 'aaa'
// 				comment: 'some comment 2'
// 			},
// 			Param{
// 				key: 'name5'
// 				value: 'aab'
// 				comment: 'somecomment 3'
// 			},
// 		]
// 		args: ['aa', 'bb']
// 		comments: ['arg comment']
// 	}
// }
