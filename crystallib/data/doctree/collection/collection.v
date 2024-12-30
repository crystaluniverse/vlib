module collection

import freeflowuniverse.crystallib.core.pathlib { Path }
import freeflowuniverse.crystallib.data.doctree.collection.data
import freeflowuniverse.crystallib.core.texttools

@[heap]
pub struct Collection {
pub mut:
	name          string @[required]
	path          Path   @[required]
	fail_on_error bool
	heal          bool = true
	pages         map[string]&data.Page
	files         map[string]&data.File
	images        map[string]&data.File
	errors        []CollectionError
}

@[params]
pub struct CollectionNewArgs {
pub mut:
	name          string @[required]
	path          string @[required]
	heal          bool = true // healing means we fix images, if selected will automatically load, remove stale links
	load          bool = true
	fail_on_error bool
}

// get a new collection
pub fn new(args_ CollectionNewArgs) !Collection {
	mut args := args_
	args.name = texttools.name_fix(args.name)

	mut pp := pathlib.get_dir(path: args.path)! // will raise error if path doesn't exist
	mut collection := Collection{
		name:          args.name
		path:          pp
		heal:          args.heal
		fail_on_error: args.fail_on_error
	}

	if args.load {
		collection.scan() or { return error('Error scanning collection ${args.name}:\n${err}') }
	}

	return collection
}

fn (c Collection) get_linked_pages() ![]string {
	mut linked_pages_set := map[string]bool{}
	for _, page in c.pages {
		for linked_page in page.get_linked_pages()! {
			linked_pages_set[linked_page] = true
		}
	}

	return linked_pages_set.keys()
}
