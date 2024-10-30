module doctree

import freeflowuniverse.crystallib.data.doctree.pointer

pub struct ObjNotFound {
	Error
pub:
	name       string
	collection string
	info       string
}

pub fn (err ObjNotFound) msg() string {
	return '"Could not find object with name ${err.name} in collection:${err.collection}.\n${err.info}'
}

pub struct CollectionNotFound {
	Error
pub:
	pointer pointer.Pointer
	msg     string
}

pub fn (err CollectionNotFound) msg() string {
	if err.msg.len > 0 {
		return err.msg
	}
	return '"Cannot find collection ${err.pointer} in tree.\n}'
}

// the next is our custom error for objects not found
pub struct NoOrTooManyObjFound {
	Error
pub:
	tree    &Tree
	pointer pointer.Pointer
	nr      int
}

pub fn (err NoOrTooManyObjFound) msg() string {
	if err.nr > 0 {
		return 'Too many obj found for ${err.tree.name}. Pointer: ${err.pointer}'
	}
	return 'No obj found for ${err.tree.name}. Pointer: ${err.pointer}'
}
