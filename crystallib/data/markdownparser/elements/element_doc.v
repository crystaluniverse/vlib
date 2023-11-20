module elements

import freeflowuniverse.crystallib.baobab.smartid

pub struct Doc {
	DocBase
pub mut:
	gid smartid.GID
	pre []HtmlSource
}

pub fn (mut self Doc) process() !int {
	self.process_elements()!
	self.processed = true
	return 0
}

pub fn (self Doc) markdown() string {
	return self.DocBase.markdown()
}

pub fn (mut self Doc) html() string {
	return self.DocBase.html()
}

// add a css or script link to a document
//  url: is source where the data comes from, can be CDN or local link
//  path: can be relative or absolute path to the info
// 	bookname, if in memory in a book
//  chaptername, if in memory in a book
//	filename string, if in memory in a book
//  cat, is .css or .script
pub fn (mut self Doc) pre_add(arg HtmlSource) string {
	// TODO what is this function for?
	return ''
}

[param]
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
