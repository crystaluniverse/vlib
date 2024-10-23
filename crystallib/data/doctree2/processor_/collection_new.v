module processor

import freeflowuniverse.crystallib.core.pathlib
import freeflowuniverse.crystallib.core.texttools

@[params]
pub struct CollectionNewArgs {
mut:
	name string @[required]
	path string @[required]
	heal bool = true // healing means we fix images, if selected will automatically load, remove stale links
	load bool = true
}

// get a new collection
pub fn (mut tree Tree) collection_new(args_ CollectionNewArgs) !&Collection {
	mut args := args_
	args.name = texttools.name_fix(args.name)

	if args.name in tree.collections {
		return error('Collection already exits')
	}

	mut pp := pathlib.get_dir(path: args.path)! // will raise error if path doesn't exist
	mut collection := &Collection{
		name: args.name
		tree: tree
		path: pp
		heal: args.heal
	}
	if args.load {
		collection.scan()!
	}

	tree.collections[collection.name] = collection
	return collection
}
