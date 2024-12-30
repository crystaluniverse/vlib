module playcmds

import freeflowuniverse.crystallib.data.doctree
import freeflowuniverse.crystallib.core.playbook
import os

pub fn play_doctree(mut plbook playbook.PlayBook) ! {

	// check if any actions for doctree, if not then nothing to do here
	// dtactions := plbook.find(filter: 'doctree.')!
	// if dtactions.len == 0 {
	// 	console.print_debug("can't find doctree.add statements, nothing to do")
	// 	return
	// }

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

		// tree.scan(
		// 	path: path
		// 	git_url: url
		// 	git_reset: reset
		// 	git_root: coderoot
		// 	git_pull: pull
		// )!
		// action.done = true
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

	for mut action in plbook.find(filter: 'doctree:export')! {
		panic('implement')
		mut p := action.params
		name := p.get('name')!
		action.done = true
	}
}
