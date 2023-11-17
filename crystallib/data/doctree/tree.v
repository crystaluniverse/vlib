module doctree

import log
import v.embed_file
// import freeflowuniverse.crystallib.baobab.context
import freeflowuniverse.crystallib.baobab.smartid

[heap]
pub struct Tree {
pub:
	name string
pub mut:
	logger &log.Logger [skip; str: skip] = &log.Log{
	level: .info
}
	collections     map[string]&Collection
	embedded_files  []embed_file.EmbedFileData // this where we have the templates for exporting a book
	state           TreeState
	macroprocessors []IMacroProcessor
	// spawner         &spawner.Spawner
	// context context.Context
	cid smartid.CID
}

pub enum TreeState {
	init
	ok
	error
}

// pub fn (mut tree Tree) reset() ! {
// 	// tree.collections = map[string]
// }

// add macroprocessor to the tree
// see interface IMacroProcessor for how macroprocessor needs to be implemented
pub fn (mut tree Tree) macroprocessor_add(mp IMacroProcessor) ! {
	tree.macroprocessors << mp
}

// fix all loaded tree
pub fn (mut tree Tree) fix() ! {
	if tree.state == .ok {
		return
	}
	for _, mut collection in tree.collections {
		collection.fix()!
	}
}

// the next is our custom error for objects not found
pub struct NoOrTooManyObjFound {
	Error
pub:
	tree    &Tree
	pointer Pointer
	nr      int
}

pub fn (err NoOrTooManyObjFound) msg() string {
	if err.nr > 0 {
		return 'Too many obj found for ${err.tree.name}. Pointer: ${err.pointer}'
	}
	return 'No obj found for ${err.tree.name}. Pointer: ${err.pointer}'
}

// get the page from pointer string: $tree:$collection:$name or
// $collection:$name or $name
pub fn (tree Tree) page_get(pointerstr string) !&Page {
	p := pointer_new(pointerstr)!
	mut res := []&Page{}
	for _, collection in tree.collections {
		if p.collection == '' || p.collection == collection.name {
			if collection.page_exists(pointerstr) {
				res << collection.page_get(pointerstr) or { panic('BUG') }
			}
		}
	}
	if res.len == 1 {
		return res[0]
	} else {
		return NoOrTooManyObjFound{
			tree: &tree
			pointer: p
			nr: res.len
		}
	}
}

// get the page from pointer string: $tree:$collection:$name or
// $collection:$name or $name
pub fn (tree Tree) image_get(pointerstr string) !&File {
	p := pointer_new(pointerstr)!
	// println("collection:'$p.collection' name:'$p.name'")
	mut res := []&File{}
	for _, collection in tree.collections {
		// println(collection.name)
		if p.collection == '' || p.collection == collection.name {
			// println("in collection")
			if collection.image_exists(pointerstr) {
				res << collection.image_get(pointerstr) or { panic('BUG') }
			}
		}
	}
	if res.len == 1 {
		return res[0]
	} else {
		return NoOrTooManyObjFound{
			tree: &tree
			pointer: p
			nr: res.len
		}
	}
}

// get the file from pointer string: $tree:$collection:$name or
// $collection:$name or $name
pub fn (mut tree Tree) file_get(pointerstr string) !&File {
	p := pointer_new(pointerstr)!
	mut res := []&File{}
	for _, collection in tree.collections {
		if p.collection == '' || p.collection == collection.name {
			if collection.file_exists(pointerstr) {
				res << collection.file_get(pointerstr) or { panic('BUG') }
			}
		}
	}
	if res.len == 1 {
		return res[0]
	} else {
		return NoOrTooManyObjFound{
			tree: &tree
			pointer: p
			nr: res.len
		}
	}
}

// exists or too many
pub fn (mut tree Tree) page_exists(name string) bool {
	_ := tree.page_get(name) or {
		if err is CollectionNotFound || err is CollectionObjNotFound || err is NoOrTooManyObjFound {
			return false
		} else {
			panic(err)
		}
	}
	return true
}

// exists or too many
pub fn (mut tree Tree) image_exists(name string) bool {
	_ := tree.image_get(name) or {
		if err is CollectionNotFound || err is CollectionObjNotFound || err is NoOrTooManyObjFound {
			return false
		} else {
			panic(err)
		}
	}
	return true
}

// exists or too many
pub fn (mut tree Tree) file_exists(name string) bool {
	_ := tree.file_get(name) or {
		if err is CollectionNotFound || err is CollectionObjNotFound || err is NoOrTooManyObjFound {
			return false
		} else {
			panic(err)
		}
	}
	return true
}