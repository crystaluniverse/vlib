module zola

import toml
import time
import freeflowuniverse.crystallib.data.doctree
import freeflowuniverse.crystallib.data.doctree.collection.data
import freeflowuniverse.crystallib.core.texttools
import freeflowuniverse.crystallib.core.pathlib
import freeflowuniverse.crystallib.data.markdownparser.elements
import freeflowuniverse.crystallib.data.markdownparser

// ZolaPage extends doctree page with zola specific metadata
pub struct ZolaPage {
	PageFrontMatter
	data.Page
pub mut:
	name     string
	path     string
	homepage bool
	template string
	// document elements.Doc   // markdown document of the page
	assets []pathlib.Path // a list of paths to assets
}

pub struct PageFrontMatter {
pub mut:
	id              string
	title           string
	description     string
	date            time.Time
	updated         time.Time
	weight          int
	draft           bool
	slug            string              @[omitempty]
	path            string
	aliases         []string
	authors         []string
	in_search_index bool = true
	template        string
	taxonomies      map[string][]string
	extra           map[string]toml.Any
}

pub struct PageAddArgs {
pub:
	name       string
	collection string @[required]
	file       string @[required]
	homepage   bool
	template   string
	path       string
}

pub fn (mut site ZolaSite) page_add(args PageAddArgs) ! {
	site.page_add_check_args(args) or { return error('Can\'t add page `${args.name}`: ${err}') }

	mut page := site.tree.page_get('${args.collection}:${args.file}') or { return err }

	pages_dir := pathlib.get_dir(
		path: '${site.path_build.path}/pages'
		create: true
	)!
	collection_file := pathlib.get_file(
		path: '${site.path_build.path}/pages/.collection'
		create: true
	)!

	mut zola_page := new_page(
		name: args.name
		homepage: args.homepage
		template: args.template
		Page: page
	)!

	front_matter := zola_page.PageFrontMatter.markdown()
	page.set_content('+++\n${front_matter}\n+++\n\n${page.get_markdown()!}')!
	// doc := markdownparser.new(content: '+++\n${front_matter}\n+++\n\n${page.doc()!.markdown()!}')!
	// page.doc_ = &doc
	// page.export(dest: '${pages_dir.path}/${page.name}.md')!
	// zola_page.doc_ = &doc
	site.pages << zola_page
}

fn new_page(page_ ZolaPage) !ZolaPage {
	mut page := ZolaPage{
		...page_
		Page: page_.Page
	}
	page.name = texttools.name_fix(page.name)

	if page.taxonomies.values().any('' in it) {
		return error('A taxonomy term cannot be an empty string')
	}
	return page
}

// checks the arguments provided to add page, returns error if error in arguments
fn (mut site ZolaSite) page_add_check_args(args PageAddArgs) ! {
	if site.pages.any(it.name == args.name) {
		return error('page with name `${args.name}` was already added')
	}
	if args.homepage && site.pages.any(it.homepage) {
		homepages := site.pages.filter(it.homepage)
		if homepages.len != 1 {
			panic('this should never happen')
		}
		return error('`${homepages[0].name}` was already added as homepage')
	}
	_ := site.tree.get_collection(args.collection) or { return err }
	_ := site.tree.page_get('${args.collection}:${args.file}') or { return err }
}

pub fn (mut page ZolaPage) export(content_dir string) ! {
	front_matter := page.PageFrontMatter.markdown()
	content := page.get_markdown()!

	page_dir := pathlib.get_dir(
		path: '${content_dir}/${page.name}'
	)!

	mut p := pathlib.get_file(path: '${content_dir}/home/index.md', create: true)!
	if !page.homepage {
		p = pathlib.get_file(path: '${content_dir}/${page.name}/index.md', create: true)!
	}
	p.write(page.get_markdown()!)!

	// if page.homepage {
	// 	page.Page.export(dest: '${content_dir}/home/index.md')!
	// } else {
	// 	page.Page.export(dest: '${content_dir}/${page.name}/index.md')!
	// }

	mut page_file := pathlib.get_file(path: '${page_dir.path}/index.md')!
	page_file.write('+++\n${front_matter}\n+++\n${content}')!

	for mut asset in page.assets {
		asset.copy(dest: page_dir.path)!
	}
}

fn (p PageFrontMatter) markdown() string {
	front_matter := toml.encode(p)
	mut lines := front_matter.split_into_lines()
	for i, mut line in lines {
		line = line.trim_space()
		if line.starts_with('date =') {
			if p.date.unix() <= 1 {
				line = ''
				continue
			}
			line = 'date = ${p.date.ymmdd()}'
		}
		if line.starts_with('updated = ') {
			// if p.updated.unix_milli() == 0 {
			line = ''
			continue
			// }
			// line = 'updated = ${p.updated.ymmdd()}'
		} else if line.starts_with('slug = ') {
			if p.slug == '' {
				line = ''
				continue
			}
		} else if line.starts_with('path = ') {
			if p.path == '' {
				line = ''
				continue
			}
		} else if line.starts_with('template = ') {
			if p.template == '' {
				line = ''
				continue
			}
		} else if line.starts_with('sort_by = ') {
			line = ''
			continue
		} else if line.starts_with('extra = ') {
			if p.extra.len == 0 {
				line = ''
				continue
			}
			line = 'extra = {${p.extra.to_toml()}}'
		}
	}
	return lines.filter(it != '').join_lines()
}
