module publishing

import os
import freeflowuniverse.crystallib.core.pathlib { Path }
import freeflowuniverse.crystallib.osal
import freeflowuniverse.crystallib.data.doctree { Tree }
import freeflowuniverse.crystallib.web.mdbook

__global (
	publisher Publisher
)

pub struct Publisher {
pub mut:
	tree      Tree
	books     map[string]Book
	root_path string = os.join_path(os.home_dir(), 'hero/publisher')
}

// returns the directory of a given collecation
fn (p Publisher) collection_directory(name string) ?Path {
	mut cols_dir := p.collections_directory()
	return cols_dir.dir_get(name) or { return none }
}

pub fn (p Publisher) collections_directory() Path {
	collections_path := '${p.root_path}/collections'
	return pathlib.get_dir(path: collections_path) or { panic('this should never happen ${err}') }
}

pub fn (p Publisher) build_directory() Path {
	build_path := '${p.root_path}/build'
	return pathlib.get_dir(path: build_path) or { panic('this should never happen ${err}') }
}

pub fn (p Publisher) publish_directory() Path {
	publish_path := '${p.root_path}/publish'
	return pathlib.get_dir(path: publish_path) or { panic('this should never happen ${err}') }
}

@[params]
pub struct PublishParams {
	production bool
}

pub fn (p Publisher) publish(name string, params PublishParams) ! {
	if name !in p.books {
		return error('book ${name} doesnt exist')
	}
	p.books[name].publish(p.publish_directory().path, params)!
}

pub struct Book {
	name        string
	title       string
	description string
	path        string
}

pub fn (book Book) publish(path string, params PublishParams) ! {
	os.execute_opt('	
		cd ${book.path}
		mdbook build --dest-dir ${path}/${book.name}')!
}

pub struct NewBook {
	name         string
	title        string
	description  string
	summary_path string
	collections  []string
}

pub fn (p Publisher) new_book(book NewBook) ! {
	mut mdbooks := mdbook.get()!
	mut cfg := mdbooks.config()!
	cfg.path_build = p.build_directory().path
	cfg.path_publish = p.publish_directory().path

	mut col_paths := []string{}
	for col in book.collections {
		col_dir := p.collection_directory(col) or {
			return error('Collection ${col} not found in publisher tree')
		}
		col_paths << col_dir.path
	}

	_ := mdbooks.generate(
		name:         book.name
		title:        book.title
		summary_path: book.summary_path
		collections:  col_paths
	)!
	publisher.books[book.name] = Book{
		name:        book.name
		title:       book.title
		description: book.description
		path:        '${p.build_directory().path}/${book.name}'
	}
}

pub fn (book Book) print() {
	println('Book: ${book.name}\n- title: ${book.title}\n- description: ${book.description}\n- path: ${book.path}')
}

pub fn (p Publisher) open(name string) ! {
	p.publish(name)!
	book := p.books[name]
	cmd := 'open \'${p.publish_directory().path}/${name}/index.html\''
	osal.exec(cmd: cmd)!
}

pub fn (p Publisher) export_tree() ! {
	publisher.tree.export(destination: '${publisher.root_path}/collections')!
}

pub fn (p Publisher) list_books() ![]Book {
	return p.books.values()
}
