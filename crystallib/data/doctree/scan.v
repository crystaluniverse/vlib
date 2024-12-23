module doctree

import freeflowuniverse.crystallib.core.pathlib { Path }
import freeflowuniverse.crystallib.data.paramsparser
import freeflowuniverse.crystallib.data.doctree.collection { Collection }
import freeflowuniverse.crystallib.develop.gittools
import os
import freeflowuniverse.crystallib.core.texttools

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
		mut gs := gittools.get(coderoot: args.git_root)!
		mut repo := gs.get_repo(
			url:    args.git_url
			pull:   args.git_pull
			reset:  args.git_reset
			reload: false
		)!
		args.path = repo.get_path_of_url(args.git_url)!
	}

	if args.path.len == 0 {
		return error('Path needs to be provided.')
	}

	mut path := pathlib.get_dir(path: args.path)!
	if !path.is_dir() {
		return error('path is not a directory')
	}

	if path.file_exists('.site') {
		move_site_to_collection(mut path)!
	}

	if is_collection_dir(path) {
		collection_name := get_collection_name(mut path)!

		tree.add_collection(
			path:          path.path
			name:          collection_name
			heal:          args.heal
			load:          true
			fail_on_error: tree.fail_on_error
		)!

		return
	}

	mut entries := path.list(recursive: false) or {
		return error('cannot list: ${path.path} \n${error}')
	}

	for mut entry in entries.paths {
		if !entry.is_dir() || is_ignored_dir(entry)! {
			continue
		}

		tree.scan(path: entry.path, heal: args.heal, load: args.load) or {
			return error('failed to scan ${entry.path} :${err}')
		}
	}
}

pub fn (mut tree Tree) scan_concurrent(args_ TreeScannerArgs) ! {
	mut args := args_
	if args.git_url.len > 0 {
		mut gs := gittools.get(coderoot: args.git_root)!
		mut repo := gs.get_repo(
			url:    args.git_url
			pull:   args.git_pull
			reset:  args.git_reset
			reload: false
		)!
		args.path = repo.get_path_of_url(args.git_url)!
	}

	if args.path.len == 0 {
		return error('Path needs to be provided.')
	}

	path := pathlib.get_dir(path: args.path)!
	mut collection_paths := scan_helper(path)!
	mut threads := []thread !Collection{}
	for mut col_path in collection_paths {
		mut col_name := get_collection_name(mut col_path)!
		col_name = texttools.name_fix(col_name)

		if col_name in tree.collections {
			if tree.fail_on_error {
				return error('Collection with name ${col_name} already exits')
			}
			// TODO: handle error
			continue
		}

		threads << spawn fn (args CollectionNewArgs) !Collection {
			mut args_ := collection.CollectionNewArgs{
				name:          args.name
				path:          args.path
				heal:          args.heal
				load:          args.load
				fail_on_error: args.fail_on_error
			}
			return collection.new(args_)!
		}(
			name:          col_name
			path:          col_path.path
			heal:          args.heal
			fail_on_error: tree.fail_on_error
		)
	}

	for _, t in threads {
		new_collection := t.wait() or { return error('Error executing thread: ${err}') }
		tree.collections[new_collection.name] = &new_collection
	}
}

// internal function that recursively returns
// the paths of collections in a given path
fn scan_helper(path_ Path) ![]Path {
	mut path := path_
	if !path.is_dir() {
		return error('path is not a directory')
	}

	if path.file_exists('.site') {
		move_site_to_collection(mut path)!
	}

	if is_collection_dir(path) {
		return [path]
	}

	mut entries := path.list(recursive: false) or {
		return error('cannot list: ${path.path} \n${error}')
	}

	mut paths := []Path{}
	for mut entry in entries.paths {
		if !entry.is_dir() || is_ignored_dir(entry)! {
			continue
		}

		paths << scan_helper(entry) or { return error('failed to scan ${entry.path} :${err}') }
	}
	return paths
}

@[params]
pub struct CollectionNewArgs {
mut:
	name          string @[required]
	path          string @[required]
	heal          bool = true // healing means we fix images, if selected will automatically load, remove stale links
	load          bool = true
	fail_on_error bool
}

// get a new collection
pub fn (mut tree Tree) add_collection(args_ CollectionNewArgs) ! {
	mut args := args_
	args.name = texttools.name_fix(args.name)

	if args.name in tree.collections {
		if args.fail_on_error {
			return error('Collection with name ${args.name} already exits')
		}
		return
	}

	mut pp := pathlib.get_dir(path: args.path)! // will raise error if path doesn't exist
	mut new_collection := collection.new(
		name:          args.name
		path:          pp.path
		heal:          args.heal
		fail_on_error: args.fail_on_error
	)!

	tree.collections[new_collection.name] = &new_collection
}

// returns true if directory should be ignored while scanning
fn is_ignored_dir(path_ Path) !bool {
	mut path := path_
	if !path.is_dir() {
		return error('path is not a directory')
	}
	name := path.name()
	return name.starts_with('.') || name.starts_with('_')
}

// gets collection name from .collection file
// if no name param, uses the directory name
fn get_collection_name(mut path Path) !string {
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

fn is_collection_dir(path Path) bool {
	return path.file_exists('.collection')
}

// moves .site file to .collection file
fn move_site_to_collection(mut path Path) ! {
	collectionfilepath1 := path.extend_file('.site')!
	collectionfilepath2 := path.extend_file('.collection')!
	os.mv(collectionfilepath1.path, collectionfilepath2.path)!
}
