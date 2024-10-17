module doctree3

import freeflowuniverse.crystallib.core.pathlib
import freeflowuniverse.crystallib.data.paramsparser
import freeflowuniverse.crystallib.develop.gittools
import os

@[params]
pub struct TreeScannerArgs {
pub mut:
	path      string
	heal      bool = true // healing means we fix images
	git_url   string
	git_reset bool
	git_root  string
	git_pull  bool
	load      bool = true // means we scan automatically the added collection
}

// walk over directory find dirs with .book or .collection inside and add to the tree .
// a path will not be added unless .collection is in the path of a collection dir or .book in a book
// ```
//	path string
//	heal bool // healing means we fix images, if selected will automatically load, remove stale links
//	git_url   string
//	git_reset bool
//	git_root  string
//	git_pull  bool
// ```	
pub fn (mut tree Tree) scan(args_ TreeScannerArgs) ! {
	mut args := args_
	if args.git_url.len > 0 {
		args.path = gittools.code_get(
			coderoot: args.git_root
			url: args.git_url
			pull: args.git_pull
			reset: args.git_reset
			reload: false
		)!
	}

	// TODO: why < 3?
	if args.path.len == 0 {
		return error('Path needs to be provided.')
	}

	mut path := pathlib.get_dir(path: args.path)!
	if !path.is_dir() {
		return error('path is not a directory')
	}

	if path.file_exists('.site') {
		tree.move_site_to_collection(mut path)!
	}

	if tree.is_collection_dir(path) {
		collection_name := tree.get_collection_name(mut path)!

		tree.new_collection(
			path: path.path
			name: collection_name
			heal: args.heal
			load: true
		)!

		// TODO: should return here since a collection explores all the directories in it's path,
		// meaning that if there are other directories in collection, they would have been already explored
		return
	}

	mut entries := path.list(recursive: false) or {
		return error('cannot list: ${path.path} \n${error}')
	}

	for mut entry in entries.paths {
		if !entry.is_dir() || tree.is_ignored_dir(mut entry)! {
			continue
		}

		tree.scan(path: entry.path, heal: args.heal, load: args.load) or {
			return error('failed to scan ${entry.path} :${err}')
		}
	}
}

// returns true if directory should be ignored while scanning
fn (tree Tree) is_ignored_dir(mut path pathlib.Path) !bool {
	if !path.is_dir() {
		return error('path is not a directory')
	}

	return path.name().starts_with('.') || path.name().starts_with('_')
}

// gets collection name from .collection file or uses the directory name
fn (tree Tree) get_collection_name(mut path pathlib.Path) !string {
	mut collection_name := path.name()
	mut filepath := path.file_get('.collection')!

	// now we found a collection we need to add
	content := filepath.read()!
	if content.trim_space() != '' {
		// means there are params in there
		mut params_ := paramsparser.parse(content)!
		if params_.exists('name') {
			collection_name = params_.get('name')!
		}
	}

	return collection_name
}

fn (tree Tree) is_collection_dir(path pathlib.Path) bool {
	return path.file_exists('.collection')
}

// moves .site file to .collection file
fn (tree Tree) move_site_to_collection(mut path pathlib.Path) ! {
	collectionfilepath1 := path.extend_file('.site')!
	collectionfilepath2 := path.extend_file('.collection')!
	os.mv(collectionfilepath1.path, collectionfilepath2.path)!
}
