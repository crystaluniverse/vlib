module slides

import freeflowuniverse.crystallib.core.playbook
import freeflowuniverse.crystallib.develop.gittools
import freeflowuniverse.crystallib.data.doctree
import os

pub fn play(mut plbook playbook.PlayBook) !&SlidesViewData {
	mut slides_data := SlidesViewData{}

	// Find and process the slides.define action
	define_actions := plbook.find(filter: 'slides.define')!
	if define_actions.len > 0 {
		define_action := define_actions[0]
		mut p := define_action.params
		slides_data.name = p.get('name')!
		slides_data.title = p.get('title')!
	}

	// Find and process the slides.add_slide actions
	slide_actions := plbook.find(filter: 'slides.add_slide')!
	for action in slide_actions {
		mut p := action.params
		slide := Slide{
			name: p.get('name')!
			title: p.get('title')!
			notes: p.get('notes')!
		}
		slides_data.slides << slide
	}

	mut slide_actions_coll := plbook.find(filter: 'slides.add_collection')!
	mut gs := gittools.get()!

	mut tree := doctree.new(
		name: 'slides'
	)!

	for mut action in slide_actions_coll {
		mut p := action.params
		url := p.get_default('url', '')!
		reset := p.get_default_false('reset')
		pull := p.get_default_false('pull')
		tree.scan(
			git_url: url
			git_reset: reset
			git_pull: pull
		)!
		tree.export(destination: '~/hero/var/collections/')!
		action.done = true
	}

	return &slides_data
}
