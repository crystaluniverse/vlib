module data

import freeflowuniverse.crystallib.core.texttools
import freeflowuniverse.crystallib.data.markdownparser.elements

// returns !!wiki.def actions
pub fn (mut page Page) get_def_actions() ![]elements.Action {
	mut doc := page.doc()!
	mut def_actions := doc.actionpointers(actor: 'wiki', name: 'def')
	mut ret := []elements.Action{}
	for def in def_actions {
		ret << *def
	}

	return ret
}

// returns page aliases, and removes processed action's content
pub fn (mut page Page) process_def_action(element_id int) ![]string {
	mut action_element := page.get_element(element_id)!

	mut doc := page.doc()!
	if mut action_element is elements.Action {
		mut aliases := map[string]bool{}
		def_action := action_element.action
		page.alias = def_action.params.get_default('name', '')!
		if page.alias == '' {
			page.alias = doc.header_name()!
		}

		action_element.action_processed = true
		action_element.content = ''
		page.changed = true
		for alias in def_action.params.get_list('alias')! {
			mut processed_alias := alias
			if processed_alias.to_lower().ends_with('.md') {
				// remove the .md at end
				processed_alias = processed_alias[0..page.collection_name.len - 3]
			}

			processed_alias = texttools.name_fix(processed_alias).replace('_', '')
			aliases[processed_alias] = true
		}

		return aliases.keys()
	}

	return error('element with id ${element_id} is not an action')
}
