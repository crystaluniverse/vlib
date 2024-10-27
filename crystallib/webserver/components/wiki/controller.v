module wiki

import freeflowuniverse.crystallib.core.pathlib
import freeflowuniverse.crystallib.webserver.components {View, Sidebar, Markdown}
import freeflowuniverse.crystallib.data.markdownparser
import freeflowuniverse.crystallib.data.markdownparser.elements
import veb
import strings
import os

pub struct WikiController {
	wiki Wiki
pub:
	base_url string = 'wiki/cyberpandemic/'
mut:
	view View
}

pub struct Context {
	veb.Context
}

pub struct ControllerConfig {
pub:
	wiki Wiki
	base_url string = 'wiki/cyberpandemic/'
}

pub fn new_wiki_controller(config ControllerConfig) &WikiController {
	mut file := pathlib.get_file(path: config.wiki.summary_path) or {panic(err)}
	summary := file.read() or {panic(err)}
	summary_doc := markdownparser.new(content: summary) or {panic(err)}
	index_path := (summary_doc.children[1].children[0].children[0].children[0] as elements.Link).url
	mut sidebar := Sidebar {}
	mut prev_indentation := 0	
	html_list := summary_doc.html() or {panic(err)}
	// list := parse_html(html_list) or {panic(err)}
	// panic(summary_doc)
	// ul := list[1] as UnorderedList

	// // mut sidebar := Sidebar{}
	// mut navitems := []IComponent{}
	// for child in ul.children {
	// 	navitems << to_navitem(child)
		
	// }

	// // }
	// // panic(list[1])

	// panic('sidebargo ${sidebar}')

	base_url := config.base_url.trim_string_right('/')
	return &WikiController {
		base_url: base_url
		wiki: config.wiki
		view: View {
			layout: WikiLayout {
				sidebar: Custom{html_list.replace('<a href="', '<a up-target=":main" href="/${base_url}/')}
			}
		}
	}
}

// finds index of wiki from summary and redirects to there
pub fn (mut app WikiController) index(mut ctx Context) veb.Result {
	dollar := '$'
	mut file := pathlib.get_file(path: app.wiki.summary_path) or {panic(err)}
	summary := file.read() or {panic(err)}
	summary_doc := markdownparser.new(content: summary) or {panic(err)}
	index_path := (summary_doc.children[1].children[0].children[0].children[0] as elements.Link).url
	
	// // nav := render_nav(summary_doc) or {panic(err)}
	// html_list := summary_doc.html() or {panic(err)}
	// list := components.parse_html_list(html_list) or {panic(err)}

	// return ctx.html(list.html())
	return ctx.redirect('${ctx.req.url}/${index_path}')
}

['/:path...']
pub fn (mut app WikiController) path(mut ctx Context, path_ string) veb.Result {
	// return ctx.html('path ${path}')
	path := path_.all_after(app.base_url)
	// return ctx.html(path)
	// panic('debugzo ${path}')
	mut file := pathlib.get_file(path: os.join_path(app.wiki.directory, path)) or {
		return ctx.not_found()
	}

	if file.extension() == 'md' {
		md := markdownparser.new(content: file.read() or {panic(err)}) or {panic(err)}
		app.view.layout.main = components.Markdown{md}
	} else {
		return ctx.file(file.path)
	}
	return ctx.html(app.view.html())
}