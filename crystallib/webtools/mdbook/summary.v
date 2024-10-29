module mdbook

import freeflowuniverse.crystallib.core.pathlib
import freeflowuniverse.crystallib.core.texttools
import os

@[heap]
pub struct Summary {
pub mut:
	items       []SummaryItem
	errors      []SummaryItem // means we found errors, so we need to add to summary
	addpages    []SummaryItem // means we found pages as links, so we need to add them to the summary
	collections []string
	production  bool
}

pub struct SummaryItem {
pub mut:
	level       int
	description string
	path        string
	collection  string
	pagename    string
}

pub fn (mut book MDBook) summary(production bool) !Summary {
	if !os.exists(book.args.summary_path) {
		panic("summary file doesn't exist")
	}
	mut summary := Summary{
		production: production
	}
	mut summary_path := pathlib.get_file(path: book.args.summary_path, create: false)!
	c := summary_path.read()!

	summary_path.link('${book.path_build.path}/edit/summary.md', true)!

	mut level := 0
	mut ident := 2

	for mut line in c.split_into_lines() {
		if !(line.trim_space().starts_with('-')) {
			continue
		}
		pre := line.all_before('-')
		level = int(pre.len / ident)
		// console.print_debug("${line}  ===  '${pre}'  ${level}")
		line = line.trim_left(' -')

		// - [Dunia Yetu](dy_intro/dunia_yetu/dunia_yetu.md)
		//     - [About Us](dy_intro/dunia_yetu/about_us.md)

		if !line.starts_with('[') {
			book.error(msg: "syntax error in summary: '${line}', needs to start with [")
			continue
		}

		if !line.contains('](') {
			book.error(msg: "syntax error in summary: '${line}', needs to have ](")
			continue
		}

		description := line.all_after_first('[').all_before(']').trim_space()
		path := line.all_after_last('(').all_before_last(')').trim_space()

		if !path.contains('/') {
			book.error(
				msg: "syntax error in summary: '${line}', doesn't contain collectionname (is first element of path)"
			)
			continue
		}
		pagename := texttools.name_fix(path.all_after_last('/'))
		collection := texttools.name_fix(path.all_before('/'))

		if collection !in summary.collections {
			summary.collections << collection
		}

		mut path_collection_str := '${book.args.build_path}/src/${collection}'.replace('~',
			os.home_dir())

		mut path_collection := pathlib.get_dir(path: path_collection_str, create: false) or {
			book.error(
				msg: "collection find error in summary: '${line}', can't find collection: ${path_collection_str} "
			)
			continue
		}

		file_path := '${path_collection.path}/${pagename}'
		if !os.exists(file_path) || !os.is_file(file_path) {
			book.error(
				msg: "page find error in summary: '${line}', can't find page: ${pagename} in collection: ${path_collection_str}"
			)
			continue
		}

		// NOTE: using this returns false because path_collection is a link
		// if !path_collection.file_exists(pagename) {
		// book.error(
		// 	msg: "page find error in summary: '${line}', can't find page: ${pagename} in collection: ${path_collection_str}"
		// )
		// continue
		// }

		summary.items << SummaryItem{
			level: level
			path: path
			description: description
			pagename: pagename
			collection: collection
		}
	}

	return summary
}

fn (mut self Summary) add_error_page(collectionname string, pagename string) {
	description := 'errors ${collectionname}'
	self.errors << SummaryItem{
		level: 2
		description: description
		pagename: pagename
		collection: collectionname
	}
}

fn (mut self Summary) is_in_summary(collection_name_ string, page_name_ string) bool {
	mut collection_name := texttools.name_fix(collection_name_).to_lower()
	mut page_name := texttools.name_fix(page_name_).to_lower()
	if !(page_name.ends_with('.md')) {
		page_name += '.md'
	}

	for i in self.items {
		mut pname := texttools.name_fix(i.pagename.to_lower())
		if !(pname.ends_with('.md')) {
			pname += '.md'
		}
		if i.collection.to_lower() == collection_name && pname == page_name {
			return true
		}
	}

	for i in self.addpages {
		mut pname := texttools.name_fix(i.pagename.to_lower())
		if !(pname.ends_with('.md')) {
			pname += '.md'
		}
		if i.collection.to_lower() == collection_name && pname == page_name {
			return true
		}
	}
	return false
}

fn (mut self Summary) add_page_additional(collectionname string, pagename string) {
	if self.is_in_summary(collectionname, pagename) {
		return
	}

	shortname := pagename.all_before_last('.').to_lower()
	description := '${shortname}'
	self.addpages << SummaryItem{
		level: 2
		description: description
		pagename: pagename
		collection: collectionname
	}
}

pub fn (mut self Summary) str() string {
	mut out := []string{}

	for item in self.items {
		mut pre := ''
		for _ in 0 .. item.level {
			pre += '  '
		}
		out << '${pre}- [${item.description}](${item.collection}/${item.pagename})'
	}

	if self.addpages.len > 0 || (!self.production && self.errors.len > 0) {
		out << '- [_](additional/additional.md)'
	}

	if self.addpages.len > 0 {
		out << '  - [unlisted_pages](additional/pages.md)'
		for item in self.addpages {
			mut pre := ''
			for _ in 0 .. item.level {
				pre += '  '
			}
			out << '${pre}- [${item.description}](${item.collection}/${item.pagename})'
		}
	}

	if !self.production && self.errors.len > 0 {
		out << '  - [errors](additional/errors.md)'
		for item in self.errors {
			mut pre := ''
			for _ in 0 .. item.level {
				pre += '  '
			}
			out << '${pre}- [${item.description}](${item.collection}/${item.pagename})'
		}
	}

	return out.join_lines()
}
