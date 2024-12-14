module collection

import freeflowuniverse.crystallib.core.pathlib
import freeflowuniverse.crystallib.core.texttools.regext
import os
import freeflowuniverse.crystallib.data.doctree.pointer
import freeflowuniverse.crystallib.data.doctree.collection.data

@[params]
pub struct CollectionExportArgs {
pub mut:
	destination    pathlib.Path @[required]
	file_paths     map[string]string
	reset          bool = true
	keep_structure bool // wether the structure of the src collection will be preserved or not
	exclude_errors bool // wether error reporting should be exported as well
	replacer       ?regext.ReplaceInstructions
}

pub fn (c Collection) export(args CollectionExportArgs) ! {
	dir_src := pathlib.get_dir(path: args.destination.path + '/' + c.name, create: true)!

	mut cfile := pathlib.get_file(path: dir_src.path + '/.collection', create: true)! // will auto save it
	cfile.write("name:${c.name} src:'${c.path.path}'")!

	mut errors := c.errors.clone()

	for _, page in c.pages {
		page.export(dir_src.path,
			file_paths: args.file_paths
			keep_structure: args.keep_structure
			replacer: args.replacer
		) or {
			if err is CollectionError {
				errors << err
			}
		}
	}

	// export files and images
	for _, file in c.files {
		file.export('${dir_src.path}/file/', reset: args.reset)!
	}
	for _, image in c.images {
		image.export('${dir_src.path}/img/', reset: args.reset)!
	}

	// export the metadata of pages linked in collection
	linked_pages := c.get_linked_pages()!
	mut linked_pages_file := pathlib.get_file(path: '${dir_src.path}/.linkedpages', create: true)!
	linked_pages_file.write(linked_pages.join_lines())!

	if !args.exclude_errors {
		c.errors_report('${dir_src.path}/errors.md', errors)!
	}
}

