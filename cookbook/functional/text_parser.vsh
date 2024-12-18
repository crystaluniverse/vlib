#!/usr/bin/env -S v -n -w -enable-globals run

import freeflowuniverse.crystallib.core.texttools

struct ProcessItem {
mut:
	name  string
	pid   int
	state ProcessState
}

enum ProcessState {
	unknown
	detached
}

pub fn processit(item_ map[string]string) ProcessItem {
	mut item := ProcessItem{}
	state_item := item_['state'] or { panic('bug') }
	item.state = match state_item.trim('() ').to_lower() {
		'detached' { .detached }
		else { .unknown }
	}
	pre := item_['pre'] or { panic('bug') }
	item.pid = pre.all_before('.').trim_space().int()
	item.name = pre.all_after('.').trim_space()
	return item
}

t2 := '
	11849.mysession	(Detached)
	17633.tracker	(Detached)
	7414.ttys003.KDSPRO	(Detached)
'

r5 := texttools.to_list_map('pre,state', t2, '').map(processit(it))
assert [
	ProcessItem{
		name:  'mysession'
		pid:   11849
		state: .detached
	},
	ProcessItem{
		name:  'tracker'
		pid:   17633
		state: .detached
	},
	ProcessItem{
		name:  'ttys003.KDSPRO'
		pid:   7414
		state: .detached
	},
] == r5

// println(r5)
