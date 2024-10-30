module data

import freeflowuniverse.crystallib.core.texttools
import freeflowuniverse.crystallib.data.markdownparser.elements
import freeflowuniverse.crystallib.data.doctree.pointer

// Note: doc should not get reparsed after invoking this method
pub fn (mut page Page) process_links(paths map[string]string) ![]string {
	mut not_found := map[string]bool{}
	mut doc := page.doc()!
	for mut element in doc.children_recursive() {
		if mut element is elements.Link {
			mut name := texttools.name_fix_keepext(element.filename)
			mut site := texttools.name_fix(element.site)
			if site == '' {
				site = page.collection_name
			}
			pointerstr := '${site}:${name}'

			ptr := pointer.pointer_new(text: pointerstr, collection: page.collection_name)!
			mut path := paths[ptr.str()] or {
				not_found[ptr.str()] = true
				continue
			}

			if ptr.cat == .page && ptr.str() !in doc.linked_pages {
				doc.linked_pages << ptr.str()
			}

			if ptr.collection == page.collection_name {
				// same directory
				path = './' + path.all_after_first('/')
			} else {
				path = '../${path}'
			}

			if ptr.cat == .image && element.extra.trim_space() != '' {
				path += ' ${element.extra.trim_space()}'
			}

			mut out := '[${element.description}](${path})'
			if ptr.cat == .image {
				out = '!${out}'
			}

			element.content = out
			element.processed = false
			element.state = .linkprocessed
			element.process()!
		}
	}

	return not_found.keys()
}
