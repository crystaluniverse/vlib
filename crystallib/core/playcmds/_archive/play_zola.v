module playcmds

import freeflowuniverse.crystallib.ui.console
import freeflowuniverse.crystallib.web.zola
import freeflowuniverse.crystallib.core.playbook

struct WebsiteItem {
mut:
	name string
	site ?&zola.ZolaSite
}

pub fn play_zola(mut plbook playbook.PlayBook) ! {
	// mut coderoot := ''
	mut buildroot := ''
	mut publishroot := ''
	mut install := true
	mut reset := false

	wsactions := plbook.find(filter: 'website.')!
	if wsactions.len == 0 {
		return
	}

	mut config_actions := plbook.find(filter: 'websites:configure')!
	if config_actions.len > 1 {
		return error('can only have 1 config action for websites')
	} else if config_actions.len == 1 {
		mut p := config_actions[0].params
		buildroot = p.get_default('buildroot', '')!
		publishroot = p.get_default('publishroot', '')!
		// coderoot = p.get_default('coderoot', '')!
		install = p.get_default_true('install')
		reset = p.get_default_false('reset')
		config_actions[0].done = true
	}
	mut websites := zola.new(
		path_build:   buildroot
		path_publish: publishroot
		install:      install
		reset:        reset
	)!

	mut ws := WebsiteItem{}

	for mut action in plbook.find(filter: 'website.')! {
		if action.name == 'define' {
			console.print_debug('website.define')
			mut p := action.params
			ws.name = p.get('name')!
			title := p.get_default('title', '')!
			description := p.get_default('description', '')!
			ws.site = websites.new(name: ws.name, title: title, description: description)!
		} else if action.name == 'template_add' {
			console.print_debug('website.template_add')
			mut p := action.params
			url := p.get_default('url', '')!
			mut site_ := ws.site or {
				return error("can't find website for template_add, should have been defined before with !!website.define")
			}

			site_.template_add(url: url)!
		} else if action.name == 'content_add' {
			console.print_debug('website.content_add')
			mut p := action.params
			url := p.get_default('url', '')!
			mut site_ := ws.site or {
				return error("can't find website for content_add, should have been defined before with !!website.define")
			}

			site_.content_add(url: url)!
		} else if action.name == 'doctree_add' {
			console.print_debug('website.doctree_add')
			mut p := action.params
			url := p.get_default('url', '')!
			pull := p.get_default_false('pull')
			mut site_ := ws.site or {
				return error("can't find website for doctree_add, should have been defined before with !!website.define")
			}

			site_.doctree_add(url: url, pull: pull)!
		} else if action.name == 'post_add' {
			console.print_debug('website.post_add')
			mut p := action.params
			name := p.get_default('name', '')!
			collection := p.get_default('collection', '')!
			file := p.get_default('file', '')!
			page := p.get_default('page', '')!
			pointer := p.get_default('pointer', '')!
			mut site_ := ws.site or {
				return error("can't find website for doctree_add, should have been defined before with !!website.define")
			}

			site_.post_add(name: name, collection: collection, file: file, pointer: pointer) or {
				return err
			}
		} else if action.name == 'blog_add' {
			console.print_debug('website.blog_add')
			mut p := action.params
			name := p.get_default('name', '')!
			collection := p.get_default('collection', '')!
			file := p.get_default('file', '')!
			page := p.get_default('page', '')!
			pointer := p.get_default('pointer', '')!
			mut site_ := ws.site or {
				return error("can't find website for doctree_add, should have been defined before with !!website.define")
			}

			site_.blog_add(name: name)!
		} else if action.name == 'person_add' {
			console.print_debug('website.person_add')
			mut p := action.params
			name := p.get_default('name', '')!
			page := p.get_default('page', '')!
			collection := p.get_default('collection', '')!
			file := p.get_default('file', '')!
			pointer := p.get_default('pointer', '')!
			mut site_ := ws.site or {
				return error("can't find website for doctree_add, should have been defined before with !!website.define")
			}

			site_.person_add(
				name:       name
				collection: collection
				file:       file
				page:       page
				pointer:    pointer
			)!
		} else if action.name == 'people_add' {
			console.print_debug('website.people_add')
			mut p := action.params
			name := p.get_default('name', '')!
			description := p.get_default('description', '')!
			sort_by_ := p.get_default('sort_by', '')!
			mut site_ := ws.site or {
				return error("can't find website for people_add, should have been defined before with !!website.define")
			}

			sort_by := zola.SortBy.from(sort_by_)!
			site_.people_add(
				name:        name
				title:       p.get_default('title', '')!
				sort_by:     sort_by
				description: description
			)!
		} else if action.name == 'blog_add' {
			console.print_debug('website.blog_add')
			mut p := action.params
			name := p.get_default('name', '')!
			description := p.get_default('description', '')!
			sort_by_ := p.get_default('sort_by', '')!
			mut site_ := ws.site or {
				return error("can't find website for people_add, should have been defined before with !!website.define")
			}

			sort_by := zola.SortBy.from(sort_by_)!
			site_.blog_add(
				name:        name
				title:       p.get_default('title', '')!
				sort_by:     sort_by
				description: description
			)!
		} else if action.name == 'news_add' {
			console.print_debug('website.news_add')
			mut p := action.params
			name := p.get_default('name', '')!
			collection := p.get_default('collection', '')!
			pointer := p.get_default('pointer', '')!
			file := p.get_default('file', '')!
			mut site_ := ws.site or {
				return error("can't find website for news_add, should have been defined before with !!website.define")
			}

			site_.article_add(name: name, collection: collection, file: file, pointer: pointer) or {
				return err
			}
		} else if action.name == 'header_add' {
			console.print_debug('website.header_add')
			mut p := action.params
			template := p.get_default('template', '')!
			logo := p.get_default('logo', '')!
			mut site_ := ws.site or {
				return error("can't find website for doctree_add, should have been defined before with !!website.define")
			}

			site_.header_add(template: template, logo: logo)!
		} else if action.name == 'header_link_add' {
			console.print_debug('website.header_link_add')
			mut p := action.params
			page := p.get_default('page', '')!
			label := p.get_default('label', '')!
			mut site_ := ws.site or {
				return error("can't find website for header_link_add, should have been defined before with !!website.define")
			}

			site_.header_link_add(page: page, label: label)!
		} else if action.name == 'footer_add' {
			console.print_debug('website.footer_add')
			mut p := action.params
			template := p.get_default('template', '')!
			mut site_ := ws.site or {
				return error("can't find website for doctree_add, should have been defined before with !!website.define")
			}

			site_.footer_add(template: template)!
		} else if action.name == 'page_add' {
			console.print_debug('website.page_add')
			mut p := action.params
			name := p.get_default('name', '')!
			collection := p.get_default('collection', '')!
			file := p.get_default('file', '')!
			homepage := p.get_default_false('homepage')
			mut site_ := ws.site or {
				return error("can't find website for doctree_add, should have been defined before with !!website.define")
			}

			site_.page_add(name: name, collection: collection, file: file, homepage: homepage)!

			// }else if  action.name=="pull"{
			// 	mut site_:=ws.site or { return error("can't find website for pull, should have been defined before with !!website.define")}
			// 	site_.pull()!
		} else if action.name == 'section_add' {
			console.print_debug('website.section_add')
			// mut p := action.params
			// name := p.get_default('name', '')!
			// // collection := p.get_default('collection', '')!
			// // file := p.get_default('file', '')!
			// // homepage := p.get_default_false('homepage')
			// mut site_ := ws.site or {
			// 	return error("can't find website for doctree_add, should have been defined before with !!website.define")
			// }

			// site_.add_section(name: name)!

			// }else if  action.name=="pull"{
			// 	mut site_:=ws.site or { return error("can't find website for pull, should have been defined before with !!website.define")}
			// 	site_.pull()!
		} else if action.name == 'generate' {
			mut site_ := ws.site or {
				return error("can't find website for generate, should have been defined before with !!website.define")
			}

			site_.generate()!
			// site_.serve()!
		} else {
			return error("Cannot find right action for website. Found '${action.name}' which is a non understood action for !!website.")
		}
		action.done = true
	}
}
