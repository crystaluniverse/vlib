module knowledgetree

import freeflowuniverse.crystallib.texttools

// FIND METHODS ON TREE

pub struct BookNotFound {
	Error
pub:
	bookname string
	tree     &Tree
	msg      string
}

pub fn (tree Tree) booknames() []string {
	mut res := []string{}
	for _, book in tree.books {
		res << book.name
	}
	res.sort()
	return res
}

pub fn (err BookNotFound) msg() string {
	booknames := err.tree.booknames().join('\n- ')
	if err.msg.len > 0 {
		return err.msg
	}
	return "Cannot not find book:'${err.bookname}'.\nKnown books:\n${booknames}"
}

pub fn (tree Tree) book_get(name string) !&MDBook {
	if name.contains(':') {
		return BookNotFound{
			tree: &tree
			msg: 'bookname cannot have : inside'
			bookname: name
		}
	}
	namelower := texttools.name_fix_no_underscore_no_ext(name)
	if namelower == '' {
		return BookNotFound{
			tree: &tree
			msg: 'book needs to be specified, now empty.'
		}
	}
	return tree.books[namelower] or { return BookNotFound{
		tree: &tree
		bookname: name
	} }
}

pub fn (tree Tree) book_exists(name string) bool {
	_ := tree.book_get(name) or {
		if err is BookNotFound {
			return false
		} else {
			panic(err) // catch unforseen errors
		}
	}
	return true
}
