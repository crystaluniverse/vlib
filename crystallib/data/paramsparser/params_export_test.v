module paramsparser

import crypto.sha256
import freeflowuniverse.crystallib.ui.console

const textin5 = "
	//this is first comment (line1)
	//this is 2nd comment (line2)
	red green blue
	id:a5 name6:aaaaa //comment_line2
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
			print()
		```
	'
	name2:   test
	name3: hi name10:'this is with space'  name11:aaa11

	name4: 'aaa'

	//somecomment
	name5:   'aab' 
"

fn test_export_helper1() {
	params := parse(textin5) or { panic(err) }

	// presort []string
	// args_allowed bool=true
	// maxcolsize int = 80
	// oneline bool //if set then will put all on oneline
	// multiline bool = true //if we will put the multiline strings as multiline in output
	// indent string
	o := params.export_helper(maxcolsize: 600) or { panic(err) }
	// console.print_debug('${o}')
	assert o.len == 14
	// console.print_debug(o.len)
	assert o[o.len - 1].firstline == false
	// console.print_debug(o[o.len - 2])
	assert o[o.len - 2].firstline == false
	assert o[o.len - 1].key == 'name5'
	// assert o[o.len - 2].key == 'name6'
	assert o[0].comment.len > 0
	assert o[0].key == ''
	assert o[0].value == ''
	assert sha256.hexhash(o.str()) == '3b3f7830145d5d1dfb01aea879ad052350f2ec4e921c2ee6cbfacbb0f1029ebd'
}

fn test_export_helper2() {
	params := parse(textin5) or { panic(err) }
	o := params.export_helper(maxcolsize: 60) or { panic(err) }

	assert sha256.hexhash(o.str()) == '0bb7fb65107a69b1a0296dbdd1b0505b178e8bebdb33d2cec307f411b05c6033'
}

const textin6 = "
	//mycomment
	red blue
	id:a6 name6:aaaaa 

	name4: 'a aa' //comment_line2

	//somecomment
	name5:   'aab' 
"

fn test_export_6() {
	params := parse(textin6) or { panic(err) }
	o := params.export_helper(maxcolsize: 60) or { panic(err) }

	paramsout := params.export()

	console.print_debug(paramsout)

	console.print_debug("EXPECT:
	// mycomment
	blue red id:a6 name6:aaaaa
	name4:'a aa' //comment_line2
	name5:aab //somecomment	
	")

	assert sha256.hexhash(paramsout) == '7b45308e1b5e729e78c8b9b12cda6cd6da4919005a7d54ecc45f07a2d26c304b'
}

const textin7 = "
	//mycomment
	red blue
	id:a7 name6:aaaaa 

	name4: '
		multiline1
			in

		multiline2
		'

	//somecomment
	name5:   'aab' 
"

fn test_export_7() {
	params := parse(textin7) or { panic(err) }
	o := params.export_helper(maxcolsize: 60) or { panic(err) }
	console.print_debug('${o}')

	paramsout := params.export()

	console.print_debug("EXPECT:
	// mycomment
	blue red id:a7 name6:aaaaa
	name4:'
			multiline1
					in

			multiline2
			'
	name5:aab //somecomment
	")

	console.print_debug(paramsout)

	assert sha256.hexhash(paramsout) == '0407be8ca3abb9214e3579c40ae1b02297cf05bf50ae687ea6b2b57bb8c5a54e'
}

const textin8 = "
	//mycomment
	red blue
	id:a8 name6:aaaaa 

	name4: '
		multiline1
			in

		multiline2
		'

	//somecomment
	//
	//multiline
	name5:   'aab' 
"

fn test_export_8() {
	params := parse(textin8) or { panic(err) }
	o := params.export_helper(maxcolsize: 60) or { panic(err) }
	console.print_debug('${o}')

	paramsout := params.export()

	console.print_debug(paramsout)

	console.print_debug("EXPECT:
	// mycomment
	blue red id:a8 name6:aaaaa
	name4:'
		multiline1
			in

		multiline2
		'
	// somecomment
	//
	// multiline
	name5:aab	
	")

	assert sha256.hexhash(paramsout) == 'ed1188df660ab6c69ea5cb967df86e7f356b513045c66e8ebb109763f3110ea2'
}

const textin9 = "
	//mycomment
	red blue
	id:a9 name6:aaaaa 

	name4: '
		multiline1
			in

		multiline2
		'

	//somecomment
	//
	//multiline
	name5:   'aab' 
"

fn test_export_9() {
	params := parse(textin9) or { panic(err) }
	o := params.export_helper(oneline: true) or { panic(err) }
	console.print_debug('${o}')

	console.print_debug("EXPECT:
	// mycomment
	!!remark.define blue red id:a9 name6:aaaaa
	name4:'
		multiline1
			in

		multiline2
		'
	// somecomment
	//
	// multiline
	name5:aab	
	")

	paramsout := params.export(oneline: true)

	console.print_debug(paramsout)

	assert sha256.hexhash(paramsout) == '811bef1e55b3b4b1b725e1a7514b092526c8fdef8dddf6ad15f9d1ca49c3eb51'
}

const textin10 = "
	//mycomment
	red blue
	id:a10 name6:aaaaa 

	name4: '
		multiline1
			in

		multiline2
		'

	//somecomment
	//
	//multiline
	name5:   'aab' 
"

fn test_export_10() {
	params := parse(textin10) or { panic(err) }
	o := params.export_helper(oneline: false, pre: '!!remark.define') or { panic(err) }
	console.print_debug('${o}')

	paramsout := params.export(oneline: false, pre: '!!remark.define')

	console.print_debug(paramsout)

	// WE EXPECT

	console.print_debug("EXPECT:
	// mycomment
	!!remark.define blue red id:a10 name6:aaaaa
	name4:'
		multiline1
			in

		multiline2
		'
	// somecomment
	//
	// multiline
	name5:aab	
	")

	assert sha256.hexhash(paramsout) == 'bf583f6b9afe84476eb3ade1bdd60ba4a6f1196d95a6e7d0fbe6f8b9fb5779d2'
}

fn test_export_list() {
	params := parse("list0: 'Kiwi'\nlist1: 'Apple', 'Banana'") or { panic(err) }
	paramsout := params.export()
	assert paramsout.trim_space() == 'list0:Kiwi list1:Apple,Banana'
}

fn test_export_text() {
	params := Params{
		params: [
			Param{
				key:   'text'
				value: "This content contains the character ' in it"
			},
		]
	}
	paramsout := params.export()
	assert paramsout.trim_space() == "text:'This content contains the character \\' in it'"
}
