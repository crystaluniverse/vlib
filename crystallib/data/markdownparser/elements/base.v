module elements

import freeflowuniverse.crystallib.core.pathlib
// import freeflowuniverse.crystallib.core.smartid
// import freeflowuniverse.crystallib.data.paramsparser
import freeflowuniverse.crystallib.core.playbook
// import freeflowuniverse.crystallib.ui.console
// import freeflowuniverse.crystallib.core.base

@[heap]
pub struct DocBase {
mut:
	parent_doc_ ?&Doc @[skip; str: skip]
pub mut:
	id        int
	content   string
	path      ?pathlib.Path
	processed bool
	// params    paramsparser.Params
	type_name string
	changed   bool
	children  []Element
	// trailing_lf bool = true // NO LONGER NEEDED !!!!
}

fn (mut self DocBase) process_base() ! {
}

fn (mut self DocBase) parent_doc() &Doc {
	mut pd := self.parent_doc_ or {
		e := doc_new() or { panic('bug') }
		&e
	}

	return pd
}

fn (mut self DocBase) remove_empty_children() {
	self.children = self.children.filter(!(it.content == '' && it.children.len == 0
		&& it.type_name in ['text', 'empty']))
}

pub fn (mut self DocBase) process() !int {
	if self.processed {
		return 0
	}
	self.remove_empty_children()
	self.process_base()!
	self.process_children()!
	self.content = '' // because now the content is in children	
	self.processed = true
	return 1
}

@[params]
pub struct ActionsGetArgs {
pub mut:
	actor string
	name  string
}

// get all actions from the children
pub fn (self DocBase) actions(args ActionsGetArgs) []playbook.Action {
	mut out := []playbook.Action{}
	for element in self.children {
		if element is Action {
			mut found := true
			if args.actor.len > 0 && args.actor != element.action.actor {
				found = false
			}
			if args.name.len > 0 && args.name != element.action.name {
				found = false
			}
			if found {
				out << element.action
			}
		} else {
			out << element.actions(args)
		}
	}
	return out
}

pub fn (self DocBase) header_name() !string {
	for element in self.children {
		if element is Header {
			return element.content
		}
	}
	return error("couldn't find header")
}

pub fn (mut self DocBase) actionpointers(args ActionsGetArgs) []&Action {
	mut out := []&Action{}
	for mut element in self.children {
		if mut element is Action {
			mut found := true
			if args.actor.len > 0 && args.actor != element.action.actor {
				found = false
			}
			if args.name.len > 0 && args.name != element.action.name {
				found = false
			}
			if found {
				out << element
			}
		}
		out << element.actionpointers(args)
	}
	return out
}

pub fn (mut self DocBase) defpointers() []&Def {
	mut out := []&Def{}
	for mut element in self.children {
		if mut element is Def {
			out << element
		}
		out << element.defpointers()
	}
	return out
}

pub fn (self DocBase) treeview() string {
	mut out := []string{}
	self.treeview_('', mut out)
	return out.join_lines()
}

pub fn (self DocBase) children() []Element {
	return self.children
}

pub fn (mut self DocBase) process_children() !int {
	mut changes := 0
	for mut element in self.children {
		changes += element.process() or {
			return error('Failed to process child ${element.type_name}\n${err}')
		}
	}
	return changes
}

fn (self DocBase) treeview_(prefix string, mut out []string) {
	mut c := self.content
	c = c.replace('\n', '\\n')
	if c.len > 80 {
		c = c[0..80]
	}
	out << '${prefix}- ${self.id} : ${self.type_name:-30}  ${c.len}  \'${c}\''
	for mut element in self.children() {
		element.treeview_(prefix + ' ', mut out)
	}
}

pub fn (self DocBase) html() !string {
	mut out := ''
	for mut element in self.children() {
		out += element.html()!
	}
	return out
}

// example see https://github.com/RelaxedJS/ReLaXed-examples/blob/master/examples/letter/letter.pug
// is to generate pdf's
pub fn (self DocBase) pug() !string {
	mut out := ''
	for mut element in self.children() {
		out += element.pug()!
	}
	return out
}

// the markdown which represents how it created the element
pub fn (self DocBase) markdown() !string {
	mut out := ''
	for mut element in self.children() {
		out += element.markdown()!
		// console.print_debug("+++++++++++${element.markdown()!}+++++++++++")
		// if element.trailing_lf {
		// 	out += '\n'
		// }
	}
	return out
}

pub fn (self DocBase) first() !Element {
	if self.children.len == 0 {
		return error('doc has no children')
	}
	mut l := self.children.first()
	return l
}

pub fn (self DocBase) last() !Element {
	if self.children.len == 0 {
		return error('doc has no children')
	}
	mut l := self.children.last()
	return l
}

pub fn (mut self DocBase) delete_last() ! {
	if self.children.len == 0 {
		return error('doc has no children')
	}

	self.children.delete_last()
}

pub fn (mut self DocBase) content_set(element_id int, c string) {
	for mut element in self.children() {
		if element.id == element_id {
			element.content = c
		}
		element.content_set(element_id, c)
	}
}

pub fn (self DocBase) children_recursive() []Element {
	mut elements := []Element{}
	self.children_recursive_(mut elements)
	return elements
}

fn (self DocBase) children_recursive_(mut elements []Element) {
	for element in self.children() {
		elements << element
		element.children_recursive_(mut elements)
	}
}

pub fn (mut self DocBase) id_set(latestid_ int) int {
	mut latestid := latestid_
	latestid += 1
	self.id = latestid
	for mut element in self.children() {
		latestid = element.id_set(latestid)
	}
	return latestid
}
