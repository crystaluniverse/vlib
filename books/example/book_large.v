module main

import freeflowuniverse.crystallib.books

const path = '~/code/github/threefoldfoundation/books'

fn do() ? {
	mut sites := books.sites_new()
	sites.scan(path + '/content')?

	mut books := books.books_new(&sites)
	books.scan(path + '/books')?

	// println(sites.sites["ppp"])

	books.mdbook_export()?
}

fn main() {
	println('ERROR IN MAIN')
	do() or { panic(err) }
}

// git reset --hard && git clean -fxd
