module publishing

import freeflowuniverse.crystallib.web.mdbook
import freeflowuniverse.crystallib.data.doctree
import freeflowuniverse.crystallib.core.playbook { Action }
import freeflowuniverse.crystallib.data.paramsparser { Params }
import freeflowuniverse.crystallib.develop.gittools
import freeflowuniverse.crystallib.core.pathlib
import os

pub fn play(mut plbook playbook.PlayBook) ! {
	// first lets configure are publisher
	if mut action := plbook.action_get(actor: 'publisher', name: 'configure') {
		play_configure(mut action)!
	}

	// lets add all the collections
	for mut action in plbook.find(filter: 'publisher:new_collection')! {
		mut p := action.params
		play_new_collection(mut p)!
		action.done = true
	}

	// then lets export the doctree with all its collections
	publisher.export_tree()!

	// now we can start defining books
	for mut action in plbook.find(filter: 'book:define')! {
		mut p := action.params
		play_book_define(mut p)!
		action.done = true
	}

	// finally lets publish defined books
	for mut action in plbook.find(filter: 'book:publish')! {
		p := action.params
		spawn play_book_publish(p)
		action.done = true
	}
}

fn play_configure(mut action Action) ! {
	mut p := action.params
	// Variables removed as they were unused
	if p.exists('buildroot') {
		_ = p.get('buildroot')!
	}
	if p.exists('coderoot') {
		_ = p.get('coderoot')!
	}
	if p.exists('publishroot') {
		_ = p.get('publishroot')!
	}
	if p.exists('reset') {
		_ = p.get_default_false('reset')
	}
	action.done = true
}

fn play_new_collection(mut p Params) ! {
	url := p.get_default('url', '')!
	path := p.get_default('path', '')!
	// name removed as unused
	reset := p.get_default_false('reset')
	pull := p.get_default_false('pull')

	mut tree := publisher.tree
	tree.scan_concurrent(
		path:      path
		git_url:   url
		git_reset: reset
		git_pull:  pull
	)!
	publisher.tree = tree
}

fn play_book_define(mut params Params) ! {
	summary_url := params.get_default('summary_url', '')!
	summary_path := if summary_url == '' {
		params.get('summary_path') or {
			return error('both summary url and summary path cannot be empty')
		}
	} else {
		get_summary_path(summary_url)!
	}

	name := params.get('name')!
	publisher.new_book(
		name:         name
		title:        params.get_default('title', name)!
		collections:  params.get_list('collections')!
		summary_path: summary_path
	)!
}

fn play_book_publish(p Params) ! {
	name := p.get('name')!
	params := p.decode[PublishParams]()!
	// production removed as unused
	publisher.publish(name, params)!
}

fn get_summary_path(summary_url string) !string {
	mut gs := gittools.get()!
	repo := gs.get_repo(url: summary_url, reset: false, pull: false)!

	// get the path corresponding to the summary_url dir/file
	summary_path := repo.get_path_of_url(summary_url)!
	mut summary_dir := pathlib.get_dir(path: summary_path)!

	summary_file := summary_dir.file_get_ignorecase('summary.md') or {
		summary_dir = summary_dir.parent()!
		summary_dir.file_get_ignorecase('summary.md') or {
			return error('summary from git needs to be dir or file: ${err}')
		}
	}

	return summary_file.path
}
