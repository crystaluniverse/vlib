module data

import freeflowuniverse.crystallib.core.pathlib
import freeflowuniverse.crystallib.data.markdownparser.elements { Action, Doc, Element }
import freeflowuniverse.crystallib.data.markdownparser

pub enum PageStatus {
	unknown
	ok
	error
}

@[heap]
pub struct Page {
mut:
	doc           &Doc            @[str: skip]
	element_cache map[int]Element
	changed       bool
pub mut:
	name            string // received a name fix
	alias           string // a proper name for e.g. def
	path            pathlib.Path
	collection_name string
}

@[params]
pub struct NewPageArgs {
pub:
	name            string       @[required]
	path            pathlib.Path @[required]
	collection_name string       @[required]
}

pub fn new_page(args NewPageArgs) !Page {
	if args.collection_name == '' {
		return error('page collection name must not be empty')
	}

	if args.name == '' {
		return error('page name must not be empty')
	}

	mut doc := markdownparser.new(path: args.path.path, collection_name: args.collection_name)!
	children := doc.children_recursive()
	mut element_cache := map[int]Element{}
	for child in children {
		element_cache[child.id] = child
	}

	mut new_page := Page{
		element_cache: element_cache
		name: args.name
		path: args.path
		collection_name: args.collection_name
		doc: &doc
	}

	return new_page
}

// return doc, reparse if needed
fn (mut page Page) doc() !&Doc {
	if page.changed {
		content := page.doc.markdown()!
		page.reparse_doc(content)!
	}

	return page.doc
}

// reparse doc markdown and assign new doc to page
fn (mut page Page) reparse_doc(content string) ! {
	doc := markdownparser.new(content: content, collection_name: page.collection_name)!
	page.element_cache = map[int]Element{}
	for child in doc.children_recursive() {
		page.element_cache[child.id] = child
	}

	page.doc = &doc
	page.changed = false
}

pub fn (page Page) key() string {
	return '${page.collection_name}:${page.name}'
}

pub fn (mut page Page) get_linked_pages() ![]string {
	doc := page.doc()!
	return doc.linked_pages
}

pub fn (mut page Page) get_markdown() !string {
	mut doc := page.doc()!
	return doc.markdown()!
}

pub fn (mut page Page) set_content(content string) ! {
	page.reparse_doc(content)!
}

fn (mut page Page) get_element(element_id int) !Element {
	return page.element_cache[element_id] or {
		return error('no element found with id ${element_id}')
	}
}

// TODO: this should not be allowed (giving access to modify page content to any caller)
pub fn (mut page Page) get_all_actions() ![]&Action {
	mut actions := []&Action{}
	mut doc := page.doc()!
	for element in doc.children_recursive() {
		if element is Action {
			actions << element
		}
	}

	return actions
}

pub fn (mut page Page) get_include_actions() ![]Action {
	mut actions := []Action{}
	mut doc := page.doc()!
	for element in doc.children_recursive() {
		if element is Action {
			if element.action.actor == 'wiki' && element.action.name == 'include' {
				actions << *element
			}
		}
	}

	return actions
}

pub fn (mut page Page) set_action_element_to_processed(element_id int) ! {
	mut element := page.element_cache[element_id] or {
		return error('page ${page.path} doc has no element with id ${element_id}')
	}

	if mut element is Action {
		element.action_processed = true
		page.changed = true
		return
	}

	return error('element with id ${element_id} is not an action')
}

pub fn (mut page Page) set_element_content_no_reparse(element_id int, content string) ! {
	mut element := page.element_cache[element_id] or {
		return error('page ${page.path} doc has no element with id ${element_id}')
	}

	element.content = content
	page.changed = true
}
