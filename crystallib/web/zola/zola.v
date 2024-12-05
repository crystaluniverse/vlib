module zola

import freeflowuniverse.crystallib.core.texttools
import freeflowuniverse.crystallib.data.doctree
import freeflowuniverse.crystallib.core.pathlib
import os

@[heap]
pub struct Zola {
pub mut:
	path_build   string
	path_publish string
	tailwindcss  bool = true
	install      bool = true
	reset        bool
	sites        map[string]&ZolaSite
}

pub fn (mut self Zola) new(args_ ZolaSiteArgs) !&ZolaSite {
	mut args := args_
	args.name = texttools.name_fix(args.name)
	mut site := ZolaSite{
		name: args.name
		title: args.title
		description: args.description
		url: args.url
		// zola: &self
		tree: doctree.new(name: 'ws_${args.name}')!
	}

	self.sites[site.name] = &site

	site.path_build = pathlib.get_dir(
		path: '${self.path_build}/${args.name}'
		create: true
	)!
	if args.path_publish == '' {
		args.path_publish = '${self.path_publish}/${args.name}'
	}
	site.path_publish = pathlib.get_dir(
		path: args.path_publish
		create: true
	)!
	// make sure we have clean env
	for i in ['css', 'static', 'templates', 'content'] {
		if os.exists('${site.path_build.path}/${i}') {
			os.rmdir_all('${site.path_build.path}/${i}')!
		}
	}
	if os.exists('${site.path_build.path}/config.toml') {
		os.rm('${site.path_build.path}/config.toml')!
	}
	site.template_install()!
	return &site
}

pub fn (mut self Zola) get(name_ string) !&ZolaSite {
	name := texttools.name_fix(name_)
	return self.sites[name] or { error('cannot find zolasite with name: ${name}') }
}
