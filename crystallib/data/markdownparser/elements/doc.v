module elements

import freeflowuniverse.crystallib.core.texttools

@[heap]
pub struct Doc {
	DocBase
pub mut:
	// gid smartid.GID
	pre             []HtmlSource
	linked_pages    []string // to know which collection:pages are needed to make this doc complete
	collection_name string
}

// add a css or script link to a document
//  url: is source where the data comes from, can be CDN or local link
//  path: can be relative or absolute path to the info
// 	bookname, if in memory in a book
//  chaptername, if in memory in a book
//	filename string, if in memory in a book
//  cat, is .css or .script
pub fn (mut self Doc) pre_add(arg HtmlSource) string {
	return ''
}

@[param]
pub struct HtmlSource {
pub mut:
	url         string
	path        string
	bookname    string
	chaptername string
	filename    string
	cat         HtmlSourceCat
}

enum HtmlSourceCat {
	css
	script
}

@[params]
pub struct DocNewArgs {
pub mut:
	pre             []HtmlSource
	content         string
	collection_name string
}

pub fn doc_new(args DocNewArgs) !Doc {
	mut d := Doc{
		pre:             args.pre
		collection_name: args.collection_name
	}
	return d
}

pub fn (mut self Doc) process() !int {
	if self.processed {
		return 0
	}
	self.remove_empty_children()
	self.process_base()!
	self.process_children()!
	self.id_set(0)
	self.content = '' // because now the content is in children	
	return 1
}

// pub fn (self Doc) markdown()! string {
// 	return ""
// }

pub fn (self Doc) html() !string {
	return "<body class='container'>${self.DocBase.html()!}</body>"
}

pub fn (self Doc) pug() !string {
	return ":markdown-it(linkify langPrefix='highlight-')\n${texttools.indent(self.markdown()!,
		'  ')}"
}
