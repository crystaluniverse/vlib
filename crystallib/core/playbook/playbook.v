module playbook

import freeflowuniverse.crystallib.core.base
import freeflowuniverse.crystallib.core.texttools
import freeflowuniverse.crystallib.data.paramsparser
import crypto.blake2b

@[heap]
pub struct PlayBook {
pub mut:
	actions    []&Action
	priorities map[int][]int // first key is the priority, the list of int's is position in list self.actions
	othertext  string        // in case there is text outside of the actions
	result     string        // if any result
	nractions  int
	done       []int // which actions did we already find/run?
	session    &base.Session
}

@[params]
pub struct ActionNewArgs {
pub mut:
	cid      string
	name     string
	actor    string
	priority int = 10 // 0 is highest, do 10 as default
	// run    bool = true // certain actions can be defined but meant to be executed directly
	actiontype ActionType
}

// add action to the book
fn (mut plbook PlayBook) action_new(args ActionNewArgs) &Action {
	plbook.nractions += 1
	mut a := Action{
		id:       plbook.nractions
		cid:      args.cid
		name:     args.name
		actor:    args.actor
		priority: args.priority
		// run: args.run
		actiontype: args.actiontype
		params:     paramsparser.Params{}
		result:     paramsparser.Params{}
	}
	plbook.actions << &a
	return &a
}

pub fn (mut plbook PlayBook) str() string {
	return plbook.heroscript() or { 'Cannot visualize playbook properly.\n${plbook.actions}' }
}

@[params]
pub struct SortArgs {
pub mut:
	prio_only bool // if true only show the actions which were prioritized before
}

// only return the actions which are not done  yet
// if filtered is set, it means we only get the ones which were prioritized before
pub fn (mut plbook PlayBook) actions_sorted(args SortArgs) ![]&Action {
	mut res := []&Action{}
	mut nrs := plbook.priorities.keys()
	nrs.sort()
	if nrs.len == 0 {
		// means sorting did not happen before
		return plbook.actions
	}
	for nr in nrs {
		if args.prio_only && nr > 49 {
			continue
		}
		action_ids := plbook.priorities[nr] or { panic('bug') }
		for id in action_ids {
			mut a := plbook.action_get(id: id)!
			res << a
		}
	}
	return res
}

@[params]
pub struct HeroScriptArgs {
pub mut:
	show_done bool = true
}

// serialize to heroscript
pub fn (mut plbook PlayBook) heroscript(args HeroScriptArgs) !string {
	mut out := ''
	for action in plbook.actions_sorted()! {
		if args.show_done == false && action.done {
			continue
		}
		out += '${action.heroscript()}\n'
	}
	if plbook.othertext.len > 0 {
		out += '${plbook.othertext}'
	}
	out = texttools.remove_empty_js_blocks(out)
	return out
}

// return list of names .
// the names are normalized (no special chars, lowercase, ... )
pub fn (mut plbook PlayBook) names() ![]string {
	mut names := []string{}
	for action in plbook.actions_sorted()! {
		names << action.name
	}
	return names
}

@[params]
pub struct ActionGetArgs {
pub mut:
	id         int
	actor      string
	name       string
	actiontype ActionType = .sal
}

// Find all actions based on ActionGetArgs
// - If id == 0, then matches all ids; when id is specified, can only return 1.
// - If actor == "", then matches all actors.
// - If name == "", then matches all actions from the defined actor (if defined).
// - If actiontype == .unknown, then matches all action types; when specified, filters by the action type, default .sal
pub fn (mut plbook PlayBook) actions_find(args ActionGetArgs) ![]&Action {
	mut res := []&Action{}
	for a in plbook.actions {
		// If id is specified, return only the action with that id
		if args.id != 0 {
			if a.id == args.id {
				return [a]
			}
			continue
		}
		// Filter by actor if specified
		if args.actor.len > 0 && a.actor != args.actor {
			continue
		}
		// Filter by name if specified
		if args.name.len > 0 && a.name != args.name {
			continue
		}
		// Filter by actiontype if specified
		if args.actiontype != .unknown && a.actiontype != args.actiontype {
			continue
		}
		// If the action passes all filters, add it to the result
		res << a
	}
	return res
}

pub fn (mut plbook PlayBook) action_exists(args ActionGetArgs) bool {
	// Use actions_find to get the filtered actions
	actions := plbook.actions_find(args) or { return false }
	if actions.len == 1 {
		return true
	} else if actions.len == 0 {
		return false
	} else {
		return false
	}
}

pub fn (mut plbook PlayBook) action_get(args ActionGetArgs) !&Action {
	// Use actions_find to get the filtered actions
	actions := plbook.actions_find(args)!
	if actions.len == 1 {
		return actions[0]
	} else if actions.len == 0 {
		return error("couldn't find action with args: ${args}")
	} else {
		return error('multiple actions found with args: ${args}, expected only one')
	}
}

pub fn (plbook PlayBook) hashkey() string {
	mut out := []string{}
	for action in plbook.actions {
		out << action.hashkey()
	}
	txt := out.join_lines()
	bs := blake2b.sum160(txt.bytes())
	return bs.hex()
}

// check if playbook is empty,if not will give error, means there are actions left to be exected
pub fn (mut plbook PlayBook) empty_check() ! {
	mut actions := []&Action{}
	for a in plbook.actions {
		if a.done == false {
			actions << a
		}
	}
	if actions.len > 0 {
		msg := plbook.heroscript(show_done: false)!
		return error('There are actions left to execute, see below:\n\n${msg}\n\n')
	}
}
