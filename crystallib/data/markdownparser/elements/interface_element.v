module elements

import freeflowuniverse.crystallib.core.playbook
// import freeflowuniverse.crystallib.data.paramsparser

@[heap]
pub interface Element {
	markdown() !string
	html() !string
	pug() !string
	actions(ActionsGetArgs) []playbook.Action
	treeview_(string, mut []string)
	children_recursive() []Element
	children_recursive_(mut []Element)
mut:
	id        int
	content   string
	processed bool
	// params    paramsparser.Params
	type_name string
	changed   bool
	// trailing_lf bool
	children []Element
	process() !int
	content_set(int, string)
	id_set(int) int
	actionpointers(ActionsGetArgs) []&Action
	defpointers() []&Def
	header_name() !string
}

// @[heap]
// pub struct ActionPointer {
// pub mut:
// 	action     playbook.Action
// 	element_id int
// }
