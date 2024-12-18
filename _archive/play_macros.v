module doctree

import freeflowuniverse.crystallib.ui.console
import freeflowuniverse.crystallib.core.playbook
import freeflowuniverse.crystallib.threefold.grid4.gridsimulator
import freeflowuniverse.crystallib.threefold.grid4.farmingsimulator
import freeflowuniverse.crystallib.biz.spreadsheet

pub fn hero_play(mut plbook playbook.PlayBook) ! {
	console.print_green('play actions (simulators)')
	farmingsimulator.play(mut plbook)!
	gridsimulator.play(mut plbook)!
}

pub fn hero_play_macro(mut tree Tree, action playbook.Action) !string {
	if action.actiontype != .macro {
		panic('should always be a macro')
	}
	console.print_green('macro: ${action.actor}:${action.name}')
	console.print_debug('${action}')
	if action.actor == 'sheet' {
		return spreadsheet.playmacro(action)!
	} else if action.actor == 'tfgridsimulation_farming' {
		return farmingsimulator.playmacro(action)!
	}
	return ''
}
