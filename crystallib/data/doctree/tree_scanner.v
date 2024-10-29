module doctree

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
// path string
// heal bool // healing means we fix images, if selected will automatically load, remove stale links
// git_url   string
// git_reset bool
// git_root  string
// git_pull  bool
// ```	
pub fn (mut tree Tree) scan(args_ TreeScannerArgs) ! {
	// $if debug{console.print_debug(" - collections find recursive: $path.path")}
	mut args := args_
	if args.git_url.len > 0 {
		mut gs := gittools.get(coderoot: args.git_root)!
	 	mut repo := gs.get_repo(
			url: args.git_url
			pull: args.git_pull
			reset: args.git_reset
			reload: false
		)!
		args.path = repo.get_path()!
	}

	if args.path.len < 3 {
		return error('Path needs to be not empty.')
	}
	mut path := pathlib.get_dir(path: args.path)!
	if path.is_dir() {
		mut name := path.name()
		if path.file_exists('.site') {
			// mv .site file to .collection file
			collectionfilepath1 := path.extend_file('.site')!
			collectionfilepath2 := path.extend_file('.collection')!
			os.mv(collectionfilepath1.path, collectionfilepath2.path)!
		}
		if path.file_exists('.collection') {
			mut filepath := path.file_get('.collection')!

			// now we found a collection we need to add
			content := filepath.read()!
			if content.trim_space() != '' {
				// means there are params in there
				mut params_ := paramsparser.parse(content)!
				if params_.exists('name') {
					name = params_.get('name')!
				}
			}
			// console.print_debug('new collection: ${path.path} name:${name}')
			tree.collection_new(
				path: path.path
				name: name
				heal: args.heal
				load: true
			)!
		}

		mut pl := path.list(recursive: false) or {
			return error('cannot list: ${path.path} \n${error}')
		}

		for mut p_in in pl.paths {
			if p_in.is_dir() {
				if p_in.name().starts_with('.') || p_in.name().starts_with('_') {
					continue
				}

				tree.scan(path: p_in.path, heal: args.heal, load: args.load) or {
					msg := 'Cannot process recursive on ${p_in.path}\n${err}'
					return error(msg)
				}
			}
		}
	}
	// if args.heal {
	// 	tree.heal()!
	// }
}

// pub fn (mut tree Tree) heal() ! {
// 	for _, mut collection in tree.collections {
// 		collection.fix()!
// 	}
// }
