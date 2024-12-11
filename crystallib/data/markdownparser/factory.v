module markdownparser

import freeflowuniverse.crystallib.core.pathlib
import freeflowuniverse.crystallib.data.markdownparser.elements
import freeflowuniverse.crystallib.data.markdownparser.parsers
import os

@[params]
pub struct NewDocArgs {
pub:
	path            string
	content         string
	collection_name string
}

// get a parsed document, path is the path to the file, if not given content is needed
pub fn new(args_ NewDocArgs) !elements.Doc {
	mut args := args_
	mut doc := elements.doc_new(collection_name: args.collection_name) or {
		return error('Failed create new doc ${args.collection_name}\n${err}')
	}
	if args.path == '' {
		doc.content = args.content
	} else {
		if args.path.trim_space() == '' {
			return error('cannot process doc where path is empty and content empty \n${args}')
		}
		doc.path = pathlib.get_file(path: args.path)!
		doc.content = os.read_file(args.path) or {
			return error('Failed to load file ${args.path}: ${err}')
		}
	}

	parsers.parse_doc(mut doc) or {
		return error('Failed to parse doc ${args.path}\n${err}')
	}
	return doc
}
