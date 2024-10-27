module wiki

import freeflowuniverse.crystallib.core.pathlib
import freeflowuniverse.crystallib.webserver.components {IComponent}
import freeflowuniverse.crystallib.data.markdownparser
import freeflowuniverse.crystallib.data.markdownparser.elements
import veb
import strings
import os

pub struct Wiki {
pub:
	name string
	title string
	directory string // directory of wiki
	static_url string
	summary_path string
	content_path string
}

pub struct Custom {
pub mut:	
	content string
}

pub fn (custom Custom) html() string {
	return custom.content
}

pub struct WikiLayout {
pub mut:
	summary string
	sidebar IComponent
	main IComponent
	links string
}

pub fn (layout WikiLayout) html() string {
	dollar := '$'
	return $tmpl('./templates/wiki.html')
}

pub fn (wiki Wiki) html(path string) string {
	dollar := '$'
	mut file := pathlib.get_file(path: wiki.summary_path) or {panic(err)}
	summary := file.read() or {panic(err)}

	index_path := wiki.get_index_path(summary) or {
		panic(err)
	}

	mut index_file := pathlib.get_file(path: index_path) or {
		panic(err)
	}

	index := index_file.read() or {panic(err)}
	index_md := markdownparser.new(content: index) or {panic(err)}
	index2 := index_md.html() or {panic(err)}

	return $tmpl('./templates/wiki_copy.html')
}

fn (wiki Wiki) get_index_path(summary string) !string {
	summary_doc := markdownparser.new(content: summary) or {panic(err)}
	index_url := (summary_doc.children[1].children[0].children[0].children[0] as elements.Link).url
	return '${wiki.content_path}/${index_url}'
}
