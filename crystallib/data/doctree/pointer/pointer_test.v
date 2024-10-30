module pointer

import freeflowuniverse.crystallib.ui.console

// import freeflowuniverse.crystallib.core.pathlib
// import freeflowuniverse.crystallib.core.texttools

// fn test_pointerpath() {
// 	p1 := pointerpath_new(path: '/tmp/A file.md') or { panic(err) }
// 	console.print_debug(p1)
// 	p1_compare := PointerPath{
// 		pointer: Pointer{
// 			collection: ''
// 			name: 'a_file'
// 			cat: .page
// 			extension: 'md'
// 			error: ''
// 			state: .unknown
// 		}
// 		path: pathlib.Path{
// 			path: '/tmp/A file.md'
// 			cat: .unknown
// 			exist: .no
// 		}
// 	}
// 	assert p1 == p1_compare

// 	p2 := pointerpath_new(path: '/tmp/ss/A__file.jpeg') or { panic(err) }
// 	p2_compare := PointerPath{
// 		pointer: Pointer{
// 			collection: ''
// 			name: 'a_file'
// 			cat: .image
// 			extension: 'jpeg'
// 			error: ''
// 			state: .unknown
// 		}
// 		path: pathlib.Path{
// 			path: '/tmp/A__file.jpeg'
// 			cat: .unknown
// 			exist: .no
// 		}
// 	}

// 	// assert p2==p2_compare
// }

fn test_pointer() {
	// p := pointer_new('Page__.md') or { panic(err) }
	// console.print_debug(p)
	// p_compare := Pointer{
	// 	collection: ''
	// 	name: 'page'
	// 	cat: .page
	// 	extension: 'md'
	// 	error: ''
	// 	state: .unknown
	// }
	// assert p == p_compare
}

// fn test_pointer2() {
// 	p := pointer_new('collectionAAA:Page__.md') or { panic(err) }
// 	console.print_debug(p)
// 	p_compare := Pointer{
// 		name: 'page'
// 		cat: .page
// 		extension: 'md'
// 		collection: 'collectionaaa'
// 		error: ''
// 		state: .unknown
// 	}
// 	assert p == p_compare
// }

// fn test_pointer3() {
// 	p := pointer_new('MY_Book:collection_AAA:Page__.md') or { panic(err) }
// 	console.print_debug(p)
// 	p_compare := Pointer{
// 		name: 'page'
// 		cat: .page
// 		extension: 'md'
// 		collection: 'collection_aaa'
// 		book: 'my_book'
// 		error: ''
// 		state: .unknown
// 	}
// 	assert p == p_compare
// }

// fn test_pointer4() {
// 	p := pointer_new('MY_Book:collection_AAA:aImage__.jpg') or { panic(err) }
// 	console.print_debug(p)
// 	p_compare := Pointer{
// 		name: 'aimage'
// 		cat: .image
// 		extension: 'jpg'
// 		collection: 'collection_aaa'
// 		book: 'my_book'
// 		error: ''
// 		state: .unknown
// 	}
// 	assert p == p_compare
// }

// fn test_pointer5() {
// 	p := pointer_new('MY_Book::aImage__.jpg') or { panic(err) }
// 	console.print_debug(p)
// 	p_compare := Pointer{
// 		name: 'aimage'
// 		cat: .image
// 		extension: 'jpg'
// 		collection: ''
// 		book: 'my_book'
// 		error: ''
// 		state: .unknown
// 	}
// 	assert p == p_compare
// }

// fn test_pointer6() {
// 	p := pointer_new('MY_Book::aImage__.jpg') or { panic(err) }
// 	assert p.str() == 'my_book::aimage.jpg'

// 	p2 := pointer_new('ddd:aImage__.jpg') or { panic(err) }
// 	assert p2.str() == 'ddd:aimage.jpg'

// 	p3 := pointer_new('aImage__.jpg') or { panic(err) }
// 	assert p3.str() == 'aimage.jpg'

// 	i := 40
// 	p4 := pointer_new('collectionAAA:Page__${i}.md') or { panic(err) }
// 	assert p4.str() == 'collectionaaa:page_40.md'
// }

// fn test_pointer7() {
// 	r := texttools.name_fix_keepext('page_40.md')
// 	assert r == 'page_40.md'
// }
