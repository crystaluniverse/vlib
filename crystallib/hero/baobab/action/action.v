module action

import crypto.blake2b
import freeflowuniverse.crystallib.data.paramsparser
import freeflowuniverse.crystallib.core.texttools
// import freeflowuniverse.crystallib.core.smartid

pub struct Action {
pub mut:
	id       int
	cid      string
	name     string
	actor    string
	priority int = 10 // 0 is highest, do 10 as default
	params   paramsparser.Params
	result   paramsparser.Params // can be used to remember outputs
	// run    bool = true // certain actions can be defined but meant to be executed directly
	actiontype ActionType = .sal
	comments   string
	done       bool // if done then no longer need to process
}

pub enum ActionType {
	unknown
	dal
	sal
	wal
	macro
}

pub fn (action Action) str() string {
	mut out := action.heroscript()
	if !action.result.empty() {
		out += '\n\nResult:\n'
		out += texttools.indent(action.result.heroscript(), '    ')
	}
	return out
}

// serialize to heroscript
pub fn (action Action) heroscript() string {
	mut out := ''
	if action.comments.len > 0 {
		out += texttools.indent(action.comments, '// ')
	}
	if action.actiontype == .sal {
		out += '!!'
	} else if action.actiontype == .macro {
		out += '!!!'
	} else {
		panic('only action sal and macro supported for now,\n${action}')
	}

	if action.actor != '' {
		out += '${action.actor}.'
	}
	out += '${action.name} '
	if action.id > 0 {
		out += 'id:${action.id} '
	}
	if !action.params.empty() {
		heroscript := action.params.heroscript()
		heroscript_lines := heroscript.split_into_lines()
		out += heroscript_lines[0] + '\n'
		for line in heroscript_lines[1..] {
			out += '    ' + line + '\n'
		}
	}
	return out
}

// return list of names .
// the names are normalized (no special chars, lowercase, ... )
pub fn (action Action) names() []string {
	mut names := []string{}
	for name in action.name.split('.') {
		names << texttools.name_fix(name)
	}
	return names
}

pub enum ActionState {
	init // first state
	next // will continue with next steps
	restart
	error
	done // means we don't process the next ones
}

// get hash from the action, should always be the same for the same action
pub fn (action Action) hashkey() string {
	txt := action.heroscript()
	bs := blake2b.sum160(txt.bytes())
	return bs.hex()
}
