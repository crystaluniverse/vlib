module doctree

import freeflowuniverse.crystallib.data.doctree.collection { CollectionError }
import freeflowuniverse.crystallib.data.doctree.collection.data
import freeflowuniverse.crystallib.ui.console

// process definitions (!!wiki.def actions, elements.Def elements)
// this must be done before processing includes.
pub fn (mut tree Tree) process_defs() ! {
	console.print_green('Processing tree defs')

	for _, mut col in tree.collections {
		for _, mut page in col.pages {
			mut p := page
			mut c := col
			tree.process_page_def_actions(mut p, mut c)!
		}
	}

	for _, mut col in tree.collections {
		for _, mut page in mut col.pages {
			mut p := page
			errors := tree.replace_page_defs_with_links(mut p)!
			// report accrued errors when replacing defs with links
			for err in errors {
				col.error(err)!
			}
		}
	}
}

fn (mut tree Tree) process_page_def_actions(mut p data.Page, mut c collection.Collection) ! {
	def_actions := p.get_def_actions()!
	if def_actions.len > 1 {
		c.error(
			path: p.path
			msg:  'a page can have at most one def action'
			cat:  .def
		)!
	}

	if def_actions.len == 0 {
		return
	}

	aliases := p.process_def_action(def_actions[0].id)!
	for alias in aliases {
		if alias in tree.defs {
			c.error(
				path: p.path
				msg:  'alias ${alias} is already used'
				cat:  .def
			)!
			continue
		}

		tree.defs[alias] = p
	}
}

fn (mut tree Tree) replace_page_defs_with_links(mut p data.Page) ![]CollectionError {
	defs := p.get_def_names()!

	mut def_data := map[string][]string{}
	mut errors := []CollectionError{}
	for def in defs {
		if referenced_page := tree.defs[def] {
			def_data[def] = [referenced_page.key(), referenced_page.alias]
		} else {
			// accrue errors that occur
			errors << CollectionError{
				path: p.path
				msg:  'def ${def} is not defined'
				cat:  .def
			}
			continue
		}
	}

	p.set_def_links(def_data)!
	// return accrued collection errors for collection to handle
	return errors
}
