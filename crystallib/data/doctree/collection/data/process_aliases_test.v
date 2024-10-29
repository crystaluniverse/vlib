module data

import freeflowuniverse.crystallib.core.pathlib

fn test_get_def_actions() {
	mut page1_path := pathlib.get_file(path: '/tmp/page1', create: true)!
	page1_content := "!!wiki.def alias:'tf-dev,cloud-dev,threefold-dev' name:'about us'"
	page1_path.write(page1_content)!
	mut page1 := new_page(name: 'page1', path: page1_path, collection_name: 'col1')!
	def_actions := page1.get_def_actions()!

	assert def_actions.len == 1

	action := def_actions[0].action
	assert action.params.get('name')! == 'about us'
	mut aliases := action.params.get_list('alias')!
	aliases.sort()
	assert ['cloud-dev', 'tf-dev', 'threefold-dev'] == aliases
}

fn test_process_def_action() {
	// create page with def action
	// get actions
	// process def action
	// processed page should have action removed and alias set
	mut page1_path := pathlib.get_file(path: '/tmp/page1', create: true)!
	page1_content := "!!wiki.def alias:'tf-dev,cloud-dev,threefold-dev' name:'about us'"
	page1_path.write(page1_content)!
	mut page1 := new_page(name: 'page1', path: page1_path, collection_name: 'col1')!
	def_actions := page1.get_def_actions()!

	assert def_actions.len == 1

	mut aliases := page1.process_def_action(def_actions[0].id)!
	assert page1.get_markdown()! == ''
	assert page1.alias == 'about us'

	aliases.sort()
	assert ['clouddev', 'tfdev', 'threefolddev'] == aliases
}
