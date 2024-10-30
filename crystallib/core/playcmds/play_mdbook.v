module playcmds

import freeflowuniverse.crystallib.webtools.mdbook
import freeflowuniverse.crystallib.data.doctree
import freeflowuniverse.crystallib.core.playbook
import os

pub fn play_mdbook(mut plbook playbook.PlayBook) ! {
	mut buildroot := '${os.home_dir()}/hero/var/mdbuild'
	mut publishroot := '${os.home_dir()}/hero/www/info'
	mut coderoot := ''
	// mut install := false
	mut reset := false
	mut pull := false

	// check if any actions for doctree, if not then nothing to do here
	// dtactions := plbook.find(filter: 'doctree.')!
	// if dtactions.len == 0 {
	// 	console.print_debug("can't find doctree.add statements, nothing to do")
	// 	return
	// }

	mut config_actions := plbook.find(filter: 'books:configure')!

	if config_actions.len > 1 {
		return error('can only have 1 config action for books')
	} else if config_actions.len == 1 {
		mut p := config_actions[0].params
		if p.exists('buildroot') {
			buildroot = p.get('buildroot')!
		}
		if p.exists('coderoot') {
			coderoot = p.get('coderoot')!
		}
		if p.exists('publishroot') {
			publishroot = p.get('publishroot')!
		}
		if p.exists('reset') {
			reset = p.get_default_false('reset')
		}
		config_actions[0].done = true
	}

	mut trees := map[string]&doctree.Tree{}
	for mut action in plbook.find(filter: 'doctree:new')! {
		mut p := action.params
		name := p.get('name')!
		fail_on_error := p.get_default_false('fail_on_error')
		println('fail on error: ${fail_on_error}')
		if name in trees {
			return error('tree with name ${name} already exists')
		}

		tree := doctree.new(name: name, fail_on_error: fail_on_error)!
		trees[name] = tree
	}

	for mut action in plbook.find(filter: 'doctree:add')! {
		mut p := action.params
		url := p.get_default('url', '')!
		path := p.get_default('path', '')!
		name := p.get('name')!

		mut tree := trees[name] or { return error('tree ${name} not found') }

		tree.scan(
			path: path
			git_url: url
			git_reset: reset
			git_root: coderoot
			git_pull: pull
		)!
		action.done = true
	}

	for mut action in plbook.find(filter: 'doctree:export')! {
		mut p := action.params
		build_path := p.get('path')!
		toreplace := p.get_default('replace', '')!
		reset2 := p.get_default_false('reset')
		name := p.get('name')!
		mut tree := trees[name] or { return error('tree: ${name} not found') }

		tree.export(
			destination: build_path
			reset: reset2
			toreplace: toreplace
		)!
		action.done = true
	}

	for mut action in plbook.find(filter: 'mdbook:export')! {
		mut p := action.params
		name := p.get('name')!
		summary_url := p.get_default('summary_url', '')!
		summary_path := p.get_default('summary_path', '')!
		title := p.get_default('title', name)!
		publish_path := p.get_default('publish_path', '${publishroot}/${name}')!
		build_path := p.get_default('build_path', '${buildroot}/${name}')!
		printbook := p.get_default_false('printbook')
		foldlevel := p.get_int_default('foldlevel', 0)!
		production := p.get_default_false('production')
		reset3 := p.get_default_true('reset')
		collections := p.get_list_default('collections', [])!

		mut mdbooks := mdbook.get()!

		mut cfg := mdbooks.config()!
		cfg.path_build = buildroot
		cfg.path_publish = publishroot

		mdbooks.generate(
			name: name
			title: title
			summary_url: summary_url
			summary_path: summary_path
			publish_path: publish_path
			build_path: build_path
			printbook: printbook
			foldlevel: foldlevel
			production: production
			collections: collections
		)!
		action.done = true
	}
}
