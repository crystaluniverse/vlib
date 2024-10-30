module collection

import freeflowuniverse.crystallib.core.pathlib
import freeflowuniverse.crystallib.core.texttools.regext
import os
import freeflowuniverse.crystallib.data.doctree.pointer

@[params]
pub struct CollectionExportArgs {
pub mut:
	destination    pathlib.Path                @[required]
	file_paths     map[string]string
	reset          bool = true
	keep_structure bool // wether the structure of the src collection will be preserved or not
	exclude_errors bool // wether error reporting should be exported as well
	replacer       ?regext.ReplaceInstructions
}

pub fn (mut c Collection) export(args CollectionExportArgs) ! {
	dir_src := pathlib.get_dir(path: args.destination.path + '/' + c.name, create: true)!

	mut cfile := pathlib.get_file(path: dir_src.path + '/.collection', create: true)! // will auto save it
	cfile.write("name:${c.name} src:'${c.path.path}'")!

	c.export_pages(
		dir_src: dir_src
		file_paths: args.file_paths
		keep_structure: args.keep_structure
		replacer: args.replacer
	)!
	c.export_files(dir_src, args.reset)!
	c.export_images(dir_src, args.reset)!
	c.export_linked_pages(dir_src)!

	if !args.exclude_errors {
		c.errors_report('${dir_src.path}/errors.md')!
	}
}

@[params]
pub struct ExportPagesArgs {
pub mut:
	dir_src        pathlib.Path
	file_paths     map[string]string
	keep_structure bool // wether the structure of the src collection will be preserved or not
	replacer       ?regext.ReplaceInstructions
}

// creates page file, processes page links, then writes page
fn (mut c Collection) export_pages(args ExportPagesArgs) ! {
	for _, mut page in c.pages {
		dest := if args.keep_structure {
			relpath := page.path.path.trim_string_left(c.path.path)
			'${args.dir_src.path}/${relpath}'
		} else {
			'${args.dir_src.path}/${page.name}.md'
		}

		not_found := page.process_links(args.file_paths)!
		for pointer_str in not_found {
			ptr := pointer.pointer_new(text: pointer_str)!
			cat := match ptr.cat {
				.page {
					CollectionErrorCat.page_not_found
				}
				.image {
					CollectionErrorCat.image_not_found
				}
				else {
					CollectionErrorCat.file_not_found
				}
			}
			c.error(path: page.path, msg: '${ptr.cat} ${ptr.str()} not found', cat: cat)!
		}

		mut dest_path := pathlib.get_file(path: dest, create: true)!
		mut markdown := page.get_markdown()!
		if mut replacer := args.replacer {
			markdown = replacer.replace(text: markdown)!
		}

		dest_path.write(markdown)!
	}
}

fn (mut c Collection) export_files(dir_src pathlib.Path, reset bool) ! {
	for _, mut file in c.files {
		mut d := '${dir_src.path}/img/${file.name}.${file.ext}'
		if reset || !os.exists(d) {
			file.copy(d)!
		}
	}
}

fn (mut c Collection) export_images(dir_src pathlib.Path, reset bool) ! {
	for _, mut file in c.images {
		mut d := '${dir_src.path}/img/${file.name}.${file.ext}'
		if reset || !os.exists(d) {
			file.copy(d)!
		}
	}
}

fn (mut c Collection) export_linked_pages(dir_src pathlib.Path) ! {
	collection_linked_pages := c.get_collection_linked_pages()!
	mut linked_pages_file := pathlib.get_file(path: dir_src.path + '/.linkedpages', create: true)!
	linked_pages_file.write(collection_linked_pages.join_lines())!
}

fn (mut c Collection) get_collection_linked_pages() ![]string {
	mut linked_pages_set := map[string]bool{}
	for _, mut page in c.pages {
		for linked_page in page.get_linked_pages()! {
			linked_pages_set[linked_page] = true
		}
	}

	return linked_pages_set.keys()
}
